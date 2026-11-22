extends PxPopup
## 설정: 배경음·효과음 슬라이더, 슬롯 연출(빠르게·보통·끄기), 진동, 화면 흔들림,
## 글자 크기, 알림, 고객센터·약관·계정, 버전.

const ROW_H := 108.0
## 영역(판) 하나 = 제목 줄 SEC_HEAD + 줄 n개 + 아래 여백 SEC_PAD. 선 장식 없이 판 테두리 하나만.
const SEC_HEAD := 60.0
const SEC_PAD := 12.0
const SEC_GAP := 20.0
const SEC_X := 24.0


func setup(_p: Dictionary) -> void:
	title = DB.t("settings.title")
	panel_rect = Rect2(60, 250, 904, 1310)


func build() -> void:
	var w := panel_rect.size.x
	var y := 96.0
	# 영역 1: 소리 (제목 + 줄 2개)
	_section(DB.t("settings.sound"), y, 2)
	y += SEC_HEAD
	for spec: Array in [["bgm", DB.t("settings.bgm"), "♪"], ["sfx", DB.t("settings.sfx"), "♫"]]:
		var key := String(spec[0])
		_row(String(spec[1]), y)
		var sl := PxControls.Slide.new()
		sl.value = float(Game.settings()[key])
		sl.changed.connect(func(v: float) -> void:
			Game.set_setting(key, v)
			if key == "sfx":
				Sfx.play("tick"))
		put(sl, Rect2(330, y + 14, 520, 80))
		y += ROW_H
	y += SEC_PAD + SEC_GAP
	# 영역 2: 게임 (제목 + 줄 5개)
	_section(DB.t("settings.play"), y, 5)
	y += SEC_HEAD
	_row(DB.t("settings.slot"), y)
	_seg("slot_speed", [DB.t("settings.fast"), DB.t("settings.normal"), DB.t("settings.off")], y)
	y += ROW_H
	_row(DB.t("settings.font"), y)
	_seg("font", [DB.t("settings.small"), DB.t("settings.normal"), DB.t("settings.large")], y)
	y += ROW_H
	var toggles := [["vibrate", DB.t("settings.vibrate")], ["shake", DB.t("settings.shake")], ["notify", DB.t("settings.notify")]]
	for i in toggles.size():
		var t: Array = toggles[i]
		var key := String(t[0])
		_row(String(t[1]), y)
		var tg := PxControls.Toggle.new()
		tg.on = bool(Game.settings()[key])
		tg.changed.connect(func(v: bool) -> void: Game.set_setting(key, v))
		put(tg, Rect2(w - 220, y + 22, 160, 64))
		y += ROW_H
	y += SEC_PAD + 24
	var btns := [["blue", DB.t("settings.support"), "support"], ["blue", DB.t("settings.terms"), "terms"], ["blue", DB.t("settings.account"), "account"]]
	for i in btns.size():
		var b: Array = btns[i]
		var pb := PxButton.colored(String(b[0]), String(b[1]), Vector2(250, 104), 32)
		var which := String(b[2])
		pb.pressed.connect(func() -> void: _info(which))
		put(pb, Rect2(48 + i * 274, y, 250, 104))
	y += 124
	var ver := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("settings.version", ["v0.1.0"]), Rect2(0, 0, ci.size.x, 36), 24, Px.MUTED)
		Px.text(ci, DB.t("settings.proto"), Rect2(0, 36, ci.size.x, 32), 20, Px.MUTED))
	put(ver, Rect2(20, y, w - 40, 70))


## 영역 판: 제목 + rows 줄을 담는 사각 영역 하나.
func _section(s: String, y: float, rows: int) -> void:
	var h := SEC_HEAD + rows * ROW_H + SEC_PAD
	var d := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, s, Rect2(24, 8, ci.size.x - 48, SEC_HEAD - 12), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	put(d, Rect2(SEC_X, y, panel_rect.size.x - SEC_X * 2, h))


## 줄 이름 (영역 판 안, 선 장식 없음).
func _row(label: String, y: float) -> void:
	var d := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, label, Rect2(Vector2.ZERO, ci.size), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(d, Rect2(SEC_X + 24, y, 250, ROW_H))


func _seg(key: String, items: Array, y: float) -> void:
	var seg := PxControls.Seg.new()
	seg.items = items
	seg.index = int(Game.settings()[key])
	seg.changed.connect(func(i: int) -> void:
		Game.set_setting(key, i)
		if key == "font" and Game.app.current != null:
			Game.app.current.queue_redraw())
	put(seg, Rect2(330, y + 18, 520, 72))


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
