extends TestCase
## 슬롯 확률 (개편 §13): 모집은 없다. 캐릭터는 전투 중 슬롯에서만 나온다.
## 당첨 칸이 장수면 등급 확률, 병사면 기본 / 정예 확률, 그 안에서는 같은 확률.


func test_no_recruit_data_left() -> void:
	check(not DB.meta.has("recruit"), "장수 모집 없음")
	check(not DB.meta.has("gold_recruit"), "골드 장수 모집 없음")
	check(not DB.meta.has("soldier_recruit"), "병사 모집 없음")
	check(DB.meta.has("slot_pool"), "slot pool odds")


func test_hero_grade_odds() -> void:
	var o := Gacha.hero_odds()
	near(float(o["b"]) + float(o["a"]) + float(o["s"]) + float(o["ss"]), 100.0, 0.001, "sums to 100")
	near(Gacha.hero_chance("zhugeliang"), 3.0 / 4.0, 0.001, "SS 4명이 3%를 나눈다")
	near(Gacha.hero_chance("guanyu"), 12.0 / 8.0, 0.001, "S 8명이 12%를 나눈다")
	var total := 0.0
	for id: String in DB.hero_ids():
		total += Gacha.hero_chance(id)
	near(total, 100.0, 0.001, "every hero adds up to 100")


func test_soldier_tier_odds() -> void:
	eq(DB.soldier_ids_of_tier("basic").size(), 5, "5 basic troops")
	eq(DB.soldier_ids_of_tier("elite").size(), 11, "11 elite troops")
	near(Gacha.soldier_chance("spear"), 70.0 / 5.0, 0.001, "basic each 14%")
	near(Gacha.soldier_chance("halberd"), 30.0 / 11.0, 0.001, "elite each 2.7%")


func test_slot_hero_follows_grade_odds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var count := {"b": 0, "a": 0, "s": 0, "ss": 0}
	var n := 6000
	for _i in n:
		count[DB.rarity_of(Gacha.slot_hero(rng, DB.hero_ids()))] += 1
	near(float(count["b"]) / n, 0.55, 0.03, "B 55%")
	near(float(count["a"]) / n, 0.30, 0.03, "A 30%")
	near(float(count["s"]) / n, 0.12, 0.02, "S 12%")
	near(float(count["ss"]) / n, 0.03, 0.012, "SS 3%")


func test_slot_soldier_follows_tier_odds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var basic := 0
	var n := 4000
	for _i in n:
		var id := Gacha.slot_soldier(rng, DB.soldier_ids())
		check(DB.is_soldier(id), "a soldier")
		if String(DB.soldier(id)["tier"]) == "basic":
			basic += 1
	near(float(basic) / n, 0.70, 0.03, "기본 70%")


func test_short_lists_still_work() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for _i in 50:
		eq(Gacha.slot_hero(rng, ["guanyu"]), "guanyu", "only one hero to pick")
		eq(Gacha.slot_soldier(rng, ["spear"]), "spear", "only one troop to pick")
