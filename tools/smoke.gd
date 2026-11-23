extends Node
## 창 없는 화면 점검 (smoke test): 게임을 화면 없이 띄워서 모든 화면과 팝업을 한 번씩
## 열어 보고, 전투를 몇 웨이브 돌린다. 실행 중 스크립트 오류가 나면 "SCRIPT ERROR"로
## 찍히므로 그 줄 수를 세면 된다. 저장 파일은 건드리지 않는다 (--no-save).
##
##   godot --headless --path . res://tools/smoke.tscn -- --no-save --save=<임시 json>
##
## 화면이 그려지는 모양(배치, 겹침)은 확인하지 못한다. 눈으로 봐야 하는 것은 따로 본다.

const HERO := "guanyu"
var _steps := 0


func _ready() -> void:
	var app: Control = (load("res://src/app/main.tscn") as PackedScene).instantiate()
	get_tree().root.add_child.call_deferred(app)
	await _wait(0.4)
	_fill_account()
	# ---- 화면
	for route: Array in [
		["lobby", {}],
		["heroes", {"mode": "units", "tab": 0}], ["heroes", {"mode": "units", "tab": 1}], ["heroes", {"mode": "items"}],
		["hero", {"id": HERO, "tab": 0}], ["hero", {"id": HERO, "tab": 1}], ["hero", {"id": HERO, "tab": 2}],
		["hero", {"id": "lvbu", "tab": 0}],
		["troop", {"id": "spear", "tab": 0}], ["troop", {"id": "spear", "tab": 1}], ["troop", {"id": "spear", "tab": 2}],
		["troop", {"id": "medic", "tab": 0}],
		["shop", {"tab": 0}], ["shop", {"tab": 1}], ["shop", {"tab": 2}], ["arena", {}], ["intro", {}], ["lobby", {}],
	]:
		_say("screen %s %s" % [route[0], route[1]])
		Game.app.goto(String(route[0]), route[1], false)
		await _wait(0.35)
	# ---- 팝업 (로비 위에서)
	var uid := int(Game.profile.data["treasures"][0]["uid"])
	var out := Game.profile.finish_run(1, 1, 10, true, 3, {"kills": 30, "spins": 12})
	for pop: Array in [
		["settings", {}], ["mail", {}], ["missions", {}], ["missions", {"tab": 1}], ["profile", {}], ["arena_shop", {}],
		["odds", {}],
		["synth", {}], ["treasure", {"uid": uid}], ["treasure", {"uid": uid, "hero": HERO}], ["treasure", {"uid": uid, "hero": "spear"}],
		["difficulty", {"stage": 1}], ["difficulty", {"stage": 2}],
		["confirm", {"title": "확인", "text": "점검", "ok": "확인"}],
		["purchase", {"id": "monthly", "name": "월정액", "desc": "점검", "price": 9900}],
		["reward", {"title": "보상", "reward": {"gold": 100, "rice": 5, "diamond": 5, "tickets": 1, "mats": 2}, "items": [{"type": "material", "slot": "weapon", "rarity": "rare"}, {"type": "treasure", "tid": String(Game.profile.data["treasures"][0]["tid"])}, {"type": "hero", "id": HERO}]}],
		["result", {"victory": true, "stage": 1, "diff": 1, "out": out, "stats": {"kills": 30, "spins": 12, "jackpots": 1}, "mvp": HERO, "castle": 0.8, "waves": 10}],
		["result", {"victory": false, "stage": 1, "diff": 2, "stats": {"kills": 3, "spins": 2, "jackpots": 0}, "mvp": "", "castle": 0.0, "waves": 3, "can_continue": true}],
	]:
		_say("popup %s %s" % [pop[0], (pop[1] as Dictionary).keys()])
		var p: PxPopup = Game.app.popup(String(pop[0]), pop[1])
		await _wait(0.3)
		if is_instance_valid(p):
			p.queue_free()
		await _wait(0.05)
	# ---- 합성: 재료 -> 장비, 장비 3 -> 윗등급
	_say("synth craft / fuse")
	var syn: PxPopup = Game.app.popup("synth", {})
	await _wait(0.2)
	syn.call("_done", Game.profile.craft("weapon", "rare"))
	await _wait(0.2)
	syn.call("_done", Game.profile.fuse("common"))
	await _wait(0.2)
	for c in Game.app.popup_layer.get_children():
		c.queue_free()
	await _wait(0.1)
	# ---- 전투: 준비 장면, 흡수 창(성급 / 속성), 웨이브, 보스
	for d in [1, 3]:
		_say("battle stage 1 diff %d: prep" % d)
		Game.app.goto("battle", {"stage": 1, "diff": d, "seed": 7}, false)
		await _wait(0.5)
		var b: Node = Game.app.current
		Game.settings()["slot_speed"] = 2
		b.call("demo", "prep")
		await _wait(0.4)
		await _absorb_both(b)
		_say("battle: 3 waves at speed 3")
		for _w in 3:
			Game.profile.add_rice(20)
			for _s in 4:
				b.call("_spin")
				await _wait(0.15)
			var pulls: Array = b.get("run").slot.nudge_wins()
			if not pulls.is_empty():
				b.call("_on_reel_tapped", int(pulls[0][0]), int(pulls[0][1]))
			await _wait(0.15)
			b.call("_advisor")
			b.call("_start_wave")
			await _wait(0.1)
			var field: BattleField = b.get("field")
			field.speed = 3.0
			var t := 0.0
			while String(b.get("state")) == "fight" and t < 60.0:
				await _wait(0.5)
				t += 0.5
			for c in Game.app.popup_layer.get_children():
				c.queue_free()
			await _wait(0.1)
			if String(b.get("state")) == "over":
				break
		_say("battle: state %s, wave %d, field %d, castle %d" % [String(b.get("state")), int(b.get("run").wave), (b.get("run").field as Array).size(), int(b.get("run").castle_hp)])
	# ---- 군량 충전 · 상점 구매 (가상 결제)
	_say("rice refill / shop purchase")
	Game.profile.data["rice"]["n"] = 3
	W.ask_rice()
	await _wait(0.2)
	var ask: PxPopup = Game.app.top_popup()
	if ask != null:
		ask.emit_signal("confirmed")
		await _wait(0.1)
	for c in Game.app.popup_layer.get_children():
		c.queue_free()
	Game.profile.purchase("g60")
	Game.profile.purchase("p_start")
	Game.profile.purchase("monthly")
	await _wait(0.1)
	_say("battle: boss wave")
	Game.app.goto("battle", {"stage": 2, "diff": 1, "seed": 3}, false)
	await _wait(0.5)
	Game.settings()["slot_speed"] = 2
	Game.app.current.call("demo", "boss")
	await _wait(0.6)
	Game.app.goto("lobby", {}, false)
	await _wait(0.4)
	print("smoke: done, %d steps" % _steps)
	get_tree().quit(0)


## 흡수 창을 두 가지로 연다: 같은 병종(성급 경험)과 다른 병종(속성 선택), 둘 다 실제로 흡수한다.
func _absorb_both(b: Node) -> void:
	var run: RunState = b.get("run")
	run.field_cap = 12
	for id in ["spear", "spear", "archer", HERO, HERO]:
		run.recruit(id)
	(b.get("field") as BattleField).sync()
	var by := {}
	for u: UnitState in run.field:
		if not by.has(u.id):
			by[u.id] = []
		by[u.id].append(u)
	for pair: Array in [["spear", "spear"], [HERO, HERO], ["archer", HERO], ["spear", HERO]]:
		var food_list: Array = by.get(pair[0], [])
		var target_list: Array = by.get(pair[1], [])
		var food: UnitState = null
		for u: UnitState in food_list:
			if run.field.has(u) and (target_list.is_empty() or u != target_list[0]):
				food = u
		if food == null or target_list.is_empty() or not run.field.has(target_list[0]):
			continue
		var chk := run.absorb_check(food, target_list[0])
		_say("absorb %s -> %s: %s" % [pair[0], pair[1], String(chk.get("mode", chk.get("reason", "?")))])
		b.call("_open_absorb", food, target_list[0])
		await _wait(0.25)
		var pop: PxPopup = Game.app.top_popup()
		if pop == null:
			continue
		if String(pop.get("mode")) == "trait":
			var cards: Array = pop.get("_cards")
			(cards[0] as PxButton).pressed.emit()
			await _wait(0.05)
		(pop.get("_ok") as PxButton).pressed.emit()
		await _wait(0.3)
		for c in Game.app.popup_layer.get_children():
			c.queue_free()
		await _wait(0.05)


## 점검용 계정: 튜토리얼 끝, 장수 · 병종 전부, 장비 · 재료 조금.
func _fill_account() -> void:
	var p := Game.profile
	p.data["tutorial"] = {"done": true}
	p.data["gold"] = 500000
	p.data["honor"] = 2000
	p.add_rice(100)
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
	for i in 3:
		p.add_material("armor", "common", 3)
		p.craft("armor", "common")
	p.auto_equip(HERO)
	p.auto_equip("spear")
	p.set_trait(HERO, "rapid")
	p.add_star_xp("spear", 7)


func _say(s: String) -> void:
	_steps += 1
	print("smoke: ", s)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
