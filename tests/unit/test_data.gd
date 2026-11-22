extends TestCase
## Data and text integrity.


func test_roster_32_by_troop() -> void:
	# 2026-11-22: 32명, 등급 SS 4 · S 8 · A 10 · B 10, 장수 병종 = 장수 분류, 병종마다 3~4명.
	eq(DB.hero_ids().size(), 32, "32 heroes")
	var by := {"b": 0, "a": 0, "s": 0, "ss": 0}
	var ok := true
	for id: String in DB.hero_ids():
		by[DB.rarity_of(id)] += 1
		var t := DB.troop_of(id)
		if not DB.is_soldier(t) or DB.cls_of(id) != DB.cls_of(t):
			ok = false
	eq(by, {"b": 10, "a": 10, "s": 8, "ss": 4}, "grades")
	check(ok, "every hero has a valid troop of the same class")
	eq(DB.soldier_ids().size(), 10, "10 troops")
	for t: String in DB.soldier_ids():
		var n := DB.heroes_of_troop(t).size()
		check(n >= 3 and n <= 4, "3-4 heroes in " + t)
	eq(DB.troop_of("guanyu"), "spear", "관우 = 창병")


func test_every_hero_has_art() -> void:
	var art: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/units/art.json"))
	var ok := true
	for id: String in DB.hero_ids():
		if not (art as Dictionary).has(String(DB.hero(id)["art"])):
			ok = false
	check(ok, "art mapping for all heroes")


func test_traits_12() -> void:
	var n := 0
	for cls: String in DB.units["traits"]:
		n += (DB.units["traits"][cls] as Array).size()
	eq(n, 12, "12 traits")


func test_all_text_keys_exist() -> void:
	var missing: Array = []
	var re := RegEx.new()
	re.compile("DB\\.t\\(\"([a-z0-9_.]+)\"")
	for path in _scripts("res://src"):
		var src := FileAccess.get_file_as_string(path)
		for m in re.search_all(src):
			var key := m.get_string(1)
			if key.ends_with(".") or key.ends_with("_"):
				# dynamic key ("stat." + id): at least one string with that prefix
				var any := false
				for k: String in DB.strings:
					if k.begins_with(key):
						any = true
						break
				if any:
					continue
			if not DB.strings.has(key) and not missing.has(key):
				missing.append(key)
	eq(missing, [], "strings_ko.json has every key")


func test_no_slot_machine_symbols() -> void:
	# 화면 설계서 §8: 777 and slot-machine icons are not used.
	var bad := false
	for path in _scripts("res://src"):
		if FileAccess.get_file_as_string(path).find("777") >= 0:
			bad = true
	check(not bad, "no 777")


func _scripts(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_scripts(dir + "/" + sub))
	return out
