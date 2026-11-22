class_name DB
extends RefCounted
## Read-only game data from res://data/*.json (built by tools/build_data.py from
## the 기획서). No game number lives in code; every screen and rule asks DB.

const DIR := "res://data/"

static var rules: Dictionary = {}
static var units: Dictionary = {}
static var stages: Dictionary = {}
static var meta: Dictionary = {}
static var shop: Dictionary = {}
static var missions: Dictionary = {}
static var mail: Dictionary = {}
static var strings: Dictionary = {}
static var _loaded := false


static func ensure() -> void:
	if _loaded:
		return
	_loaded = true
	rules = _read("rules.json")
	units = _read("units.json")
	stages = _read("stages.json")
	meta = _read("meta.json")
	shop = _read("shop.json")
	missions = _read("missions.json")
	mail = _read("mail.json")
	strings = _read("strings_ko.json")


static func _read(file: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(DIR + file)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("DB: cannot parse " + file)
	return {}


## Localised text from strings_ko.json; "%s" args are filled in order.
static func t(key: String, args: Array = []) -> String:
	ensure()
	var s := String(strings.get(key, key))
	if not args.is_empty():
		s = s % args
	return s


# ---------------------------------------------------------------- units

static func is_hero(id: String) -> bool:
	ensure()
	return units["heroes"].has(id)


static func is_soldier(id: String) -> bool:
	ensure()
	return units["soldiers"].has(id)


static func hero(id: String) -> Dictionary:
	ensure()
	return units["heroes"].get(id, {})


static func soldier(id: String) -> Dictionary:
	ensure()
	return units["soldiers"].get(id, {})


## Definition of a recruitable unit (soldier or hero).
static func unit_def(id: String) -> Dictionary:
	ensure()
	if units["heroes"].has(id):
		return units["heroes"][id]
	return units["soldiers"].get(id, {})


static func unit_name(id: String) -> String:
	return String(unit_def(id).get("name", id))


static func cls_of(id: String) -> String:
	return String(unit_def(id).get("cls", ""))


## 병종 of a unit: a soldier is its own troop; a hero belongs to one troop
## (관우 = 창병). Slot lines match on this (2026-11-22 재설계).
static func troop_of(id: String) -> String:
	ensure()
	if units["soldiers"].has(id):
		return id
	return String(units["heroes"].get(id, {}).get("troop", ""))


static func troop_name(troop: String) -> String:
	return String(soldier(troop).get("name", troop))


## All soldier (병종) ids in data order.
static func soldier_ids() -> Array:
	ensure()
	return units["soldiers"].keys()


## Soldier ids of a recruit tier ("basic" / "elite").
static func soldier_ids_of_tier(tier: String) -> Array:
	var out: Array = []
	for id: String in soldier_ids():
		if String(units["soldiers"][id].get("tier", "basic")) == tier:
			out.append(id)
	return out


## Heroes that belong to [param troop].
static func heroes_of_troop(troop: String) -> Array:
	var out: Array = []
	for id: String in hero_ids():
		if String(units["heroes"][id].get("troop", "")) == troop:
			out.append(id)
	return out


static func fac_of(id: String) -> String:
	return String(unit_def(id).get("fac", ""))


static func rarity_of(id: String) -> String:
	return String(unit_def(id).get("rarity", "soldier"))


static func cls_name(cls: String) -> String:
	ensure()
	return String(units["classes"].get(cls, {}).get("name", cls))


static func fac_name(fac: String) -> String:
	ensure()
	return String(units["factions"].get(fac, {}).get("name", ""))


static func fac_color(fac: String) -> Color:
	ensure()
	var f: Dictionary = units["factions"].get(fac, {})
	return Color(String(f.get("color", "#5b6b7e")))


static func rarity_color(rarity: String) -> Color:
	ensure()
	return Color(String(units["rarities"].get(rarity, {}).get("color", "#8a8f98")))


static func rarity_name(rarity: String) -> String:
	ensure()
	return String(units["rarities"].get(rarity, {}).get("name", ""))


static func hero_ids() -> Array:
	ensure()
	return units["heroes"].keys()


static func hero_ids_of_rarity(rarity: String) -> Array:
	var out: Array = []
	for id: String in hero_ids():
		if String(units["heroes"][id]["rarity"]) == rarity:
			out.append(id)
	return out


static func traits_of(cls: String) -> Array:
	ensure()
	return units["traits"].get(cls, [])


static func trait_def(trait_id: String) -> Dictionary:
	ensure()
	for cls: String in units["traits"]:
		for tr: Dictionary in units["traits"][cls]:
			if String(tr["id"]) == trait_id:
				var d := tr.duplicate()
				d["cls"] = cls
				return d
	return {}


static func advisor_skill(id: String) -> Dictionary:
	ensure()
	return units["advisors"].get(id, {})


static func enemy_def(id: String) -> Dictionary:
	ensure()
	if units["enemies"].has(id):
		return units["enemies"][id]
	return units["bosses"].get(id, {})


static func is_boss(id: String) -> bool:
	ensure()
	return units["bosses"].has(id)


# ---------------------------------------------------------------- stages

static func chapters() -> Array:
	ensure()
	return stages["chapters"]


static func chapter(c: int) -> Dictionary:
	var list := chapters()
	return list[clampi(c - 1, 0, list.size() - 1)]


static func stage_count() -> int:
	return chapters().size() * 8


## "1-3" style key.
static func stage_key(c: int, s: int) -> String:
	return "%d-%d" % [c, s]


## Global 1-based stage number (1-1 = 1, 2-1 = 9).
static func stage_index(c: int, s: int) -> int:
	return (c - 1) * 8 + s


static func stage_name(c: int, s: int) -> String:
	var names: Array = chapter(c)["stages"]
	return String(names[clampi(s - 1, 0, names.size() - 1)])


## Enemy hp/atk multiplier of a stage: 1.09^(s-1) (콘텐츠 §2.2).
static func stage_mult(c: int, s: int) -> float:
	ensure()
	return pow(float(stages["difficulty_base"]), stage_index(c, s) - 1)


## The 10 waves of stage c-s: the template with stage scaling, the 5th stage's
## general and the 8th stage's chapter boss on wave 10.
## Each wave: {list: [[enemy, n]], flank: [...], boss: id or "", judge: bool}
static func stage_waves(c: int, s: int) -> Array:
	ensure()
	var tmpl: Array = stages["waves_template"]
	var ch := chapter(c)
	var grow := 1.0 + float(stages["count_step"]) * (s - 1)
	var out: Array = []
	for w in tmpl.size():
		var src: Dictionary = tmpl[w]
		var wave := {"list": [], "flank": [], "boss": "", "judge": bool(src.get("judge", false))}
		for pair: Array in src.get("list", []):
			wave["list"].append([String(pair[0]), maxi(1, int(round(float(pair[1]) * grow)))])
		for pair: Array in src.get("flank", []):
			wave["flank"].append([String(pair[0]), maxi(1, int(round(float(pair[1]) * grow)))])
		if w == tmpl.size() - 1:
			if s == 8:
				wave["boss"] = String(ch["boss"])
			elif s == 5:
				wave["boss"] = String(ch["elite"])
			else:
				wave["list"].append(["brute", 1 + int(s >= 3)])
		out.append(wave)
	return out


static func stage_boss(c: int, s: int) -> String:
	var waves := stage_waves(c, s)
	return String(waves[waves.size() - 1]["boss"])


static func recommended_power(c: int, s: int) -> int:
	ensure()
	var base := float(stages["recommended_power"]) * pow(float(stages["recommended_step"]), c - 1)
	return int(round(base * (0.55 + 0.45 * float(s) / 8.0) / 100.0)) * 100


# ---------------------------------------------------------------- treasures

static func treasure_def(tid: String) -> Dictionary:
	ensure()
	for t: Dictionary in meta["treasure"]["list"]:
		if String(t["id"]) == tid:
			return t
	return {}


static func treasures_of_rarity(rarity: String) -> Array:
	ensure()
	var out: Array = []
	for t: Dictionary in meta["treasure"]["list"]:
		if String(t["rarity"]) == rarity:
			out.append(t)
	return out
