extends TestCase
## Meta formulas (메타-성장-과금 §4).


func test_no_unit_levels_only_star_and_lord() -> void:
	# 개편 §9.1: 기초 능력치 = 기본값 x 1.15^(성급-1) x (1 + 0.05 x (군주 Lv - 1)).
	near(MetaRules.star_mult(6), 2.01, 0.01, "x2.01 at 6성")
	near(MetaRules.lord_mult({"lord_lv": 1}), 1.0, 0.001, "Lv.1 = x1")
	near(MetaRules.lord_mult({"lord_lv": 11}), 1.5, 0.001, "Lv.11 = +50%")
	near(MetaRules.grown(50.0, 3, {"lord_lv": 11}), 50.0 * 1.15 * 1.15 * 1.5, 0.01, "star x lord")
	var p := {"lord_lv": 1, "troops": {"spear": {"star": 1, "xp": 0, "traits": []}}}
	var a: float = MetaRules.soldier_stats(p, "spear")["atk"]
	p["lord_lv"] = 21
	near(MetaRules.soldier_stats(p, "spear")["atk"], a * 2.0, 0.01, "군주 레벨이 병사 능력치를 올린다")
	p["troops"]["spear"]["star"] = 2
	near(MetaRules.soldier_stats(p, "spear")["atk"], a * 2.0 * 1.15, 0.01, "성급이 병사 능력치를 올린다")


func test_star_xp_tables() -> void:
	var total := 0
	for s in range(1, 6):
		total += MetaRules.star_need("guanyu", s)
	eq(total, 190, "장수 1->6성 = 경험 190 (복사본 19명)")
	eq(MetaRules.star_need("guanyu", 6), -1, "max 6")
	eq(MetaRules.star_need("spear", 1), 5, "병종 1->2성 = 5")
	eq(MetaRules.star_xp("guanyu", "guanyu"), 10, "같은 장수 복사본 = 10")
	eq(MetaRules.star_xp("rider", "guanyu"), 1, "같은 병종 병사 = 1")
	eq(MetaRules.star_xp("spear", "spear"), 1, "병사끼리 = 1")
	eq(MetaRules.trait_slots(1), 1, "1성 1칸")
	eq(MetaRules.trait_slots(3), 3, "3성 3칸 (칸 = 성급)")
	eq(MetaRules.trait_slots(6), 6, "6성 6칸")


func test_clear_exp() -> void:
	eq(MetaRules.clear_exp(1, 1, false), 100, "stage 1 보통")
	eq(MetaRules.clear_exp(3, 2, false), 450, "stage 3 어려움 = 100 x 3 x 1.5")
	eq(MetaRules.clear_exp(1, 1, true), 200, "첫 클리어 2배")


func test_counters() -> void:
	# 개편 §9.5: 창병 -> 기병 -> 보병 -> 궁병 -> 창병.
	near(DB.counter("pike", "cav"), 1.3, 0.001, "창병은 기병에 강하다")
	near(DB.counter("cav", "inf"), 1.3, 0.001, "기병은 보병에 강하다")
	near(DB.counter("inf", "arc"), 1.3, 0.001, "보병은 궁병에 강하다")
	near(DB.counter("arc", "pike"), 1.3, 0.001, "궁병은 창병에 강하다")
	near(DB.counter("pike", "arc"), 0.8, 0.001, "창병은 궁병에 약하다")
	near(DB.counter("fire", "inf"), 1.3, 0.001, "화공은 보병에 강하다")
	near(DB.counter("fire", "cav"), 0.8, 0.001, "화공은 기병에 약하다")
	near(DB.counter("thunder", "cav"), 1.3, 0.001, "뇌공은 기병에 강하다")
	near(DB.counter("medic", "inf"), 1.0, 0.001, "의원은 상성이 없다")
	eq(DB.ctr_of("guanyu"), "cav", "관우 = 기병 줄")
	eq(DB.ctr_of("zhugeliang"), "fire", "제갈량 = 화공 줄")
	eq(DB.counter_lists("pike")["strong"], ["cav"], "list for the screen")


func test_unit_fx_merges_feature_and_traits() -> void:
	var p := {"lord_lv": 1, "heroes": {}, "troops": {"shield": {"star": 1, "xp": 0, "traits": [{"id": "iron", "lv": 2}]},
		"spear": {"star": 1, "xp": 0, "traits": [{"id": "sweep", "lv": 3}, {"id": "longbow", "lv": 1}]}}}
	var fx := MetaRules.unit_fx(p, "shield")
	check(bool(fx.get("taunt", false)), "방패병은 타고난 도발")
	near(float(fx["ranged_resist"]), 0.6, 0.001, "타고난 원거리 저항")
	near(float(fx["dmg_taken"]), 0.87, 0.001, "철벽 Lv.2")
	var fs := MetaRules.unit_fx(p, "spear")
	near(float(fs["splash"]), 0.4, 0.001, "휩쓸기 Lv.3")
	near(float(fs["range"]), 30.0, 0.001, "장궁 Lv.1")


func test_start_stars_by_rarity() -> void:
	eq(MetaRules.start_star("zhangfei"), 1, "장수 1성")
	eq(MetaRules.start_star("guanyu"), 2, "명장 2성")
	eq(MetaRules.start_star("zhugeliang"), 3, "기린아 3성")


func test_power_formula() -> void:
	eq(MetaRules.power_of({"atk": 120, "def": 80, "hp": 1640}), 3480, "spec example 3,480")


func test_lord_exp() -> void:
	eq(MetaRules.lord_exp_need(2), 492, "Lv.2 = 492")
	near(float(MetaRules.lord_exp_need(10)), 3990.0, 3.0, "Lv.10 ~ 3,990")


func test_treasure_sub_unlock() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var leg := DB.treasures_of_rarity("legend")[0] as Dictionary
	var item := MetaRules.make_treasure(String(leg["id"]), 1, rng)
	eq((item["subs"] as Array).size(), 4, "legend rolls 4 subs")
	eq(MetaRules.treasure_open_subs(item), 1, "1 open at +0")
	item["lv"] = 5
	eq(MetaRules.treasure_open_subs(item), 2, "+5 opens one")
	item["lv"] = 15
	eq(MetaRules.treasure_open_subs(item), 4, "+15 all")
	var com := DB.treasures_of_rarity("common")[0] as Dictionary
	var c := MetaRules.make_treasure(String(com["id"]), 2, rng)
	c["lv"] = 15
	eq(MetaRules.treasure_open_subs(c), 1, "common max 1")


func test_hero_stats_include_treasure() -> void:
	var p := Profile.defaults()
	p["heroes"]["guanyu"] = Profile.new_hero("guanyu")
	var before := MetaRules.hero_stats(p, "guanyu")
	var rng := RandomNumberGenerator.new()
	var weapon := DB.treasures_of_rarity("rare")[0] as Dictionary
	var item := MetaRules.make_treasure(String(weapon["id"]), 50, rng)
	p["treasures"].append(item)
	p["heroes"]["guanyu"]["eq"][String(weapon["slot"])] = 50
	var after := MetaRules.hero_stats(p, "guanyu")
	var stat := MetaRules.treasure_main_stat(item)
	near(float(after[stat]) - float(before[stat]), MetaRules.treasure_main(item), 0.01, "main stat added")


func test_run_gold() -> void:
	eq(MetaRules.run_gold(10, true), 1500, "100 x 10 + 500")
	eq(MetaRules.run_gold(4, false), 400, "defeat at wave 4")


func test_stage_scaling() -> void:
	var a: Dictionary = DB.stages["army"]
	near(DB.stage_mult(1, 2), float(a["base"]), 0.001, "새 계정 스테이지 1 보통 = army.base")
	near(DB.stage_mult(3, 2), float(a["base"]) * pow(float(a["stage_step"]), 2), 0.001, "x stage_step per stage")
	check(DB.stage_mult(1, 1) < DB.stage_mult(1, 2) and DB.stage_mult(1, 2) < DB.stage_mult(1, 3), "쉬움 < 보통 < 어려움")
	near(DB.stage_mult(1, 2, 2.0), 2.0, 0.001, "내 병력 몫이 그대로 곱해진다")
	eq(DB.stage_count(), 10, "10 stages")
	eq(DB.difficulties().size(), 3, "3 difficulties")
	eq(DB.stage_boss(1), "zhangjiao", "stage 1 boss 장각")
	for s in range(1, DB.stage_count() + 1):
		check(DB.is_boss(DB.stage_boss(s)), "stage %d has a boss" % s)
	var waves := DB.stage_waves(1, 1)
	eq(waves.size(), 10, "10 waves")
	eq(String(waves[9]["boss"]), "zhangjiao", "boss on the last wave")
	check(int(DB.stage_waves(1, 3)[1]["list"][0][1]) > int(DB.stage_waves(1, 1)[1]["list"][0][1]), "어려움 has more enemies than 쉬움")
	# 적 수: 보통 첫 웨이브는 틀 그대로, 웨이브가 갈수록 · 내 병력이 많을수록 늘어난다
	eq(DB.count_mult(2, 0), 1.0, "보통 wave 1 = the template count")
	check(DB.count_mult(2, 9) > DB.count_mult(2, 0), "later wave: more enemies")
	check(int(DB.stage_waves(1, 2, 2.5)[0]["list"][0][1]) > int(DB.stage_waves(1, 2)[0]["list"][0][1]), "bigger army: more enemies")
	check(float(DB.stage_waves(1, 2, 2.5)[0]["gap_mult"]) < 1.0, "many enemies come closer together")


func test_army_scale() -> void:
	var p := Profile.new()
	var a: Dictionary = DB.stages["army"]
	var s0 := MetaRules.army_scale(p.data, [])
	near(float(s0["level"]), 1.0, 0.001, "새 계정: 레벨 1")
	near(float(s0["count"]), 1.0, 0.001, "새 계정: 적 수 그대로")
	near(float(s0["mult"]), float(a["base"]), 0.001, "새 계정: 적 세기 = base")
	var army: Array = []
	for i in 16:
		army.append({"id": "spear"})
	var s1 := MetaRules.army_scale(p.data, army)
	eq(int(s1["n"]), 16, "인원수")
	check(float(s1["count"]) > float(s0["count"]), "부대가 크면 적이 많다")
	check(float(s1["count"]) <= float(a["count_max"]), "적 수 배율은 count_max 까지")
	check(float(s1["mult"]) > float(s0["mult"]), "적 수로 못 옮긴 몫은 적 세기로")
	p.add_star_xp("spear", 99)
	check(float(MetaRules.army_scale(p.data, army)["level"]) > float(s1["level"]), "유닛이 강해지면 레벨이 오른다")
	var run := RunState.new(RandomNumberGenerator.new(), [], [], 1, 2, p)
	near(run.enemy_mult(), DB.stage_mult(1, 2, float(run.scale["mult"])), 0.001, "전투는 시작할 때의 병력 몫을 쓴다")
	check(run.to_save().has("scale"), "퇴각 저장에 적 배율이 들어 있다")
