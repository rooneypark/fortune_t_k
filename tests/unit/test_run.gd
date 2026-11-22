extends TestCase
## Run rules (GDD v5 §3.2-3.6, §7, §8).


func _run(seed: int = 1) -> RunState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return RunState.new(rng, ["guanyu", "zhangfei", "zhaoyun", "huangzhong"], [], "zhugeliang", 1, 1)


func test_start_values() -> void:
	var r := _run()
	eq(r.rice, 300, "start rice 300")
	eq(r.castle_hp, 1000, "castle 1000")
	eq(r.field_cap, 6, "field cap 6")
	eq(r.hero_quota, 3, "hero quota 3 (최대 장수 3)")
	eq(r.bench_size, 8, "bench 8")
	eq(r.wave_count(), 10, "10 waves")


const MISS := {"cols": [["archer", "shield", "rider"], ["archer", "rider", "spear"], ["shield", "spear", "rider"]]}


func test_spin_cost_grows_and_resets() -> void:
	var r := _run()
	eq(r.spin_cost(), 100, "first 100")
	r.slot.forced = MISS.duplicate(true)
	r.spin()
	eq(r.spin_cost(), 120, "+20")
	eq(r.rice, 200, "paid 100")
	r.slot.forced = MISS.duplicate(true)
	r.spin()
	eq(r.rice, 80, "paid 120")
	eq(r.spin_block_reason() != "", true, "blocked when rice < cost")
	eq(r.spin().is_empty(), true, "blocked spin returns {}")
	r.finish_wave()
	eq(r.spin_cost(), 100, "reset each wave")


func test_nudge_is_quarter_of_last_spin() -> void:
	var r := _run()
	r.spin()
	eq(r.nudge_cost(), 25, "100 / 4")
	r.spin()
	eq(r.nudge_cost(), 30, "120 / 4")


func test_wave_income_and_castle_regen() -> void:
	var r := _run()
	eq(r.wave_income(0), 360, "280 + 0 + 80")
	eq(r.wave_income(3), 420, "280 + 60 + 80")
	r.damage_castle(400)
	var got := r.finish_wave()
	eq(int(got["castle"]), 100, "10% of max")
	eq(r.castle_hp, 700, "600 + 100")


func test_castle_fall() -> void:
	var r := _run()
	r.damage_castle(2000)
	check(r.castle_fallen(), "fallen at 0")
	eq(r.castle_hp, 0, "clamped")
	check(r.revive(), "continue once")
	eq(r.castle_hp, 500, "half")
	check(not r.revive(), "only once per run")


func test_respawn_times() -> void:
	var r := _run()
	var s := UnitState.create("spear")
	var h := UnitState.create("guanyu")
	near(r.respawn_time(s), 5.0, 0.001, "soldier 5s")
	near(r.respawn_time(h), 12.0, 0.001, "hero 12s")
	h.add_xp(5)
	near(r.respawn_time(h), 16.0, 0.001, "+2s per rank")


func test_recruit_fills_field_then_bench() -> void:
	var r := _run()
	for i in 6:
		r.recruit("spear")
	eq(r.field.size(), 6, "field cap 6")
	r.recruit("archer")
	eq(r.bench.size(), 1, "overflow to bench")


func test_hero_quota() -> void:
	var r := _run()
	r.recruit("guanyu")
	r.recruit("zhangfei")
	r.recruit("zhaoyun")
	r.recruit("huangzhong")
	eq(r.heroes_on_field(), 3, "only 3 heroes on field")
	eq(r.bench.size(), 1, "fourth hero benched")


func test_duplicate_hero_absorbs() -> void:
	var r := _run()
	r.recruit("guanyu")
	var ev := r.recruit("guanyu")
	eq(ev[0]["type"], "rank", "copy absorbed")
	eq(r.find_owned("guanyu").rank, 2, "rank 2 at xp 2")
	r.recruit("guanyu")
	r.recruit("guanyu")
	eq(r.find_owned("guanyu").rank, 3, "rank 3 at xp 5+")
	r.spins_this_wave = 1
	var before := r.rice
	ev = r.recruit("guanyu")
	eq(ev[0]["type"], "refund", "max rank refunds")
	eq(r.rice - before, 50, "half of spin price")


func test_bench_full_locks_lever() -> void:
	var r := _run()
	r.force_bench = true
	for i in 8:
		r.recruit("spear")
	eq(r.bench.size(), 8, "full")
	eq(r.spin_block_reason(), DB.t("battle.bench_full"), "lever locked")


func test_absorb_same_class_rank() -> void:
	var r := _run()
	r.recruit("spear")
	r.recruit("spear")
	r.recruit("shield")
	var a: UnitState = r.field[0]
	var b: UnitState = r.field[1]
	var c: UnitState = r.field[2]
	eq(r.absorb_check(b, a)["mode"], "rank", "same class -> rank")
	eq(int(r.absorb_check(b, a)["xp"]), 2, "same unit = 2")
	eq(int(r.absorb_check(c, a)["xp"]), 1, "same class = 1")
	eq(r.absorb_rank(b, a), 1, "rank up to 2")
	eq(r.field.size(), 2, "food gone")
	r.absorb_rank(c, a)
	eq(a.xp, 3, "xp 3")
	check(not r.absorb_check(a, a)["ok"], "self ignored")


func test_absorb_max_rank_blocked() -> void:
	var r := _run()
	var a := UnitState.create("spear", 5)
	var b := UnitState.create("spear")
	r.field.append(a)
	r.field.append(b)
	check(not r.absorb_check(b, a)["ok"], "3단 blocks same-class absorb")


func test_trait_absorb_slots_equal_rank() -> void:
	var r := _run()
	var target := UnitState.create("spear")
	var f1 := UnitState.create("archer")
	var f2 := UnitState.create("rider")
	r.field.append(target)
	r.bench.append(f1)
	r.bench.append(f2)
	eq(r.absorb_check(f1, target)["mode"], "trait", "different class -> trait")
	eq(r.trait_options(f1, target).size(), 3, "three choices")
	check(r.absorb_trait(f1, target, "rapid"), "took 속사")
	eq(target.traits, ["rapid"] as Array[String], "one slot at rank 1")
	check(not r.absorb_trait(f2, target, "gallop"), "slot full without replace")
	check(r.bench.has(f2), "food kept when cancelled")
	check(r.absorb_trait(f2, target, "gallop", 0), "replace slot 0")
	eq(target.traits, ["gallop"] as Array[String], "replaced")


func test_trait_rules() -> void:
	var r := _run()
	var target := UnitState.create("archer", 2)
	var f1 := UnitState.create("spear")
	var f2 := UnitState.create("shield")
	var f3 := UnitState.create("rider")
	r.field.append(target)
	for f in [f1, f2, f3]:
		r.bench.append(f)
	check(r.absorb_trait(f1, target, "iron"), "first")
	check(not r.absorb_trait(f2, target, "iron"), "no duplicate trait")
	check(not r.absorb_trait(f3, target, "rapid"), "not own class trait")


func test_field_cap_purchase() -> void:
	var r := _run()
	check(r.buy_field_cap(), "buy +1")
	eq(r.field_cap, 7, "7")
	eq(r.rice, 200, "cost 100")
	check(not r.buy_hero_quota(), "hero quota cannot be bought (max 3)")


func test_advisor_respin_once_per_wave() -> void:
	var r := _run(5)
	r.slot.forced = {"cols": [["archer", "shield", "rider"], ["archer", "rider", "spear"], ["shield", "spear", "rider"]]}
	r.spin()
	check(r.advisor_ready(), "ready after miss")
	check(not r.use_advisor(1).is_empty(), "used")
	check(not r.advisor_ready(), "once per wave")
	r.finish_wave()
	check(not r.advisor_used, "reset next wave")


func test_no_faction_lines() -> void:
	var r := _run()
	r.slot.forced = {"cols": [["guanyu", "spear", "shield"], ["zhaoyun", "archer", "rider"], ["huangzhong", "rider", "archer"]]}
	r.spin()
	check(r.faction_buff.is_empty(), "3 촉 heroes on a line give nothing now")
	eq(r.field.size(), 0, "nobody recruited")


func test_lineup_capped_at_three() -> void:
	eq(_run().lineup.size(), 3, "4 heroes passed, 3 kept")


func test_stars() -> void:
	var r := _run()
	eq(r.stars_earned(true), 3, "full castle 3 stars")
	r.damage_castle(200)
	eq(r.stars_earned(true), 2, "80% -> 2")
	r.damage_castle(400)
	eq(r.stars_earned(true), 1, "40% -> 1")
	eq(r.stars_earned(false), 0, "defeat 0")


func test_no_diamond_path_to_rice() -> void:
	# GDD §11-3: nothing in RunState accepts diamonds.
	var src := FileAccess.get_file_as_string("res://src/core/run_state.gd")
	check(src.find("diamond") < 0, "run_state never touches diamonds")


func test_payline_summons_grade1_character() -> void:
	# 1) Unit line: exactly 1 grade-1 unit total (NOT 2!)
	var r := _run()
	r.rice = 1000
	r.slot.forced = {"cols": [["rider", "spear", "archer"], ["archer", "spear", "rider"], ["shield", "spear", "archer"]]}
	var res := r.spin()
	eq(r.field.size(), 1, "unit payline summons exactly 1 unit total")
	eq(r.bench.size(), 0, "no extra unit on bench")
	eq((res["events"] as Array).size(), 1, "exactly 1 event")
	eq(r.field[0].rank, 1, "summoned unit is grade 1")

	# 2) Troop line with a hero (창병·창병·관우): only the hero joins
	var rc := _run()
	rc.slot.forced = {"cols": [["archer", "guanyu", "rider"], ["rider", "spear", "archer"], ["rider", "spear", "archer"]]}
	rc.spin()
	eq(rc.field.size(), 1, "hero line summons exactly 1 unit")
	eq(rc.field[0].id, "guanyu", "the hero, not a spear")
	eq(rc.field[0].rank, 1, "grade 1")

	# 3) Same hero again on a spear line: rank exp instead of a second body
	var r2 := _run()
	r2.recruit("guanyu")
	r2.slot.forced = {"cols": [["archer", "guanyu", "rider"], ["rider", "spear", "archer"], ["rider", "spear", "archer"]]}
	r2.spin()
	eq(r2.field.size(), 1, "still one guanyu")
	eq(r2.find_owned("guanyu").rank, 2, "copy absorbed -> rank 2")

	# 4) Multiple paylines in one spin: 1 grade-1 unit per completed line
	var rm := _run()
	rm.rice = 1000
	# Row 0 = spear x3 AND Row 2 = archer x3 (2 lines)
	rm.slot.forced = {"cols": [["spear", "rider", "archer"], ["spear", "shield", "archer"], ["spear", "rider", "archer"]]}
	var rm_res := rm.spin()
	eq((rm_res["result"]["lines"] as Array).size(), 2, "two lines completed")
	eq(rm.field.size(), 2, "two lines summon exactly 2 units (1 per line)")
	eq(rm.bench.size(), 0, "no extra bench units")
	eq(rm.field[0].rank, 1, "first multi-line unit grade 1")
	eq(rm.field[1].rank, 1, "second multi-line unit grade 1")

	# Crossing unit lines (row 1 spear + diag spear) = 2 lines -> 2 grade-1 units
	var rx := _run()
	rx.slot.forced = {"cols": [["spear", "spear", "rider"], ["archer", "spear", "archer"], ["rider", "spear", "spear"]]}
	var rx_res := rx.spin()
	eq((rx_res["result"]["lines"] as Array).size(), 2, "two crossing lines completed")
	eq(rx.field.size(), 2, "crossing 2 lines summon exactly 2 grade-1 units")
	eq(rx.field[0].rank, 1, "crossing unit 0 grade 1")
	eq(rx.field[1].rank, 1, "crossing unit 1 grade 1")


func test_tutorial_flow_guanyu_deploy() -> void:
	var r := _run()
	r.rice = 600
	r.reserve_tutorial_hero = true
	r.slot.forced = {"cols": [["rider", "spear", "archer"], ["archer", "spear", "rider"], ["shield", "spear", "archer"]]}
	r.spin()
	r.slot.forced = {"cols": [["archer", "shield", "rider"], ["archer", "rider", "spear"], ["shield", "spear", "rider"]], "above": ["", "", "archer"]}
	r.spin()
	r.nudge(2, 1)
	r.slot.forced = {"cols": [["archer", "guanyu", "rider"], ["rider", "spear", "archer"], ["rider", "spear", "archer"]]}
	r.force_bench = true
	r.spin()
	r.force_bench = false
	r.reserve_tutorial_hero = false
	var gy := r.find_owned("guanyu")
	check(gy != null and r.bench.has(gy), "guanyu waiting on bench")
	eq(r.deploy(gy), "", "guanyu deploys cleanly to field")
	check(r.field.has(gy), "guanyu is on field")
