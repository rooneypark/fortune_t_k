class_name RunState
extends RefCounted
## One run (= one stage on one difficulty, 10 waves): the 천명 slot (군량 is the
## account's: 1 per spin, at most spins_per_battle spins a run, 개편 §13),
## recruiting straight onto the field, absorb (성급 / 속성), castle health,
## respawn times. 스테이지-흡수-합성-개편 §3.2: no lineup, no bench, no hero limit —
## every owned troop and hero is on the reels and a recruit stands on the field.
## No nodes: the battle screen owns the battlefield and asks this object.

signal changed

var rng: RandomNumberGenerator
## The account: absorbing writes 성급 경험 and 속성 here at once (개편 §9.2).
var account: Profile
var slot := SlotMachine.new()
var stage := 1
var diff := 1
var waves: Array = []
## Hero ids on the reels (every owned hero).
var heroes: Array = []
var soldiers: Array = []
## Fixed 책사 (tests / tutorial); "" = the first hero on the field with a slot skill.
var advisor_fixed := ""
var advisor: String:
	get:
		if advisor_fixed != "":
			return advisor_fixed
		for u in field:
			if u.is_hero() and not DB.advisor_skill(u.id).is_empty():
				return u.id
		return ""

## 0-based wave index.
var wave := 0
## Spins made this run (다시 돌리기는 세지 않는다).
var spins := 0
var field_cap := 0
var field_cap_bought := 0
var castle_hp := 0
var castle_max := 0
var field: Array[UnitState] = []
var last_result: Dictionary = {}
var advisor_used := false
var hero_boost_next := false
## 책사 "동남풍": the next spin wins with slot_lucky_chance per reel.
var lucky_next := false
var continued := false
## Counters for missions / results.
var stats := {"spins": 0, "jackpots": 0, "absorbs": 0, "traits": 0, "stars": 0, "new_units": 0, "kills": 0, "streak": 0, "best_streak": 0}


func _init(random: RandomNumberGenerator, hero_ids: Array = [], soldier_ids: Array = [],
		s: int = 1, d: int = 1, acc: Profile = null) -> void:
	DB.ensure()
	rng = random
	account = acc if acc != null else Profile.new()
	stage = s
	diff = d
	waves = DB.stage_waves(s, d)
	var r := DB.rules
	heroes = hero_ids.duplicate()
	soldiers = soldier_ids if not soldier_ids.is_empty() else r["soldiers_base"]
	field_cap = int(r["field_cap_base"])
	castle_max = int(r["castle_hp"])
	castle_hp = castle_max
	slot.setup(heroes, soldiers, int(r["strip_length"]), rng)


# ---------------------------------------------------------------- costs

## 군량 the account has now (시간으로 차고 금으로 산다).
var rice: int:
	get:
		return account.rice_now()


## 군량 for one spin.
func spin_cost() -> int:
	return int(DB.rules["spin_rice"])


## 군량 for shifting one blank reel (재배치).
func nudge_cost() -> int:
	return int(DB.rules["respin_rice"])


func spins_max() -> int:
	return int(DB.rules["spins_per_battle"])


func spins_left() -> int:
	return maxi(0, spins_max() - spins)


func field_full() -> bool:
	return field.size() >= field_cap


## Why a spin is not possible now, or "": the run's spins are used up, the field
## is full (absorb or buy a slot), or the account has no 군량.
func spin_block_reason() -> String:
	if spins_left() <= 0:
		return DB.t("battle.no_spins")
	if field_full():
		return DB.t("battle.field_full")
	if rice < spin_cost():
		return DB.t("battle.no_rice")
	return ""


func can_nudge() -> bool:
	return slot.can_nudge and rice >= nudge_cost() and not field_full()


## 금 for the next field slot (this run only), or -1 at the limit.
func field_cap_cost() -> int:
	var costs: Array = DB.rules["field_cap_costs"]
	return -1 if field_cap_bought >= costs.size() else int(costs[field_cap_bought])


func buy_field_cap() -> bool:
	var c := field_cap_cost()
	if c < 0 or not account.pay("gold", c):
		return false
	field_cap += 1
	field_cap_bought += 1
	changed.emit()
	return true


# ---------------------------------------------------------------- slot

## Pays and spins. Returns {result, events} or {} when blocked.
func spin() -> Dictionary:
	if spin_block_reason() != "":
		return {}
	account.spend_rice(spin_cost())
	spins += 1
	stats["spins"] += 1
	# 전장에 아무도 없으면 최소 1칸은 당첨 (개편 §9.9 보장)
	last_result = slot.spin(rng, hero_boost_next, lucky_next, 1 if field.is_empty() else 0)
	hero_boost_next = false
	lucky_next = false
	var events := _apply(last_result)
	changed.emit()
	return {"result": last_result, "events": events}


## Pays and shifts the blank [param reel] ([param dir] +1 = down: the cell above
## comes into the row, -1 = up). Returns {result, events} or {}.
func nudge(reel: int, dir: int) -> Dictionary:
	if not can_nudge():
		return {}
	var res := slot.nudge(reel, dir)
	if res.is_empty():
		return {}
	account.spend_rice(nudge_cost())
	last_result = res
	var events := _apply(res)
	changed.emit()
	return {"result": res, "events": events}


## Advisor skill type of the current advisor ("respin", "lucky", "hero_boost").
func advisor_type() -> String:
	return String(DB.advisor_skill(advisor).get("type", "respin"))


## True when the advisor button should be lit.
func advisor_ready() -> bool:
	if advisor_used or advisor == "" or DB.advisor_skill(advisor).is_empty():
		return false
	match advisor_type():
		"respin":
			return not last_result.is_empty() and slot.first_blank() >= 0 and not field_full()
		_:
			return true


## Uses the advisor skill (GDD §3.3b), once per wave. [param reel] for respin
## (a blank reel). Returns {result, events} for respin, {ok: true} for buffs, or {}.
func use_advisor(reel: int = 0) -> Dictionary:
	if not advisor_ready():
		return {}
	match advisor_type():
		"respin":
			var res := slot.respin_reel(reel, rng)
			if res.is_empty():
				return {}
			advisor_used = true
			last_result = res
			var events := _apply(res)
			changed.emit()
			return {"result": res, "events": events}
		"lucky":
			lucky_next = true
		"hero_boost":
			hero_boost_next = true
	advisor_used = true
	changed.emit()
	return {"ok": true}


## Turns a slot result into units. Event types:
## field (a new unit stands on the field; "new": true when the hero / troop just
## joined the account), lost (no room left), refund (잭팟: 군량 comes back).
func _apply(res: Dictionary) -> Array:
	var events: Array = []
	var recruits: Array = res["recruits"]
	if recruits.is_empty():
		stats["streak"] = 0
		return events
	stats["streak"] += 1
	stats["best_streak"] = maxi(int(stats["best_streak"]), int(stats["streak"]))
	for rc: Dictionary in recruits:
		events.append_array(recruit(String(rc["id"])))
	if bool(res.get("jackpot", false)):
		stats["jackpots"] += 1
		var back := int(DB.rules["jackpot_refund_rice"])
		account.add_rice(back)
		events.append({"type": "refund", "rice": back})
	return events


## Adds one recruited unit to the field, or loses it when the field is full
## (several winning reels can overflow the last free slots). A hero that is
## already on the field is not merged: the copy stands beside it (개편 §3.3).
## A hero or troop the account does not have yet joins it here, for good (개편 §13:
## 캐릭터는 전투 중 슬롯에서만 얻는다) — also when there is no room for the body.
func recruit(id: String) -> Array:
	var is_new := account.join(id)
	if is_new:
		stats["new_units"] += 1
	var u := UnitState.create(id, 0)
	if field_full():
		return [{"type": "lost", "unit": u, "new": is_new}]
	field.append(u)
	return [{"type": "field", "unit": u, "summon": true, "new": is_new}]


func heroes_on_field() -> int:
	var n := 0
	for u in field:
		if u.is_hero():
			n += 1
	return n


func remove_unit(u: UnitState) -> void:
	field.erase(u)


# ---------------------------------------------------------------- absorb (개편 §9.2)

func star_of(u: UnitState) -> int:
	return account.unit_star(u.id)


## 속성 of a unit: [{id, lv}] (the hero's own, or its troop's for a soldier).
func traits_of(u: UnitState) -> Array:
	return MetaRules.unit_traits(account.data, u.id)


func trait_slots(u: UnitState) -> int:
	return MetaRules.trait_slots(star_of(u))


## How [param food] would be absorbed by [param target]:
## same 병종 -> {ok, mode: "star", xp}; another 병종 -> {ok, mode: "trait"}.
## Not ok: {ok: false, reason}.
func absorb_check(food: UnitState, target: UnitState) -> Dictionary:
	if food == target or food == null or target == null:
		return {"ok": false, "reason": ""}
	if account.unit_entry(target.id).is_empty():
		return {"ok": false, "reason": DB.t("absorb.guest")}
	if food.troop() == target.troop():
		if star_of(target) >= MetaRules.star_max():
			return {"ok": false, "reason": DB.t("absorb.max_star")}
		return {"ok": true, "mode": "star", "xp": MetaRules.star_xp(food.id, target.id)}
	return {"ok": true, "mode": "trait"}


## Same-병종 absorb: food disappears, the target's 성급 경험 rises in the account.
## Returns {gained, star, xp, need}, or {} when not allowed.
func absorb_star(food: UnitState, target: UnitState) -> Dictionary:
	var chk := absorb_check(food, target)
	if not chk["ok"] or chk["mode"] != "star":
		return {}
	var res := account.add_star_xp(target.id, int(chk["xp"]))
	if res.is_empty():
		return {}
	remove_unit(food)
	stats["absorbs"] += 1
	stats["stars"] += 1
	changed.emit()
	return res


## The three 속성 of food's troop for the picker, with the target's level of each:
## [{id, name, descs, lv (0 = not owned), maxed}].
func trait_options(food: UnitState, target: UnitState) -> Array:
	var out: Array = []
	for tr: Dictionary in DB.traits_for(food.troop()):
		var d := tr.duplicate()
		d["lv"] = MetaRules.trait_level(account.data, target.id, String(tr["id"]))
		d["maxed"] = int(d["lv"]) >= MetaRules.trait_max()
		out.append(d)
	return out


## Other-병종 absorb: the target takes [param trait_id] of food's troop (+1 level
## when it already has it). When all slots are full, [param replace_index] names
## the 속성 to swap out. Returns success; the food stays when it fails.
func absorb_trait(food: UnitState, target: UnitState, trait_id: String, replace_index: int = -1) -> bool:
	var chk := absorb_check(food, target)
	if not chk["ok"] or chk["mode"] != "trait":
		return false
	var offered := false
	for tr: Dictionary in DB.traits_for(food.troop()):
		if String(tr["id"]) == trait_id:
			offered = true
	if not offered or account.set_trait(target.id, trait_id, replace_index) != "":
		return false
	remove_unit(food)
	stats["absorbs"] += 1
	stats["traits"] += 1
	changed.emit()
	return true


# ---------------------------------------------------------------- waves & castle

## Seconds a fallen unit waits: soldier 5 / hero 12 (GDD §3.6).
func respawn_time(u: UnitState) -> float:
	var r := DB.rules
	return float(r["respawn_hero"]) if u.is_hero() else float(r["respawn_soldier"])


func damage_castle(amount: float) -> void:
	castle_hp = maxi(0, castle_hp - int(round(amount)))
	changed.emit()


func castle_fallen() -> bool:
	return castle_hp <= 0


func castle_ratio() -> float:
	return float(castle_hp) / float(maxi(1, castle_max))


## Reset after a cleared wave: the castle mends 10 %. Returns {castle}.
## (군량은 전투 안에서 벌지 않는다.)
func finish_wave() -> Dictionary:
	var heal := mini(castle_max - castle_hp, int(round(castle_max * float(DB.rules["castle_regen"]))))
	castle_hp += heal
	wave += 1
	advisor_used = false
	slot.can_nudge = false
	changed.emit()
	return {"castle": heal}


func wave_count() -> int:
	return waves.size()


func is_last_wave() -> bool:
	return wave >= waves.size() - 1


func current_wave() -> Dictionary:
	return waves[clampi(wave, 0, waves.size() - 1)]


## Continue after defeat (다이아/광고, once per run): castle back to half.
func revive() -> bool:
	if continued:
		return false
	continued = true
	castle_hp = castle_max / 2
	changed.emit()
	return true


## Stage stars (콘텐츠 §2.3): clear, castle >= 50 %, castle >= 90 %.
func stars_earned(victory: bool) -> int:
	if not victory:
		return 0
	var n := 1
	if castle_ratio() >= 0.5:
		n += 1
	if castle_ratio() >= 0.9:
		n += 1
	return n
