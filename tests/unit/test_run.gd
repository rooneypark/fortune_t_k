extends TestCase
## Run rules (GDD v5 §3.3-3.6, §7, §8 + 스테이지-흡수-합성-개편 §3.2, §9):
## 3-reel slot, units stand on the field at once, absorb = 성급 / 속성 in the account.
## 군량은 계정의 것 (돌리기 1회 = 1, 한 전투 10회), 캐릭터는 슬롯에서 나오면 합류한다 (§13).

const HEROES := ["guanyu", "zhangfei", "zhaoyun", "huangzhong", "zhugeliang"]
const MISS := {"cells": ["", "", ""]}


func _account() -> Profile:
	var p := Profile.new()
	p.rng.seed = 5
	for id: String in HEROES:
		p.add_hero_card(id)
	for id in ["shield", "halberd"]:
		p.add_troop_card(id)
	return p


func _run(seed: int = 1, acc: Profile = null) -> RunState:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var r := RunState.new(rng, HEROES, ["spear", "sword", "archer", "rider", "shield", "halberd"], 1, 1, acc if acc != null else _account())
	return r


func test_start_values() -> void:
	var r := _run()
	eq(r.rice, int(DB.rules["rice_max"]), "군량은 계정의 것: 새 계정은 가득 (30)")
	eq(r.spins_left(), 15, "군량 30 = 15번 (한 번에 2)")
	eq(r.castle_hp, 1000, "castle 1000")
	eq(r.field_cap, 8, "field cap 8")
	eq(r.heroes.size(), 5, "every hero passed in is on the reels (no lineup cap)")
	eq(r.wave_count(), 10, "10 waves")


func test_spin_costs_two_rice_and_no_limit() -> void:
	var r := _run()
	r.recruit("spear")
	var rice := r.rice
	eq(r.spin_cost(), 2, "군량 2")
	for i in 15:
		r.field.resize(1)
		r.slot.forced = MISS.duplicate(true)
		check(not r.spin().is_empty(), "spin %d (no 10-spin limit)" % (i + 1))
		eq(r.spin_cost(), 2, "the price does not grow")
	eq(r.rice, rice - 30, "paid 30 군량 from the account")
	eq(r.spins_left(), 0, "군량 used up")
	eq(r.spin_block_reason(), DB.t("battle.no_rice"), "no 군량: spin refused")
	check(r.spin().is_empty(), "blocked spin returns {}")
	r.account.add_rice(3)
	eq(r.spins_left(), 1, "군량 3 = 1번")
	eq(r.spin_block_reason(), "", "군량 again: spin allowed")


func test_no_rice_blocks_the_lever() -> void:
	var r := _run()
	r.account.spend_rice(r.rice)
	eq(r.spin_block_reason(), DB.t("battle.no_rice"), "no 군량")
	check(r.spin().is_empty(), "refused")
	r.account.data["gold"] = 100000
	eq(r.account.refill_rice(), "", "금으로 채운다")
	eq(r.spin_block_reason(), "", "can spin again")


func test_castle_regen_and_no_rice_income() -> void:
	var r := _run()
	var rice := r.rice
	r.damage_castle(400)
	var got := r.finish_wave()
	eq(int(got["castle"]), 100, "10% of max")
	eq(r.castle_hp, 700, "600 + 100")
	eq(r.rice, rice, "웨이브를 깨도 군량은 안 생긴다")
	check(not got.has("rice"), "no rice income")


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
	near(r.respawn_time(UnitState.create("spear")), 5.0, 0.001, "soldier 5s")
	near(r.respawn_time(UnitState.create("guanyu")), 12.0, 0.001, "hero 12s")


# ---------------------------------------------------------------- slot -> field

func test_every_winning_reel_recruits() -> void:
	var r := _run()
	r.slot.forced = {"cells": ["spear", "", "guanyu"]}
	var res := r.spin()
	eq(r.field.size(), 2, "two winning reels = two units")
	eq(r.field[0].id, "spear", "soldier")
	eq(r.field[1].id, "guanyu", "hero")
	eq((res["events"] as Array).size(), 2, "two events")
	eq(int(r.stats["jackpots"]), 0, "not a jackpot")


func test_all_blank_gives_nothing() -> void:
	var r := _run()
	r.recruit("spear")
	r.slot.forced = MISS.duplicate(true)
	var res := r.spin()
	eq(r.field.size(), 1, "nobody new")
	eq((res["events"] as Array).size(), 0, "no events")
	eq(int(r.stats["streak"]), 0, "streak reset")


func test_empty_field_always_gets_a_unit() -> void:
	# 전부 꽝이 이어지면 아무도 없이 멈춘다. 전장이 비어 있으면 최소 1칸 당첨.
	for seed in range(1, 60):
		var r := _run(seed)
		r.spin()
		check(r.field.size() >= 1, "seed %d: the first spin gives at least one unit" % seed)
	var r2 := _run(3)
	r2.recruit("spear")
	var blanks := 0
	for i in 200:
		r2.account.add_rice(r2.spin_cost())
		r2.spins = 0
		r2.field.resize(1)
		if (r2.spin()["result"]["wins"] as Array).is_empty():
			blanks += 1
	check(blanks > 20, "with a unit on the field an all-blank spin is still possible")


func test_jackpot_refunds_the_spin() -> void:
	var r := _run()
	r.slot.forced = {"cells": ["spear", "archer", "rider"]}
	var res := r.spin()
	eq(r.field.size(), 3, "three units")
	eq(r.rice, int(DB.rules["rice_max"]), "the 군량 came back")
	eq(int(r.stats["jackpots"]), 1, "jackpot counted")
	var refund := false
	for e: Dictionary in res["events"]:
		if String(e["type"]) == "refund":
			refund = int(e["rice"]) == int(DB.rules["jackpot_refund_rice"])
	check(refund, "refund event = jackpot_refund_rice")


func test_shift_one_blank_reel() -> void:
	var r := _run()
	r.slot.forced = {"cells": ["spear", "", ""], "above": ["", "", "archer"], "below": ["", "rider", ""]}
	r.spin()
	check(r.can_nudge(), "a blank reel may be shifted")
	check(r.nudge(0, 1).is_empty(), "a winning reel is refused")
	var rice := r.rice
	var res := r.nudge(2, 1)
	eq(r.rice, rice - 1, "재배치 = 군량 1")
	eq(r.spins, 1, "재배치는 돌리기 횟수에 안 든다")
	eq(r.field.size(), 2, "spear + archer")
	eq(r.field[1].id, "archer", "the cell above came down")
	eq((res["events"] as Array).size(), 1, "only the new unit")
	check(r.can_nudge(), "more shifts while a blank is left")
	var res2 := r.nudge(1, -1)
	eq(r.rice, rice - 2 + int(DB.rules["jackpot_refund_rice"]), "second shift = 군량 1 more, jackpot refund back")
	eq(r.field[2].id, "rider", "the cell below came up")
	check(bool(res2["result"]["jackpot"]), "three wins by shifts = jackpot")
	check(not r.can_nudge(), "no blank left")


func test_soldiers_have_no_limit() -> void:
	var r := _run()
	for i in 20:
		eq(r.recruit("spear")[0]["type"], "field", "a soldier always stands on the field")
	eq(r.field.size(), 20, "20 soldiers, over the cap of 8")
	eq(r.spin_block_reason(), "", "the lever stays open")


func test_heroes_stop_at_the_cap() -> void:
	var r := _run()
	for i in 8:
		eq(r.recruit("guanyu")[0]["type"], "field", "hero %d stands" % (i + 1))
	check(r.heroes_full(), "8 heroes = full")
	eq(r.recruit("zhangfei")[0]["type"], "lost", "the ninth hero has no place")
	eq(r.recruit("spear")[0]["type"], "field", "but soldiers still come in")
	eq(r.spin_block_reason(), "", "spinning is still allowed")


func test_no_hero_limit() -> void:
	var r := _run()
	for id in ["guanyu", "zhangfei", "zhaoyun", "huangzhong"]:
		r.recruit(id)
	eq(r.heroes_on_field(), 4, "four heroes on the field (no hero quota)")


func test_army_carries_over_with_hp() -> void:
	# 내 부대 (2026-11-23): 이겨도 져도 남고, 체력도 이어진다. 계정에 없는 손님 장수는 빠진다.
	var r := _run()
	r.recruit("spear")
	r.recruit("archer")
	r.field[0].hp_ratio = 0.4
	r.field[0].anchor = Vector2(300, 800)
	var guest := UnitState.create("lvbu", 0)
	r.field.append(guest)
	r.account.data["heroes"].erase("lvbu")
	r.account.set_army(r.field)
	var army := r.account.army()
	eq(army.size(), 2, "spear + archer (guest hero left out)")
	eq(float(army[0]["hp"]), 0.4, "hp kept")
	var r2 := _run(2, r.account)
	r2.load_units(r.account.army())
	eq(r2.field.size(), 2, "the army stands on the next field")
	eq(r2.field[0].hp_ratio, 0.4, "with its hp")
	eq(r2.field[0].anchor, Vector2(300, 800), "in its place")
	r.account.finish_run(1, 1, 3, false, 0, {})
	eq(r.account.army().size(), 2, "a lost run keeps the army")
	eq(r.account.current_stage(), 1, "and the stage stays")


func test_retreat_save_and_restore() -> void:
	var r := _run()
	r.recruit("spear")
	r.recruit("guanyu")
	r.field[0].anchor = Vector2(300, 700)
	r.finish_wave()
	r.finish_wave()
	r.castle_hp = 640
	r.buy_field_cap()
	var save := r.to_save()
	var r2 := RunState.new(RandomNumberGenerator.new(), ["guanyu"], ["spear"], 1, 1, r.account)
	r2.restore(save)
	eq(r2.wave, 2, "two waves won: go on from the third")
	eq(r2.castle_hp, 640, "castle health kept")
	eq(r2.field.size(), 2, "units kept")
	eq(r2.field[1].id, "guanyu", "same units")
	eq(r2.field[0].anchor, Vector2(300, 700), "same places")
	eq(r2.field_cap, 9, "bought place kept")
	r.account.suspend_run(save)
	check(not r.account.suspended().is_empty(), "stored on the account")
	r.account.finish_run(1, 1, 10, true, 1, {})
	check(r.account.suspended().is_empty(), "finishing the run clears it")


func test_field_cap_purchase() -> void:
	var r := _run()
	var gold := int(r.account.data["gold"])
	var rice := r.rice
	check(r.buy_field_cap(), "buy +1")
	eq(r.field_cap, 9, "9")
	eq(int(r.account.data["gold"]), gold - 500, "금 500")
	eq(r.rice, rice, "군량은 안 든다")
	r.account.data["gold"] = 0
	check(not r.buy_field_cap(), "needs 금")


# ---------------------------------------------------------------- absorb: 성급 (같은 병종)

func test_duplicate_hero_stands_beside_and_feeds_star() -> void:
	var r := _run()
	r.recruit("zhangfei")
	var ev := r.recruit("zhangfei")
	eq(ev[0]["type"], "field", "the copy is a second unit, not merged")
	eq(r.field.size(), 2, "two zhangfei on the field")
	var chk := r.absorb_check(r.field[1], r.field[0])
	eq(chk["mode"], "star", "same hero -> 성급")
	eq(int(chk["xp"]), 10, "a copy = 10")
	var res := r.absorb_star(r.field[1], r.field[0])
	eq(int(res["gained"]), 1, "1성 -> 2성 with one copy")
	eq(r.field.size(), 1, "copy gone")
	eq(r.account.star_of("zhangfei"), 2, "saved in the account at once")
	eq(int(r.stats["stars"]), 1, "counted for the mission")


func test_soldier_feeds_hero_of_the_same_troop() -> void:
	var r := _run()
	r.recruit("guanyu")
	r.recruit("spear")
	var chk := r.absorb_check(r.field[1], r.field[0])
	eq(chk["mode"], "star", "창병 -> 관우 (창병 장수)")
	eq(int(chk["xp"]), 1, "a soldier = 1")
	var res := r.absorb_star(r.field[1], r.field[0])
	eq(int(res["gained"]), 0, "not enough yet")
	eq(int(r.account.hero("guanyu")["xp"]), 1, "1 / 20")


func test_soldiers_raise_the_whole_troop() -> void:
	var r := _run()
	for i in 6:
		r.recruit("spear")
	var target: UnitState = r.field[0]
	var last := {}
	for i in 5:
		last = r.absorb_star(r.field[1], target)
	eq(int(last["gained"]), 1, "5 absorbs -> 병종 2성")
	eq(int(r.account.troop("spear")["star"]), 2, "the troop's star, for every spear")
	eq(r.star_of(target), 2, "read through the run")
	eq(r.field.size(), 1, "five gone")


func test_star_survives_the_run() -> void:
	var acc := _account()
	var r := _run(1, acc)
	r.recruit("zhangfei")
	r.recruit("zhangfei")
	r.absorb_star(r.field[1], r.field[0])
	var next := _run(2, acc)
	next.recruit("zhangfei")
	eq(next.star_of(next.field[0]), 2, "the next run starts with the higher 성급")
	check(MetaRules.hero_stats(acc.data, "zhangfei")["atk"] > MetaRules.base_stats("zhangfei")["atk"], "and the higher base stats")


func test_max_star_blocks_same_troop_absorb() -> void:
	var r := _run()
	r.account.hero("zhangfei")["star"] = 6
	r.recruit("zhangfei")
	r.recruit("zhangfei")
	var chk := r.absorb_check(r.field[1], r.field[0])
	check(not chk["ok"], "6성 takes no more")
	eq(String(chk["reason"]), DB.t("absorb.max_star"), "reason")
	check(r.absorb_star(r.field[1], r.field[0]).is_empty(), "refused")
	eq(r.field.size(), 2, "copy kept")


func test_slot_units_join_the_account() -> void:
	# 개편 §13: 캐릭터는 전투 중 슬롯에서만 얻는다. 처음 나온 장수 · 병종은 그 자리에서 합류.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var acc := Profile.new()
	var r := RunState.new(rng, ["lvbu"], ["spear", "vine"], 1, 1, acc)
	r.recruit("spear")
	r.slot.forced = {"cells": ["lvbu", "vine", "spear"]}
	var res := r.spin()
	check(acc.owns("lvbu"), "여포 합류")
	check(acc.owns_troop("vine"), "등갑병 합류")
	var news := 0
	for e: Dictionary in res["events"]:
		if bool(e.get("new", false)):
			news += 1
	eq(news, 2, "two new units flagged (spear was already owned)")
	eq(int(r.stats["new_units"]), 2, "counted")
	check(r.absorb_check(r.field[0], r.field[1])["ok"], "a hero that just joined can absorb at once")
	check(not r.absorb_check(r.field[0], r.field[0])["ok"], "self ignored")
	var next := RunState.new(rng, ["lvbu"], ["spear", "vine"], 1, 1, acc)
	next.recruit("lvbu")
	eq(int(next.stats["new_units"]), 0, "next time it is not new")


func test_new_unit_joins_even_when_the_field_is_full() -> void:
	var r := _run()
	for i in 8:
		r.recruit("spear")
	for i in 8:
		r.recruit("guanyu")
	var ev := r.recruit("lvbu")
	eq(ev[0]["type"], "lost", "no hero place for the body")
	check(bool(ev[0]["new"]) and r.account.owns("lvbu"), "but the hero joined the account")


# ---------------------------------------------------------------- absorb: 속성 (다른 병종)

func test_other_troop_gives_a_trait_choice() -> void:
	var r := _run()
	r.recruit("spear")
	r.recruit("archer")
	r.recruit("halberd")
	var target: UnitState = r.field[0]
	eq(r.absorb_check(r.field[1], target)["mode"], "trait", "궁병 -> 창병 = 속성")
	eq(r.absorb_check(r.field[2], target)["mode"], "trait", "극병 -> 창병: same class but another troop = 속성")
	var opts := r.trait_options(r.field[1], target)
	eq(opts.size(), 3, "three choices")
	eq([opts[0]["id"], opts[1]["id"], opts[2]["id"]], ["longbow", "rapid", "aim"], "궁병: 분류 2 + 고유 1")
	eq(int(opts[1]["lv"]), 0, "not owned yet")
	check(r.absorb_trait(r.field[1], target, "rapid"), "took 속사")
	eq(r.traits_of(target), [{"id": "rapid", "lv": 1}], "saved on the troop")
	eq(r.field.size(), 2, "food gone")
	eq(int(r.stats["traits"]), 1, "counted")


func test_same_trait_again_levels_up() -> void:
	var r := _run()
	r.recruit("spear")
	var target: UnitState = r.field[0]
	for i in 3:
		r.recruit("archer")
		check(r.absorb_trait(r.field[1], target, "rapid"), "rapid %d" % (i + 1))
	eq(r.traits_of(target), [{"id": "rapid", "lv": 3}], "Lv.3")
	r.recruit("archer")
	check(bool(r.trait_options(r.field[1], target)[1]["maxed"]), "shown as maxed")
	check(not r.absorb_trait(r.field[1], target, "rapid"), "max level refused")
	eq(r.field.size(), 2, "food kept when refused")


func test_full_slots_need_a_replace() -> void:
	var r := _run()
	r.recruit("spear")
	r.recruit("archer")
	r.recruit("rider")
	var target: UnitState = r.field[0]
	eq(r.trait_slots(target), 1, "1성 = 1칸")
	check(r.absorb_trait(r.field[1], target, "rapid"), "first")
	var rider: UnitState = r.field[1]
	check(not r.absorb_trait(rider, target, "gallop"), "slot full without replace")
	check(r.field.has(rider), "food kept when cancelled")
	check(r.absorb_trait(rider, target, "gallop", 0), "replace slot 0")
	eq(r.traits_of(target), [{"id": "gallop", "lv": 1}], "replaced")


func test_only_the_foods_traits_are_offered() -> void:
	var r := _run()
	r.recruit("spear")
	r.recruit("archer")
	check(not r.absorb_trait(r.field[1], r.field[0], "gallop"), "궁병 cannot give a 기병 trait")
	check(not r.absorb_trait(r.field[1], r.field[0], "no_such"), "unknown trait")
	eq(r.field.size(), 2, "food kept")


# ---------------------------------------------------------------- 책사

func test_stars() -> void:
	var r := _run()
	eq(r.stars_earned(true), 3, "full castle 3 stars")
	r.damage_castle(200)
	eq(r.stars_earned(true), 2, "80% -> 2")
	r.damage_castle(400)
	eq(r.stars_earned(true), 1, "40% -> 1")
	eq(r.stars_earned(false), 0, "defeat 0")


func test_run_state_has_one_currency() -> void:
	# 개편 §13: 다이아는 없다. 전투 안에서 쓰는 것은 군량(돌리기)과 금(전장 칸)뿐.
	var src := FileAccess.get_file_as_string("res://src/core/run_state.gd")
	check(src.find("diamond") < 0, "run_state never touches diamonds")


func test_tutorial_flow() -> void:
	# 창병 당첨 -> 전부 꽝, 세 번째 줄 위의 궁병을 끌어내림 -> 창병 + 관우.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var r := RunState.new(rng, ["guanyu"], ["spear", "sword", "archer", "rider"], 1, 1, Profile.new())
	r.slot.forced = {"cells": ["spear", "", ""]}
	r.spin()
	r.slot.forced = {"cells": ["", "", ""], "above": ["", "", "archer"]}
	r.spin()
	check(not r.nudge(2, 1).is_empty(), "pull the archer above the third reel down")
	r.slot.forced = {"cells": ["spear", "guanyu", ""]}
	r.spin()
	eq(r.field.size(), 4, "spear, archer, spear, guanyu")
	eq(r.field[3].id, "guanyu", "guanyu stands on the field right away")
	check(r.account.owns("guanyu"), "and joins the account (모집 화면 없음)")
	eq(r.spins, 3, "three spins used, the shift does not count")
