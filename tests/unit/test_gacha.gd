extends TestCase
## 장수 모집 odds, pity and 10-pull guarantee (메타 §3.3, §4.1, §8).


func test_rates_over_100k_pulls() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var counts := {"b": 0, "a": 0, "s": 0, "ss": 0}
	var n := 100000
	for i in n:
		counts[Gacha.roll_rarity(rng, Gacha.odds())] += 1
	near(100.0 * counts["b"] / n, 55.0, 0.5, "B 55%")
	near(100.0 * counts["a"] / n, 30.0, 0.5, "A 30%")
	near(100.0 * counts["s"] / n, 12.0, 0.5, "S 12%")
	near(100.0 * counts["ss"] / n, 3.0, 0.3, "SS 3%")


func test_pity_61st_is_ss() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var c := Gacha.pull(rng, 60)
	eq(c["rarity"], "ss", "after 60 misses")
	eq(int(c["pity"]), 0, "counter resets")


func test_ten_pull_guarantee() -> void:
	var ok := true
	for seed in 300:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		var res := Gacha.pull_many(rng, 0, 10)
		var good := false
		for card: Dictionary in res["cards"]:
			if Gacha.grade_rank(String(card["rarity"])) >= Gacha.grade_rank("s"):
				good = true
		if not good:
			ok = false
	check(ok, "every 10-pull has S+")


func test_hero_chance_table() -> void:
	near(Gacha.hero_chance("ss"), 3.0 / 4.0, 0.001, "SS each 0.75%")
	near(Gacha.hero_chance("b"), 55.0 / 10.0, 0.01, "B each 5.5%")


func test_gold_recruit_weaker_and_limited() -> void:
	var g: Dictionary = DB.meta["gold_recruit"]["odds"]
	check(float(g["ss"]) < float(DB.meta["recruit"]["odds"]["ss"]), "gold SS below diamond SS")
	var p := Profile.new()
	p.clock = func() -> int: return 1795000000
	p.data["gold"] = 1000000
	for i in int(DB.meta["gold_recruit"]["daily_max"]):
		eq(String(p.recruit_gold(1)["error"]), "", "gold pull %d" % i)
	check(String(p.recruit_gold(1)["error"]) != "", "daily limit")
	eq(int(p.data["gold"]), 1000000 - int(DB.meta["gold_recruit"]["cost_one"]) * int(DB.meta["gold_recruit"]["daily_max"]), "paid gold")


func test_soldier_pull_odds() -> void:
	near(Gacha.soldier_chance("spear"), 70.0 / 4.0, 0.001, "basic each 17.5%")
	near(Gacha.soldier_chance("halberd"), 30.0 / 6.0, 0.001, "elite each 5%")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for i in 50:
		check(DB.is_soldier(Gacha.pull_soldier(rng)), "pull gives a soldier")


func test_box_pity() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var r := Gacha.roll_box(rng, 29)
	check(r["rarity"] == "epic" or r["rarity"] == "legend", "30th box epic+")
