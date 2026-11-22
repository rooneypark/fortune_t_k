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
	p.upgrade_stat("guanyu", "atk")
	var text := p.to_json()
	var q := _p()
	check(q.load_json(text), "loads")
	eq(q.data["gold"], p.data["gold"], "gold kept")
	eq(q.hero("guanyu")["up"]["atk"], 1, "upgrade kept")
	check(typeof(q.data["gold"]) == TYPE_INT, "ints restored")


func test_old_save_gets_new_keys() -> void:
	var q := _p()
	check(q.load_json("{\"gold\": 5}"), "partial save")
	eq(q.data["gold"], 5, "kept")
	check(q.data.has("settings"), "defaults filled")


func test_upgrade_and_cap() -> void:
	var p := _p()
	p.data["gold"] = 10000000
	var star := p.star_of("zhangfei")
	for i in MetaRules.upgrade_cap(star):
		eq(p.upgrade_stat("zhangfei", "hp"), "", "upgrade ok")
	check(p.upgrade_stat("zhangfei", "hp") != "", "capped at star x 10")


func test_star_up_uses_cards() -> void:
	var p := _p()
	check(p.star_up("zhangfei") != "", "needs a card")
	p.add_hero_card("zhangfei")
	eq(p.star_up("zhangfei"), "", "1 card -> 2성")
	eq(p.star_of("zhangfei"), 2, "2성")


func test_recruit_spends_tickets_then_diamonds() -> void:
	var p := _p()
	p.data["tickets"] = 1
	p.data["diamond"] = 3000
	var r := p.recruit(1)
	eq((r["cards"] as Array).size(), 1, "one card")
	eq(p.data["tickets"], 0, "ticket used")
	eq(p.data["diamond"], 3000, "diamonds untouched")
	r = p.recruit(10)
	eq((r["cards"] as Array).size(), 10, "ten")
	eq(p.data["diamond"], 300, "2,700 paid")
	r = p.recruit(10)
	check(r["error"] != "", "not enough")


func test_finish_run_rewards_and_unlock() -> void:
	var p := _p()
	check(not p.is_unlocked(1, 2), "1-2 locked")
	var dia: int = p.data["diamond"]
	var out := p.finish_run(1, 1, 10, true, 3, {"kills": 50, "spins": 12})
	eq(int(out["gold"]), 1500, "gold")
	check(bool(out["first"]), "first clear")
	eq(int(p.data["diamond"]) - dia, 50, "first clear 50 diamonds")
	check(p.is_unlocked(1, 2), "1-2 unlocked")
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


func test_first_purchase_double() -> void:
	var p := _p()
	var d: int = p.data["diamond"]
	p.purchase("d60")
	eq(int(p.data["diamond"]) - d, 120, "first x2")
	p.purchase("d60")
	eq(int(p.data["diamond"]) - d, 180, "then normal")


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
	p.data["diamond"] = 1000
	for i in 5:
		eq(p.buy_arena_entry(), "", "buy extra %d" % i)
	eq(int(p.data["diamond"]), 900, "5 x 20 diamonds")
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
	check(txt.find("\"honor\"") < 0, "diamond shop sells no 군공")


func test_arena_shop_hero_card() -> void:
	var p := _p()
	p.data["honor"] = 1000
	var before := int(p.hero("guanyu")["cards"])
	var price := p.arena_price("card", "guanyu")
	check(price > 0, "card has a price")
	var res := p.buy_arena_item("card", "guanyu")
	check(bool(res["ok"]), "bought card")
	eq(int(p.hero("guanyu")["cards"]), before + 1, "+1 card")
	eq(int(p.data["honor"]), 1000 - price, "paid 군공")
	check(not bool(p.buy_arena_item("card", "not_a_hero")["ok"]), "only owned heroes")
	for i in 4:
		p.buy_arena_item("card", "guanyu")
	check(not bool(p.buy_arena_item("card", "guanyu")["ok"]), "weekly limit 5")
	p.clock = func() -> int: return 1795000000 + 7 * 86400
	check(bool(p.buy_arena_item("card", "guanyu")["ok"]), "limit resets next week")


func test_arena_shop_needs_honor() -> void:
	var p := _p()
	p.data["honor"] = 10
	check(not bool(p.buy_arena_item("tickets")["ok"]), "not enough 군공")
	eq(int(p.data["honor"]), 10, "nothing taken")


func test_max_star_duplicate_gives_honor() -> void:
	var p := _p()
	p.hero("guanyu")["star"] = int(DB.meta["star"]["max"])
	var c := p.add_hero_card("guanyu")
	check(bool(c["honor"]), "converted")
	eq(int(p.data["honor"]), int(DB.meta["arena"]["dup_honor"]), "dup -> 군공 30")


func test_leftover_rice_becomes_gold() -> void:
	# 메타 §3.10: 남은 군량 × 2 → 골드, 패배여도.
	var p := _p()
	var g := int(p.data["gold"])
	var out := p.finish_run(1, 1, 4, false, 0, {}, 180)
	eq(int(out["rice_gold"]), 360, "180 rice -> 360 gold")
	eq(int(p.data["gold"]) - g, MetaRules.run_gold(4, false) + 360, "gold includes rice")


func test_start_rice_bonus_by_lord_level() -> void:
	eq(MetaRules.start_rice_bonus(9), 0, "Lv9 none")
	eq(MetaRules.start_rice_bonus(10), 20, "Lv10 +20")
	eq(MetaRules.start_rice_bonus(35), 60, "Lv35 +60")


func test_gold_buy_daily_limit() -> void:
	var p := _p()
	p.data["diamond"] = 100000
	for i in 3:
		eq(p.buy_gold(0), "", "buy %d" % i)
	check(p.buy_gold(0) != "", "4th refused")


func test_shop_never_sells_rice() -> void:
	# 기획서: 다이아로 군량·스핀을 살 수 없다.
	var txt := JSON.stringify(DB.shop)
	check(txt.find("\"rice\"") < 0 and txt.find("\"spins\"") < 0, "no rice / spin products")
	var p := _p()
	for prod: Dictionary in DB.shop["packages"]:
		var rw := p.purchase(String(prod["id"]))
		check(not rw.has("rice"), "package gives no rice")


func test_hero_level_from_upgrades() -> void:
	var p := _p()
	eq(MetaRules.hero_level(p.data, "guanyu"), 1, "fresh Lv.1")
	p.data["gold"] = 10000000
	for i in 3:
		p.upgrade_stat("guanyu", "atk")
		p.upgrade_stat("guanyu", "def")
		p.upgrade_stat("guanyu", "hp")
	eq(MetaRules.hero_level(p.data, "guanyu"), 4, "avg 3 -> Lv.4")
	eq(MetaRules.hero_level(p.data, "lvbu_not_owned"), 0, "not owned 0")


func test_new_account_has_no_heroes_and_four_troops() -> void:
	var p := Profile.new()
	eq((p.data["heroes"] as Dictionary).size(), 0, "no heroes")
	eq((p.data["troops"] as Dictionary).keys(), ["spear", "shield", "archer", "rider"], "4 basic troops")


func test_hero_lineup_max_three() -> void:
	var p := _p()
	p.add_hero_card("huangzhong")
	eq((p.data["lineup"] as Array).size(), 3, "auto-joins only up to 3")
	p.set_lineup(["guanyu", "zhangfei", "zhaoyun", "huangzhong"], "")
	eq((p.data["lineup"] as Array).size(), 3, "set_lineup caps at 3")
	p.set_lineup(["lvbu"], "")
	eq((p.data["lineup"] as Array).size(), 0, "not owned heroes refused")


func test_soldier_recruit_uses_gold_and_cards() -> void:
	var p := _p()
	p.data["gold"] = 100000
	var res := p.recruit_soldiers(10)
	eq(String(res["error"]), "", "ok")
	eq((res["cards"] as Array).size(), 10, "10 cards")
	eq(int(p.data["gold"]), 100000 - int(DB.meta["soldier_recruit"]["cost_ten"]), "paid gold")
	p.data["gold"] = 0
	check(String(p.recruit_soldiers(1)["error"]) != "", "needs gold")


func test_troop_star_up() -> void:
	var p := _p()
	check(p.troop_star_up("spear") != "", "needs a card")
	p.add_troop_card("spear")
	eq(p.troop_star_up("spear"), "", "1 card -> 2성")
	eq(int(p.troop("spear")["star"]), 2, "2성")
	check(MetaRules.soldier_stats(p.data, "spear")["atk"] > float(DB.soldier("spear")["atk"]), "stars raise soldier atk")
	var t := p.add_troop_card("halberd")
	check(bool(t["new"]) and p.owns_troop("halberd"), "new troop unlocked")


func test_troop_lineup_four() -> void:
	var p := _p()
	p.add_troop_card("halberd")
	p.set_troop_lineup(["halberd", "spear", "archer", "rider", "shield"])
	eq((p.data["troop_lineup"] as Array).size(), 4, "4 troops")
	p.set_troop_lineup(["heavy"])
	eq((p.data["troop_lineup"] as Array).size(), 0, "unowned troop refused")


func test_troop_upgrade_like_heroes() -> void:
	var p := _p()
	p.data["gold"] = 1000000
	var before: float = MetaRules.soldier_stats(p.data, "spear")["atk"]
	eq(p.troop_upgrade_stat("spear", "atk"), "", "upgrade ok")
	eq(int(p.troop("spear")["up"]["atk"]), 1, "Lv 1")
	check(MetaRules.soldier_stats(p.data, "spear")["atk"] > before, "atk rises")
	var cap := MetaRules.upgrade_cap(1)
	p.troop_upgrade_all("spear")
	eq(int(p.troop("spear")["up"]["def"]), cap, "capped by star")
	check(p.troop_upgrade_stat("spear", "def") != "", "needs star at cap")
	check(p.troop_upgrade_stat("heavy", "atk") != "", "not owned refused")
