extends TestCase
## 천명 슬롯 rules (GDD v5 §3.2).


func test_paylines_are_three_rows_and_two_diagonals() -> void:
	eq(SlotMachine.LINES.size(), 5, "5 lines")
	eq(SlotMachine.LINES[3], [[0, 0], [1, 1], [2, 2]], "diag down")
	eq(SlotMachine.LINES[4], [[0, 2], [1, 1], [2, 0]], "diag up")


func test_line_kinds() -> void:
	# 2026-11-22: 같은 병종 한 줄. 장수는 자기 병종으로 센다 (관우 = 창병).
	eq(SlotMachine.line_kind("spear", "spear", "spear"), "unit", "same unit")
	eq(SlotMachine.line_kind("spear", "spear", "guanyu"), "troop", "spear spear guanyu")
	eq(SlotMachine.line_kind("guanyu", "xiahoudun", "spear"), "troop", "two spear heroes + spear")
	eq(SlotMachine.line_kind("spear", "shield", "spear"), "", "same 보병 class is not enough")
	eq(SlotMachine.line_kind("shield", "shield", "guanyu"), "", "guanyu is not a shield")
	eq(SlotMachine.line_kind("guanyu", "zhaoyun", "huangzhong"), "", "no faction lines")


func test_soldier_line_recruits_one_soldier() -> void:
	var g := grid_rows([["rider", "archer", "shield"], ["spear", "spear", "spear"], ["archer", "rider", "archer"]])
	var r := SlotMachine.evaluate(g)
	eq((r["lines"] as Array).size(), 1, "one line")
	eq((r["recruits"] as Array).size(), 1, "one body")
	eq(r["recruits"][0]["id"], "spear", "spear")


func test_hero_on_troop_line_recruits_only_the_hero() -> void:
	var g := grid_rows([["archer", "rider", "rider"], ["spear", "spear", "guanyu"], ["rider", "archer", "archer"]])
	var r := SlotMachine.evaluate(g)
	eq((r["recruits"] as Array).size(), 1, "one recruit")
	eq(r["recruits"][0]["id"], "guanyu", "hero only, no spears")
	eq(r["lines"][0]["heroes"], ["guanyu"], "line lists the hero")
	eq(r["factions"], [], "no faction buff")


func test_each_line_counts() -> void:
	# Row 1 spear x3 and the diagonal spear-spear-spear: two lines, two spears.
	var g := grid_rows([["spear", "archer", "rider"], ["spear", "spear", "spear"], ["rider", "archer", "spear"]])
	var r := SlotMachine.evaluate(g)
	eq((r["lines"] as Array).size(), 2, "two lines")
	eq((r["recruits"] as Array).size(), 2, "one soldier per line")


func test_miss_gives_nothing_and_allows_nudge() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := SlotMachine.new()
	s.setup(["guanyu"], ["spear", "shield", "archer", "rider"], 18, 3, 2, rng)
	s.forced = {"cols": [["archer", "shield", "rider"], ["archer", "rider", "spear"], ["shield", "spear", "rider"]], "above": ["", "", "archer"]}
	var r := s.spin(rng)
	eq((r["lines"] as Array).size(), 0, "miss")
	eq((r["recruits"] as Array).size(), 0, "nothing")
	check(s.can_nudge, "nudge allowed")
	var n := s.nudge(2, 1)
	eq((n["lines"] as Array).size(), 1, "nudge down completes archer row")
	eq(n["recruits"][0]["id"], "archer", "archer recruited")
	check(not s.can_nudge, "only once")
	check(s.nudge(1, 1).is_empty(), "second nudge refused")


func test_spin_deterministic_with_seed() -> void:
	var a := SlotMachine.new()
	var b := SlotMachine.new()
	var r1 := RandomNumberGenerator.new()
	var r2 := RandomNumberGenerator.new()
	r1.seed = 99
	r2.seed = 99
	a.setup(["guanyu", "zhangfei"], ["spear", "archer"], 18, 3, 2, r1)
	b.setup(["guanyu", "zhangfei"], ["spear", "archer"], 18, 3, 2, r2)
	a.spin(r1)
	b.spin(r2)
	eq(a.grid(), b.grid(), "same seed same grid")


func test_reels_contain_lineup_and_soldiers_only() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := SlotMachine.new()
	var allowed := ["guanyu", "zhaoyun", "spear", "shield", "archer", "rider"]
	s.setup(["guanyu", "zhaoyun"], ["spear", "shield", "archer", "rider"], 40, 3, 2, rng)
	var ok := true
	for strip: Array in s.strips:
		for id in strip:
			if not allowed.has(id):
				ok = false
	check(ok, "only lineup + basic soldiers")
