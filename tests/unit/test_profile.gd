extends TestCase
## Account actions and save round trip.


func _p() -> Profile:
	var p := Profile.new()
	p.rng.seed = 11
	p.clock = func() -> int: return 1795000000
	# 2026-11-22: 계정은 장수 없이 시작한다. 테스트용으로 셋을 준다.
	for id in ["guanyu", "zhangfei", "zhaoyun"]:
		p.add_hero_card(id)
	return p


func test_save_round_trip() -> void:
	var p := _p()
	p.data["gold"] = 1234
	p.add_star_xp("guanyu", 3)
	p.set_trait("guanyu", "iron")
	var text := p.to_json()
	var q := _p()
	check(q.load_json(text), "loads")
	eq(q.data["gold"], p.data["gold"], "gold kept")
	eq(int(q.hero("guanyu")["xp"]), 3, "성급 경험 kept")
	eq(q.hero("guanyu")["traits"], [{"id": "iron", "lv": 1}], "속성 kept")
	check(typeof(q.hero("guanyu")["traits"][0]["lv"]) == TYPE_INT, "trait level is an int again")
	check(typeof(q.data["gold"]) == TYPE_INT, "ints restored")


func test_old_save_gets_new_keys() -> void:
	var q := _p()
	check(q.load_json("{\"gold\": 5}"), "partial save")
	eq(q.data["gold"], 5, "kept")
	check(q.data.has("settings"), "defaults filled")


func test_star_xp_raises_star_and_keeps_rest() -> void:
	var p := _p()
	eq(p.star_of("zhangfei"), 1, "starts 1성")
	var r := p.add_star_xp("zhangfei", 4)
	eq(int(r["gained"]), 0, "not yet")
	eq(int(r["xp"]), 4, "4 / 10")
	r = p.add_star_xp("zhangfei", 10)
	eq(int(r["gained"]), 1, "2성")
	eq(p.star_of("zhangfei"), 2, "star saved")
	eq(int(r["xp"]), 4, "rest carries over")
	eq(int(r["need"]), 20, "next needs 20")
	r = p.add_star_xp("zhangfei", 1000)
	eq(p.star_of("zhangfei"), 6, "capped at 6성")
	eq(int(p.hero("zhangfei")["xp"]), 0, "no xp past max")
	check(p.add_star_xp("zhangfei", 1).is_empty(), "max star takes no more")
	check(p.add_star_xp("lvbu", 5).is_empty(), "not owned")


func test_duplicate_recruit_becomes_gold() -> void:
	var p := _p()
	var gold := int(p.data["gold"])
	var r := p.add_hero_card("guanyu")
	check(not bool(r["new"]), "already owned")
	eq(int(p.data["gold"]) - gold, int(DB.meta["star"]["dup_gold"]["s"]), "S 장수 복사본 -> 골드")
	eq(p.star_of("guanyu"), 2, "star unchanged: 성급은 전투에서만")
	gold = int(p.data["gold"])
	p.add_troop_card("spear")
	eq(int(p.data["gold"]) - gold, int(DB.meta["star"]["troop_dup_gold"]), "가진 병종 -> 골드")


func test_traits_slots_levels_replace() -> void:
	var p := _p()
	eq(p.set_trait("zhangfei", "iron"), "", "first trait")
	eq(p.set_trait("zhangfei", "iron"), "", "same again = level 2")
	eq(p.hero("zhangfei")["traits"], [{"id": "iron", "lv": 2}], "Lv.2")
	check(p.set_trait("zhangfei", "rapid") != "", "1성 = 1칸: full without replace")
	eq(p.set_trait("zhangfei", "rapid", 0), "", "replace slot 0")
	eq(p.hero("zhangfei")["traits"], [{"id": "rapid", "lv": 1}], "replaced")
	p.set_trait("zhangfei", "rapid")
	p.set_trait("zhangfei", "rapid")
	check(p.set_trait("zhangfei", "rapid") != "", "max level 3")
	p.add_star_xp("zhangfei", 30)
	eq(p.star_of("zhangfei"), 3, "3성")
	eq(p.set_trait("zhangfei", "iron"), "", "3성 = 2칸")
	eq((p.hero("zhangfei")["traits"] as Array).size(), 2, "two traits")
	check(p.set_trait("zhangfei", "no_such_trait") != "", "unknown trait refused")
	eq(p.set_trait("spear", "rapid"), "", "troops take traits too")
	eq(p.troop("spear")["traits"], [{"id": "rapid", "lv": 1}], "saved on the troop")


func test_slot_join_adds_new_units_only_once() -> void:
	# 개편 §13: 캐릭터는 전투 중 슬롯에서만 얻는다.
	var p := Profile.new()
	check(not p.owns("lvbu"), "not owned")
	check(p.join("lvbu"), "a hero drawn by the slot joins")
	check(p.owns("lvbu"), "owned now")
	eq(p.star_of("lvbu"), MetaRules.start_star("lvbu"), "starts at its grade's star")
	check(not p.join("lvbu"), "the second time is not new")
	check(p.join("halberd"), "a troop joins too")
	check(p.owns_troop("halberd"), "troop owned")
	check(not p.join("spear"), "a starting troop is not new")
	check(not p.join("no_such_unit"), "unknown id")


func test_finish_run_rewards_and_unlock() -> void:
	var p := _p()
	check(p.is_unlocked(1, 1), "stage 1 보통 open")
	check(p.is_unlocked(1, 2) and p.is_unlocked(1, 3), "stage 1: 어려움 · 지옥도 처음부터 열림")
	check(not p.is_unlocked(2, 1), "stage 2 locked")
	var gold: int = p.data["gold"]
	var out := p.finish_run(1, 1, 10, true, 3, {"kills": 50, "spins": 10})
	eq(int(out["run_gold"]), 1500, "run gold 100 x 10 + 500")
	check(bool(out["first"]), "first clear")
	eq(int(out["first_gold"]), 2000, "first clear 금 2,000")
	eq(int(p.data["gold"]) - gold, 3500, "both paid in 금")
	check(p.is_unlocked(1, 2), "어려움 unlocked")
	check(p.is_unlocked(2, 1), "stage 2 unlocked")
	check(p.is_unlocked(2, 3), "stage 2: 모든 난이도 열림")
	eq(int(out["lord_exp"]), 200, "첫 클리어 군주 경험 100 x 2")
	eq(String(p.data["progress"]["last"]), "2-1", "next stage")
	out = p.finish_run(1, 1, 10, true, 2, {})
	check(not bool(out["first"]), "second clear not first")
	eq(p.stars_of("1-1"), 3, "best stars kept")


func test_missions_track_and_claim() -> void:
	var p := _p()
	p.refresh_periods()
	var mi: Dictionary = DB.missions["daily"][0]
	eq(p.mission_state(mi, "daily"), "progress", "not yet")
	p.track(String(mi["stat"]), int(mi["need"]))
	eq(p.mission_state(mi, "daily"), "ready", "ready")
	var gold: int = p.data["gold"]
	p.claim_mission(mi, "daily")
	eq(p.mission_state(mi, "daily"), "claimed", "claimed")
	check(int(p.data["gold"]) > gold, "reward paid")
	p.clock = func() -> int: return 1795000000 + 86400
	p.refresh_periods()
	eq(p.mission_state(mi, "daily"), "progress", "daily reset next day")


func test_shop_sells_gold_only() -> void:
	# 개편 §13: 재화는 금 하나. 현금으로 파는 것은 금(과 꾸러미의 군량 · 재료)뿐.
	var p := _p()
	var g: int = p.data["gold"]
	p.purchase("g60")
	eq(int(p.data["gold"]) - g, 4000, "first purchase x2")
	p.purchase("g60")
	eq(int(p.data["gold"]) - g, 6000, "then normal")
	var txt := JSON.stringify(DB.shop)
	check(txt.find("diamond") < 0, "no diamonds anywhere in the shop")
	check(txt.find("tickets") < 0, "no recruit tickets")
	check(not p.data.has("diamond") and not p.data.has("tickets"), "the account has no diamonds or tickets")
	var rice := p.rice_now()
	var rw := p.purchase("p_start")
	eq(p.rice_now() - rice, 50, "꾸러미의 군량")
	check(int(rw["gold"]) > 0, "꾸러미의 금")


func test_treasure_equip_swap() -> void:
	var p := _p()
	var g := p.add_treasure(String(DB.treasures_of_rarity("rare")[0]["id"]))
	var uid := int(g["uid"])
	p.equip("guanyu", uid)
	eq(MetaRules.treasure_owner(p.data, uid), "guanyu", "equipped")
	p.equip("zhangfei", uid)
	eq(MetaRules.treasure_owner(p.data, uid), "zhangfei", "moved freely")
	var gold: int = p.data["gold"]
	var got := p.dismantle(uid)
	eq(got, 300, "rare dismantle 300")
	eq(int(p.data["gold"]) - gold, 300, "gold added")


func test_arena_five_free_per_day() -> void:
	# 콘텐츠 §7: 하루 무료 5회, 04:00 초기화, 추가 입장 다이아 20 (하루 5회).
	var p := _p()
	var clk := {"t": 1795000000}
	p.clock = func() -> int: return int(clk["t"])
	eq(int(p.sync_arena_entries()["entries"]), 5, "starts with 5")
	for i in 5:
		check(p.use_arena_entry(), "free entry %d" % i)
	check(not p.use_arena_entry(), "6th free entry refused")
	p.data["gold"] = 10000
	for i in 5:
		eq(p.buy_arena_entry(), "", "buy extra %d" % i)
	eq(int(p.data["gold"]), 5000, "5 x 금 1,000")
	check(p.buy_arena_entry() != "", "6th purchase refused")
	eq(int(p.sync_arena_entries()["entries"]), 5, "5 bought entries")
	clk["t"] = int(clk["t"]) + p.seconds_to_reset()
	var st := p.sync_arena_entries()
	eq(int(st["entries"]), 5, "back to 5 after 04:00")
	eq(int(st["bought"]), 0, "purchases reset")


func test_arena_day_survives_reload() -> void:
	var p := _p()
	p.use_arena_entry()
	p.use_arena_entry()
	var q := _p()
	q.load_json(p.to_json())
	eq(int(q.sync_arena_entries()["entries"]), 3, "same day: 3 left after reload")


func test_arena_honor_and_never_diamonds() -> void:
	var p := _p()
	eq(p.finish_arena(true), 20, "win 20")
	eq(p.finish_arena(false), 5, "lose 5")
	eq(int(p.data["honor"]), 25, "honor total")
	var txt := JSON.stringify(DB.shop)
	check(txt.find("\"honor\"") < 0, "the shop sells no 군공")


func test_arena_shop_sells_an_epic_treasure_and_no_hero_card() -> void:
	var p := _p()
	p.data["honor"] = 1000
	check(p.arena_item("card").is_empty(), "장수 카드는 없다 (성급은 전투에서만)")
	var price := p.arena_price("treasure")
	check(price > 0, "treasure has a price")
	var res := p.buy_arena_item("treasure")
	check(bool(res["ok"]), "bought")
	eq(String(DB.treasure_def(String(res["gained"][0]["tid"]))["rarity"]), "epic", "영웅 보물")
	eq(int(p.data["honor"]), 1000 - price, "paid 군공")
	check(not bool(p.buy_arena_item("treasure")["ok"]), "weekly limit 1")
	p.clock = func() -> int: return 1795000000 + 8 * 86400
	check(bool(p.buy_arena_item("treasure")["ok"]), "limit resets next week")


func test_arena_shop_needs_honor() -> void:
	var p := _p()
	p.data["honor"] = 10
	check(not bool(p.buy_arena_item("rice")["ok"]), "not enough 군공")
	eq(int(p.data["honor"]), 10, "nothing taken")


func test_rice_fills_over_time_and_is_bought_with_gold() -> void:
	# 개편 §13: 군량은 시간으로 저절로 차고(30분에 1, 최대 30), 금으로 바로 채운다.
	var p := _p()
	var clk := {"t": 1795000000}
	p.clock = func() -> int: return int(clk["t"])
	var cap := int(DB.rules["rice_max"])
	eq(p.rice_now(), cap, "a new account starts full")
	check(p.spend_rice(10), "spend 10")
	eq(p.rice_now(), cap - 10, "20 left")
	var step := int(DB.rules["rice_regen_sec"])
	eq(step, 1800, "30분에 1 (2026-11-23)")
	eq(p.rice_next_sec(), step, "one step to the next one")
	clk["t"] = int(clk["t"]) + step - 1
	eq(p.rice_now(), cap - 10, "not yet")
	clk["t"] = int(clk["t"]) + 1
	eq(p.rice_now(), cap - 9, "+1 after one step")
	clk["t"] = int(clk["t"]) + step * 3 + 100
	eq(p.rice_now(), cap - 6, "+3 more, the rest of the time is kept")
	clk["t"] = int(clk["t"]) + 86400
	eq(p.rice_now(), cap, "stops at the max")
	eq(p.rice_next_sec(), 0, "full")
	check(not p.spend_rice(cap + 1), "cannot overspend")
	p.spend_rice(cap)
	eq(p.rice_refill_cost(), cap * int(DB.rules["rice_price"]), "금 300 each")
	p.data["gold"] = 100
	check(p.refill_rice() != "", "needs 금")
	p.data["gold"] = 20000
	eq(p.refill_rice(), "", "filled")
	eq(p.rice_now(), cap, "max")
	eq(int(p.data["gold"]), 20000 - cap * int(DB.rules["rice_price"]), "paid")
	check(p.refill_rice() != "", "already full")
	p.add_rice(15)
	eq(p.rice_now(), cap + 15, "rewards may go over the max")
	clk["t"] = int(clk["t"]) + 3600
	eq(p.rice_now(), cap + 15, "and it does not grow or shrink there")
	var q := _p()
	q.clock = p.clock
	check(q.load_json(p.to_json()), "save round trip")
	eq(q.rice_now(), cap + 15, "군량 saved")


func test_old_save_diamonds_and_tickets_turn_into_gold_and_rice() -> void:
	var p := _p()
	var old := {"version": 3, "gold": 1000, "diamond": 200, "tickets": 2, "pity": {"normal": 5}, "gold_buy": {"day": "", "count": 1},
		"tutorial": {"done": true, "recruit": true}}
	check(p.load_json(JSON.stringify(old)), "loads")
	eq(int(p.data["gold"]), 1000 + 200 * Profile.DIAMOND_GOLD, "다이아 x30 -> 금")
	eq(p.rice_now(), int(DB.rules["rice_max"]) + 2 * Profile.TICKET_RICE, "모집권 x10 -> 군량")
	for k in ["diamond", "tickets", "pity", "gold_buy", "gold_recruit"]:
		check(not p.data.has(k), k + " dropped")
	check(bool(p.data["tutorial"]["done"]), "tutorial state kept")
	var g := int(p.data["gold"])
	p.grant({"diamond": 10, "tickets": 1})
	eq(int(p.data["gold"]) - g, 300, "옛 우편의 다이아도 금으로")


func test_packages_hold_gold_rice_or_materials_only() -> void:
	var p := _p()
	for prod: Dictionary in DB.shop["packages"]:
		var rw := p.purchase(String(prod["id"]))
		for k: String in rw:
			check(k in ["gold", "rice", "mats", "_gained"], "package key " + k)


func test_new_account_has_no_heroes_and_four_troops() -> void:
	var p := Profile.new()
	eq((p.data["heroes"] as Dictionary).size(), 0, "no heroes")
	eq((p.data["troops"] as Dictionary).keys(), ["spear", "sword", "archer", "rider"], "4 basic troops")


func test_old_save_migrates_to_stages() -> void:
	var p := _p()
	var old := {"version": 1, "lineup": ["guanyu"], "advisor": "", "troop_lineup": ["spear"],
		"progress": {"cleared": {"1-8": 3, "2-8": 2, "3-2": 1}, "last": "3-3"}}
	check(p.load_json(JSON.stringify(old)), "loads")
	eq(p.stars_of("1-1"), 3, "1장 완료 -> 스테이지 1 보통")
	eq(p.stars_of("2-1"), 2, "2장 완료 -> 스테이지 2 보통")
	eq(p.stars_of("3-1"), 0, "3장은 끝까지 못 깼다")
	eq(String(p.data["progress"]["last"]), "3-1", "next = stage 3")
	check(not p.data.has("lineup") and not p.data.has("troop_lineup"), "lineup fields dropped")
	eq(int(p.data["version"]), Profile.VERSION, "version bumped")
	check(p.load_json(p.to_json()), "round trip")
	eq(p.stars_of("2-1"), 2, "not migrated twice")


func test_troop_star_by_xp() -> void:
	var p := _p()
	var before: float = MetaRules.soldier_stats(p.data, "spear")["atk"]
	eq(int(p.add_star_xp("spear", 5)["gained"]), 1, "5 경험 -> 2성")
	eq(int(p.troop("spear")["star"]), 2, "2성")
	near(MetaRules.soldier_stats(p.data, "spear")["atk"], before * 1.15, 0.01, "stars raise soldier atk")
	var t := p.add_troop_card("halberd")
	check(bool(t["new"]) and p.owns_troop("halberd"), "new troop unlocked")


func test_old_save_v2_cards_become_gold() -> void:
	var p := _p()
	var old := {"version": 2, "gold": 1000, "lord_lv": 5,
		"heroes": {"guanyu": {"star": 3, "cards": 2, "up": {"atk": 5, "def": 0, "hp": 0}, "eq": {}}},
		"troops": {"spear": {"star": 2, "cards": 3, "up": {"atk": 1, "def": 0, "hp": 0}}},
		"barracks": {"inf": {"atk": 3, "hp": 0}}}
	check(p.load_json(JSON.stringify(old)), "loads")
	eq(p.star_of("guanyu"), 3, "성급 kept")
	check(not p.hero("guanyu").has("cards") and not p.hero("guanyu").has("up"), "cards and upgrades dropped")
	eq(p.hero("guanyu")["traits"], [], "empty traits")
	eq(int(p.troop("spear")["star"]), 2, "troop star kept")
	eq(int(p.data["gold"]), 1000 + 2 * int(DB.meta["star"]["dup_gold"]["s"]) + 3 * int(DB.meta["star"]["troop_dup_gold"]), "cards -> gold")
	check(not p.data.has("barracks"), "barracks dropped")
	eq(int(p.data["version"]), Profile.VERSION, "version bumped")


func test_lord_exp_only_on_clear() -> void:
	var p := _p()
	var lost := p.finish_run(1, 1, 8, false, 0, {})
	eq(int(lost["lord_exp"]), 0, "defeat pays no 군주 경험")
	var won := p.finish_run(2, 1, 10, true, 3, {})
	eq(int(won["lord_exp"]), 400, "stage 2 first clear = 100 x 2 x 2")


# ---------------------------------------------------------------- 재료 · 합성 (개편 §3.7~3.8)

func _mat_total(p: Profile) -> int:
	var n := 0
	for slot: String in p.data["materials"]:
		for r: String in p.data["materials"][slot]:
			n += int(p.data["materials"][slot][r])
	return n


func test_stage_rewards_are_materials() -> void:
	var p := _p()
	var before := (p.data["treasures"] as Array).size()
	var out := p.finish_run(1, 1, 10, true, 3, {})
	eq((out["materials"] as Array).size(), 3, "승리 2개 + 첫 클리어 1개")
	eq(_mat_total(p), 3, "saved in the account")
	eq((p.data["treasures"] as Array).size(), before, "no treasure straight from a stage")
	var order: Array = DB.meta["treasure"]["rarity_order"]
	check(order.find(String(out["materials"][2]["rarity"])) >= order.find("rare"), "first clear material is 희귀 or better")
	out = p.finish_run(1, 1, 10, true, 3, {})
	eq((out["materials"] as Array).size(), 2, "다시 깨면 2개")
	eq((p.finish_run(1, 1, 5, false, 0, {})["materials"] as Array).size(), 1, "패배: 5웨이브 이상이면 1개")
	eq((p.finish_run(1, 1, 4, false, 0, {})["materials"] as Array).size(), 0, "패배: 5웨이브 전이면 없음")


func test_harder_difficulty_gives_better_materials() -> void:
	var p := _p()
	var order: Array = DB.meta["treasure"]["rarity_order"]
	var sums := [0.0, 0.0, 0.0]
	for d in [1, 2, 3]:
		for _i in 400:
			sums[d - 1] += order.find(String(p.roll_material(d)["rarity"]))
	check(sums[0] < sums[1] and sums[1] < sums[2], "보통 < 어려움 < 지옥")
	var legend_normal := 0
	for _i in 400:
		if String(p.roll_material(1)["rarity"]) == "legend":
			legend_normal += 1
	eq(legend_normal, 0, "보통에서는 전설 재료가 안 나온다")


func test_craft_three_materials_into_a_treasure() -> void:
	var p := _p()
	p.add_material("weapon", "rare", 2)
	check(not bool(p.craft("weapon", "rare")["ok"]), "2개로는 안 된다")
	eq(p.material_count("weapon", "rare"), 2, "refused craft keeps the materials")
	p.add_material("weapon", "rare", 2)
	var gold := int(p.data["gold"])
	var res := p.craft("weapon", "rare")
	check(bool(res["ok"]), "3개 -> 보물")
	eq(p.material_count("weapon", "rare"), 1, "3 used, 1 left")
	eq(int(p.data["gold"]), gold, "합성은 골드가 들지 않는다")
	var def := DB.treasure_def(String(res["item"]["tid"]))
	eq(String(def["slot"]), "weapon", "같은 종류")
	eq(String(def["rarity"]), "rare", "같은 등급")
	eq((p.data["treasures"] as Array).size(), 1, "one treasure")


func test_fuse_three_treasures_into_a_better_one() -> void:
	var p := _p()
	for _i in 3:
		p.add_material("armor", "common", 3)
		p.craft("armor", "common")
	eq((p.data["treasures"] as Array).size(), 3, "three common armors")
	# a worn treasure is not used
	p.equip("guanyu", int(p.data["treasures"][0]["uid"]))
	check(not bool(p.fuse("common")["ok"]), "장착한 보물은 빼고 센다")
	p.unequip("guanyu", "armor")
	var res := p.fuse("common")
	check(bool(res["ok"]), "3개 -> 희귀 1개")
	eq((p.data["treasures"] as Array).size(), 1, "3 gone, 1 made")
	var def := DB.treasure_def(String(res["item"]["tid"]))
	eq(String(def["rarity"]), "rare", "한 단계 위")
	eq(String(def["slot"]), "armor", "넣은 보물의 종류")
	check(not bool(p.fuse("legend")["ok"]), "전설은 합성할 수 없다")


func test_reward_mats_and_old_boxes() -> void:
	var p := _p()
	var got := p.grant({"mats": 3})
	eq(got.size(), 3, "three materials listed")
	eq(String(got[0]["type"]), "material", "material entries")
	eq(_mat_total(p), 3, "희귀 재료 3개")
	p.grant({"boxes": 1})
	eq(_mat_total(p), 6, "옛 보물 상자 1개 = 재료 3개")
	check(not p.data.has("pity"), "천장 기록은 없다")


# ---------------------------------------------------------------- 장비 (개편 §11): 칸 3개, 일반 + 보물, 장수 · 병종 모두

func _gear(p: Profile, slot: String, rarity: String, name: String = "") -> Dictionary:
	for t: Dictionary in DB.treasures_of(slot, rarity):
		if name == "" or String(t["name"]) == name:
			return p.add_treasure(String(t["id"]))
	return {}


func test_normal_gear_is_stats_only_treasure_has_a_special() -> void:
	for t: Dictionary in DB.meta["treasure"]["list"]:
		var special := (t.get("fx", []) as Array).size() == 2
		eq(special, String(t["rarity"]) in ["epic", "legend"], "보물만 특수 능력: " + String(t["name"]))
		eq(String(t["kind"]), "treasure" if special else "normal", "kind of " + String(t["name"]))
	eq((DB.meta["treasure"]["slots"] as Array), ["weapon", "armor", "charm"], "칸 3개")
	eq(DB.t("slot.charm"), "장신구", "장신구")


func test_troop_wears_gear_for_all_its_soldiers() -> void:
	var p := _p()
	var before: float = MetaRules.soldier_stats(p.data, "spear")["atk"]
	var g := _gear(p, "weapon", "common")
	p.equip("spear", int(g["uid"]))
	eq(MetaRules.treasure_owner(p.data, int(g["uid"])), "spear", "the troop wears it")
	check(MetaRules.soldier_stats(p.data, "spear")["atk"] > before, "병사 공격이 오른다")
	near(MetaRules.bare_stats(p.data, "spear")["atk"], before, 0.001, "bare stats ignore gear")
	p.equip("guanyu", int(g["uid"]))
	eq(MetaRules.treasure_owner(p.data, int(g["uid"])), "guanyu", "moved to the hero")
	near(MetaRules.soldier_stats(p.data, "spear")["atk"], before, 0.001, "troop lost it")
	p.unequip("guanyu", "weapon")
	eq(MetaRules.treasure_owner(p.data, int(g["uid"])), "", "back in the bag")


func test_treasure_special_reaches_the_battle_effects() -> void:
	var p := _p()
	var g := _gear(p, "weapon", "legend", "청룡언월도")
	check(not g.is_empty(), "청룡언월도")
	var plain: float = MetaRules.hero_stats(p.data, "zhangfei")["atk"]
	p.equip("zhangfei", int(g["uid"]))
	var other: float = MetaRules.hero_stats(p.data, "zhangfei")["atk"] - plain
	near(float(MetaRules.unit_fx(p.data, "zhangfei")["splash"]), 0.45, 0.001, "특수 능력: 주변 45% 피해")
	var gy: float = MetaRules.hero_stats(p.data, "guanyu")["atk"]
	p.equip("guanyu", int(g["uid"]))
	near(MetaRules.hero_stats(p.data, "guanyu")["atk"] - gy, other * 1.3, 0.01, "전용 장수는 주 능력치 +30%")
	check(not MetaRules.unit_fx(p.data, "zhangfei").has("splash") or float(MetaRules.unit_fx(p.data, "zhangfei")["splash"]) < 0.45, "taken off zhangfei")
	var a := _gear(p, "armor", "epic", "명광개")
	p.equip("spear", int(a["uid"]))
	near(float(MetaRules.unit_fx(p.data, "spear")["dmg_taken"]), 0.9, 0.001, "병종도 보물의 특수 능력을 받는다")


func test_auto_equip_prefers_treasures() -> void:
	var p := _p()
	var c := _gear(p, "weapon", "common")
	var e := _gear(p, "weapon", "epic")
	var worn := _gear(p, "armor", "rare")
	p.equip("guanyu", int(worn["uid"]))
	p.auto_equip("spear")
	eq(int(p.troop("spear")["eq"]["weapon"]), int(e["uid"]), "보물을 먼저 낀다")
	check(not p.troop("spear")["eq"].has("armor"), "남이 낀 장비는 뺏지 않는다")
	p.auto_equip("zhangfei")
	eq(int(p.hero("zhangfei")["eq"]["weapon"]), int(c["uid"]), "남은 일반 장비")


func test_old_troop_without_eq_loads() -> void:
	var p := _p()
	check(p.load_json(JSON.stringify({"version": 3, "troops": {"spear": {"star": 2, "xp": 1, "traits": []}}})), "loads")
	eq(p.troop("spear")["eq"], {}, "eq added")
	var g := _gear(p, "charm", "common")
	p.equip("spear", int(g["uid"]))
	check(p.load_json(p.to_json()), "round trip")
	eq(int(p.troop("spear")["eq"]["charm"]), int(g["uid"]), "troop gear saved")


func test_stage_back_costs_gold_and_reclear_advances() -> void:
	var p := _p()
	eq(p.current_stage(), 1, "starts at stage 1")
	check(p.stage_back() != "", "첫 스테이지는 못 되돌린다")
	p.finish_run(1, 1, 10, true, 3, {})
	p.finish_run(2, 1, 10, true, 3, {})
	eq(p.current_stage(), 3, "보통을 깨면 다음 스테이지")
	p.data["gold"] = 0
	check(p.stage_back() != "", "금이 없으면 못 되돌린다")
	p.data["gold"] = p.stage_back_cost() * 2
	eq(p.stage_back(), "", "되돌리기 성공")
	eq(p.current_stage(), 2, "한 스테이지 뒤로")
	eq(int(p.data["gold"]), p.stage_back_cost(), "금이 든다")
	p.finish_run(2, 2, 10, true, 3, {})
	eq(p.current_stage(), 2, "어려움을 깨도 그대로")
	var g := int(p.data["gold"])
	p.finish_run(2, 1, 10, true, 3, {})
	eq(p.current_stage(), 3, "다시 깨면 다음 스테이지")
	check(int(p.data["gold"]) > g, "다시 깨도 금을 받는다")
