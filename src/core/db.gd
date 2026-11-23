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


## 속성 3장 a food of [param troop] offers: its class's two + its own (개편 §9.6).
static func traits_for(troop: String) -> Array:
	ensure()
	var out: Array = []
	var cls := String(units["soldiers"].get(troop, {}).get("cls", ""))
	for tr: Dictionary in units["traits"]["class"].get(cls, []):
		out.append(tr)
	if units["traits"]["troop"].has(troop):
		out.append(units["traits"]["troop"][troop])
	return out


static func trait_def(trait_id: String) -> Dictionary:
	ensure()
	for cls: String in units["traits"]["class"]:
		for tr: Dictionary in units["traits"]["class"][cls]:
			if String(tr["id"]) == trait_id:
				return tr
	for troop: String in units["traits"]["troop"]:
		var t: Dictionary = units["traits"]["troop"][troop]
		if String(t["id"]) == trait_id:
			return t
	return {}


## "철벽 2 · 받는 피해 -13%" style text of a trait at [param lv] (1-based).
static func trait_desc(trait_id: String, lv: int) -> String:
	var descs: Array = trait_def(trait_id).get("descs", [])
	return String(descs[clampi(lv - 1, 0, descs.size() - 1)]) if not descs.is_empty() else ""


## 상성 줄 of a unit or enemy (창병 / 보병 / 궁병 / 기병 / 화공 / 뇌공 / 의원).
static func ctr_of(id: String) -> String:
	ensure()
	var d := unit_def(id)
	if d.is_empty():
		d = enemy_def(id)
	return String(d.get("ctr", d.get("cls", "")))


## Damage multiplier of an attacker of line [param ctr] against a defender of class [param cls] (§9.5).
static func counter(ctr: String, cls: String) -> float:
	ensure()
	return float(units["counters"].get(ctr, {}).get(cls, 1.0))


## Classes [param ctr] is strong (mult > 1) or weak (mult < 1) against: {strong: [cls], weak: [cls]}.
static func counter_lists(ctr: String) -> Dictionary:
	ensure()
	var strong: Array = []
	var weak: Array = []
	var row: Dictionary = units["counters"].get(ctr, {})
	for cls: String in row:
		if float(row[cls]) > 1.0:
			strong.append(cls)
		elif float(row[cls]) < 1.0:
			weak.append(cls)
	return {"strong": strong, "weak": weak}


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

## 스테이지 10개 (스테이지-흡수-합성-개편 §3.1): [{id, name, enemy, hue, boss}].
static func stage_list() -> Array:
	ensure()
	return stages["stages"]


static func stage_def(s: int) -> Dictionary:
	var list := stage_list()
	return list[clampi(s - 1, 0, list.size() - 1)]


static func stage_count() -> int:
	return stage_list().size()


## 난이도: [{id, name, mult, count}] (보통 · 어려움 · 지옥).
static func difficulties() -> Array:
	ensure()
	return stages["difficulties"]


static func difficulty(d: int) -> Dictionary:
	var list := difficulties()
	return list[clampi(d - 1, 0, list.size() - 1)]


## "3-2" style key: stage 3, difficulty 2.
static func stage_key(s: int, d: int) -> String:
	return "%d-%d" % [s, d]


static func stage_name(s: int) -> String:
	return String(stage_def(s).get("name", ""))


## Enemy count multiplier (2026-11-23, 적 수 제한 없음 · 병사 무제한에 맞춤): grows with the
## stage and the wave so the start stays small. count_base x (1 + count_stage x (s-1))
## x (1 + count_wave x wave) x difficulty count.
static func count_mult(s: int, d: int, wave: int) -> float:
	ensure()
	return float(stages.get("count_base", 1.0)) * (1.0 + float(stages.get("count_stage", 0.0)) * (s - 1)) 		* (1.0 + float(stages.get("count_wave", 0.0)) * wave) * float(difficulty(d)["count"])


## Enemy hp/atk multiplier: stage_base^(stage-1) x difficulty (§4).
static func stage_mult(s: int, d: int) -> float:
	ensure()
	return pow(float(stages["stage_base"]), s - 1) * float(difficulty(d)["mult"])


## The 10 waves of stage s on difficulty d: the template with the difficulty's
## enemy count and the stage boss on the last wave.
## Each wave: {list: [[enemy, n]], flank: [...], boss: id or "", judge: bool}
static func stage_waves(s: int, d: int) -> Array:
	ensure()
	var tmpl: Array = stages["waves_template"]
	var out: Array = []
	for w in tmpl.size():
		var src: Dictionary = tmpl[w]
		var grow := count_mult(s, d, w)
		# 적이 많아지면 나오는 간격을 좁힌다 (웨이브가 너무 길어지지 않게)
		var wave := {"list": [], "flank": [], "boss": "", "judge": bool(src.get("judge", false)),
			"gap_mult": 1.0 / sqrt(maxf(1.0, grow))}
		for pair: Array in src.get("list", []):
			wave["list"].append([String(pair[0]), maxi(1, int(round(float(pair[1]) * grow)))])
		for pair: Array in src.get("flank", []):
			wave["flank"].append([String(pair[0]), maxi(1, int(round(float(pair[1]) * grow)))])
		if w == tmpl.size() - 1:
			wave["boss"] = stage_boss(s)
		out.append(wave)
	return out


static func stage_boss(s: int) -> String:
	return String(stage_def(s).get("boss", ""))


static func recommended_power(s: int, d: int) -> int:
	ensure()
	return int(round(float(stages["recommended_power"]) * stage_mult(s, d) / 100.0)) * 100


# ---------------------------------------------------------------- treasures

static func treasure_def(tid: String) -> Dictionary:
	ensure()
	for t: Dictionary in meta["treasure"]["list"]:
		if String(t["id"]) == tid:
			return t
	return {}


## Treasures of one slot (weapon / armor / charm) and rarity: the pool a 합성 picks from.
static func treasures_of(slot: String, rarity: String) -> Array:
	ensure()
	var out: Array = []
	for t: Dictionary in meta["treasure"]["list"]:
		if String(t["slot"]) == slot and String(t["rarity"]) == rarity:
			out.append(t)
	return out


## Next rarity up ("" for the top one).
static func next_rarity(rarity: String) -> String:
	ensure()
	var order: Array = meta["treasure"]["rarity_order"]
	var i := order.find(rarity)
	return String(order[i + 1]) if i >= 0 and i + 1 < order.size() else ""


static func treasures_of_rarity(rarity: String) -> Array:
	ensure()
	var out: Array = []
	for t: Dictionary in meta["treasure"]["list"]:
		if String(t["rarity"]) == rarity:
			out.append(t)
	return out
