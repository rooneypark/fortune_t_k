extends TestCase
## Meta formulas (메타-성장-과금 §4).


func test_upgrade_cost_curve() -> void:
	eq(MetaRules.upgrade_cost(0), 50, "level 1 costs 50")
	eq(MetaRules.upgrade_cost(9), 1581, "level 10 costs 1,581")
	eq(MetaRules.upgrade_cost(29), 8216, "level 30 costs 8,216")
	eq(MetaRules.upgrade_cost(59), 23238, "level 60 costs 23,238")


func test_upgrade_example() -> void:
	# 공격 기본 50, 3성, 강화 20 -> 50 x 1.15^2 x 1.8 = 119
	near(MetaRules.upgraded(50.0, 3, 20), 119.0, 0.1, "spec example")


func test_star_costs() -> void:
	var total := 0
	for s in range(1, 6):
		total += MetaRules.star_cost(s)
	eq(total, 19, "1->6 = 19 cards")
	eq(MetaRules.star_cost(6), -1, "max 6")
	near(MetaRules.star_mult(6), 2.01, 0.01, "x2.01 at 6")


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
	near(DB.stage_mult(1, 8), 1.83, 0.01, "s=8 1.83")
	near(DB.stage_mult(3, 8), 7.26, 0.05, "s=24 ~7.25")
	eq(DB.stage_boss(1, 8), "zhangjiao", "1-8 boss 장각")
	eq(DB.stage_boss(1, 5) != "", true, "1-5 has a general")
	eq(DB.stage_waves(1, 1).size(), 10, "10 waves")


func test_auto_lineup_and_required_troops() -> void:
	var p := Profile.new()
	for id in ["guanyu", "zhangfei", "zhaoyun", "huangzhong"]:
		p.add_hero_card(id)
	var a := MetaRules.auto_lineup(p.data)
	eq((a["heroes"] as Array).size(), 3, "3 heroes")
	eq((a["troops"] as Array).size(), 4, "4 troops")
	for h: String in a["heroes"]:
		check((a["troops"] as Array).has(DB.troop_of(h)), "hero troop included: " + h)
	eq(MetaRules.required_troops(["guanyu", "xiahoudun"]), ["spear"], "same troop once")


func test_line_chance_falls_with_more_troops() -> void:
	var four := MetaRules.line_chance(["spear", "shield", "archer", "rider"], [])
	var ten := MetaRules.line_chance(DB.soldier_ids(), [])
	near(four, 0.27, 0.02, "4 troops ~27%")
	check(ten < 0.06, "10 troops ~5%")
