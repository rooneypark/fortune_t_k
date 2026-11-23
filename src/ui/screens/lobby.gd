extends PxScreen
## 로비: 상단 HUD(초상·골드/다이아 클릭→상점·설정), 왼쪽 우편/임무, 오른쪽 가방/모집,
## 성문 앞 출정 팻말 + 군웅대전 버튼(최대 10, 2시간당 +1), 성 안뜰을 거니는 장수들.

var _walkers: Array = []
var _t := 0.0
var _sign: PxButton
var _arena_btn: PxButton
var _clouds: DrawLayer
var _rng := RandomNumberGenerator.new()


func build() -> void:
	bg = Px.tex("lobby_bg")
	Sfx.play_bgm("bgm_lobby")
	_rng.randomize()
	_clouds = DrawLayer.make(_draw_clouds)
	put(_clouds, Rect2(0, 0, 1024, 600))
	# 상단 HUD
	var face := W.portrait_frame(String(Game.profile.data["avatar"]), Vector2(148, 188), "Lv.%d" % Game.lord_lv())
	face.pressed.connect(func() -> void: Game.app.popup("profile"))
	put(face, Rect2(36, 12, 148, 188))
	put(W.gold_chip(Vector2(320, 96)), Rect2(200, 36, 320, 96))
	put(W.rice_chip(Vector2(328, 96)), Rect2(536, 36, 328, 96))
	var gear := PxButton.make("btn_settings")
	gear.pressed.connect(func() -> void: Game.app.popup("settings"))
	put(gear, Rect2(880, 32, 104, 104))
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
		put(b, Rect2(36, 232 + i * 152, 120, 128))
	# 오른쪽: 장수(장수 · 병종 도감) · 아이템(장비 가방 · 도감 · 합성) (딱 2개, 개편 §13)
	var bag := PxButton.make("btn_bag")
	bag.tooltip_text = DB.t("lobby.bag")
	bag.pressed.connect(func() -> void: Game.app.goto("heroes", {"mode": "units"}))
	put(bag, Rect2(868, 232, 120, 128))
	var items := PxButton.make("btn_recruit")
	items.tooltip_text = DB.t("lobby.recruit")
	items.pressed.connect(func() -> void: Game.app.goto("heroes", {"mode": "items"}))
	put(items, Rect2(868, 384, 120, 128))
	# 주공 전투력
	var info := DrawLayer.make(_draw_info)
	put(info, Rect2(200, 146, 680, 60))
	# 성문 두 개 (2026-11-23): 왼쪽 성문 = 출정(스테이지), 오른쪽 성문 = 군웅대전(다른 유저와 대전)
	_sign = PxButton.new()
	_sign.size = GATE
	_sign.sound = "whoosh"
	_sign.tooltip_text = DB.t("lobby.sortie")
	_sign.pressed.connect(_on_sign)
	_sign.overlay = _draw_stage_gate
	put(_sign, Rect2(92, 800, GATE.x, GATE.y), Pin.MID)
	_arena_btn = PxButton.new()
	_arena_btn.size = GATE
	_arena_btn.tooltip_text = DB.t("lobby.arena")
	_arena_btn.overlay = _draw_arena_gate
	_arena_btn.pressed.connect(func() -> void: Game.app.goto("arena"))
	put(_arena_btn, Rect2(532, 800, GATE.x, GATE.y), Pin.MID)
	# 성 안뜰을 돌아다니는 랜덤 장수 (최대 4명, 최소 표식: 별 + 레벨만)
	_spawn_walkers()
	set_process(true)
	_daily()
	if bool(params.get("tutorial", false)) and not Game.tutorial_done():
		_tutorial_gate()


func _spawn_walkers() -> void:
	_walkers.clear()
	# 대표 장수 먼저, 남는 자리는 보유 병종 (장수 없이 시작해도 성 앞이 비지 않게)
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
				W.draw_rank(ci, Rect2(Vector2.ZERO, ci.size), Game.profile.star_of(id), 0, 20.0)
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


## 성문 두 개: 같은 모양(돌 문틀 + 나무 문짝 + 깃발 간판), 색과 글자만 다르다. 임시 그림.
const GATE := Vector2(400, 432)


func _draw_stage_gate(b: PxButton, off: Vector2) -> void:
	_draw_gate(b, off, DB.t("lobby.gate_stage"), DB.t("lobby.gate_stage_sub", [Game.profile.current_stage()]), Color("#b8322a"), Px.WHITE)


func _draw_arena_gate(b: PxButton, off: Vector2) -> void:
	var n := int(Game.profile.sync_arena_entries()["entries"])
	_draw_gate(b, off, DB.t("lobby.gate_arena"), DB.t("lobby.gate_arena_sub", [n]), Color("#2f5fb0"), Px.WHITE if n > 0 else Color("#ff8a80"))


func _draw_gate(b: PxButton, off: Vector2, label: String, sub: String, flag: Color, sub_col: Color) -> void:
	var r := Rect2(off, b.size)
	# 돌 문틀
	b.draw_rect(r, Px.INK)
	b.draw_rect(r.grow(-5), Color("#857c6c"))
	var row := 0
	var y := r.position.y + 8
	while y < r.end.y - 8:
		b.draw_rect(Rect2(r.position.x + 5, y + 44, r.size.x - 10, 3), Color(0, 0, 0, 0.16))
		var x := r.position.x + 5 + (36.0 if row % 2 == 1 else 0.0)
		while x < r.end.x - 8:
			b.draw_rect(Rect2(x, y, 3, 44), Color(0, 0, 0, 0.12))
			x += 72
		y += 47
		row += 1
	# 문 (둥근 윗부분 + 나무 문짝 두 장)
	var door := Rect2(r.position.x + 56, r.position.y + 150, r.size.x - 112, r.size.y - 150)
	var cx := door.get_center().x
	var rad := door.size.x * 0.5
	b.draw_circle(Vector2(cx, door.position.y + 10), rad + 8, Px.INK)
	b.draw_rect(Rect2(door.position.x - 8, door.position.y + 10, door.size.x + 16, door.size.y - 10), Px.INK)
	b.draw_circle(Vector2(cx, door.position.y + 10), rad, Color("#6a4526"))
	b.draw_rect(Rect2(door.position.x, door.position.y + 10, door.size.x, door.size.y - 10), Color("#6a4526"))
	var px := door.position.x + 26
	while px < door.end.x - 6:
		b.draw_rect(Rect2(px, door.position.y - rad * 0.5, 3, door.size.y + rad * 0.5), Color(0, 0, 0, 0.18))
		px += 34
	b.draw_rect(Rect2(cx - 3, door.position.y - rad + 14, 6, door.size.y + rad - 14), Px.INK)
	for side in [-1.0, 1.0]:
		b.draw_circle(Vector2(cx + side * 30, door.position.y + door.size.y * 0.55), 12, Px.INK)
		b.draw_circle(Vector2(cx + side * 30, door.position.y + door.size.y * 0.55), 8, Px.GOLD)
	# 깃발 간판
	var sign := Rect2(r.position.x + 40, r.position.y + 18, r.size.x - 80, 104)
	b.draw_rect(sign, Px.INK)
	b.draw_rect(sign.grow(-4), flag)
	b.draw_rect(Rect2(sign.position.x + 4, sign.position.y + 4, sign.size.x - 8, 8), flag.lightened(0.25))
	Px.text(b, label, Rect2(sign.position.x, sign.position.y + 4, sign.size.x, 58), 44, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 7)
	Px.text(b, sub, Rect2(sign.position.x, sign.position.y + 60, sign.size.x, 38), 26, sub_col, HORIZONTAL_ALIGNMENT_CENTER, 5)


func _on_sign() -> void:
	if not Game.tutorial_done():
		Game.next_stage = {"stage": 1, "diff": 1}
		Game.app.goto("battle", {"stage": 1, "diff": 1, "tutorial": true})
		return
	# 스테이지 목록 없이 지금 스테이지의 난이도 창을 바로 띄운다.
	Game.app.popup("difficulty", {"stage": Game.profile.current_stage()})
	if not Game.profile.changed.is_connected(_sign.queue_redraw):
		Game.profile.changed.connect(_sign.queue_redraw)


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
