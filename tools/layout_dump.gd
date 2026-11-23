extends Node
## 창 없는 배치 기록: 모든 화면과 팝업을 화면 없이 열고, 그려진 자리(글자 · 그림 · 버튼 · 판)를
## 화면마다 JSON으로 남긴다. 좌표는 논리 화면 1024 x 1792 기준. 스크린샷은 찍지 않는다.
## `tools/ui_spec.py`가 이 JSON으로 UI 그림 규격서(`design/ux/UI-그림-규격.md`)를 만든다.
##
##   godot --headless --path . res://tools/layout_dump.tscn -- --no-save --save=<임시 json>
##
## 결과: design/ux/규격/raw/<번호_이름>.json

const OUT := "res://design/ux/규격/raw/"
const HERO := "guanyu"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var app: Control = (load("res://src/app/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(app)
	await _wait(0.4)
	_fill_account()
	var uid := int(Game.profile.data["treasures"][0]["uid"])
	var out := Game.profile.finish_run(1, 1, 10, true, 3, {"kills": 30, "spins": 10})
	# [파일 이름, 화면, 화면 인자, 팝업, 팝업 인자, 전투 장면]
	var shots := [
		["01_intro", "intro", {}, "", {}, ""],
		["02_lobby", "lobby", {}, "", {}, ""],
		["04_pop_difficulty", "lobby", {}, "difficulty", {"stage": 1}, ""],
		["05_battle_prep", "battle", {"stage": 1, "diff": 1, "seed": 7}, "", {}, "prep"],
		["06_battle_fight", "battle", {"stage": 1, "diff": 1, "seed": 7}, "", {}, "fight"],
		["07_pop_absorb", "battle", {"stage": 1, "diff": 1, "seed": 7}, "", {}, "absorb"],
		["08_pop_wave_clear", "battle", {"stage": 1, "diff": 1, "seed": 7}, "", {}, "wave_clear"],
		["09_pop_pause", "battle", {"stage": 1, "diff": 1, "seed": 7}, "pause", {}, "prep"],
		["10_pop_result_win", "lobby", {}, "result", {"victory": true, "stage": 1, "diff": 1, "out": out, "stats": {"kills": 30, "spins": 10, "jackpots": 1}, "mvp": HERO, "castle": 0.8, "waves": 10}, ""],
		["11_pop_result_lose", "lobby", {}, "result", {"victory": false, "stage": 1, "diff": 2, "stats": {"kills": 3, "spins": 2, "jackpots": 0}, "mvp": "", "castle": 0.0, "waves": 3, "can_continue": true}, ""],
		["12_units_heroes", "heroes", {"mode": "units", "tab": 0}, "", {}, ""],
		["13_units_soldiers", "heroes", {"mode": "units", "tab": 1}, "", {}, ""],
		["14_items", "heroes", {"mode": "items"}, "", {}, ""],
		["15_hero_growth", "hero", {"id": HERO, "tab": 0}, "", {}, ""],
		["16_hero_traits", "hero", {"id": HERO, "tab": 1}, "", {}, ""],
		["17_hero_gear", "hero", {"id": HERO, "tab": 2}, "", {}, ""],
		["18_hero_unowned", "hero", {"id": "lvbu", "tab": 0}, "", {}, ""],
		["19_troop_growth", "troop", {"id": "spear", "tab": 0}, "", {}, ""],
		["20_troop_gear", "troop", {"id": "spear", "tab": 2}, "", {}, ""],
		["21_pop_treasure", "heroes", {"mode": "items"}, "treasure", {"uid": uid, "hero": HERO}, ""],
		["22_pop_synth", "heroes", {"mode": "items"}, "synth", {}, ""],
		["23_shop_rec", "shop", {"tab": 0}, "", {}, ""],
		["24_shop_gold", "shop", {"tab": 1}, "", {}, ""],
		["25_shop_rice", "shop", {"tab": 2}, "", {}, ""],
		["26_shop_pack", "shop", {"tab": 3}, "", {}, ""],
		["27_arena", "arena", {}, "", {}, ""],
		["28_pop_arena_shop", "arena", {}, "arena_shop", {}, ""],
		["29_pop_settings", "lobby", {}, "settings", {}, ""],
		["30_pop_mail", "lobby", {}, "mail", {}, ""],
		["31_pop_missions", "lobby", {}, "missions", {}, ""],
		["32_pop_profile", "lobby", {}, "profile", {}, ""],
		["33_pop_odds", "lobby", {}, "odds", {}, ""],
		["34_pop_confirm", "lobby", {}, "confirm", {"title": "군량 채우기", "text": "금 9,000으로 군량을 가득 채울까요?", "ok": "구매"}, ""],
		["35_pop_purchase", "shop", {"tab": 1}, "purchase", {"id": "g60", "name": "금 2,000", "desc": "금 2,000", "price": 1200}, ""],
		["36_pop_reward", "lobby", {}, "reward", {"title": "보상", "reward": {"gold": 5000, "rice": 10}, "items": [{"type": "material", "slot": "weapon", "rarity": "rare"}, {"type": "treasure", "tid": String(Game.profile.data["treasures"][0]["tid"])}]}, ""],
	]
	for s: Array in shots:
		Game.app.goto(String(s[1]), s[2], false)
		await _wait(0.5)
		if String(s[5]) != "":
			Game.settings()["slot_speed"] = 2
			Game.app.current.call("demo", String(s[5]))
			await _wait(1.2)
		if String(s[3]) != "":
			Game.app.popup(String(s[3]), s[4])
			await _wait(0.5)
		await _record(ProjectSettings.globalize_path(OUT + String(s[0]) + ".json"))
		for c in Game.app.popup_layer.get_children():
			c.queue_free()
		await _wait(0.1)
	print("layout_dump: done, %d screens" % shots.size())
	get_tree().quit(0)


## 점검용 계정: 튜토리얼 끝, 장수 · 병종 대부분, 장비 · 재료 조금 (smoke.gd와 같은 식).
func _fill_account() -> void:
	var p := Game.profile
	p.data["tutorial"] = {"done": true}
	p.data["gold"] = 123456
	p.data["honor"] = 2000
	for id: String in DB.hero_ids():
		if id != "lvbu":
			p.add_hero_card(id)
	for id: String in DB.soldier_ids():
		if id != "medic":
			p.add_troop_card(id)
	for slot in ["weapon", "armor", "charm"]:
		for r in ["common", "rare", "epic", "legend"]:
			p.add_material(slot, r, 4)
			p.craft(slot, r)
	p.auto_equip(HERO)
	p.auto_equip("spear")
	p.set_trait(HERO, "rapid")
	p.add_star_xp("spear", 7)


## App._record_layout과 같은 일을 하되, 창이 없어도 멈추지 않게 그리기 완료 신호 대신
## 프레임 두 번을 기다린다.
func _record(path: String) -> void:
	var app: Node = Game.app
	Px.records.clear()
	Px.recording = true
	app.call("_redraw_all", app)
	await get_tree().process_frame
	await get_tree().process_frame
	Px.recording = false
	app.call("_record_areas", app)
	var seen := {}
	var out: Array = []
	for r: Dictionary in Px.records:
		var key := "%s|%d|%d|%d|%d|%s" % [r["kind"], r["x"], r["y"], r["w"], r["h"], r["label"]]
		if seen.has(key):
			continue
		seen[key] = true
		out.append(r)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"canvas": [(app as Control).size.x, (app as Control).size.y], "items": out}, " "))
	var kinds := {}
	for r: Dictionary in out:
		kinds[r["kind"]] = int(kinds.get(r["kind"], 0)) + 1
	print("layout saved: ", path.get_file(), " ", kinds)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
