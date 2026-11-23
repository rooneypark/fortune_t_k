class_name Profile
extends RefCounted
## The account (everything that survives a run): currencies, heroes with stars /
## upgrades / treasures, stage progress, pity counters, missions, pass,
## mail, shop flags, settings and tutorial state. Plain dictionary so it saves
## as JSON. All account actions live here so they are testable without nodes.
## (기획서는 결제 때문에 서버 저장을 요구한다 — 지금은 로컬 저장, 서버는 나중에.)

signal changed

## 옛 보상 · 옛 저장의 다이아와 모집권을 바꾸는 값 (개편 §13).
const DIAMOND_GOLD := 30
const TICKET_RICE := 10

## 2: 스테이지 10 × 난이도 3 (진행 키 "스테이지-난이도"), 편성 없음.
## 3: 성급 경험 · 속성을 계정에 저장, 카드 · 강화 · 병영 없음 (개편 §9).
## 4: 재화는 금 하나 (다이아 · 모집권 없음), 군량은 계정의 것 (개편 §13).
const VERSION := 4

var data: Dictionary = {}
var rng := RandomNumberGenerator.new()
## Unix time source; tests may replace it.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())


static func defaults() -> Dictionary:
	DB.ensure()
	var st: Dictionary = DB.meta["start"]
	var d := {
		"version": VERSION,
		"gold": int(st["gold"]), "honor": 0,
		# 군량: n = 지금 가진 양, t = 마지막으로 채워진 시각 (0 = 아직 안 셈). 시간으로 차고 금으로 산다.
		"rice": {"n": int(DB.rules["rice_max"]), "t": 0},
		"lord_lv": 1, "lord_exp": 0, "name": "주공", "avatar": "guanyu",
		"heroes": {}, "troops": {}, "treasures": [], "next_uid": 1,
		# 재료: 종류(weapon / armor / charm) -> 등급 -> 개수 (개편 §3.7)
		"materials": {},
		"progress": {"cleared": {}, "last": "1-1"},
		"missions": {"day": "", "week": "", "daily": {}, "weekly": {}, "total": {}, "claimed": {}},
		"arena": {"day": "", "used": 0, "bought": 0},
		"arena_shop": {"week": "", "bought": {}},
		"mail": [],
		"shop": {"first": {}, "monthly_until": 0, "monthly_last": "", "packages": {}},
		"attendance": {"count": 0, "last": ""},
		"settings": {"bgm": 0.6, "sfx": 0.8, "slot_speed": 1, "vibrate": true, "shake": true, "font": 1, "notify": true},
		"tutorial": {"done": false},
		"stats": {"runs": 0, "victories": 0, "best_stage": 0, "jackpots": 0, "kills": 0},
	}
	for id: String in st["heroes"]:
		d["heroes"][id] = new_hero(id)
	for id: String in st["troops"]:
		d["troops"][id] = new_troop()
	return d


## 병종: 성급 · 성급 경험 · 속성 [{id, lv}] (전투 중 흡수로 오른다, 개편 §9.2) · 장비 칸 eq.
static func new_troop() -> Dictionary:
	return {"star": 1, "xp": 0, "traits": [], "eq": {}}


## 장수: 병종과 같은 구조 (성급 · 속성 · 장비 칸 eq: 무기 / 갑옷 / 장신구).
static func new_hero(id: String) -> Dictionary:
	return {"star": MetaRules.start_star(id), "xp": 0, "traits": [], "eq": {}}


func _init() -> void:
	rng.randomize()
	data = defaults()


func reset() -> void:
	data = defaults()
	changed.emit()


# ---------------------------------------------------------------- save / load

func to_json() -> String:
	return JSON.stringify(data, " ")


func load_json(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return false
	var d := defaults()
	var old_version := int((parsed as Dictionary).get("version", 1))
	_merge(d, parsed)
	data = d
	_fix_types()
	_migrate(old_version)
	return true


## Fills missing keys from defaults (old saves stay valid).
static func _merge(base: Dictionary, over: Dictionary) -> void:
	for k: String in over:
		if base.has(k) and base[k] is Dictionary and over[k] is Dictionary and k != "heroes" and k != "cleared":
			_merge(base[k], over[k])
		else:
			base[k] = over[k]


## JSON numbers come back as floats; turn counters back into ints.
func _fix_types() -> void:
	for k in ["gold", "honor", "lord_lv", "lord_exp", "next_uid"]:
		data[k] = int(data[k])
	data["rice"] = {"n": int(data["rice"].get("n", 0)), "t": int(data["rice"].get("t", 0))}
	for group in ["heroes", "troops"]:
		for id: String in data[group]:
			var e: Dictionary = data[group][id]
			e["star"] = int(e.get("star", 1))
			e["xp"] = int(e.get("xp", 0))
			var traits: Array = []
			for t: Variant in e.get("traits", []):
				if t is Dictionary:
					traits.append({"id": String(t["id"]), "lv": int(t["lv"])})
			e["traits"] = traits
			var eq: Dictionary = e.get("eq", {})
			for s: String in eq:
				eq[s] = int(eq[s])
			e["eq"] = eq
	for slot: String in data["materials"]:
		for r: String in data["materials"][slot]:
			data["materials"][slot][r] = int(data["materials"][slot][r])
	for t: Dictionary in data["treasures"]:
		t["uid"] = int(t["uid"])
		t["lv"] = int(t["lv"])
	for k in ["used", "bought"]:
		data["arena"][k] = int(data["arena"].get(k, 0))
	data["arena"].erase("entries")
	data["arena"].erase("updated_at")
	for k: String in data["arena_shop"]["bought"]:
		data["arena_shop"]["bought"][k] = int(data["arena_shop"]["bought"][k])
	for k: String in data["shop"]["packages"]:
		data["shop"]["packages"][k] = int(data["shop"]["packages"][k])
	data["shop"]["monthly_until"] = int(data["shop"]["monthly_until"])
	for m: Dictionary in data["mail"]:
		m["expires"] = int(m["expires"])


func save_to(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(to_json())
	return true


func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	return load_json(FileAccess.get_file_as_string(path))


# ---------------------------------------------------------------- currencies

func can_pay(kind: String, amount: int) -> bool:
	return int(data.get(kind, 0)) >= amount


func pay(kind: String, amount: int) -> bool:
	if not can_pay(kind, amount):
		return false
	data[kind] = int(data[kind]) - amount
	changed.emit()
	return true


# ---------------------------------------------------------------- 군량 (개편 §13)

## 군량 now: fills by 1 every rice_regen_sec up to rice_max (more than the max is
## kept when it was bought or given, it just does not grow).
func rice_now() -> int:
	_tick_rice()
	return int(data["rice"]["n"])


func _tick_rice() -> void:
	var r: Dictionary = data["rice"]
	var now := int(clock.call())
	var step := int(DB.rules["rice_regen_sec"])
	var cap := int(DB.rules["rice_max"])
	if int(r["t"]) <= 0 or int(r["n"]) >= cap:
		r["t"] = now
		return
	var gained := int((now - int(r["t"])) / step)
	if gained <= 0:
		return
	r["n"] = mini(cap, int(r["n"]) + gained)
	r["t"] = now if int(r["n"]) >= cap else int(r["t"]) + gained * step


## Seconds until the next 군량, or 0 when full.
func rice_next_sec() -> int:
	_tick_rice()
	if int(data["rice"]["n"]) >= int(DB.rules["rice_max"]):
		return 0
	return maxi(1, int(DB.rules["rice_regen_sec"]) - (int(clock.call()) - int(data["rice"]["t"])))


func spend_rice(n: int) -> bool:
	if rice_now() < n:
		return false
	data["rice"]["n"] = int(data["rice"]["n"]) - n
	changed.emit()
	return true


## Adds 군량 (rewards, purchases, refunds): may go over the max.
func add_rice(n: int) -> void:
	_tick_rice()
	data["rice"]["n"] = int(data["rice"]["n"]) + n
	changed.emit()


## 금 to fill 군량 to the max right now (rice_price each), 0 when already full.
func rice_refill_cost() -> int:
	return maxi(0, int(DB.rules["rice_max"]) - rice_now()) * int(DB.rules["rice_price"])


## 즉시 충전: pays 금 and fills 군량 to the max. Returns "" or the reason.
func refill_rice() -> String:
	var cost := rice_refill_cost()
	if cost <= 0:
		return DB.t("rice.full")
	if not pay("gold", cost):
		return DB.t("common.no_gold")
	data["rice"]["n"] = int(DB.rules["rice_max"])
	data["rice"]["t"] = int(clock.call())
	changed.emit()
	return ""


## Grants a reward dictionary: gold, honor, rice (군량), lord_exp, mats (재료 n개),
## hero (id), treasure (tid). Old mail may still hold diamond / tickets / boxes:
## they turn into 금 / 군량 / 재료. Returns the gained items for display.
func grant(reward: Dictionary) -> Array:
	var gained: Array = []
	for k: String in reward:
		var v: Variant = reward[k]
		match k:
			"gold", "honor":
				data[k] = int(data[k]) + int(v)
			"diamond":
				data["gold"] = int(data["gold"]) + int(v) * DIAMOND_GOLD
			"rice":
				add_rice(int(v))
			"tickets":
				add_rice(int(v) * TICKET_RICE)
			"lord_exp":
				add_lord_exp(int(v))
			"mats", "boxes":
				# 보상 재료는 희귀 등급, 종류는 랜덤. ("boxes"는 옛 우편에 남은 보물 상자: 상자 1 = 재료 3)
				var n := int(v) * (int(DB.meta["treasure"]["materials"]["craft"]) if k == "boxes" else 1)
				var slots: Array = DB.meta["treasure"]["slots"]
				for i in n:
					gained.append(add_material(String(slots[rng.randi_range(0, slots.size() - 1)]), String(DB.meta["treasure"]["materials"]["reward_rarity"])))
			"hero":
				gained.append(add_hero_card(String(v)))
			"treasure":
				gained.append(add_treasure(String(v)))
	changed.emit()
	return gained


func add_lord_exp(amount: int) -> int:
	var ups := 0
	data["lord_exp"] = int(data["lord_exp"]) + amount
	while int(data["lord_lv"]) < int(DB.meta["lord"]["max"]) and int(data["lord_exp"]) >= MetaRules.lord_exp_need(int(data["lord_lv"])):
		data["lord_exp"] = int(data["lord_exp"]) - MetaRules.lord_exp_need(int(data["lord_lv"]))
		data["lord_lv"] = int(data["lord_lv"]) + 1
		ups += 1
	return ups


# ---------------------------------------------------------------- heroes

func owns(id: String) -> bool:
	return data["heroes"].has(id)


func hero(id: String) -> Dictionary:
	return data["heroes"].get(id, {})


func star_of(id: String) -> int:
	return int(hero(id).get("star", 0))


## A hero from a reward (mail etc.): a new hero, or gold when already owned (성급은
## 전투 중 흡수로만 오른다, 개편 §3.3). Returns {type, id, new, gold}.
func add_hero_card(id: String) -> Dictionary:
	if not owns(id):
		data["heroes"][id] = new_hero(id)
		return {"type": "hero", "id": id, "new": true}
	var g := int(DB.meta["star"]["dup_gold"].get(DB.rarity_of(id), 0))
	data["gold"] = int(data["gold"]) + g
	return {"type": "hero", "id": id, "new": false, "gold": g}


# ---------------------------------------------------------------- 성급 · 속성 (개편 §9.2)

## The entry that holds a unit's 성급 / 속성 (hero, or the troop of a soldier); {} when not owned.
func unit_entry(id: String) -> Dictionary:
	return MetaRules.entry(data, id)


func unit_star(id: String) -> int:
	return MetaRules.unit_star(data, id)


## Adds 성급 경험 to an owned hero / troop and raises its 성급 while the bar is full.
## Returns {gained, star, xp, need} ({} when not owned or already max).
func add_star_xp(id: String, amount: int) -> Dictionary:
	var e := unit_entry(id)
	if e.is_empty() or int(e["star"]) >= MetaRules.star_max():
		return {}
	var gained := 0
	e["xp"] = int(e.get("xp", 0)) + amount
	while true:
		var need := MetaRules.star_need(id, int(e["star"]))
		if need < 0:
			e["xp"] = 0
			break
		if int(e["xp"]) < need:
			break
		e["xp"] = int(e["xp"]) - need
		e["star"] = int(e["star"]) + 1
		gained += 1
	changed.emit()
	return {"gained": gained, "star": int(e["star"]), "xp": int(e["xp"]), "need": MetaRules.star_need(id, int(e["star"]))}


## Gives an owned unit the 속성 [param trait_id]: +1 level when it has it, a new
## one at level 1 when a slot is free, else it replaces slot [param replace_index].
## Returns "" or the reason it failed.
func set_trait(id: String, trait_id: String, replace_index: int = -1) -> String:
	var e := unit_entry(id)
	if e.is_empty() or DB.trait_def(trait_id).is_empty():
		return "?"
	var traits: Array = e["traits"]
	for t: Dictionary in traits:
		if String(t["id"]) == trait_id:
			if int(t["lv"]) >= MetaRules.trait_max():
				return DB.t("absorb.trait_max")
			t["lv"] = int(t["lv"]) + 1
			changed.emit()
			return ""
	if traits.size() >= MetaRules.trait_slots(int(e["star"])):
		if replace_index < 0 or replace_index >= traits.size():
			return DB.t("absorb.replace")
		traits[replace_index] = {"id": trait_id, "lv": 1}
	else:
		traits.append({"id": trait_id, "lv": 1})
	changed.emit()
	return ""


# ---------------------------------------------------------------- 병종 (troops, 2026-11-22)

func owns_troop(id: String) -> bool:
	return data["troops"].has(id)


func troop(id: String) -> Dictionary:
	return data["troops"].get(id, {})


## A soldier card: a new troop, or gold when already owned. Returns {type, id, new, gold}.
func add_troop_card(id: String) -> Dictionary:
	if not owns_troop(id):
		data["troops"][id] = new_troop()
		return {"type": "soldier", "id": id, "new": true}
	var g := int(DB.meta["star"]["troop_dup_gold"])
	data["gold"] = int(data["gold"]) + g
	return {"type": "soldier", "id": id, "new": false, "gold": g}


## A hero or troop drawn by the slot joins the account when it is not there yet
## (개편 §13: 캐릭터는 전투 중 슬롯에서만 얻는다). Returns true when it is new.
func join(id: String) -> bool:
	if DB.is_hero(id):
		if owns(id):
			return false
		data["heroes"][id] = new_hero(id)
	elif DB.is_soldier(id):
		if owns_troop(id):
			return false
		data["troops"][id] = new_troop()
	else:
		return false
	track("new_units", 1)
	changed.emit()
	return true


# ---------------------------------------------------------------- treasures

func add_treasure(tid: String) -> Dictionary:
	var uid := int(data["next_uid"])
	data["next_uid"] = uid + 1
	var item := MetaRules.make_treasure(tid, uid, rng)
	if (data["treasures"] as Array).size() >= int(DB.meta["treasure"]["bag_max"]):
		send_mail("보물 가방이 가득 찼어요", "보관함 대신 우편으로 보냈어요.", {"treasure": tid}, 30)
		return {"type": "treasure", "tid": tid, "mailed": true}
	data["treasures"].append(item)
	if String(DB.treasure_def(tid).get("rarity", "")) == "legend":
		track("legend_treasure", 1)
	return {"type": "treasure", "tid": tid, "uid": uid}


# ---------------------------------------------------------------- 재료 · 합성 (개편 §3.7~3.8)

func material_count(slot: String, rarity: String) -> int:
	return int(data["materials"].get(slot, {}).get(rarity, 0))


## Adds materials. Returns {type: "material", slot, rarity} for the reward display.
func add_material(slot: String, rarity: String, n: int = 1) -> Dictionary:
	if not data["materials"].has(slot):
		data["materials"][slot] = {}
	data["materials"][slot][rarity] = material_count(slot, rarity) + n
	return {"type": "material", "slot": slot, "rarity": rarity}


## One stage-reward material: a random slot, the rarity by the difficulty's odds
## (not below [param min_rarity] when given).
func roll_material(d: int, min_rarity: String = "") -> Dictionary:
	var cfg: Dictionary = DB.meta["treasure"]["materials"]
	var odds: Array = cfg["odds"]
	var rarity := Gacha.roll_rarity(rng, odds[clampi(d - 1, 0, odds.size() - 1)])
	var order: Array = DB.meta["treasure"]["rarity_order"]
	if min_rarity != "" and order.find(rarity) < order.find(min_rarity):
		rarity = min_rarity
	var slots: Array = DB.meta["treasure"]["slots"]
	return add_material(String(slots[rng.randi_range(0, slots.size() - 1)]), rarity)


## 재료 합성: 3 materials of one slot and rarity -> one treasure of that slot and
## rarity (equal odds inside it). No gold. Returns {ok, error, item}.
func craft(slot: String, rarity: String) -> Dictionary:
	var need := int(DB.meta["treasure"]["materials"]["craft"])
	if material_count(slot, rarity) < need:
		return {"ok": false, "error": DB.t("synth.no_mats", [need])}
	var pool := DB.treasures_of(slot, rarity)
	if pool.is_empty():
		return {"ok": false, "error": "?"}
	data["materials"][slot][rarity] = material_count(slot, rarity) - need
	var item := add_treasure(String(pool[rng.randi_range(0, pool.size() - 1)]["id"]))
	track("crafts", 1)
	changed.emit()
	return {"ok": true, "error": "", "item": item}


## Treasures of [param rarity] that a 보물 합성 may use: not worn, lowest level first.
func fuse_candidates(rarity: String) -> Array:
	var out: Array = []
	for item: Dictionary in data["treasures"]:
		if String(DB.treasure_def(String(item["tid"])).get("rarity", "")) == rarity and MetaRules.treasure_owner(data, int(item["uid"])) == "":
			out.append(item)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["lv"]) < int(b["lv"]) if int(a["lv"]) != int(b["lv"]) else int(a["uid"]) < int(b["uid"]))
	return out


## 보물 합성: 3 unworn treasures of one rarity -> one treasure a rarity higher, in the
## slot of one of the three. The top rarity cannot be fused. Returns {ok, error, item, used}.
func fuse(rarity: String) -> Dictionary:
	var up := DB.next_rarity(rarity)
	if up == "":
		return {"ok": false, "error": DB.t("synth.top")}
	var need := int(DB.meta["treasure"]["materials"]["fuse"])
	var cand := fuse_candidates(rarity)
	if cand.size() < need:
		return {"ok": false, "error": DB.t("synth.no_treasures", [need])}
	var used: Array = cand.slice(0, need)
	var slot := String(DB.treasure_def(String(used[rng.randi_range(0, need - 1)]["tid"]))["slot"])
	var pool := DB.treasures_of(slot, up)
	if pool.is_empty():
		pool = DB.treasures_of_rarity(up)
	for item: Dictionary in used:
		data["treasures"].erase(item)
	var got := add_treasure(String(pool[rng.randi_range(0, pool.size() - 1)]["id"]))
	track("crafts", 1)
	changed.emit()
	return {"ok": true, "error": "", "item": got, "used": used}


## Puts 장비 [param uid] on an owned hero or troop (its slot: 무기 / 갑옷 / 장신구).
## Whoever wore it before takes it off; what was in that slot goes back to the bag.
func equip(unit_id: String, uid: int) -> void:
	var item := MetaRules.find_treasure(data, uid)
	var e := unit_entry(unit_id)
	if item.is_empty() or e.is_empty():
		return
	var slot := String(DB.treasure_def(String(item["tid"]))["slot"])
	var prev := MetaRules.treasure_owner(data, uid)
	if prev != "":
		unit_entry(prev)["eq"].erase(slot)
	e["eq"][slot] = uid
	changed.emit()


func unequip(unit_id: String, slot: String) -> void:
	var e := unit_entry(unit_id)
	if not e.is_empty():
		e["eq"].erase(slot)
		changed.emit()


## Best 장비 (보물 first, then by main value) into each slot, taking only what
## nobody else wears (자동 장착).
func auto_equip(unit_id: String) -> void:
	var e := unit_entry(unit_id)
	if e.is_empty():
		return
	var order: Array = DB.meta["treasure"]["rarity_order"]
	for slot: String in DB.meta["treasure"]["slots"]:
		var best := {}
		var best_v := -1.0
		var cur_uid := int(e["eq"].get(slot, -1))
		for item: Dictionary in data["treasures"]:
			var def := DB.treasure_def(String(item["tid"]))
			if String(def["slot"]) != slot:
				continue
			var owner := MetaRules.treasure_owner(data, int(item["uid"]))
			if owner != "" and owner != unit_id:
				continue
			var v := order.find(String(def["rarity"])) * 100000.0 + MetaRules.treasure_main(item)
			if v > best_v:
				best_v = v
				best = item
		if not best.is_empty() and int(best["uid"]) != cur_uid:
			equip(unit_id, int(best["uid"]))


func enhance_treasure(uid: int) -> String:
	var item := MetaRules.find_treasure(data, uid)
	if item.is_empty():
		return "?"
	if int(item["lv"]) >= int(DB.meta["treasure"]["max_level"]):
		return DB.t("treasure.max")
	if not pay("gold", MetaRules.treasure_level_cost(item)):
		return DB.t("common.no_gold")
	item["lv"] = int(item["lv"]) + 1
	track("treasure_ups", 1)
	changed.emit()
	return ""


func dismantle(uid: int) -> int:
	var item := MetaRules.find_treasure(data, uid)
	if item.is_empty():
		return 0
	var owner := MetaRules.treasure_owner(data, uid)
	if owner != "":
		var slot := String(DB.treasure_def(String(item["tid"]))["slot"])
		unit_entry(owner)["eq"].erase(slot)
	var gold := MetaRules.dismantle_gold(item)
	data["treasures"].erase(item)
	data["gold"] = int(data["gold"]) + gold
	changed.emit()
	return gold


# ---------------------------------------------------------------- stages

## Old saves (version 1: 6장 × 8스테이지, 키 "장-스테이지") -> 스테이지 10 × 난이도 3.
## 장 c의 마지막 스테이지(c-8)를 깼으면 스테이지 c 보통 클리어로 옮긴다 (개편 §5).
func _migrate(old_version: int) -> void:
	if old_version < 2:
		var old: Dictionary = data["progress"].get("cleared", {})
		var cleared := {}
		var top := 0
		for c in range(1, 7):
			var st := int(old.get("%d-8" % c, 0))
			if st > 0:
				cleared[DB.stage_key(c, 1)] = st
				top = c
		data["progress"] = {"cleared": cleared, "last": DB.stage_key(mini(top + 1, DB.stage_count()), 1)}
		data["stats"]["best_stage"] = top
	if old_version < 3:
		# 카드 -> 골드, 강화 · 병영은 없어진다 (돌려주지 않는다: 군주 레벨이 그 자리를 맡는다).
		var dup: Dictionary = DB.meta["star"]["dup_gold"]
		for id: String in data["heroes"]:
			var h: Dictionary = data["heroes"][id]
			data["gold"] = int(data["gold"]) + int(h.get("cards", 0)) * int(dup.get(DB.rarity_of(id), 0))
			h.erase("cards")
			h.erase("up")
		for id: String in data["troops"]:
			var t: Dictionary = data["troops"][id]
			data["gold"] = int(data["gold"]) + int(t.get("cards", 0)) * int(DB.meta["star"]["troop_dup_gold"])
			t.erase("cards")
			t.erase("up")
	if old_version < 4:
		# 다이아 -> 금 (x30), 모집권 -> 군량 (x10). 모집 · 천장 기록은 없어진다.
		data["gold"] = int(data["gold"]) + int(data.get("diamond", 0)) * DIAMOND_GOLD
		data["rice"]["n"] = int(data["rice"]["n"]) + int(data.get("tickets", 0)) * TICKET_RICE
	for k in ["lineup", "advisor", "troop_lineup", "barracks", "diamond", "tickets", "pity", "gold_buy", "gold_recruit"]:
		data.erase(k)
	data["tutorial"].erase("recruit")
	data["version"] = VERSION


func stars_of(key: String) -> int:
	return int(data["progress"]["cleared"].get(key, 0))


## 스테이지 s의 난이도 d가 열렸는가: 앞 난이도를 깼거나, 보통(1)이면 앞 스테이지의 보통을 깼을 때.
func is_unlocked(s: int, d: int) -> bool:
	if d > 1:
		return stars_of(DB.stage_key(s, d - 1)) > 0
	return s <= 1 or stars_of(DB.stage_key(s - 1, 1)) > 0


## 가장 멀리 열린 스테이지.
func frontier_stage() -> int:
	var f := 1
	for s in range(2, DB.stage_count() + 1):
		if is_unlocked(s, 1):
			f = s
	return f


## 지금 스테이지: 출정하면 바로 여기로 들어간다. 되돌리지 않았으면 가장 멀리 열린 곳.
func current_stage() -> int:
	var f := frontier_stage()
	var c := int(data["progress"].get("cur", 0))
	return f if c <= 0 else clampi(c, 1, f)


func stage_back_cost() -> int:
	return int(DB.rules.get("stage_back_gold", 500))


## 금을 내고 한 스테이지 되돌린다. 실패하면 이유, 성공하면 "".
func stage_back() -> String:
	var s := current_stage()
	if s <= 1:
		return DB.t("stage.back_first")
	if not pay("gold", stage_back_cost()):
		return DB.t("common.no_gold")
	data["progress"]["cur"] = s - 1
	changed.emit()
	return ""


## Records a finished run and pays rewards (콘텐츠 §2.3, 메타 §4.6).
## Returns {gold, lord_exp, diamond, treasure, first, stars, level_ups}.
## Records a finished run and pays 금, 군주 경험 and 재료.
func finish_run(s: int, d: int, waves_reached: int, victory: bool, stars: int, run_stats: Dictionary) -> Dictionary:
	var key := DB.stage_key(s, d)
	var first := victory and stars_of(key) == 0
	var cur_before := current_stage()
	var gold := MetaRules.run_gold(waves_reached, victory)
	# 군주 경험은 클리어했을 때만 (개편 §9.3).
	var lexp := MetaRules.clear_exp(s, d, first) if victory else 0
	var out := {"gold": gold, "run_gold": gold, "first_gold": 0,
		"lord_exp": lexp, "materials": [], "first": first, "stars": stars}
	# 재료 (개편 §3.7): 승리 2개, 패배는 5웨이브 이상이면 1개, 첫 클리어는 희귀 이상 1개 더.
	var mcfg: Dictionary = DB.meta["treasure"]["materials"]
	var mats := int(mcfg["per_win"]) if victory else (int(mcfg["per_loss"]) if waves_reached >= int(mcfg["loss_wave"]) else 0)
	for i in mats:
		out["materials"].append(roll_material(d))
	data["gold"] = int(data["gold"]) + gold
	out["level_ups"] = add_lord_exp(lexp)
	if first:
		var bonus := int(DB.stages["first_clear_gold"])
		data["gold"] = int(data["gold"]) + bonus
		out["first_gold"] = bonus
		out["gold"] = gold + bonus
		out["materials"].append(roll_material(d, String(mcfg["first_min"])))
	if victory:
		data["progress"]["cleared"][key] = maxi(stars_of(key), stars)
		data["stats"]["victories"] = int(data["stats"]["victories"]) + 1
		data["stats"]["best_stage"] = maxi(int(data["stats"]["best_stage"]), s)
		track("clears", 1)
		if first and s == 1 and d == 1:
			track("chapter1", 1)
		# 다음에 열어 줄 곳: 보통을 깼으면 다음 스테이지, 아니면 같은 자리.
		var ns := mini(s + 1, DB.stage_count()) if d == 1 else s
		data["progress"]["last"] = DB.stage_key(ns, 1 if d == 1 else d)
		# 지금 스테이지의 보통을 깨면 다음 스테이지로 넘어간다 (되돌린 뒤 다시 깰 때도 같다).
		if d == 1 and s == cur_before:
			data["progress"]["cur"] = ns
	data["stats"]["runs"] = int(data["stats"]["runs"]) + 1
	data["stats"]["kills"] = int(data["stats"]["kills"]) + int(run_stats.get("kills", 0))
	track("runs", 1)
	track("spins", int(run_stats.get("spins", 0)))
	track("jackpots", int(run_stats.get("jackpots", 0)))
	track("absorbs", int(run_stats.get("absorbs", 0)))
	track("star_absorbs", int(run_stats.get("stars", 0)))
	track("kills", int(run_stats.get("kills", 0)))
	track("traits_total", int(run_stats.get("traits", 0)))
	track("jackpots_total", int(run_stats.get("jackpots", 0)))
	changed.emit()
	return out


# ---------------------------------------------------------------- missions (콘텐츠 §8)

static func _date_key(unix: int) -> String:
	# Missions reset at 04:00 local (UTC+9 baseline).
	var d := Time.get_date_dict_from_unix_time(unix + 9 * 3600 - 4 * 3600)
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


static func _week_key(unix: int) -> String:
	var days := int((unix + 9 * 3600 - 4 * 3600) / 86400)
	return "W%d" % int((days + 3) / 7)


## Resets daily / weekly counters when the day or week changed.
func refresh_periods() -> void:
	var m: Dictionary = data["missions"]
	var now := int(clock.call())
	var day := _date_key(now)
	var week := _week_key(now)
	if String(m["day"]) != day:
		if String(m["day"]) != "" and _all_daily_done():
			m["weekly"]["daily_days"] = int(m["weekly"].get("daily_days", 0)) + 1
		m["day"] = day
		m["daily"] = {}
		for mi: Dictionary in DB.missions["daily"]:
			m["claimed"].erase(mi["id"])
	if String(m["week"]) != week:
		m["week"] = week
		m["weekly"] = {}
		for mi: Dictionary in DB.missions["weekly"]:
			m["claimed"].erase(mi["id"])


func _all_daily_done() -> bool:
	for mi: Dictionary in DB.missions["daily"]:
		if String(mi["id"]) != "d_all" and not data["missions"]["claimed"].has(mi["id"]):
			return false
	return true


func track(stat: String, n: int) -> void:
	if n == 0:
		return
	var m: Dictionary = data["missions"]
	for scope in ["daily", "weekly", "total"]:
		m[scope][stat] = int(m[scope].get(stat, 0)) + n


func mission_progress(mi: Dictionary, scope: String) -> int:
	var stat := String(mi["stat"])
	var m: Dictionary = data["missions"]
	match stat:
		"daily_done":
			var n := 0
			for d: Dictionary in DB.missions["daily"]:
				if String(d["id"]) != "d_all" and m["claimed"].has(d["id"]):
					n += 1
			return n
		"weekly_done":
			var n := 0
			for d: Dictionary in DB.missions["weekly"]:
				if String(d["id"]) != "w_all" and m["claimed"].has(d["id"]):
					n += 1
			return n
		"heroes_owned":
			return (data["heroes"] as Dictionary).size()
		"star4":
			var n := 0
			for id: String in data["heroes"]:
				if int(data["heroes"][id]["star"]) >= 4:
					n += 1
			return n
		"daily_days":
			return int(m["weekly"].get("daily_days", 0))
	var src: Dictionary = m["total"] if scope == "achievements" else m[scope]
	return int(src.get(stat, 0))


func mission_state(mi: Dictionary, scope: String) -> String:
	if data["missions"]["claimed"].has(mi["id"]):
		return "claimed"
	return "ready" if mission_progress(mi, scope) >= int(mi["need"]) else "progress"


func claim_mission(mi: Dictionary, scope: String) -> Array:
	if mission_state(mi, scope) != "ready":
		return []
	data["missions"]["claimed"][mi["id"]] = true
	return grant(mi["reward"])


func claimable_missions() -> int:
	refresh_periods()
	var n := 0
	for scope in ["daily", "weekly", "achievements"]:
		for mi: Dictionary in DB.missions[scope]:
			if mission_state(mi, scope) == "ready":
				n += 1
	return n


# ---------------------------------------------------------------- arena (콘텐츠 §7: 하루 무료 5회, 04:00 초기화)

## Seconds until the next 04:00 (KST) reset.
func seconds_to_reset() -> int:
	var local := int(clock.call()) + 9 * 3600 - 4 * 3600
	return 86400 - posmod(local, 86400)


func _arena_today() -> Dictionary:
	var a: Dictionary = data["arena"]
	var day := _date_key(int(clock.call()))
	if String(a.get("day", "")) != day:
		a["day"] = day
		a["used"] = 0
		a["bought"] = 0
	return a


## {entries (left today), max (free per day), bought, buy_max, buy_cost, next_sec}
func sync_arena_entries() -> Dictionary:
	var a := _arena_today()
	var cfg: Dictionary = DB.meta["arena"]
	var free := int(cfg["free_per_day"])
	var left := maxi(0, free + int(a["bought"]) - int(a["used"]))
	return {"entries": left, "max": free, "bought": int(a["bought"]), "buy_max": int(cfg["extra_max"]),
		"buy_cost": int(cfg["extra_cost"]), "next_sec": seconds_to_reset()}


func use_arena_entry() -> bool:
	if int(sync_arena_entries()["entries"]) <= 0:
		return false
	data["arena"]["used"] = int(data["arena"]["used"]) + 1
	changed.emit()
	return true


## Extra entry for 금 (하루 extra_max회). Returns "" or an error text.
func buy_arena_entry() -> String:
	var st := sync_arena_entries()
	if int(st["bought"]) >= int(st["buy_max"]):
		return DB.t("arena.buy_limit")
	if not pay("gold", int(st["buy_cost"])):
		return DB.t("common.no_gold")
	data["arena"]["bought"] = int(data["arena"]["bought"]) + 1
	changed.emit()
	return ""


## Result of one arena match: 군공 (승 win_honor / 패 lose_honor). Returns 군공 gained.
func finish_arena(victory: bool) -> int:
	var cfg: Dictionary = DB.meta["arena"]
	var hn := int(cfg["win_honor"] if victory else cfg["lose_honor"])
	data["honor"] = int(data["honor"]) + hn
	track("arena", 1)
	changed.emit()
	return hn


# ---------------------------------------------------------------- 군웅 상점 (콘텐츠 §7.1, 주간, 군공 전용)

func _arena_shop_week() -> Dictionary:
	var sh: Dictionary = data["arena_shop"]
	var week := _week_key(int(clock.call()))
	if String(sh.get("week", "")) != week:
		sh["week"] = week
		sh["bought"] = {}
	return sh


func arena_item(item_id: String) -> Dictionary:
	for it: Dictionary in DB.meta["arena"]["shop"]:
		if String(it["id"]) == item_id:
			return it
	return {}


## How many of [param item_id] were bought this week.
func arena_bought(item_id: String) -> int:
	return int(_arena_shop_week()["bought"].get(item_id, 0))


## 군공 price of a 군웅 상점 item. -1 when not for sale.
func arena_price(item_id: String) -> int:
	var it := arena_item(item_id)
	return -1 if it.is_empty() else int(it["cost"])


## Buys one item with 군공. Returns {ok, error, gained}.
func buy_arena_item(item_id: String) -> Dictionary:
	var it := arena_item(item_id)
	if it.is_empty():
		return {"ok": false, "error": "?"}
	if arena_bought(item_id) >= int(it["limit"]):
		return {"ok": false, "error": DB.t("arena_shop.sold_out")}
	var kind := String(it["kind"])
	var price := arena_price(item_id)
	if price < 0 or not pay("honor", price):
		return {"ok": false, "error": DB.t("arena_shop.no_honor")}
	var bought: Dictionary = data["arena_shop"]["bought"]
	bought[item_id] = int(bought.get(item_id, 0)) + 1
	var gained: Array = []
	match kind:
		"treasure":
			var pool := DB.treasures_of_rarity(String(it["rarity"]))
			gained.append(add_treasure(String(pool[rng.randi_range(0, pool.size() - 1)]["id"])))
		"rice", "gold":
			grant({kind: int(it["amount"])})
	changed.emit()
	return {"ok": true, "error": "", "gained": gained}


static func format_hms(sec: int) -> String:
	var s := maxi(0, sec)
	@warning_ignore("integer_division")
	var h := s / 3600
	@warning_ignore("integer_division")
	var m := (s % 3600) / 60
	var r := s % 60
	return "%02d:%02d:%02d" % [h, m, r]


# ---------------------------------------------------------------- mail

func send_mail(title: String, body: String, reward: Dictionary, days: int) -> void:
	data["mail"].append({"id": "m%d_%d" % [int(clock.call()), (data["mail"] as Array).size()], "title": title, "body": body,
		"reward": reward, "expires": int(clock.call()) + days * 86400, "claimed": false})


func seed_welcome_mail() -> void:
	if not (data["mail"] as Array).is_empty():
		return
	for m: Dictionary in DB.mail["welcome"]:
		send_mail(String(m["title"]), String(m["body"]), m["reward"], int(m["days"]))


func claim_mail(index: int) -> Array:
	var list: Array = data["mail"]
	if index < 0 or index >= list.size() or bool(list[index]["claimed"]):
		return []
	list[index]["claimed"] = true
	return grant(list[index]["reward"])


func unclaimed_mail() -> int:
	var n := 0
	for m: Dictionary in data["mail"]:
		if not bool(m["claimed"]):
			n += 1
	return n


func delete_read_mail() -> void:
	var keep: Array = []
	for m: Dictionary in data["mail"]:
		if not bool(m["claimed"]):
			keep.append(m)
	data["mail"] = keep
	changed.emit()


# ---------------------------------------------------------------- shop (개발용 가상 결제)

## Applies a (mock) store purchase: 금 묶음, 월정액, 꾸러미. Only 금 (and what a
## package holds) is sold for money. Returns the granted reward dictionary.
func purchase(product_id: String) -> Dictionary:
	var sh := DB.shop
	var reward := {}
	if product_id == "monthly":
		var mo: Dictionary = sh["monthly"]
		reward = {"gold": int(mo["now"])}
		data["shop"]["monthly_until"] = maxi(int(data["shop"]["monthly_until"]), int(clock.call())) + int(mo["days"]) * 86400
	else:
		for p: Dictionary in sh["gold_packs"]:
			if String(p["id"]) == product_id:
				var amt := int(p["amount"])
				if bool(sh["first_double"]) and not data["shop"]["first"].has(product_id):
					amt *= 2
				data["shop"]["first"][product_id] = true
				reward = {"gold": amt}
		for p: Dictionary in sh["packages"]:
			if String(p["id"]) == product_id:
				var bought := int(data["shop"]["packages"].get(product_id, 0))
				if bought >= int(p["limit"]):
					return {}
				data["shop"]["packages"][product_id] = bought + 1
				for k in ["gold", "rice", "mats"]:
					if p.has(k):
						reward[k] = int(p[k])
	var gained := grant(reward)
	reward["_gained"] = gained
	changed.emit()
	return reward


## 월정액의 매일 금; returns the amount granted today (0 if none).
func claim_monthly() -> int:
	var now := int(clock.call())
	if int(data["shop"]["monthly_until"]) < now:
		return 0
	var day := _date_key(now)
	if String(data["shop"]["monthly_last"]) == day:
		return 0
	data["shop"]["monthly_last"] = day
	var amt := int(DB.shop["monthly"]["daily"])
	data["gold"] = int(data["gold"]) + amt
	changed.emit()
	return amt


## 7-day repeating attendance (콘텐츠 §8.4). Returns {day, reward} or {} if already today.
func claim_attendance() -> Dictionary:
	var day := _date_key(int(clock.call()))
	var a: Dictionary = data["attendance"]
	if String(a["last"]) == day:
		return {}
	a["last"] = day
	var list: Array = DB.missions["attendance"]
	var idx := int(a["count"]) % list.size()
	a["count"] = int(a["count"]) + 1
	var rw: Dictionary = list[idx]
	grant(rw)
	return {"day": idx + 1, "reward": rw}
