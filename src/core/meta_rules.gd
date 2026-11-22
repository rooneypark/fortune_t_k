class_name MetaRules
extends RefCounted
## Formulas outside the run (메타-성장-과금 §4, 콘텐츠 §10). Pure functions over
## a profile dictionary (see Profile.defaults()).


static func _m() -> Dictionary:
	DB.ensure()
	return DB.meta


## Hero base stats before stars: data row.
static func base_stats(id: String) -> Dictionary:
	var d := DB.unit_def(id)
	return {"hp": float(d.get("hp", 100)), "atk": float(d.get("atk", 10)), "def": float(d.get("def", 0))}


static func star_mult(star: int) -> float:
	return pow(float(_m()["star"]["mult"]), star - 1)


## Value of one stat after stars and upgrades (§4.3).
static func upgraded(base: float, star: int, level: int) -> float:
	return base * star_mult(star) * (1.0 + float(_m()["upgrade"]["per_level"]) * level)


## Gold for raising a stat from [param level] to level + 1: round(50 x (level+1)^1.5).
static func upgrade_cost(level: int) -> int:
	var u: Dictionary = _m()["upgrade"]
	return int(round(float(u["cost_base"]) * pow(level + 1, float(u["cost_exp"]))))


static func upgrade_cap(star: int) -> int:
	return star * int(_m()["upgrade"]["cap_per_star"])


## Cards needed to go from [param star] to star + 1, or -1 at max.
static func star_cost(star: int) -> int:
	var cards: Array = _m()["star"]["cards"]
	if star < 1 or star > cards.size():
		return -1
	return int(cards[star - 1])


static func start_star(id: String) -> int:
	return int(DB.units["rarities"].get(DB.rarity_of(id), {}).get("start_star", 1))


# ---------------------------------------------------------------- treasures

static func treasure_main(item: Dictionary) -> float:
	var t: Dictionary = _m()["treasure"]
	var def := DB.treasure_def(String(item["tid"]))
	var base := float(t["main_base"][def["slot"]][def["rarity"]])
	return base * (1.0 + float(t["main_per_level"]) * int(item.get("lv", 0)))


static func treasure_main_stat(item: Dictionary) -> String:
	var def := DB.treasure_def(String(item["tid"]))
	return String(_m()["treasure"]["main_stat"][def["slot"]])


## Number of open sub-stat slots: 1 + one per unlock level reached, up to the rarity max.
static func treasure_open_subs(item: Dictionary) -> int:
	var t: Dictionary = _m()["treasure"]
	var def := DB.treasure_def(String(item["tid"]))
	var max_slots := int(t["sub_slots"][def["rarity"]])
	var n := 1
	for lv in t["sub_unlock"]:
		if int(item.get("lv", 0)) >= int(lv):
			n += 1
	return mini(n, max_slots)


static func treasure_level_cost(item: Dictionary) -> int:
	var t: Dictionary = _m()["treasure"]
	return int(round(float(t["level_cost_base"]) * pow(int(item.get("lv", 0)) + 1, float(t["level_cost_exp"]))))


static func treasure_spent(item: Dictionary) -> int:
	var total := 0
	var probe := item.duplicate()
	for lv in int(item.get("lv", 0)):
		probe["lv"] = lv
		total += treasure_level_cost(probe)
	return total


static func dismantle_gold(item: Dictionary) -> int:
	var t: Dictionary = _m()["treasure"]
	var def := DB.treasure_def(String(item["tid"]))
	return int(t["dismantle"][def["rarity"]]) + int(treasure_spent(item) * float(t["dismantle_refund"]))


## New treasure instance with random sub stats (max slots rolled now, opened by level).
static func make_treasure(tid: String, uid: int, rng: RandomNumberGenerator) -> Dictionary:
	var t: Dictionary = _m()["treasure"]
	var def := DB.treasure_def(tid)
	var kinds: Array = t["sub_kinds"]
	var subs: Array = []
	for i in int(t["sub_slots"][def["rarity"]]):
		var k: Dictionary = kinds[rng.randi_range(0, kinds.size() - 1)]
		subs.append({"kind": k["id"], "v": float(k["v"])})
	return {"uid": uid, "tid": tid, "lv": 0, "subs": subs}


# ---------------------------------------------------------------- hero totals

## Final account stats of a hero (§4.5): base x 1.15^(star-1) x (1 + 0.04 x lv) + treasures.
## Also returns the summed open sub stats (crit, crit_dmg, aspd, energy, guard, spd).
static func hero_stats(profile: Dictionary, id: String) -> Dictionary:
	var b := base_stats(id)
	var h: Dictionary = profile.get("heroes", {}).get(id, {})
	var star := int(h.get("star", start_star(id)))
	var up: Dictionary = h.get("up", {})
	var out := {
		"atk": upgraded(b["atk"], star, int(up.get("atk", 0))),
		"def": upgraded(b["def"], star, int(up.get("def", 0))),
		"hp": upgraded(b["hp"], star, int(up.get("hp", 0))),
		"crit": 0.0, "crit_dmg": 0.0, "aspd": 0.0, "energy": 0.0, "guard": 0.0, "spd": 0.0,
	}
	var eq: Dictionary = h.get("eq", {})
	for slot: String in eq:
		var item := find_treasure(profile, int(eq[slot]))
		if item.is_empty():
			continue
		out[treasure_main_stat(item)] += treasure_main(item)
		var open := treasure_open_subs(item)
		var subs: Array = item.get("subs", [])
		for i in mini(open, subs.size()):
			out[String(subs[i]["kind"])] += float(subs[i]["v"])
	return out


## Soldier stats: 병종 카드 성급 x1.15^(star-1) and barracks upgrades (+3 % per level on atk and hp).
static func soldier_stats(profile: Dictionary, id: String) -> Dictionary:
	var d := DB.soldier(id)
	var cls := String(d.get("cls", "inf"))
	var lv: Dictionary = profile.get("barracks", {}).get(cls, {})
	var k := float(_m()["barracks"]["per_level"])
	var t: Dictionary = profile.get("troops", {}).get(id, {})
	var star := int(t.get("star", 1))
	var up: Dictionary = t.get("up", {})
	return {"atk": upgraded(float(d["atk"]), star, int(up.get("atk", 0))) * (1.0 + k * int(lv.get("atk", 0))),
		"hp": upgraded(float(d["hp"]), star, int(up.get("hp", 0))) * (1.0 + k * int(lv.get("hp", 0))),
		"def": upgraded(float(d.get("def", 0)), star, int(up.get("def", 0))),
		"crit": 0.0, "crit_dmg": 0.0, "aspd": 0.0, "energy": 0.0, "guard": 0.0, "spd": 0.0}


static func barracks_cost(level: int) -> int:
	var b: Dictionary = _m()["barracks"]
	return int(round(float(b["cost_base"]) * pow(level + 1, float(b["cost_exp"]))))


static func barracks_cap(lord_lv: int) -> int:
	return lord_lv * int(_m()["barracks"]["cap_per_lord_lv"])


## 전투력 = atk x 10 + def x 8 + hp (§4.7).
static func power_of(stats: Dictionary) -> int:
	var p: Dictionary = _m()["power"]
	return int(round(float(stats["atk"]) * float(p["atk"]) + float(stats["def"]) * float(p["def"]) + float(stats["hp"]) * float(p["hp"])))


static func hero_power(profile: Dictionary, id: String) -> int:
	return power_of(hero_stats(profile, id))


static func find_treasure(profile: Dictionary, uid: int) -> Dictionary:
	for t: Dictionary in profile.get("treasures", []):
		if int(t["uid"]) == uid:
			return t
	return {}


## Hero id wearing treasure [param uid], or "".
static func treasure_owner(profile: Dictionary, uid: int) -> String:
	var heroes: Dictionary = profile.get("heroes", {})
	for id: String in heroes:
		var eq: Dictionary = heroes[id].get("eq", {})
		for slot: String in eq:
			if int(eq[slot]) == uid:
				return id
	return ""


# ---------------------------------------------------------------- lord level

## Exp from level n to n+1: round(200 x n^1.3) (콘텐츠 §10).
static func lord_exp_need(lv: int) -> int:
	var l: Dictionary = _m()["lord"]
	return int(round(float(l["exp_base"]) * pow(lv, float(l["exp_exp"]))))


static func lineup_slots(lord_lv: int) -> int:
	var n := 6
	for pair: Array in _m()["lord"]["lineup_slots"]:
		if lord_lv >= int(pair[0]):
			n = int(pair[1])
	return n


## 병종 전투력 (병종 탭 표시용).
static func soldier_power(profile: Dictionary, id: String) -> int:
	return power_of(soldier_stats(profile, id))


## Run gold (§4.6): 100 x waves reached + 500 on victory.
static func run_gold(waves_reached: int, victory: bool) -> int:
	var s := DB.stages
	return int(s["gold_per_wave"]) * waves_reached + (int(s["gold_victory"]) if victory else 0)


## Gold for the 군량 left when a run ends (메타 §3.10: 남은 군량 × rice_to_gold).
static func rice_gold(rice_left: int) -> int:
	return maxi(0, rice_left) * int(DB.rules["rice_to_gold"])


## Extra starting 군량 from 주공 레벨 (메타 §3.10: Lv 10·20·30에서 +20씩).
static func start_rice_bonus(lord_lv: int) -> int:
	var n := 0
	for step: Array in DB.rules["start_rice_lord"]:
		if lord_lv >= int(step[0]):
			n += int(step[1])
	return n


## Card / lobby "Lv": 1 + the average of the three stat upgrade levels.
static func hero_level(profile: Dictionary, id: String) -> int:
	var h: Dictionary = profile["heroes"].get(id, {})
	if h.is_empty():
		return 0
	var up: Dictionary = h["up"]
	return 1 + int((int(up.get("atk", 0)) + int(up.get("def", 0)) + int(up.get("hp", 0))) / 3)


# ---------------------------------------------------------------- 출정 편성 (병종 4 + 장수 최대 3)

## Troops a hero lineup needs on the reels (each hero's own troop, no repeats).
static func required_troops(heroes: Array) -> Array:
	var out: Array = []
	for h: Variant in heroes:
		var t := DB.troop_of(String(h))
		if t != "" and not out.has(t):
			out.append(t)
	return out


## 자동 편성: the strongest owned heroes (max hero_lineup_max) whose troops still
## fit, their troops, then the strongest other owned troops up to troop_lineup.
## Returns {heroes, troops}.
static func auto_lineup(profile: Dictionary) -> Dictionary:
	var hmax := int(DB.rules["hero_lineup_max"])
	var tmax := int(DB.rules["troop_lineup"])
	var heroes: Array = (profile.get("heroes", {}) as Dictionary).keys()
	heroes.sort_custom(func(a: String, b: String) -> bool: return hero_power(profile, a) > hero_power(profile, b))
	var pick: Array = []
	var troops: Array = []
	for h: String in heroes:
		if pick.size() >= hmax:
			break
		var t := DB.troop_of(h)
		if not troops.has(t) and troops.size() >= tmax:
			continue
		pick.append(h)
		if not troops.has(t):
			troops.append(t)
	var owned: Array = (profile.get("troops", {}) as Dictionary).keys()
	owned.sort_custom(func(a: String, b: String) -> bool: return soldier_power(profile, a) > soldier_power(profile, b))
	for t: String in owned:
		if troops.size() >= tmax:
			break
		if not troops.has(t):
			troops.append(t)
	return {"heroes": pick, "troops": troops}


## Chance (0..1) that one spin completes at least one line, for a reel made of
## [param troops] (weight_soldier each) and [param heroes] (weight_hero each).
## A line matches when its 3 cells share a troop (heroes count as their troop).
static func line_chance(troops: Array, heroes: Array) -> float:
	var ws := float(DB.rules["weight_soldier"])
	var wh := float(DB.rules["weight_hero"])
	var total := ws * troops.size() + wh * heroes.size()
	if total <= 0.0:
		return 0.0
	var per_line := 0.0
	for t: Variant in troops:
		var w := ws
		for h: Variant in heroes:
			if DB.troop_of(String(h)) == String(t):
				w += wh
		var p := w / total
		per_line += p * p * p
	return 1.0 - pow(1.0 - per_line, SlotMachine.LINES.size())
