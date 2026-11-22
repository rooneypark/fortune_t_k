class_name RunState
extends RefCounted
## One run (= one stage, 10 waves) under GDD v5: 군량, the 천명 slot, recruiting
## into the field or the bench, absorb (rank / trait), castle health, respawn
## times. No nodes: the battle screen owns the battlefield and asks this object.

signal changed

var rng: RandomNumberGenerator
var slot := SlotMachine.new()
var chapter := 1
var stage := 1
var waves: Array = []
var lineup: Array = []
var soldiers: Array = []
var advisor := ""

var rice := 0
## 0-based wave index.
var wave := 0
var spins_this_wave := 0
var field_cap := 0
var hero_quota := 0
var field_cap_bought := 0
var hero_quota_bought := 0
var castle_hp := 0
var castle_max := 0
var field: Array[UnitState] = []
var bench: Array[UnitState] = []
var bench_size := 8
## faction id -> attack bonus this wave (faction lines).
var faction_buff: Dictionary = {}
var last_result: Dictionary = {}
var advisor_used := false
var faction_double := false
var hero_boost_next := false
var free_nudge := false
var continued := false
## Tutorial: newly recruited units go to the bench.
var force_bench := false
## Tutorial: reserve 1 hero quota slot so 장수 배치 단계에서 장비가 막히지 않게.
var reserve_tutorial_hero := false
## Counters for missions / results.
var stats := {"spins": 0, "jackpots": 0, "absorbs": 0, "traits": 0, "kills": 0, "streak": 0, "best_streak": 0}


func _init(random: RandomNumberGenerator, lineup_heroes: Array = [], soldier_ids: Array = [],
		advisor_id: String = "", c: int = 1, s: int = 1) -> void:
	DB.ensure()
	rng = random
	chapter = c
	stage = s
	waves = DB.stage_waves(c, s)
	var r := DB.rules
	lineup = lineup_heroes.slice(0, int(r["hero_lineup_max"]))
	soldiers = soldier_ids if not soldier_ids.is_empty() else r["soldiers_base"]
	advisor = advisor_id
	rice = int(r["start_rice"])
	field_cap = int(r["field_cap_base"])
	hero_quota = int(r["hero_quota_base"])
	bench_size = int(r["bench_size"])
	castle_max = int(r["castle_hp"])
	castle_hp = castle_max
	slot.setup(lineup, soldiers, int(r["strip_length"]), int(r["weight_soldier"]), int(r["weight_hero"]), rng)


# ---------------------------------------------------------------- costs

## 군량 for the next spin: base + step x spins already made this wave (GDD §7).
func spin_cost() -> int:
	return int(DB.rules["spin_base"]) + int(DB.rules["spin_step"]) * spins_this_wave


## Price of the last spin (for the nudge and the max-rank refund).
func last_spin_price() -> int:
	return int(DB.rules["spin_base"]) + int(DB.rules["spin_step"]) * maxi(0, spins_this_wave - 1)


## Nudge = 1/4 of the spin that missed (GDD §3.2-6).
func nudge_cost() -> int:
	if free_nudge:
		return 0
	return int(round(last_spin_price() * float(DB.rules["nudge_ratio"])))


## Why a spin is not possible now, or "".
func spin_block_reason() -> String:
	if bench.size() >= bench_size:
		return DB.t("battle.bench_full")
	if rice < spin_cost():
		return DB.t("battle.no_rice")
	return ""


func can_nudge() -> bool:
	return slot.can_nudge and rice >= nudge_cost()


func field_cap_cost() -> int:
	var costs: Array = DB.rules["field_cap_costs"]
	return -1 if field_cap_bought >= costs.size() else int(costs[field_cap_bought])


func hero_quota_cost() -> int:
	var costs: Array = DB.rules["hero_quota_costs"]
	return -1 if hero_quota_bought >= costs.size() else int(costs[hero_quota_bought])


func buy_field_cap() -> bool:
	var c := field_cap_cost()
	if c < 0 or rice < c:
		return false
	rice -= c
	field_cap += 1
	field_cap_bought += 1
	changed.emit()
	return true


func buy_hero_quota() -> bool:
	var c := hero_quota_cost()
	if c < 0 or rice < c:
		return false
	rice -= c
	hero_quota += 1
	hero_quota_bought += 1
	changed.emit()
	return true


# ---------------------------------------------------------------- slot

## Pays and spins. Returns {result, events} or {} when blocked.
func spin() -> Dictionary:
	if spin_block_reason() != "":
		return {}
	rice -= spin_cost()
	spins_this_wave += 1
	stats["spins"] += 1
	free_nudge = false
	last_result = slot.spin(rng, hero_boost_next)
	hero_boost_next = false
	var events := _apply(last_result)
	changed.emit()
	return {"result": last_result, "events": events}


## Pays and nudges [param reel] by [param dir]. Returns {result, events} or {}.
func nudge(reel: int, dir: int) -> Dictionary:
	if not can_nudge():
		return {}
	var cost := nudge_cost()
	var res := slot.nudge(reel, dir)
	if res.is_empty():
		return {}
	rice -= cost
	free_nudge = false
	last_result = res
	var events := _apply(res)
	changed.emit()
	return {"result": res, "events": events}


## Advisor skill type of the current advisor ("respin", "faction_double", ...).
func advisor_type() -> String:
	return String(DB.advisor_skill(advisor).get("type", "respin"))


## True when the advisor button should be lit.
func advisor_ready() -> bool:
	if advisor_used or advisor == "" or DB.advisor_skill(advisor).is_empty():
		return false
	match advisor_type():
		"respin", "free_nudge":
			return slot.can_nudge
		_:
			return true


## Uses the advisor skill (GDD §3.3b), once per wave. [param reel] for respin.
## Returns {result, events} for respin, {ok: true} for buffs, or {}.
func use_advisor(reel: int = 0) -> Dictionary:
	if not advisor_ready():
		return {}
	advisor_used = true
	match advisor_type():
		"respin":
			last_result = slot.respin_reel(reel, rng)
			var events := _apply(last_result)
			changed.emit()
			return {"result": last_result, "events": events}
		"free_nudge":
			free_nudge = true
		"faction_double":
			faction_double = true
			for f: String in faction_buff:
				faction_buff[f] = float(DB.rules["faction_line_atk"]) * 2.0
		"hero_boost":
			hero_boost_next = true
	changed.emit()
	return {"ok": true}


## Turns a slot result into units. Event types:
## field / bench (new unit), rank (an owned hero absorbed the copy),
## refund (owned hero already max rank), merged (overflow absorbed), lost.
func _apply(res: Dictionary) -> Array:
	var events: Array = []
	var bonus := float(DB.rules["faction_line_atk"]) * (2.0 if faction_double else 1.0)
	for f: String in res["factions"]:
		faction_buff[f] = bonus
	var lines: Array = res["lines"]
	if lines.is_empty():
		stats["streak"] = 0
	else:
		stats["streak"] += 1
		stats["best_streak"] = maxi(int(stats["best_streak"]), int(stats["streak"]))
		for l: Dictionary in lines:
			if l["kind"] == "unit":
				stats["jackpots"] += 1
			events.append_array(_summon_one_for_line(l))
	return events


## 줄 완성 소환 (2026-11-22 재설계): 같은 병종 한 줄 = 1명.
## 줄에 장수가 끼어 있으면 그 장수만 들어온다 (창병·창병·관우 -> 관우).
## 이미 이 런에 있는 장수면 등급 경험, 장수 칸(최대 3)이 차면 대기석.
## 장수가 없으면 그 병종 병사 1명.
func _summon_one_for_line(l: Dictionary) -> Array:
	var heroes: Array = l.get("heroes", [])
	if not heroes.is_empty():
		var out: Array = []
		for h: Variant in heroes:
			out.append_array(recruit(String(h)))
		return out
	var troop := String(l.get("troop", ""))
	if troop == "" or not DB.is_soldier(troop):
		return []
	var u := UnitState.create(troop, 0)
	if not force_bench and _field_has_room_for(u):
		field.append(u)
		return [{"type": "field", "unit": u, "summon": true, "line_summon": true}]
	if bench.size() < bench_size:
		bench.append(u)
		return [{"type": "bench", "unit": u, "line_summon": true}]
	return []


## Adds one recruited unit carrying [param xp] (merged copies).
func recruit(id: String, xp: int = 0) -> Array:
	if DB.is_hero(id):
		var owned := find_owned(id)
		if owned != null:
			if owned.is_max_rank():
				var refund := int(round(last_spin_price() * float(DB.rules["max_rank_refund_ratio"])))
				rice += refund
				return [{"type": "refund", "unit": owned, "rice": refund}]
			var gained := owned.add_xp(int(DB.rules["absorb_same_unit"]) + xp)
			return [{"type": "rank", "unit": owned, "gained": gained}]
	var u := UnitState.create(id, xp)
	if not force_bench and _field_has_room_for(u):
		field.append(u)
		return [{"type": "field", "unit": u, "summon": true}]
	if bench.size() < bench_size:
		bench.append(u)
		return [{"type": "bench", "unit": u}]
	# Overflow (GDD §8): absorb into a same-class unit, else lost.
	for host in field + bench:
		if host.cls() == u.cls() and not host.is_max_rank():
			host.add_xp((int(DB.rules["absorb_same_unit"]) if host.id == u.id else int(DB.rules["absorb_same_class"])) + xp)
			return [{"type": "merged", "unit": host}]
	return [{"type": "lost", "unit": u}]


func _field_has_room_for(u: UnitState) -> bool:
	if field.size() >= field_cap:
		return false
	return not u.is_hero() or heroes_on_field() < hero_quota


func find_owned(id: String) -> UnitState:
	for u in field:
		if u.id == id:
			return u
	for u in bench:
		if u.id == id:
			return u
	return null


func heroes_on_field() -> int:
	var n := 0
	for u in field:
		if u.is_hero():
			n += 1
	return n


func remove_unit(u: UnitState) -> void:
	field.erase(u)
	bench.erase(u)


## Bench -> field. Returns "" or the reason it failed.
func deploy(u: UnitState) -> String:
	if not bench.has(u):
		return "?"
	if field.size() >= field_cap:
		return DB.t("battle.field_full")
	if u.is_hero() and heroes_on_field() >= hero_quota:
		return DB.t("battle.hero_full")
	bench.erase(u)
	field.append(u)
	changed.emit()
	return ""


## Field -> bench (prep only, checked by the caller). Returns "" or the reason.
func to_bench(u: UnitState) -> String:
	if not field.has(u):
		return "?"
	if bench.size() >= bench_size:
		return DB.t("battle.bench_full")
	field.erase(u)
	bench.append(u)
	changed.emit()
	return ""


# ---------------------------------------------------------------- absorb (GDD §3.4)

## How [param food] would be absorbed by [param target]:
## {ok, mode: "rank" | "trait", reason, xp}
func absorb_check(food: UnitState, target: UnitState) -> Dictionary:
	if food == target or food == null or target == null:
		return {"ok": false, "reason": ""}
	if food.cls() == target.cls():
		if target.is_max_rank():
			return {"ok": false, "reason": DB.t("absorb.max_rank")}
		var xp := int(DB.rules["absorb_same_unit"]) if food.id == target.id else int(DB.rules["absorb_same_class"])
		return {"ok": true, "mode": "rank", "xp": xp}
	return {"ok": true, "mode": "trait"}


## Same-class absorb: food disappears, target gains rank xp. Returns ranks gained or -1.
func absorb_rank(food: UnitState, target: UnitState) -> int:
	var chk := absorb_check(food, target)
	if not chk["ok"] or chk["mode"] != "rank":
		return -1
	remove_unit(food)
	var gained := target.add_xp(int(chk["xp"]))
	stats["absorbs"] += 1
	changed.emit()
	return gained


## The three traits of food's class for the picker, with "owned" flags.
func trait_options(food: UnitState, target: UnitState) -> Array:
	var out: Array = []
	for tr: Dictionary in DB.traits_of(food.cls()):
		var d := tr.duplicate()
		d["owned"] = target.has_trait(String(tr["id"]))
		d["cls"] = food.cls()
		out.append(d)
	return out


## Different-class absorb: target takes [param trait_id]. When all slots are
## full, [param replace_index] names the trait to swap out. Returns success.
func absorb_trait(food: UnitState, target: UnitState, trait_id: String, replace_index: int = -1) -> bool:
	var chk := absorb_check(food, target)
	if not chk["ok"] or chk["mode"] != "trait":
		return false
	var tcls := String(DB.trait_def(trait_id).get("cls", ""))
	if target.has_trait(trait_id) or tcls == target.cls() or tcls != food.cls():
		return false
	if target.traits.size() >= target.trait_slots():
		if replace_index < 0 or replace_index >= target.traits.size():
			return false
		target.traits[replace_index] = trait_id
	else:
		target.traits.append(trait_id)
	remove_unit(food)
	stats["absorbs"] += 1
	stats["traits"] += 1
	changed.emit()
	return true


# ---------------------------------------------------------------- waves & castle

## Seconds a fallen unit waits: soldier 5 / hero 12, +2 per rank above 1 (GDD §3.6).
func respawn_time(u: UnitState) -> float:
	var r := DB.rules
	var base := float(r["respawn_hero"]) if u.is_hero() else float(r["respawn_soldier"])
	return base + float(r["respawn_per_rank"]) * (u.rank - 1)


func damage_castle(amount: float) -> void:
	castle_hp = maxi(0, castle_hp - int(round(amount)))
	changed.emit()


func castle_fallen() -> bool:
	return castle_hp <= 0


func castle_ratio() -> float:
	return float(castle_hp) / float(maxi(1, castle_max))


## 군량 for clearing wave [param wave_index] (0-based): 280 + 20 x w + 80 (GDD §7).
func wave_income(wave_index: int) -> int:
	var r := DB.rules
	return int(r["wave_income_base"]) + int(r["wave_income_step"]) * wave_index + int(r["wave_clear_bonus"])


## Reward and reset after a cleared wave. Returns {rice, castle}.
func finish_wave() -> Dictionary:
	var gain := wave_income(wave)
	var heal := mini(castle_max - castle_hp, int(round(castle_max * float(DB.rules["castle_regen"]))))
	rice += gain
	castle_hp += heal
	wave += 1
	spins_this_wave = 0
	faction_buff.clear()
	advisor_used = false
	faction_double = false
	free_nudge = false
	slot.can_nudge = false
	changed.emit()
	return {"rice": gain, "castle": heal}


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
