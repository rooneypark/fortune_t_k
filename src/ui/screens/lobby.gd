extends PxScreen
## 로비 (2026-11-24 2차, 민수 님 확정 그림): 배경 한 장(lobby_bg: 하늘 · 삼국지 성루 · 성벽 · 빈 현판 · 성문, 출정 때 열림),
## 상단 HUD(초상 · 금/군량 · 설정), 오른쪽 아래로 편지 · 임무(동그란 버튼), 성문 위 현판에 스테이지 이름,
## 광장에 모인 내 부대, 아래 탭 5칸(아이콘만): 장수 · 가방 · [출정: 가운데 금빛, 위로 솟음] · 쟁패 · 상점.
## 부품 그림(lobby_*.png)과 자리(assets/ui/lobby_layout.json)는 tools/import_lobby2_ui.py 가 만든다.
## 탭 줄은 9-slice(nine.json). 탭은 위에 아이콘, 아래 글자 띠에 이름 (2026-11-24 3차: 글자가 없으니 밋밋해서 다시 넣음).

var _walkers: Array = []
var _t := 0.0
var _sign: PxButton
var _arena_btn: PxButton
## 성문 앞 부대 자리 (가운데 정렬, 최대 4줄 x 9명) — 광장(성문 아래 y 875 ~ 출정 탭 위 1520)
const ARMY_TOP := 1080.0
const ARMY_ROW := 72.0
const ARMY_COL := 96.0
const ARMY_COLS := 9
const ARMY_MAX := 36
var _rng := RandomNumberGenerator.new()
var _heal_t := 0.0
var _tut_guide: Node
## 하단 탭 버튼 (열린 화면에 맞춰 금테로 표시)
var _tabs := {}
var _heal_fx: Array = []
var _heal_layer: DrawLayer
## 출정 연출 (2026-11-23): 성문이 열리고(0→1) 부대가 문 안으로 행군한 뒤 다음 화면으로.
var _door_open := 0.0
var _marching := false
## 열리는 성문 번호 (성문은 하나라 늘 0)
var _march_gate := 0
var _door_layers: Array = []
## 배경 그림의 성문 나무 문짝 자리 (tools/import_lobby2_ui.py 의 GATE 와 같게). 성문은 가운데 하나.
const DOORS := [Rect2(377, 565, 271, 309)]
const DOOR_ART := ["gate1"]
const MARCH_TIME := 1.8


func build() -> void:
	bg = Px.tex("lobby_bg")
	Sfx.play_bgm("bgm_lobby")
	_rng.randomize()
	# 상단 HUD — 전부 완성 화면의 통째 그림. 자리는 그림을 떼어 낸 자리 그대로 (lobby_layout.json).
	var face := _part("lobby_portrait")
	var avatar := Art.avatar(String(Art.of_unit(String(Game.profile.data["avatar"]))["art"]))
	face.overlay = func(btn: PxButton, off: Vector2) -> void:
		# 액자 속 그림 칸에 내 대표 장수, 아래 어두운 띠에 레벨
		var pic := Rect2(off + Vector2(btn.size.x * 0.13, btn.size.y * 0.1), Vector2(btn.size.x * 0.74, btn.size.y * 0.64))
		Px.fit(btn, avatar, pic)
		Px.text(btn, "Lv.%d" % Game.lord_lv(), Rect2(off + Vector2(btn.size.x * 0.13, btn.size.y * 0.77), Vector2(btn.size.x * 0.74, btn.size.y * 0.15)), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4)
	face.pressed.connect(func() -> void: Game.app.popup("profile"))
	put(face, _rect("lobby_portrait"))
	# 금 · 군량 칩: 숫자 칸(아이콘과 "+" 사이)에 숫자만 쓴다. 칩을 누르면 상점 / 군량 채우기.
	var gold := _part("lobby_chip_gold")
	_chip_text(gold, func() -> String: return Px.num(int(Game.profile.data["gold"])))
	gold.pressed.connect(func() -> void: Game.app.goto("shop", {"tab": 1}))
	put(gold, _rect("lobby_chip_gold"))
	var rice := _part("lobby_chip_rice")
	_chip_text(rice, func() -> String: return "%d/%d" % [Game.profile.rice_now(), int(DB.rules["rice_max"])])
	rice.pressed.connect(W.ask_rice)
	put(rice, _rect("lobby_chip_rice"))
	var gear := _part("lobby_btn_settings")
	gear.pressed.connect(func() -> void: Game.app.popup("settings"))
	put(gear, _rect("lobby_btn_settings"))
	# 오른쪽: 편지 · 임무 (설정 아래 동그란 버튼)
	var side := [["lobby_btn_mail", "mail", "lobby.mail"], ["lobby_btn_mission", "missions", "lobby.missions"]]
	for i in side.size():
		var it: Array = side[i]
		var b := _part(String(it[0]))
		var key := String(it[1])
		b.badge = _badge_for(key)
		b.tooltip_text = DB.t(String(it[2]))
		b.pressed.connect(func() -> void:
			var p := Game.app.popup(key)
			p.closed.connect(_refresh_badges))
		b.set_meta("route", key)
		put(b, _rect(String(it[0])))
	# 성문 위 현판: 스테이지 이름 (퇴각해 둔 전투가 있으면 그 웨이브)
	var plaque := DrawLayer.make(_draw_plaque)
	plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	put(plaque, _rect("lobby_plaque"), Pin.MID)
	# 주공 전투력
	var info := DrawLayer.make(_draw_info)
	put(info, Rect2(200, 150, 680, 60))
	# 성문 (열림 연출용 문짝 두 장 + 문 안쪽 어둠). 닫혀 있을 때는 배경 그림 그대로.
	for gi in DOORS.size():
		var g := gi
		var dl := DrawLayer.make(func(ci: Control) -> void: _draw_door(ci, g))
		dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		put(dl, DOORS[gi], Pin.MID)
		_door_layers.append(dl)
	# 아래 탭 줄 바탕 + 5칸 (시안에서 떼어 낸 그림): 장수 · 가방 · 출정(가운데, 주홍 · 위로 솟음) · 쟁패 · 상점. 위 아이콘 + 아래 글자.
	var bar := DrawLayer.make(func(ci: Control) -> void: ci.draw_texture_rect(Px.tex("lobby_tab_bar"), Rect2(Vector2.ZERO, ci.size), false))
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	put(bar, _rect("lobby_tab_bar"), Pin.BOTTOM)
	var tabs := [
		["heroes", "lobby_tab_hero", DB.t("lobby.bag")],
		["items", "lobby_tab_bag", DB.t("lobby.recruit")],
		["stage", "lobby_tab_stage", DB.t("lobby.btn_stage")],
		["arena", "lobby_tab_arena", DB.t("lobby.btn_arena")],
		["shop", "lobby_tab_shop", DB.t("lobby.shop")],
	]
	for tb: Array in tabs:
		var key := String(tb[0])
		var r := _rect(String(tb[1]))
		var big := key == "stage"
		# 탭 그림은 시안에서 통째로 떼어 낸 것 (아이콘 · 빈 글자 띠 포함). 게임은 글자 띠에 이름만 쓴다.
		var b := PxButton.make(String(tb[1]), false, r.size)
		var label := String(tb[2])
		var bd := _rect("tab_band_stage" if big else "tab_band")
		var band := Rect2(bd.position.x, bd.position.y, r.size.x - bd.position.x * 2, bd.size.y)
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, label, Rect2(band.position + off, band.size), 32 if big else 28, Px.GOLD if big else Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 5)
		b.tooltip_text = label
		put(b, r, Pin.BOTTOM)
		match key:
			"heroes":
				b.pressed.connect(func() -> void: Game.app.goto("heroes", {"mode": "units"}))
			"items":
				b.pressed.connect(func() -> void: Game.app.goto("heroes", {"mode": "items"}))
			"shop":
				b.pressed.connect(func() -> void: Game.app.goto("shop", {"tab": 0}))
			"stage":
				# 출정: 행동 버튼. 누르면 난이도 창 → 성문이 열리고 부대가 나간다.
				_sign = b
				b.sound = "drum"
				b.pressed.connect(_on_sign)
			"arena":
				# 쟁패 (준비 중 — 알림만). 생기면: 현판에 순위 → 성문이 열리고 쟁패로.
				_arena_btn = b
				b.pressed.connect(func() -> void: toast(DB.t("lobby.arena_soon")))
		if key != "stage" and key != "arena":
			_tabs[key] = b
	# 성문 앞에 모인 내 부대 (의원이 있으면 로비에서 조금씩 치료)
	_spawn_walkers()
	_heal_layer = DrawLayer.make(_draw_heal_fx)
	_heal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heal_layer.z_index = 500
	put(_heal_layer, Rect2(0, 0, 1024, 1792), Pin.MID)
	set_process(true)
	_daily()
	if bool(params.get("tutorial", false)) and not Game.tutorial_done():
		_tutorial_gate()
	# 결과 창의 "다음 스테이지": 로비로 돌아와 그 스테이지의 난이도를 묻는다 (2026-11-24)
	elif int(params.get("ask_diff", 0)) > 0:
		Game.app.popup.call_deferred("difficulty", {"stage": int(params["ask_diff"])})


func _spawn_walkers() -> void:
	_walkers.clear()
	# 내 부대만 (전장에서 뽑아 살아남은 유닛, 2026-11-23). 도감에 들어온 병종 · 장수는 보이지 않는다.
	var picks: Array = []
	for e: Dictionary in Game.profile.army():
		picks.append(String(e.get("id", "")))
	var n := mini(ARMY_MAX, picks.size())
	var h := 120.0 if n <= 18 else 100.0
	for i in n:
		var id := String(picks[i])
		# 성문 앞에 줄지어 모인다 (가운데부터, 한 줄 9명)
		var row := i / ARMY_COLS
		var in_row := mini(ARMY_COLS, n - row * ARMY_COLS)
		var col := i % ARMY_COLS
		var pos := Vector2(512.0 + (col - (in_row - 1) * 0.5) * ARMY_COL, ARMY_TOP + row * ARMY_ROW)
		var u := UnitView.make(id, h)
		u.flip = false
		put(u, Rect2(pos.x, pos.y, 0, 0), Pin.MID)
		var idx := i
		var tag := DrawLayer.make(func(ci: Control) -> void:
			if DB.is_hero(id):
				W.draw_rank(ci, Rect2(Vector2.ZERO, ci.size), Game.profile.star_of(id), 0, 20.0)
			else:
				W.draw_rank(ci, Rect2(Vector2.ZERO, ci.size), int(Game.profile.troop(id).get("star", 1)), 0, 20.0)
			# 다친 유닛은 체력 막대 (부대 체력은 다음 전투로 이어진다)
			var hp := _army_hp(idx)
			if hp < 0.999:
				var br := Rect2(30, 26, 80, 8)
				ci.draw_rect(br.grow(2), Px.INK)
				ci.draw_rect(br, Px.BAR_BG)
				ci.draw_rect(Rect2(br.position, Vector2(br.size.x * hp, br.size.y)), Px.HP_GREEN if hp > 0.5 else Px.HP_RED))
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		put(tag, Rect2(pos.x - 70, pos.y + 8, 140, 40), Pin.MID)
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
			"id": id, "u": u, "tag": tag, "hit": hit, "home": pos, "idx": i, "act": 0.0,
			"pos": pos, "target": pos,
			"wait": _rng.randf_range(0.4, 2.0), "speed": _rng.randf_range(44.0, 68.0),
		})


## 부대는 제자리 근처에서만 조금씩 움직인다 (성문 앞에 모여 있게).
func _pick_walk_target(near: Vector2, skip_idx: int) -> Vector2:
	var home: Vector2 = _walkers[skip_idx]["home"] if skip_idx >= 0 and skip_idx < _walkers.size() else near
	return home + Vector2(_rng.randf_range(-24.0, 24.0), _rng.randf_range(-14.0, 14.0))


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
		if _marching:
			# 출정: 성문 안으로 행군해 들어가 사라진다
			var door: Rect2 = DOORS[_march_gate]
			var gate_in := Vector2(door.get_center().x + (float(i % 3) - 1.0) * 26.0, door.end.y - 6.0)
			var dv := gate_in - pos
			if dv.length() < 16.0 or _door_open < 0.6:
				if dv.length() < 16.0:
					u.visible = false
					tag.visible = false
				u.action = "idle" if dv.length() >= 16.0 else u.action
			else:
				pos += dv.normalized() * minf(dv.length(), 330.0 * dt)
				w["pos"] = pos
				u.action = "walk"
				u.flip = dv.x < 0.0
		elif float(w["act"]) > 0.0:
			# 치료 동작 중 (의원)
			w["act"] = float(w["act"]) - dt
			u.action = "attack"
		elif wait > 0.0:
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
					if d > 1.0 and d < 60.0:
						dir = (dir + away.normalized() * 0.9).normalized()
				pos += dir * float(w["speed"]) * dt
				pos.x = clampf(pos.x, 80.0, 944.0)
				pos.y = clampf(pos.y, ARMY_TOP - 30.0, ARMY_TOP + ARMY_ROW * 3.0 + 30.0)
				w["pos"] = pos
				u.action = "walk"
				if absf(dir.x) > 0.08:
					u.flip = dir.x < 0.0
		u.position = Vector2(pos.x + dx(), pos.y + mid_dy)
		u.z_index = clampi(int(pos.y) - 1100, 0, 600)
		tag.position = Vector2(pos.x - 70.0 + dx(), pos.y + 8.0 + mid_dy)
		tag.z_index = clampi(int(pos.y) - 1100, 0, 600) + 1
		hit.position = Vector2(pos.x - 65.0 + dx(), pos.y - 150.0 + mid_dy)
		hit.z_index = clampi(int(pos.y) - 1100, 0, 600) + 2


## 부대 유닛 i의 체력 비율.
func _army_hp(i: int) -> float:
	var a := Game.profile.army()
	return float((a[i] as Dictionary).get("hp", 1.0)) if i < a.size() else 1.0


## 로비 치료 (2026-11-23): 부대에 의원(의원 병사 · 의원 병종 장수)이 있으면 army_heal_tick초마다
## 의원마다 가장 다친 유닛 하나를 army_heal_amount만큼 치료한다. 의원은 치료 동작, 대상 위에 초록 +.
func _heal_army(dt: float) -> void:
	_heal_t += dt
	if _heal_t < float(DB.rules.get("army_heal_tick", 2.0)):
		return
	_heal_t = 0.0
	var army := Game.profile.army()
	var amount := float(DB.rules.get("army_heal_amount", 0.05))
	var healed := false
	for w: Dictionary in _walkers:
		if DB.troop_of(String(w["id"])) != "medic":
			continue
		var best := -1
		var low := 0.999
		for k in mini(army.size(), _walkers.size()):
			var hp := float((army[k] as Dictionary).get("hp", 1.0))
			if hp < low:
				low = hp
				best = k
		if best < 0:
			break
		(army[best] as Dictionary)["hp"] = snappedf(minf(1.0, low + amount), 0.01)
		healed = true
		w["act"] = 0.6
		var tw: Dictionary = _walkers[best]
		(w["u"] as UnitView).flip = (tw["pos"] as Vector2).x < (w["pos"] as Vector2).x
		_heal_fx.append({"pos": tw["pos"], "t": 0.0})
	if healed:
		Game.profile.changed.emit()


func _draw_heal_fx(ci: Control) -> void:
	for f: Dictionary in _heal_fx:
		var k := float(f["t"]) / 0.9
		var p: Vector2 = (f["pos"] as Vector2) + Vector2(0, -150.0 - 40.0 * k)
		var c := Color(0.45, 1.0, 0.5, 1.0 - k)
		ci.draw_rect(Rect2(p.x - 4, p.y - 14, 8, 28), c)
		ci.draw_rect(Rect2(p.x - 14, p.y - 4, 28, 8), c)


## 부품 자리 (화면 px): tools/import_lobby_ui.py 가 그림을 떼어 낸 자리 그대로 적어 둔 것.
static var _layout: Dictionary = {}


func _rect(name: String) -> Rect2:
	if _layout.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/lobby_layout.json"))
		_layout = parsed if parsed is Dictionary else {}
	var r: Array = _layout.get(name, [0, 0, 100, 100])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


## 통째 그림 부품 하나 (그림 크기 그대로).
func _part(name: String) -> PxButton:
	return PxButton.make(name, false, _rect(name).size)


## 칩의 숫자: 아이콘과 "+" 사이의 어두운 칸에 쓴다. 계정 값이 바뀌면 같이 바뀐다.
func _chip_text(chip: PxButton, getter: Callable) -> void:
	chip.text_rect = Rect2(chip.size.x * 0.29, chip.size.y * 0.2, chip.size.x * 0.5, chip.size.y * 0.56)
	chip.text_align = HORIZONTAL_ALIGNMENT_CENTER
	chip.font_size = 30
	chip.text = str(getter.call())
	var refresh := func() -> void:
		if is_instance_valid(chip):
			chip.text = str(getter.call())
	Game.profile.changed.connect(refresh)
	chip.tree_exiting.connect(func() -> void:
		if Game.profile.changed.is_connected(refresh):
			Game.profile.changed.disconnect(refresh))


## 지금 열린 화면의 탭을 금테로 (장수 · 병사 화면 = 장수, 아이템 화면 = 가방).
func _mark_tabs() -> void:
	var on := ""
	match Game.app.dialog_route:
		"hero", "troop":
			on = "heroes"
		"heroes":
			on = "items" if Game.app.dialog != null and String(Game.app.dialog.get("mode")) == "items" else "heroes"
		"shop":
			on = "shop"
	for k: String in _tabs:
		var b: PxButton = _tabs[k]
		if is_instance_valid(b) and b.highlight != (k == on):
			b.highlight = k == on


## 성문 위 현판의 글자: 지금 스테이지 이름 (퇴각해 둔 전투가 있으면 스테이지-웨이브).
func _draw_plaque(ci: Control) -> void:
	var sus := Game.profile.suspended()
	var st := Game.profile.current_stage() if sus.is_empty() else int(sus["stage"])
	var s := "%s · %s" % [DB.t("stage.n", [st]), DB.stage_name(st)]
	if not sus.is_empty():
		s = "%d-%d · %s" % [st, int(sus["wave"]) + 1, DB.stage_name(st)]
	Px.text(ci, s, Rect2(Vector2.ZERO, ci.size), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 6)


## 출정 연출: 성문 [param gate](0 = 왼쪽)이 열리고 부대가 그 문으로 행군한 뒤 [param then]을 부른다. 한 번만.
func march_out(then: Callable, gate: int = 0) -> void:
	if _marching:
		return
	_marching = true
	_march_gate = gate
	_sign.disabled = true
	_arena_btn.disabled = true
	Sfx.play("whoosh")
	var tw := create_tween()
	tw.tween_property(self, "_door_open", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(MARCH_TIME - 0.5 if not _walkers.is_empty() else 0.4)
	tw.tween_callback(then)


## 성문: 안쪽 어둠 위에 문짝 두 장을 양옆으로 접어 연다 (문짝 그림이 없으면 아무것도 안 그린다).
func _draw_door(ci: Control, gate: int) -> void:
	if _door_open <= 0.0 or gate != _march_gate:
		return
	var art: String = DOOR_ART[gate]
	var hole := Px.tex(art + "_hole")
	var l := Px.tex(art + "_door_l")
	var r := Px.tex(art + "_door_r")
	if hole == null or l == null or r == null:
		return
	var sz := ci.size
	ci.draw_texture_rect(hole, Rect2(Vector2.ZERO, sz), false)
	var half := sz.x * 0.5
	var w := half * (1.0 - 0.82 * _door_open)
	# 문짝이 안쪽으로 젖혀지며 어두워진다
	var k := 1.0 - 0.45 * _door_open
	ci.draw_texture_rect(l, Rect2(0, 0, w, sz.y), false, Color(k, k, k))
	ci.draw_texture_rect(r, Rect2(sz.x - w, 0, w, sz.y), false, Color(k, k, k))


func _on_sign() -> void:
	# 튜토리얼 안내(출정 버튼 가리킴)는 누르면 닫는다 (전투 화면까지 남지 않게)
	if is_instance_valid(_tut_guide):
		_tut_guide.queue_free()
	# 장수 · 가방 화면이 열려 있으면 닫고 로비에서 출정한다
	Game.app.close_dialog(false)
	if not Game.tutorial_done():
		Game.next_stage = {"stage": 1, "diff": 1}
		Game.app.goto("battle", {"stage": 1, "diff": 1, "tutorial": true})
		return
	# 퇴각해 둔 전투가 있으면 그 웨이브부터 바로 이어서 한다.
	var sus := Game.profile.suspended()
	if not sus.is_empty():
		Game.next_stage = {"stage": int(sus["stage"]), "diff": int(sus["diff"])}
		march_out(func() -> void: Game.app.goto("battle", {"stage": int(sus["stage"]), "diff": int(sus["diff"]), "resume": true}))
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
	_tut_guide = Guide.show_at(Game.app.overlay_layer, Rect2(_sign.position, _sign.size).grow(10), DB.t("tut.gate"))
	_tut_guide.advanced.connect(_tut_guide.queue_free)


func _process(delta: float) -> void:
	_t += delta
	_step_walkers(delta)
	_heal_army(delta)
	_mark_tabs()
	for f: Dictionary in _heal_fx:
		f["t"] = float(f["t"]) + delta
	_heal_fx = _heal_fx.filter(func(f: Dictionary) -> bool: return float(f["t"]) < 0.9)
	if is_instance_valid(_heal_layer):
		_heal_layer.queue_redraw()
	for c in get_children():
		if c is DrawLayer:
			c.queue_redraw()


func _draw_info(ci: Control) -> void:
	var total := 0
	for id: String in Game.lineup():
		total += MetaRules.hero_power(Game.profile.data, id)
	Px.fit(ci, Px.tex("icon_sword"), Rect2(0, 12, 36, 36))
	Px.text(ci, Px.num(total), Rect2(44, 0, 300, 60), 32, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)


func back() -> bool:
	Game.app.confirm_quit()
	return true
