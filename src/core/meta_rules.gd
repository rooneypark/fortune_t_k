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


## 군주 레벨 배율 (개편 §9.3): every unit's base atk / def / hp x (1 + 0.03 x (Lv - 1)).
static func lord_mult(profile: Dictionary) -> float:
	return 1.0 + float(_m()["lord"]["stat_per_level"]) * (int(profile.get("lord_lv", 1)) - 1)


## Base stat after 성급 and 군주 레벨. Units have no level of their own (§9.1).
static func grown(base: float, star: int, profile: Dictionary) -> float:
	return base * star_mult(star) * lord_mult(profile)


## 군주 경험 for clearing stage s on difficulty d (only a clear pays, first clear x2).
static func clear_exp(s: int, d: int, first: bool) -> int:
	var l: Dictionary = _m()["lord"]
	var diffs: Array = l["diff_exp"]
	var e := float(l["clear_exp"]) * s * float(diffs[clampi(d - 1, 0, diffs.size() - 1)])
	return int(round(e * (float(l["first_mult"]) if first else 1.0)))


# ---------------------------------------------------------------- 성급 · 속성 (계정, 개편 §9.2)

## The account entry that holds a unit's 성급 / 속성: the hero's own, or its troop's
## for a soldier. {} when not owned.
static func entry(profile: Dictionary, id: String) -> Dictionary:
	if DB.is_hero(id):
		return profile.get("heroes", {}).get(id, {})
	return profile.get("troops", {}).get(id, {})


static func unit_star(profile: Dictionary, id: String) -> int:
	var e := entry(profile, id)
	if e.is_empty():
		return start_star(id) if DB.is_hero(id) else 1
	return int(e.get("star", 1))


static func star_max() -> int:
	return int(_m()["star"]["max"])


## 성급 경험 needed to go from [param star] to star + 1, or -1 at max.
static func star_need(id: String, star: int) -> int:
	var table: Array = _m()["star"]["hero_xp" if DB.is_hero(id) else "troop_xp"]
	if star < 1 or star > table.size() or star >= star_max():
		return -1
	return int(table[star - 1])


## 성급 경험 a food gives a target of the same troop: 10 for a copy of the same hero, else 1.
static func star_xp(food_id: String, target_id: String) -> int:
	var s: Dictionary = _m()["star"]
	return int(s["xp_copy"]) if food_id == target_id and DB.is_hero(food_id) else int(s["xp_troop"])


## 속성 칸 수 by 성급 (1~2성 1, 3~4성 2, 5~6성 3).
static func trait_slots(star: int) -> int:
	var slots: Array = _m()["star"]["trait_slots"]
	return int(slots[clampi(star - 1, 0, slots.size() - 1)])


static func trait_max() -> int:
	return int(_m()["star"]["trait_max"])


## 속성 of a unit: [{id, lv}].
static func unit_traits(profile: Dictionary, id: String) -> Array:
	return entry(profile, id).get("traits", [])


static func trait_level(profile: Dictionary, id: String, trait_id: String) -> int:
	for t: Dictionary in unit_traits(profile, id):
		if String(t["id"]) == trait_id:
			return int(t["lv"])
	return 0


## Adds one effect to a fighter's fx set. Multipliers multiply, flat bonuses add,
## "best of" effects keep the larger value.
static func merge_fx(out: Dictionary, key: String, v: Variant) -> void:
	match key:
		"dmg_taken", "ranged_resist", "hp", "aspd", "spd", "energy", "vs_cav", "full_hp_dmg", "phalanx", "burn_taken":
			out[key] = float(out.get(key, 1.0)) * float(v)
		"def_add", "range", "crit", "crit_dmg":
			out[key] = float(out.get(key, 0.0)) + float(v)
		"taunt":
			out["taunt"] = true
		"taunt_guard":
			out["taunt"] = true
			out["dmg_taken"] = float(out.get("dmg_taken", 1.0)) * float(v)
		"backline":
			out["backline"] = true
			if v is float or v is int:
				out["backline_dmg"] = maxf(float(out.get("backline_dmg", 1.0)), float(v))
		_:
			# splash, pierce, first_hit, armor_break, burn, stun_chance, heal_aura, double, first_hit_stun, skirmish
			out[key] = maxf(float(out.get(key, 0.0)), float(v))


## Everything the battle needs to know about a unit's effects: the troop's own
## feature (a hero fights like its troop) plus the account's 속성 at their levels.
static func unit_fx(profile: Dictionary, id: String) -> Dictionary:
	var out := {}
	var innate: Dictionary = DB.soldier(DB.troop_of(id)).get("fx", {})
	for k: String in innate:
		merge_fx(out, k, innate[k])
	# 보물(영웅 · 전설 장비)의 특수 능력 (개편 §11)
	var eq: Dictionary = entry(profile, id).get("eq", {})
	for slot: String in eq:
		var item := find_treasure(profile, int(eq[slot]))
		if item.is_empty():
			continue
		var gear: Array = DB.treasure_def(String(item["tid"])).get("fx", [])
		if gear.size() == 2:
			merge_fx(out, String(gear[0]), gear[1])
	for t: Dictionary in unit_traits(profile, id):
		var def := DB.trait_def(String(t["id"]))
		if def.is_empty():
			continue
		var vals: Array = def["v"]
		merge_fx(out, String(def["fx"]), vals[clampi(int(t["lv"]) - 1, 0, vals.size() - 1)])
	return out


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

## Adds what the worn 장비 give to [param out]: the main stat (a hero wearing its
## own 전용 보물 gets exclusive_bonus on it) and the open sub stats.
static func _add_gear(out: Dictionary, profile: Dictionary, id: String) -> void:
	var eq: Dictionary = entry(profile, id).get("eq", {})
	for slot: String in eq:
		var item := find_treasure(profile, int(eq[slot]))
		if item.is_empty():
			continue
		var main := treasure_main(item)
		if String(DB.treasure_def(String(item["tid"])).get("exclusive", "")) == id:
			main *= float(_m()["treasure"]["exclusive_bonus"])
		out[treasure_main_stat(item)] += main
		var open := treasure_open_subs(item)
		var subs: Array = item.get("subs", [])
		for i in mini(open, subs.size()):
			out[String(subs[i]["kind"])] += float(subs[i]["v"])


## Final account stats of a hero: base x 1.15^(star-1) x 군주 배율 + 장비.
## Also returns the summed open sub stats (crit, crit_dmg, aspd, energy, guard, spd).
static func hero_stats(profile: Dictionary, id: String) -> Dictionary:
	var b := base_stats(id)
	var star := int(profile.get("heroes", {}).get(id, {}).get("star", start_star(id)))
	var out := {
		"atk": grown(b["atk"], star, profile),
		"def": grown(b["def"], star, profile),
		"hp": grown(b["hp"], star, profile),
		"crit": 0.0, "crit_dmg": 0.0, "aspd": 0.0, "energy": 0.0, "guard": 0.0, "spd": 0.0,
	}
	_add_gear(out, profile, id)
	return out


## Soldier stats: base x 1.15^(병종 성급 - 1) x 군주 배율 + the troop's 장비
## (worn by the troop, so every soldier of it has them).
static func soldier_stats(profile: Dictionary, id: String) -> Dictionary:
	var d := DB.soldier(id)
	var star := int(profile.get("troops", {}).get(id, {}).get("star", 1))
	var out := {"atk": grown(float(d["atk"]), star, profile), "hp": grown(float(d["hp"]), star, profile),
		"def": grown(float(d.get("def", 0)), star, profile),
		"crit": 0.0, "crit_dmg": 0.0, "aspd": 0.0, "energy": 0.0, "guard": 0.0, "spd": 0.0}
	_add_gear(out, profile, id)
	return out


## Stats of a unit without its 장비 (for the "장비 합계" line).
static func bare_stats(profile: Dictionary, id: String) -> Dictionary:
	var e := entry(profile, id).duplicate()
	e["eq"] = {}
	var p := {"lord_lv": profile.get("lord_lv", 1), "heroes": {}, "troops": {}, "treasures": []}
	p["heroes" if DB.is_hero(id) else "troops"][id] = e
	return unit_stats(p, id)


## Stats of any recruitable unit.
static func unit_stats(profile: Dictionary, id: String) -> Dictionary:
	return hero_stats(profile, id) if DB.is_hero(id) else soldier_stats(profile, id)


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


## Hero or troop id wearing 장비 [param uid], or "".
static func treasure_owner(profile: Dictionary, uid: int) -> String:
	for group in ["heroes", "troops"]:
		var units: Dictionary = profile.get(group, {})
		for id: String in units:
			var eq: Dictionary = units[id].get("eq", {})
			for slot: String in eq:
				if int(eq[slot]) == uid:
					return id
	return ""


# ---------------------------------------------------------------- lord level

## Exp from level n to n+1: round(200 x n^1.3) (콘텐츠 §10).
static func lord_exp_need(lv: int) -> int:
	var l: Dictionary = _m()["lord"]
	return int(round(float(l["exp_base"]) * pow(lv, float(l["exp_exp"]))))


## 병종 전투력 (병종 탭 표시용).
static func soldier_power(profile: Dictionary, id: String) -> int:
	return power_of(soldier_stats(profile, id))


## Run gold (§4.6): 100 x waves reached + 500 on victory.
static func run_gold(waves_reached: int, victory: bool) -> int:
	var s := DB.stages
	return int(s["gold_per_wave"]) * waves_reached + (int(s["gold_victory"]) if victory else 0)
