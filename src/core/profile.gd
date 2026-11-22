class_name Profile
extends RefCounted
## The account (everything that survives a run): currencies, heroes with stars /
## upgrades / treasures, lineup, stage progress, pity counters, missions, pass,
## mail, shop flags, settings and tutorial state. Plain dictionary so it saves
## as JSON. All account actions live here so they are testable without nodes.
## (기획서는 결제 때문에 서버 저장을 요구한다 — 지금은 로컬 저장, 서버는 나중에.)

signal changed

const VERSION := 1

var data: Dictionary = {}
var rng := RandomNumberGenerator.new()
## Unix time source; tests may replace it.
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system())


static func defaults() -> Dictionary:
	DB.ensure()
	var st: Dictionary = DB.meta["start"]
	var d := {
		"version": VERSION,
		"gold": int(st["gold"]), "diamond": int(st["diamond"]), "tickets": int(st["tickets"]), "honor": 0,
		"lord_lv": 4, "lord_exp": 120, "name": "주공", "avatar": "guanyu",
		"heroes": {}, "troops": {}, "troop_lineup": (st["troops"] as Array).duplicate(), "treasures": [], "next_uid": 1,
		"lineup": (DB.rules["default_lineup"] as Array).duplicate(), "advisor": String(DB.rules["default_advisor"]),
		"barracks": {"inf": {"atk": 0, "hp": 0}, "arc": {"atk": 0, "hp": 0}, "cav": {"atk": 0, "hp": 0}, "str": {"atk": 0, "hp": 0}},
		"progress": {"cleared": {}, "last": "1-1"},
		"pity": {"normal": 0, "box": 0, "soldier": 0},
		"missions": {"day": "", "week": "", "daily": {}, "weekly": {}, "total": {}, "claimed": {}},
		"arena": {"day": "", "used": 0, "bought": 0},
		"arena_shop": {"week": "", "bought": {}},
		"gold_buy": {"day": "", "count": 0},
		"gold_recruit": {"day": "", "count": 0},
		"mail": [],
		"shop": {"first": {}, "monthly_until": 0, "monthly_last": "", "packages": {}},
		"attendance": {"count": 0, "last": ""},
		"settings": {"bgm": 0.6, "sfx": 0.8, "slot_speed": 1, "vibrate": true, "shake": true, "font": 1, "notify": true},
		"tutorial": {"done": false, "recruit": false},
		"stats": {"runs": 0, "victories": 0, "best_stage": 0, "jackpots": 0, "kills": 0},
	}
	for id: String in st["heroes"]:
		d["heroes"][id] = new_hero(id)
	for id: String in st["troops"]:
		d["troops"][id] = new_troop()
	return d


## 병종 카드: 성급 · 카드 · 강화(공·방·체), 장수와 같은 구조 (보물은 없음).
static func new_troop() -> Dictionary:
	return {"star": 1, "cards": 0, "up": {"atk": 0, "def": 0, "hp": 0}}


static func new_hero(id: String) -> Dictionary:
	return {"star": MetaRules.start_star(id), "cards": 0, "up": {"atk": 0, "def": 0, "hp": 0}, "eq": {}}


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
	_merge(d, parsed)
	data = d
	_fix_types()
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
	for k in ["gold", "diamond", "tickets", "honor", "lord_lv", "lord_exp", "next_uid"]:
		data[k] = int(data[k])
	for id: String in data["heroes"]:
		var h: Dictionary = data["heroes"][id]
		h["star"] = int(h["star"])
		h["cards"] = int(h["cards"])
		for s: String in h["up"]:
			h["up"][s] = int(h["up"][s])
		for s: String in h["eq"]:
			h["eq"][s] = int(h["eq"][s])
	for id: String in data["troops"]:
		var t: Dictionary = data["troops"][id]
		t["star"] = int(t["star"])
		t["cards"] = int(t["cards"])
		var up: Dictionary = t.get("up", {})
		t["up"] = {"atk": int(up.get("atk", 0)), "def": int(up.get("def", 0)), "hp": int(up.get("hp", 0))}
	for t: Dictionary in data["treasures"]:
		t["uid"] = int(t["uid"])
		t["lv"] = int(t["lv"])
	for k: String in data["pity"]:
		data["pity"][k] = int(data["pity"][k])
	for k in ["used", "bought"]:
		data["arena"][k] = int(data["arena"].get(k, 0))
	data["arena"].erase("entries")
	data["arena"].erase("updated_at")
	for k: String in data["arena_shop"]["bought"]:
		data["arena_shop"]["bought"][k] = int(data["arena_shop"]["bought"][k])
	data["gold_buy"]["count"] = int(data["gold_buy"]["count"])
	data["gold_recruit"]["count"] = int(data["gold_recruit"]["count"])
	for k: String in data["shop"]["packages"]:
		data["shop"]["packages"][k] = int(data["shop"]["packages"][k])
	data["shop"]["monthly_until"] = int(data["shop"]["monthly_until"])
	for b: Dictionary in data["barracks"].values():
		for s: String in b:
			b[s] = int(b[s])
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


## Grants a reward dictionary: gold, diamond, tickets, lord_exp, pass_exp, boxes,
## hero (id), treasure (tid). Returns the list of gained treasures/heroes for display.
func grant(reward: Dictionary) -> Array:
	var gained: Array = []
	for k: String in reward:
		var v: Variant = reward[k]
		match k:
			"gold", "diamond", "tickets", "honor":
				data[k] = int(data[k]) + int(v)
			"lord_exp":
				add_lord_exp(int(v))
			"boxes":
				for i in int(v):
					gained.append(open_box_free())
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


## A recruited copy: new hero, or +1 card (6성 -> 군공, 메타 §5). Returns {id, new, honor}.
func add_hero_card(id: String) -> Dictionary:
	if not owns(id):
		data["heroes"][id] = new_hero(id)
		var lu: Array = data["lineup"]
		if lu.size() < int(DB.rules["hero_lineup_max"]) and not lu.has(id):
			lu.append(id)
		return {"type": "hero", "id": id, "new": true}
	var h := hero(id)
	if int(h["star"]) >= int(DB.meta["star"]["max"]):
		var hn := int(DB.meta["arena"]["dup_honor"])
		data["honor"] = int(data["honor"]) + hn
		return {"type": "hero", "id": id, "new": false, "honor": true, "honor_amount": hn}
	h["cards"] = int(h["cards"]) + 1
	return {"type": "hero", "id": id, "new": false}


## Raises one stat (atk/def/hp) a level for gold. Returns "" or the reason.
func upgrade_stat(id: String, stat: String) -> String:
	if not owns(id):
		return "?"
	var h := hero(id)
	var lv := int(h["up"][stat])
	if lv >= MetaRules.upgrade_cap(int(h["star"])):
		return DB.t("hero.need_star")
	var cost := MetaRules.upgrade_cost(lv)
	if not pay("gold", cost):
		return DB.t("common.no_gold")
	h["up"][stat] = lv + 1
	track("upgrades", 1)
	changed.emit()
	return ""


## Upgrades the cheapest stat repeatedly while gold lasts (모두 강화). Returns levels gained.
func upgrade_all(id: String) -> int:
	var n := 0
	while n < 300:
		var h := hero(id)
		var best := ""
		var best_cost := 1 << 30
		for s in ["atk", "def", "hp"]:
			var lv := int(h["up"][s])
			if lv < MetaRules.upgrade_cap(int(h["star"])) and MetaRules.upgrade_cost(lv) < best_cost:
				best = s
				best_cost = MetaRules.upgrade_cost(lv)
		if best == "" or not can_pay("gold", best_cost):
			break
		upgrade_stat(id, best)
		n += 1
	return n


func star_up(id: String) -> String:
	if not owns(id):
		return "?"
	var h := hero(id)
	var cost := MetaRules.star_cost(int(h["star"]))
	if cost < 0:
		return DB.t("hero.max_star")
	if int(h["cards"]) < cost:
		return DB.t("hero.no_cards")
	h["cards"] = int(h["cards"]) - cost
	h["star"] = int(h["star"]) + 1
	changed.emit()
	return ""


## 장수 편성 (최대 hero_lineup_max명, 보유 장수만).
func set_lineup(ids: Array, advisor: String) -> void:
	var out: Array = []
	for id: Variant in ids:
		if owns(String(id)) and not out.has(String(id)) and out.size() < int(DB.rules["hero_lineup_max"]):
			out.append(String(id))
	data["lineup"] = out
	data["advisor"] = advisor if owns(advisor) else ""
	changed.emit()


# ---------------------------------------------------------------- 병종 (troops, 2026-11-22)

func owns_troop(id: String) -> bool:
	return data["troops"].has(id)


func troop(id: String) -> Dictionary:
	return data["troops"].get(id, {})


## 슬롯에 올릴 병종 편성 (정확히 troop_lineup개, 보유 병종만).
func set_troop_lineup(ids: Array) -> void:
	var out: Array = []
	for id: Variant in ids:
		if owns_troop(String(id)) and not out.has(String(id)) and out.size() < int(DB.rules["troop_lineup"]):
			out.append(String(id))
	data["troop_lineup"] = out
	changed.emit()


## A soldier card: new troop, or +1 card (max star -> gold). Returns {type, id, new, gold}.
func add_troop_card(id: String) -> Dictionary:
	if not owns_troop(id):
		data["troops"][id] = new_troop()
		return {"type": "soldier", "id": id, "new": true}
	var t := troop(id)
	if int(t["star"]) >= int(DB.meta["star"]["max"]):
		var g := int(DB.meta["soldier_recruit"]["max_star_gold"])
		data["gold"] = int(data["gold"]) + g
		return {"type": "soldier", "id": id, "new": false, "gold": g}
	t["cards"] = int(t["cards"]) + 1
	return {"type": "soldier", "id": id, "new": false}


## 병종 강화 (골드, 장수와 같은 비용·상한 공식). Returns "" or the reason.
func troop_upgrade_stat(id: String, stat: String) -> String:
	if not owns_troop(id):
		return "?"
	var t := troop(id)
	var lv := int(t["up"][stat])
	if lv >= MetaRules.upgrade_cap(int(t["star"])):
		return DB.t("hero.need_star")
	var cost := MetaRules.upgrade_cost(lv)
	if not pay("gold", cost):
		return DB.t("common.no_gold")
	t["up"][stat] = lv + 1
	track("upgrades", 1)
	changed.emit()
	return ""


## 병종 일괄 강화: cheapest stat first while gold lasts. Returns levels gained.
func troop_upgrade_all(id: String) -> int:
	var n := 0
	while n < 300 and owns_troop(id):
		var t := troop(id)
		var best := ""
		var best_cost := 1 << 30
		for s in ["atk", "def", "hp"]:
			var lv := int(t["up"][s])
			if lv < MetaRules.upgrade_cap(int(t["star"])) and MetaRules.upgrade_cost(lv) < best_cost:
				best = s
				best_cost = MetaRules.upgrade_cost(lv)
		if best == "" or not can_pay("gold", best_cost):
			break
		troop_upgrade_stat(id, best)
		n += 1
	return n


func troop_star_up(id: String) -> String:
	if not owns_troop(id):
		return "?"
	var t := troop(id)
	var cost := MetaRules.star_cost(int(t["star"]))
	if cost < 0:
		return DB.t("hero.max_star")
	if int(t["cards"]) < cost:
		return DB.t("hero.no_cards")
	t["cards"] = int(t["cards"]) - cost
	t["star"] = int(t["star"]) + 1
	changed.emit()
	return ""


## 병사 모집: gold only. 1 or 10 pulls. Returns {cards, error}.
func recruit_soldiers(count: int) -> Dictionary:
	var sr: Dictionary = DB.meta["soldier_recruit"]
	var price := int(sr["cost_ten"]) if count >= 10 else int(sr["cost_one"]) * count
	if not pay("gold", price):
		return {"cards": [], "error": DB.t("common.no_gold")}
	var cards: Array = []
	for i in count:
		var id := Gacha.pull_soldier(rng)
		cards.append(add_troop_card(id))
	track("soldier_recruits", count)
	changed.emit()
	return {"cards": cards, "error": ""}


# ---------------------------------------------------------------- recruit

## 1 or 10 pulls. Pays tickets first, then diamonds. Returns {cards, error}.
func recruit(count: int) -> Dictionary:
	var rc: Dictionary = DB.meta["recruit"]
	var price := int(rc["cost_ten"]) if count >= 10 else int(rc["cost_one"]) * count
	if int(data["tickets"]) >= count:
		data["tickets"] = int(data["tickets"]) - count
	elif not pay("diamond", price):
		return {"cards": [], "error": DB.t("common.no_diamond")}
	var res := Gacha.pull_many(rng, int(data["pity"]["normal"]), count)
	data["pity"]["normal"] = int(res["pity"])
	var cards: Array = []
	for c: Dictionary in res["cards"]:
		var info := add_hero_card(String(c["id"]))
		info["rarity"] = c["rarity"]
		cards.append(info)
	track("recruits", count)
	changed.emit()
	return {"cards": cards, "error": ""}


## 골드 장수 모집 left today.
func gold_recruits_left() -> int:
	var g: Dictionary = data["gold_recruit"]
	var day := _date_key(int(clock.call()))
	if String(g.get("day", "")) != day:
		g["day"] = day
		g["count"] = 0
	return maxi(0, int(DB.meta["gold_recruit"]["daily_max"]) - int(g["count"]))


## 골드 장수 모집 [param count]회 (하루 daily_max). Returns {cards, error}.
func recruit_gold(count: int) -> Dictionary:
	if gold_recruits_left() < count:
		return {"cards": [], "error": DB.t("recruit.gold_limit")}
	var price := int(DB.meta["gold_recruit"]["cost_one"]) * count
	if not pay("gold", price):
		return {"cards": [], "error": DB.t("common.no_gold")}
	data["gold_recruit"]["count"] = int(data["gold_recruit"]["count"]) + count
	var cards: Array = []
	for i in count:
		var c := Gacha.pull_gold(rng)
		var info := add_hero_card(String(c["id"]))
		info["rarity"] = c["rarity"]
		cards.append(info)
	track("recruits", count)
	changed.emit()
	return {"cards": cards, "error": ""}


## Tutorial: the fixed hero (관우) — or a card if owned.
func recruit_tutorial() -> Dictionary:
	var id := String(DB.meta["recruit"]["tutorial_hero"])
	var info := add_hero_card(id)
	info["rarity"] = DB.rarity_of(id)
	data["tutorial"]["recruit"] = true
	changed.emit()
	return info


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


func open_box_free() -> Dictionary:
	var r := Gacha.roll_box(rng, int(data["pity"]["box"]))
	data["pity"]["box"] = int(r["pity"])
	return add_treasure(String(r["tid"]))


## Paid treasure box (다이아 150). Returns the gained item or {error}.
func buy_box() -> Dictionary:
	if not pay("diamond", int(DB.shop["box_cost"])):
		return {"error": DB.t("common.no_diamond")}
	var g := open_box_free()
	changed.emit()
	return g


func equip(hero_id: String, uid: int) -> void:
	var item := MetaRules.find_treasure(data, uid)
	if item.is_empty() or not owns(hero_id):
		return
	var slot := String(DB.treasure_def(String(item["tid"]))["slot"])
	var prev := MetaRules.treasure_owner(data, uid)
	if prev != "":
		hero(prev)["eq"].erase(slot)
	hero(hero_id)["eq"][slot] = uid
	changed.emit()


func unequip(hero_id: String, slot: String) -> void:
	if owns(hero_id):
		hero(hero_id)["eq"].erase(slot)
		changed.emit()


## Best treasure (by main value) into each empty or weaker slot (자동 장착).
func auto_equip(hero_id: String) -> void:
	for slot: String in DB.meta["treasure"]["slots"]:
		var best := {}
		var best_v := -1.0
		var cur_uid := int(hero(hero_id)["eq"].get(slot, -1))
		for item: Dictionary in data["treasures"]:
			if String(DB.treasure_def(String(item["tid"]))["slot"]) != slot:
				continue
			var owner := MetaRules.treasure_owner(data, int(item["uid"]))
			if owner != "" and owner != hero_id:
				continue
			var v := MetaRules.treasure_main(item)
			if v > best_v:
				best_v = v
				best = item
		if not best.is_empty() and int(best["uid"]) != cur_uid:
			equip(hero_id, int(best["uid"]))


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
		hero(owner)["eq"].erase(slot)
	var gold := MetaRules.dismantle_gold(item)
	data["treasures"].erase(item)
	data["gold"] = int(data["gold"]) + gold
	changed.emit()
	return gold


# ---------------------------------------------------------------- stages

func stars_of(key: String) -> int:
	return int(data["progress"]["cleared"].get(key, 0))


func is_unlocked(c: int, s: int) -> bool:
	if c == 1 and s == 1:
		return true
	var pc := c
	var ps := s - 1
	if ps < 1:
		pc -= 1
		ps = 8
	return stars_of(DB.stage_key(pc, ps)) > 0


func chapter_stars(c: int) -> int:
	var n := 0
	for s in range(1, 9):
		n += stars_of(DB.stage_key(c, s))
	return n


## Records a finished run and pays rewards (콘텐츠 §2.3, 메타 §4.6).
## Returns {gold, lord_exp, diamond, treasure, first, stars, level_ups}.
## Records a finished run. [param rice_left] is the 군량 left at the end; it
## turns into gold (메타 §3.10) whether the run was won, lost or given up.
func finish_run(c: int, s: int, waves_reached: int, victory: bool, stars: int, run_stats: Dictionary, rice_left: int = 0) -> Dictionary:
	var key := DB.stage_key(c, s)
	var first := victory and stars_of(key) == 0
	var gold := MetaRules.run_gold(waves_reached, victory)
	var rice_gold := MetaRules.rice_gold(rice_left)
	var lexp := int(DB.stages["lord_exp_per_wave"]) * waves_reached
	var out := {"gold": gold + rice_gold, "run_gold": gold, "rice_left": maxi(0, rice_left), "rice_gold": rice_gold,
		"lord_exp": lexp, "diamond": 0, "treasure": {}, "first": first, "stars": stars}
	data["gold"] = int(data["gold"]) + gold + rice_gold
	out["level_ups"] = add_lord_exp(lexp)
	if first:
		var dia := int(DB.stages["first_clear_diamond"])
		data["diamond"] = int(data["diamond"]) + dia
		out["diamond"] = dia
		var pool := DB.treasures_of_rarity("rare" if rng.randf() < 0.8 else "epic")
		out["treasure"] = add_treasure(String(pool[rng.randi_range(0, pool.size() - 1)]["id"]))
	if victory:
		data["progress"]["cleared"][key] = maxi(stars_of(key), stars)
		data["stats"]["victories"] = int(data["stats"]["victories"]) + 1
		data["stats"]["best_stage"] = maxi(int(data["stats"]["best_stage"]), DB.stage_index(c, s))
		track("clears", 1)
		if s == 8 and c == 1:
			track("chapter1", 1)
		var nc := c
		var ns := s + 1
		if ns > 8:
			nc += 1
			ns = 1
		if nc <= DB.chapters().size():
			data["progress"]["last"] = DB.stage_key(nc, ns)
	data["stats"]["runs"] = int(data["stats"]["runs"]) + 1
	data["stats"]["kills"] = int(data["stats"]["kills"]) + int(run_stats.get("kills", 0))
	track("runs", 1)
	track("spins", int(run_stats.get("spins", 0)))
	track("jackpots", int(run_stats.get("jackpots", 0)))
	track("absorbs", int(run_stats.get("absorbs", 0)))
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


## Extra entry for diamonds (하루 extra_max회). Returns "" or an error text.
func buy_arena_entry() -> String:
	var st := sync_arena_entries()
	if int(st["bought"]) >= int(st["buy_max"]):
		return DB.t("arena.buy_limit")
	if not pay("diamond", int(st["buy_cost"])):
		return DB.t("common.no_diamond")
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


## 군공 price; hero cards depend on the hero's rarity. -1 when not for sale.
func arena_price(item_id: String, hero_id: String = "") -> int:
	var it := arena_item(item_id)
	if it.is_empty():
		return -1
	if String(it["kind"]) == "hero_card":
		return int((it["cost"] as Dictionary).get(DB.rarity_of(hero_id), -1))
	return int(it["cost"])


## Buys one item with 군공 (never diamonds). Hero cards need an owned hero
## below max star. Returns {ok, error, gained}.
func buy_arena_item(item_id: String, hero_id: String = "") -> Dictionary:
	var it := arena_item(item_id)
	if it.is_empty():
		return {"ok": false, "error": "?"}
	if arena_bought(item_id) >= int(it["limit"]):
		return {"ok": false, "error": DB.t("arena_shop.sold_out")}
	var kind := String(it["kind"])
	if kind == "hero_card":
		if not owns(hero_id):
			return {"ok": false, "error": DB.t("arena_shop.not_owned")}
		if star_of(hero_id) >= int(DB.meta["star"]["max"]):
			return {"ok": false, "error": DB.t("arena_shop.max_star")}
	var price := arena_price(item_id, hero_id)
	if price < 0 or not pay("honor", price):
		return {"ok": false, "error": DB.t("arena_shop.no_honor")}
	var bought: Dictionary = data["arena_shop"]["bought"]
	bought[item_id] = int(bought.get(item_id, 0)) + 1
	var gained: Array = []
	match kind:
		"hero_card":
			hero(hero_id)["cards"] = int(hero(hero_id)["cards"]) + 1
			gained.append({"type": "hero", "id": hero_id, "new": false})
		"treasure":
			var pool := DB.treasures_of_rarity(String(it["rarity"]))
			gained.append(add_treasure(String(pool[rng.randi_range(0, pool.size() - 1)]["id"])))
		"tickets", "gold":
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

## Applies a (mock) store purchase. Returns the granted reward dictionary.
func purchase(product_id: String) -> Dictionary:
	var sh := DB.shop
	var reward := {}
	if product_id == "monthly":
		var mo: Dictionary = sh["monthly"]
		reward = {"diamond": int(mo["now"])}
		data["shop"]["monthly_until"] = maxi(int(data["shop"]["monthly_until"]), int(clock.call())) + int(mo["days"]) * 86400
	else:
		for p: Dictionary in sh["diamonds"]:
			if String(p["id"]) == product_id:
				var amt := int(p["amount"])
				if bool(sh["first_double"]) and not data["shop"]["first"].has(product_id):
					amt *= 2
				data["shop"]["first"][product_id] = true
				reward = {"diamond": amt}
		for p: Dictionary in sh["packages"]:
			if String(p["id"]) == product_id:
				var bought := int(data["shop"]["packages"].get(product_id, 0))
				if bought >= int(p["limit"]):
					return {}
				data["shop"]["packages"][product_id] = bought + 1
				for k in ["tickets", "gold", "diamond", "boxes"]:
					if p.has(k):
						reward[k] = int(p[k])
	var gained := grant(reward)
	reward["_gained"] = gained
	changed.emit()
	return reward


## Gold buys left today (메타 §3.9: 하루 gold_daily_limit회).
func gold_buys_left() -> int:
	var gb: Dictionary = data["gold_buy"]
	var day := _date_key(int(clock.call()))
	if String(gb.get("day", "")) != day:
		gb["day"] = day
		gb["count"] = 0
	return maxi(0, int(DB.shop["gold_daily_limit"]) - int(gb["count"]))


func buy_gold(index: int) -> String:
	var g: Dictionary = DB.shop["gold"][index]
	if gold_buys_left() <= 0:
		return DB.t("shop.gold_limit")
	if not pay("diamond", int(g["cost"])):
		return DB.t("common.no_diamond")
	data["gold_buy"]["count"] = int(data["gold_buy"]["count"]) + 1
	data["gold"] = int(data["gold"]) + int(g["gold"])
	changed.emit()
	return ""


## Monthly card daily diamonds; returns amount granted today (0 if none).
func claim_monthly() -> int:
	var now := int(clock.call())
	if int(data["shop"]["monthly_until"]) < now:
		return 0
	var day := _date_key(now)
	if String(data["shop"]["monthly_last"]) == day:
		return 0
	data["shop"]["monthly_last"] = day
	var amt := int(DB.shop["monthly"]["daily"])
	data["diamond"] = int(data["diamond"]) + amt
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


# ---------------------------------------------------------------- barracks (콘텐츠 §3.2)

## Soldier class stat upgrade for gold. Returns "" or the reason.
func upgrade_barracks(cls: String, stat: String) -> String:
	var b: Dictionary = data["barracks"][cls]
	var lv := int(b[stat])
	if lv >= MetaRules.barracks_cap(int(data["lord_lv"])):
		return DB.t("barracks.cap")
	if not pay("gold", MetaRules.barracks_cost(lv)):
		return DB.t("common.no_gold")
	b[stat] = lv + 1
	changed.emit()
	return ""
