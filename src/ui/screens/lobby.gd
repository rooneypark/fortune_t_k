extends PxScreen
## 로비: 상단 HUD(초상·골드/다이아 클릭→상점·설정), 왼쪽 우편/임무, 오른쪽 가방/모집,
## 성문 앞 출정 팻말 + 군웅대전 버튼(최대 10, 2시간당 +1), 성 안뜰을 거니는 장수들.

var _walkers: Array = []
var _t := 0.0
var _sign: PxButton
var _arena_btn: PxButton
var _btn_recruit: PxButton
var _clouds: DrawLayer
var _rng := RandomNumberGenerator.new()


func build() -> void:
	bg = Px.tex("lobby_bg")
	Sfx.play_bgm("bgm_lobby")
	_rng.randomize()
	_clouds = DrawLayer.make(_draw_clouds)
	put(_clouds, Rect2(0, 0, 1024, 600))
	# 상단 HUD
	var face := W.portrait_frame(String(Game.profile.data["avatar"]), Vector2(146, 185), "Lv.%d" % Game.lord_lv())
	face.pressed.connect(func() -> void: Game.app.popup("profile"))
	put(face, Rect2(38, 12, 146, 185))
	put(W.gold_chip(Vector2(321, 98)), Rect2(200, 36, 321, 98))
	put(W.diamond_chip(Vector2(326, 98)), Rect2(536, 36, 326, 98))
	var gear := PxButton.make("btn_settings")
	gear.pressed.connect(func() -> void: Game.app.popup("settings"))
	put(gear, Rect2(878, 36, 108, 102))
	# 왼쪽: 우편 · 임무
	var left_side := [["btn_mail", "mail", "lobby.mail"], ["btn_mission", "missions", "lobby.missions"]]
	for i in left_side.size():
		var it: Array = left_side[i]
		var b := PxButton.make(String(it[0]))
		var key := String(it[1])
		b.badge = _badge_for(key)
		b.tooltip_text = DB.t(String(it[2]))
		b.pressed.connect(func() -> void:
			var p := Game.app.popup(key)
			p.closed.connect(_refresh_badges))
		b.set_meta("route", key)
		put(b, Rect2(36, 234 + i * 151, 120, 130))
	# 오른쪽: 가방 · 모집 (딱 2개)
	var bag := PxButton.make("btn_bag")
	bag.tooltip_text = DB.t("lobby.bag")
	bag.pressed.connect(func() -> void: Game.app.goto("heroes"))
	put(bag, Rect2(868, 234, 120, 130))
	_btn_recruit = PxButton.make("btn_recruit")
	_btn_recruit.tooltip_text = DB.t("lobby.recruit")
	_btn_recruit.pressed.connect(func() -> void: Game.app.goto("recruit"))
	put(_btn_recruit, Rect2(868, 385, 120, 130))
	# 주공 전투력
	var info := DrawLayer.make(_draw_info)
	put(info, Rect2(200, 146, 680, 60))
	# 성문 앞 출정 팻말 + 군웅대전 버튼
	_sign = PxButton.make("sign_battle")
	_sign.sound = "whoosh"
	_sign.pressed.connect(_on_sign)
	_sign.overlay = _draw_battle_sign
	put(_sign, Rect2(340, 1068, SIGN.x, SIGN.y), Pin.MID)
	_arena_btn = PxButton.make("btn_arena")
	_arena_btn.tooltip_text = DB.t("lobby.arena")
	_arena_btn.overlay = _draw_arena_btn
	_arena_btn.pressed.connect(func() -> void: Game.app.goto("arena"))
	put(_arena_btn, Rect2(534, 1068, SIGN.x, SIGN.y), Pin.MID)
	# 성 안뜰을 돌아다니는 랜덤 장수 (최대 4명, 최소 표식: 별 + 레벨만)
	_spawn_walkers()
	set_process(true)
	_daily()
	if bool(params.get("tutorial", false)) and not Game.tutorial_done():
		_tutorial_gate()
	elif bool(params.get("tutorial_recruit", false)):
		_tutorial_recruit()


func _spawn_walkers() -> void:
	_walkers.clear()
	# 편성 장수 먼저, 남는 자리는 편성 병종 (장수 없이 시작해도 성 앞이 비지 않게)
	var picks: Array = Game.lineup()
	for t: String in Game.sortie_troops():
		if picks.size() < 4:
			picks.append(t)
	var n := mini(4, picks.size())
	var starts := [Vector2(210, 1430), Vector2(410, 1560), Vector2(630, 1420), Vector2(820, 1550)]
	for i in n:
		var id := String(picks[i])
		var pos: Vector2 = starts[i]
		var u := UnitView.make(id, 150.0)
		u.flip = i >= 2
		put(u, Rect2(pos.x, pos.y, 0, 0), Pin.MID)
		var tag := DrawLayer.make(func(ci: Control) -> void:
			if DB.is_hero(id):
				W.draw_rank(ci, Rect2(Vector2.ZERO, ci.size), Game.profile.star_of(id), MetaRules.hero_level(Game.profile.data, id), 20.0)
			else:
				W.draw_rank(ci, Rect2(Vector2.ZERO, ci.size), int(Game.profile.troop(id).get("star", 1)), 0, 20.0))
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		put(tag, Rect2(pos.x - 70, pos.y + 8, 140, 36), Pin.MID)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.pressed.connect(func() -> void:
			Sfx.play("click")
			if DB.is_hero(id):
				Game.app.goto("hero", {"id": id, "from": "lobby"})
			else:
				Game.app.goto("heroes", {"tab": 1}))
		put(hit, Rect2(pos.x - 65, pos.y - 150, 130, 195), Pin.MID)
		_walkers.append({
			"id": id, "u": u, "tag": tag, "hit": hit,
			"pos": pos, "target": _pick_walk_target(pos, -1),
			"wait": _rng.randf_range(0.4, 2.0), "speed": _rng.randf_range(44.0, 68.0),
		})


func _pick_walk_target(near: Vector2, skip_idx: int) -> Vector2:
	for _try in 16:
		var cand := Vector2(
			clampf(near.x + _rng.randf_range(-240.0, 240.0), 140.0, 884.0),
			clampf(near.y + _rng.randf_range(-130.0, 130.0), 1350.0, 1660.0))
		var ok := true
		for j in _walkers.size():
			if j == skip_idx:
				continue
			var other: Dictionary = _walkers[j]
			if cand.distance_to(other["pos"]) < 120.0 or cand.distance_to(other["target"]) < 120.0:
				ok = false
				break
		if ok:
			return cand
	return Vector2(_rng.randf_range(160.0, 864.0), _rng.randf_range(1360.0, 1650.0))


func _step_walkers(dt: float) -> void:
	var mid_dy := dy(Pin.MID)
	for i in _walkers.size():
		var w: Dictionary = _walkers[i]
		var u: UnitView = w["u"]
		var tag: DrawLayer = w["tag"]
		var hit: Button = w["hit"]
		if not is_instance_valid(u):
			continue
		var wait := float(w["wait"])
		var pos: Vector2 = w["pos"]
		if wait > 0.0:
			wait -= dt
			w["wait"] = wait
			u.action = "idle"
			if wait <= 0.0:
				w["target"] = _pick_walk_target(pos, i)
		else:
			var tgt: Vector2 = w["target"]
			var diff := tgt - pos
			if diff.length() < 10.0:
				w["wait"] = _rng.randf_range(1.4, 3.2)
				u.action = "idle"
			else:
				var dir := diff.normalized()
				# gentle separation from other walkers
				for j in _walkers.size():
					if j == i:
						continue
					var o: Dictionary = _walkers[j]
					var away: Vector2 = pos - (o["pos"] as Vector2)
					var d := away.length()
					if d > 1.0 and d < 105.0:
						dir = (dir + away.normalized() * 0.9).normalized()
				pos += dir * float(w["speed"]) * dt
				pos.x = clampf(pos.x, 140.0, 884.0)
				pos.y = clampf(pos.y, 1350.0, 1660.0)
				w["pos"] = pos
				u.action = "walk"
				if absf(dir.x) > 0.08:
					u.flip = dir.x < 0.0
		u.position = Vector2(pos.x + dx(), pos.y + mid_dy)
		u.z_index = clampi(int(pos.y) - 1300, 0, 400)
		tag.position = Vector2(pos.x - 70.0 + dx(), pos.y + 8.0 + mid_dy)
		tag.z_index = clampi(int(pos.y) - 1300, 0, 400) + 1
		hit.position = Vector2(pos.x - 65.0 + dx(), pos.y - 150.0 + mid_dy)
		hit.z_index = clampi(int(pos.y) - 1300, 0, 400) + 2


## 출정 · 군웅대전 팻말: 같은 팻말(나무판 + 기둥), 왼쪽 아이콘 + 오른쪽 숫자만.
const SIGN := Vector2(150, 147)
const SIGN_TEXT := Rect2(80, 14, 56, 76)


func _draw_battle_sign(b: PxButton, off: Vector2) -> void:
	var last := String(Game.profile.data["progress"]["last"]).split("-")
	var stg := DB.stage_index(int(last[0]), int(last[1]))
	Px.text(b, str(stg), Rect2(SIGN_TEXT.position + off, SIGN_TEXT.size), 40, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 7)


func _draw_arena_btn(b: PxButton, off: Vector2) -> void:
	var st := Game.profile.sync_arena_entries()
	var n := int(st["entries"])
	var col := Px.WHITE if n > 0 else Color("#ff8a80")
	Px.text(b, str(n), Rect2(SIGN_TEXT.position + off, SIGN_TEXT.size), 40, col, HORIZONTAL_ALIGNMENT_CENTER, 7)


func _on_sign() -> void:
	if not Game.tutorial_done():
		Game.next_stage = {"chapter": 1, "stage": 1}
		Game.app.goto("battle", {"chapter": 1, "stage": 1, "tutorial": true})
		return
	Game.app.goto("stage")


func _badge_for(key: String) -> bool:
	match key:
		"mail":
			return Game.profile.unclaimed_mail() > 0
		"missions":
			return Game.profile.claimable_missions() > 0
	return false


func _refresh_badges() -> void:
	for c in get_children():
		if c is PxButton and c.has_meta("route"):
			(c as PxButton).badge = _badge_for(String(c.get_meta("route")))


func _daily() -> void:
	if not Game.tutorial_done():
		return
	var parts: Array = []
	var m := Game.profile.claim_monthly()
	if m > 0:
		parts.append(DB.t("lobby.monthly", [m]))
	var a := Game.profile.claim_attendance()
	if not a.is_empty():
		var p := Game.app.popup("reward", {"title": DB.t("lobby.attendance", [a["day"]]), "reward": a["reward"]})
		p.closed.connect(_refresh_badges)
	if not parts.is_empty():
		toast(" · ".join(parts))


func _tutorial_gate() -> void:
	var g := Guide.show_at(Game.app.overlay_layer, Rect2(_sign.position, _sign.size).grow(10), DB.t("tut.gate"))
	g.advanced.connect(g.queue_free)


func _tutorial_recruit() -> void:
	var r := Rect2(_btn_recruit.position, _btn_recruit.size).grow(8)
	var g := Guide.show_at(Game.app.overlay_layer, r, DB.t("tut.recruit"))
	g.advanced.connect(g.queue_free)


func _process(delta: float) -> void:
	_t += delta
	_clouds.queue_redraw()
	if is_instance_valid(_arena_btn):
		_arena_btn.queue_redraw()
	_step_walkers(delta)
	for c in get_children():
		if c is DrawLayer and c != _clouds:
			c.queue_redraw()


func _draw_clouds(ci: Control) -> void:
	for i in 4:
		var x := fmod(i * 330.0 + _t * (8.0 + i * 3.0), 1400.0) - 200.0
		var y := 260.0 + i * 70.0
		var c := Color(1, 1, 1, 0.18)
		ci.draw_rect(Rect2(x, y, 160, 26), c)
		ci.draw_rect(Rect2(x + 30, y - 18, 90, 20), c)


func _draw_info(ci: Control) -> void:
	var total := 0
	for id: String in Game.lineup():
		total += MetaRules.hero_power(Game.profile.data, id)
	Px.fit(ci, Px.tex("icon_sword"), Rect2(0, 12, 36, 36))
	Px.text(ci, Px.num(total), Rect2(44, 0, 300, 60), 32, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)


func back() -> bool:
	Game.app.confirm_quit()
	return true
