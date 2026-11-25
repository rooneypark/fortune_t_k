extends PxPopup
## 설정: 배경음 · 효과음 막대, 슬롯 연출(빠르게 · 보통 · 끄기), 글자 크기, 진동 · 화면 흔들림 · 알림,
## 고객센터 · 약관 · 계정, 버전. (시안: 설정8_시안1.png + 설정8_시안2_릴아이콘_링크줄.png)
## 자리는 8차 시안에서 잰 화면 px 그대로. 틀(안쪽 판이 있는 큰 창 kit_frame2) · 제목 띠 · 닫기 · 줄 · 버튼은 공용 부품.
const FRAME := Rect2(85, 363, 853, 1042)
const TITLE := Rect2(249, 362, 526, 98)
const CLOSE := Rect2(817, 379, 90, 87)
## 영역 4개 (금테 어두운 칸): 소리 / 슬롯 연출 · 글자 크기 / 스위치 3줄 / 링크 3줄
const SEC_X := 150.0
const SEC_W := 730.0
const SEC := [[480.0, 200.0], [692.0, 196.0], [900.0, 256.0], [1168.0, 160.0]]    # [y, 높이]


func setup(_p: Dictionary) -> void:
	title = DB.t("settings.title")
	title_size = 40
	panel_rect = Rect2(60, 250, 904, 1310)
	use_kit(FRAME, TITLE, CLOSE, "kit_frame2")


func build() -> void:
	for s: Array in SEC:
		var box := DrawLayer.make(func(ci: Control) -> void: Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size)))
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(box, Rect2(SEC_X, float(s[0]), SEC_W, float(s[1])))
	# 영역 1: 소리 — 아이콘 + 막대
	var y := float(SEC[0][0]) + 18
	for spec: Array in [["bgm", DB.t("settings.bgm"), "ic_music"], ["sfx", DB.t("settings.sfx"), "ic_sound"]]:
		var key := String(spec[0])
		_icon(String(spec[2]), String(spec[1]), Rect2(186, y, 92, 80))
		var sl := PxControls.Slide.new()
		sl.value = float(Game.settings()[key])
		sl.changed.connect(func(v: float) -> void:
			Game.set_setting(key, v)
			if key == "sfx":
				Sfx.play("tick"))
		_place(sl, Rect2(303, y + 6, 540, 68))
		y += 88
	# 영역 2: 슬롯 연출 (릴 아이콘) · 글자 크기
	y = float(SEC[1][0]) + 14
	_icon("ic_reel", DB.t("settings.slot"), Rect2(180, y, 180, 78))
	_seg("slot_speed", [DB.t("settings.fast"), DB.t("settings.normal"), DB.t("settings.off")], y)
	y += 90
	_label(DB.t("settings.font"), Rect2(186, y, 200, 78))
	_seg("font", [DB.t("settings.small"), DB.t("settings.normal"), DB.t("settings.large")], y)
	# 영역 3: 스위치 3줄 (이름은 왼쪽, 스위치는 오른쪽 끝)
	y = float(SEC[2][0]) + 22
	for t: Array in [["vibrate", DB.t("settings.vibrate")], ["shake", DB.t("settings.shake")], ["notify", DB.t("settings.notify")]]:
		var key := String(t[0])
		_label(String(t[1]), Rect2(186, y, 460, 60))
		var tg := PxControls.Toggle.new()
		tg.on = bool(Game.settings()[key])
		tg.changed.connect(func(v: bool) -> void: Game.set_setting(key, v))
		_place(tg, Rect2(686, y + 4, 146, 52))
		y += 79
	# 영역 4: 링크 3줄 (오른쪽 끝에 작은 삼각형)
	y = float(SEC[3][0]) + 8
	for b: Array in [[DB.t("settings.support"), "support"], [DB.t("settings.terms"), "terms"], [DB.t("settings.account"), "account"]]:
		var which := String(b[1])
		var label := String(b[0])
		var link := PxButton.new()
		link.size = Vector2(SEC_W - 28, 48)
		link.press_depth = 2.0
		link.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, label, Rect2(off + Vector2(22, 0), Vector2(btn.size.x - 90, btn.size.y)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			var c := off + Vector2(btn.size.x - 34, btn.size.y * 0.5)
			btn.draw_colored_polygon(PackedVector2Array([c + Vector2(-10, -15), c + Vector2(14, 0), c + Vector2(-10, 15)]), Px.INK)
			btn.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -9), c + Vector2(8, 0), c + Vector2(-6, 9)]), Color("#f4b93a"))
		link.pressed.connect(func() -> void: _info(which))
		_place(link, Rect2(SEC_X + 14, y, SEC_W - 28, 48))
		y += 48
	var ver := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, "%s  ·  %s" % [DB.t("settings.version", ["v0.1.0"]), DB.t("settings.proto")], Rect2(Vector2.ZERO, ci.size), 17, Px.MUTED))
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(ver, Rect2(SEC_X, 1334, SEC_W, 32))


func _icon(icon_name: String, tip: String, r: Rect2) -> void:
	var d := DrawLayer.make(func(ci: Control) -> void: Px.fit(ci, Px.tex(icon_name), Rect2(Vector2.ZERO, ci.size)))
	d.tooltip_text = tip
	_place(d, r)


func _label(s: String, r: Rect2) -> void:
	var d := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, s, Rect2(Vector2.ZERO, ci.size), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(d, r)


func _seg(key: String, items: Array, y: float) -> void:
	var seg := PxControls.Seg.new()
	seg.items = items
	seg.index = int(Game.settings()[key])
	seg.changed.connect(func(i: int) -> void:
		Game.set_setting(key, i)
		if key == "font" and Game.app.current != null:
			Game.app.current.queue_redraw())
	_place(seg, Rect2(402, y, 444, 78))


func _info(which: String) -> void:
	match which:
		"account":
			var c := Game.app.popup("confirm", {"title": DB.t("settings.account"), "text": DB.t("settings.account_text"), "ok": DB.t("settings.reset")})
			c.confirmed.connect(func() -> void:
				Game.profile.reset()
				Game.profile.seed_welcome_mail()
				Game.save_now()
				Game.app.goto("intro"))
		_:
			Game.app.popup("confirm", {"title": DB.t("settings." + which), "text": DB.t("settings.%s_text" % which), "ok": DB.t("common.ok")})
