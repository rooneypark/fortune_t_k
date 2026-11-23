extends PxPopup
## 일시정지: 계속하기, 배경음·효과음, 슬롯 연출, 설정, 출정 포기.


func setup(_p: Dictionary) -> void:
	title = DB.t("pause.title")
	panel_rect = Rect2(92, 420, 840, 980)


func build() -> void:
	var y := 110.0
	for spec: Array in [["bgm", DB.t("settings.bgm")], ["sfx", DB.t("settings.sfx")]]:
		var key := String(spec[0])
		var lab := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, String(spec[1]), Rect2(0, 0, ci.size.x, ci.size.y), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		put(lab, Rect2(60, y, 220, 80))
		var sl := PxControls.Slide.new()
		sl.value = float(Game.settings()[key])
		sl.changed.connect(func(v: float) -> void: Game.set_setting(key, v))
		put(sl, Rect2(280, y, 500, 80))
		y += 100
	var lab2 := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("settings.slot"), Rect2(0, 0, ci.size.x, ci.size.y), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(lab2, Rect2(60, y, 220, 80))
	var seg := PxControls.Seg.new()
	seg.items = [DB.t("settings.fast"), DB.t("settings.normal"), DB.t("settings.off")]
	seg.index = int(Game.settings()["slot_speed"])
	seg.changed.connect(func(i: int) -> void: Game.set_setting("slot_speed", i))
	put(seg, Rect2(280, y, 500, 80))
	y += 130
	var resume := PxButton.colored("yellow", DB.t("pause.resume"), Vector2(600, 130), 44)
	resume.pressed.connect(close)
	put(resume, Rect2(120, y, 600, 130))
	y += 150
	var st := PxButton.colored("blue", DB.t("pause.settings"), Vector2(600, 110), 38)
	st.pressed.connect(func() -> void: Game.app.popup("settings"))
	put(st, Rect2(120, y, 600, 110))
	y += 130
	var quit := PxButton.colored("red", DB.t("pause.retreat"), Vector2(600, 110), 38)
	quit.pressed.connect(func() -> void:
		var c := Game.app.popup("confirm", {"title": DB.t("pause.retreat"), "text": DB.t("pause.retreat_text"), "ok": DB.t("pause.retreat_ok")})
		c.confirmed.connect(func() -> void:
			var b: Node = Game.app.current
			if b != null and b.has_method("retreat"):
				b.retreat()
			Game.app.goto("lobby")))
	put(quit, Rect2(120, y, 600, 110))
