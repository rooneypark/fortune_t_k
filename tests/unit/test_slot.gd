extends TestCase
## 천명 슬롯 rules (스테이지-흡수-합성-개편 §9.9): three independent reels,
## each a unit (1/3) or a blank; every winning reel recruits; three wins = 잭팟.


func _slot(seed: int = 7, heroes: Array = ["guanyu", "zhaoyun"]) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var s := SlotMachine.new()
	s.setup(heroes, ["spear", "shield", "archer", "rider"], 12, rng)
	return [s, rng]


func test_evaluate_counts_winning_reels() -> void:
	var r := SlotMachine.evaluate(["spear", "", "guanyu"], [0, 1, 2])
	eq(r["wins"], [0, 2], "two winning reels")
	eq((r["recruits"] as Array).size(), 2, "each winning reel recruits")
	eq(r["recruits"][0]["id"], "spear", "first reel")
	eq(r["recruits"][1]["id"], "guanyu", "third reel")
	check(not bool(r["jackpot"]), "two wins are not a jackpot")
	eq((SlotMachine.evaluate(["", "", ""], [0, 1, 2])["recruits"] as Array).size(), 0, "all blank = nothing")


func test_three_wins_are_a_jackpot() -> void:
	var r := SlotMachine.evaluate(["spear", "archer", "rider"], [0, 1, 2])
	check(bool(r["jackpot"]), "three different units still a jackpot")
	eq((r["recruits"] as Array).size(), 3, "three units")


func test_odds_add_up() -> void:
	near(SlotMachine.win_chance(), 1.0 / 3.0, 0.001, "33% per reel")
	near(SlotMachine.chance_of(0), 0.296, 0.002, "all blank 29.6%")
	near(SlotMachine.chance_of(1), 0.444, 0.002, "one win 44.4%")
	near(SlotMachine.chance_of(2), 0.222, 0.002, "two wins 22.2%")
	near(SlotMachine.chance_of(3), 0.037, 0.002, "jackpot 3.7%")


func test_shift_a_blank_reel_up_or_down() -> void:
	# 재배치: 꽝 줄의 위 칸이나 아래 칸을 가운데로 끌어온다 (위아래 둘 다).
	var p := _slot()
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	s.forced = {"cells": ["spear", "", ""], "above": ["rider", "", "archer"], "below": ["", "shield", ""]}
	var r := s.spin(rng)
	eq(s.cells(), ["spear", "", ""], "scripted cells")
	eq((r["recruits"] as Array).size(), 1, "one unit")
	eq(s.peek(2, -1), "archer", "the cell above the third reel is visible")
	eq(s.peek(1, 1), "shield", "the cell below the second reel is visible")
	check(s.can_nudge, "a blank reel may be shifted")
	eq(s.nudge_wins(), [[1, -1], [2, 1]], "shifts that bring a unit in")
	check(s.nudge(0, 1).is_empty(), "a winning reel cannot be shifted")
	check(s.can_nudge, "a refused shift keeps the chance")
	var n := s.nudge(2, 1)
	eq(s.cells(), ["spear", "", "archer"], "down: the cell above came into the row")
	eq((n["recruits"] as Array).size(), 1, "only the shifted reel recruits")
	eq(n["recruits"][0]["id"], "archer", "archer")
	check(not s.can_nudge, "once per spin")
	check(s.nudge(1, -1).is_empty(), "second shift refused")
	# up: the cell below comes into the row
	s.forced = {"cells": ["", "", ""], "above": ["", "", ""], "below": ["", "shield", ""]}
	s.spin(rng)
	eq(s.nudge(1, -1)["recruits"][0]["id"], "shield", "up: the cell below came into the row")


func test_shift_onto_a_blank_gives_nothing() -> void:
	var p := _slot()
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	s.forced = {"cells": ["", "", ""], "above": ["", "", ""], "below": ["", "", ""]}
	s.spin(rng)
	eq(s.nudge_wins(), [], "nothing to bring in")
	var n := s.nudge(0, 1)
	eq((n["recruits"] as Array).size(), 0, "a blank came in")
	check(not s.can_nudge, "the chance is used")


func test_advisor_respin_rerolls_a_blank() -> void:
	var p := _slot()
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	s.forced = {"cells": ["spear", "", ""]}
	s.spin(rng)
	check(s.respin_reel(0, rng).is_empty(), "a winning reel is not re-spun")
	check(not s.respin_reel(1, rng).is_empty(), "a blank reel is")
	check(not s.can_nudge, "ends the shift chance")


func test_shift_can_complete_a_jackpot() -> void:
	var p := _slot()
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	s.forced = {"cells": ["spear", "rider", ""], "above": ["", "", "shield"]}
	s.spin(rng)
	check(bool(s.nudge(2, 1)["jackpot"]), "third win by a shift = jackpot")


func test_no_respin_after_three_wins() -> void:
	var p := _slot()
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	s.forced = {"cells": ["spear", "rider", "archer"]}
	s.spin(rng)
	check(not s.can_nudge, "nothing to spin again")
	eq(s.first_blank(), -1, "no blank")


func test_spin_deterministic_with_seed() -> void:
	var a := _slot(99)
	var b := _slot(99)
	(a[0] as SlotMachine).spin(a[1])
	(b[0] as SlotMachine).spin(b[1])
	eq((a[0] as SlotMachine).cells(), (b[0] as SlotMachine).cells(), "same seed same cells")


func test_reels_show_owned_units_only() -> void:
	var p := _slot(3)
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	var allowed := ["", "guanyu", "zhaoyun", "spear", "shield", "archer", "rider"]
	var ok := true
	for _i in 40:
		s.spin(rng)
		for strip: Array in s.strips:
			for id in strip:
				if not allowed.has(id):
					ok = false
	check(ok, "only owned heroes, owned troops and blanks")


func test_win_rate_and_hero_share() -> void:
	var p := _slot(11)
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	var wins := 0
	var heroes := 0
	var n := 3000
	for _i in n:
		for id: String in s.spin(rng)["cells"]:
			if id != "":
				wins += 1
				if DB.is_hero(id):
					heroes += 1
	near(float(wins) / float(n * 3), 1.0 / 3.0, 0.02, "about a third of the reels win")
	near(float(heroes) / float(wins), SlotMachine.hero_chance(), 0.02, "about 10% of the wins are heroes")


func test_no_heroes_means_soldiers_only() -> void:
	var p := _slot(5, [])
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	var ok := true
	for _i in 200:
		for id: String in s.spin(rng)["cells"]:
			if id != "" and not DB.is_soldier(id):
				ok = false
	check(ok, "no hero can appear when none is owned")


func test_lucky_and_hero_boost() -> void:
	var p := _slot(21)
	var s: SlotMachine = p[0]
	var rng: RandomNumberGenerator = p[1]
	var wins := 0
	var heroes := 0
	var n := 2000
	for _i in n:
		for id: String in s.spin(rng, true, true)["cells"]:
			if id != "":
				wins += 1
				if DB.is_hero(id):
					heroes += 1
	near(float(wins) / float(n * 3), float(DB.rules["slot_lucky_chance"]), 0.03, "lucky: 50% per reel")
	near(float(heroes) / float(wins), float(DB.rules["slot_boost_hero_chance"]), 0.03, "boost: half of the wins are heroes")
