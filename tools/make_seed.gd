extends SceneTree
## Builds a mid-game profile for screenshots: tutorial done, chapter 1 partly
## cleared, more heroes, treasures, mail. Run:
## godot --headless --path . -s res://tools/make_seed.gd -- /tmp/f3k_shot_seed.json


func _init() -> void:
	var out := "/tmp/f3k_shot_seed.json"
	for a in OS.get_cmdline_user_args():
		out = a
	var p := Profile.new()
	p.rng.seed = 7
	var d := p.data
	d["tutorial"]["done"] = true
	d["tutorial"]["recruit"] = true
	d["lord_lv"] = 12
	d["lord_exp"] = 540
	d["gold"] = 284500
	d["diamond"] = 3260
	d["tickets"] = 4
	d["pity"]["normal"] = 37
	d["pity"]["box"] = 11
	for id in ["guanyu", "zhangfei", "zhaoyun", "lvbu", "zhouyu", "diaochan", "ganning", "xuchu", "taishici"]:
		p.add_hero_card(id)
	for id in ["halberd", "crossbow", "fire"]:
		p.add_troop_card(id)
	for id: String in d["troops"]:
		d["troops"][id]["cards"] = 1 + id.length() % 3
	for id: String in d["heroes"]:
		var h: Dictionary = d["heroes"][id]
		h["cards"] = 3 + (id.length() % 5)
		h["up"] = {"atk": 4 + id.length() % 6, "def": 3 + id.length() % 4, "hp": 4 + id.length() % 5}
	d["heroes"]["guanyu"]["star"] = 4
	d["heroes"]["zhaoyun"]["star"] = 3
	for i in 14:
		p.open_box_free()
	for it: Dictionary in d["treasures"]:
		it["lv"] = int(it["uid"]) % 9
	p.auto_equip("guanyu")
	p.auto_equip("zhangfei")
	for s in range(1, 6):
		d["progress"]["cleared"]["1-%d" % s] = 3 if s < 4 else 2
	d["progress"]["last"] = "1-5"
	d["stats"] = {"runs": 23, "victories": 17, "best_stage": 5, "jackpots": 41, "kills": 2380}
	p.refresh_periods()
	d["missions"]["daily"] = {"runs": 2, "spins": 20, "upgrades": 3}
	d["attendance"]["last"] = Profile._date_key(int(Time.get_unix_time_from_system()))
	d["attendance"]["count"] = 3
	p.seed_welcome_mail()
	p.save_to(out)
	print("seed saved: ", out)
	quit()
