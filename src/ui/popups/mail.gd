extends PxPopup
## 우편함: 제목 · 내용 · 보상 · 남은 기간, 받기 / 모두 받기 / 읽은 우편 삭제. (시안: 우편함8_완성화면.png)
## 자리는 8차 시안에서 잰 화면 px 그대로. 틀(안쪽 판이 있는 큰 창 kit_frame2) · 제목 띠 · 닫기 · 줄 · 버튼은 공용 부품.
const FRAME := Rect2(85, 363, 853, 1042)
const TITLE := Rect2(249, 362, 526, 98)
const CLOSE := Rect2(817, 379, 90, 87)
const LIST := Rect2(154, 482, 717, 728)         # 우편 줄이 구르는 칸 (5줄)
const ROW := Vector2(717, 134)                  # 줄 간격 146
const BTN_ALL := Rect2(154, 1221, 353, 131)
const BTN_DEL := Rect2(517, 1221, 354, 131)


func setup(_p: Dictionary) -> void:
	title = DB.t("mail.title")
	title_size = 40
	panel_rect = Rect2(60, 260, 904, 1280)
	Game.profile.seed_welcome_mail()
	use_kit(FRAME, TITLE, CLOSE, "kit_frame2")


func build() -> void:
	var list: Array = Game.profile.data["mail"]
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var content := Control.new()
	sc.add_child(content)
	var now := int(Time.get_unix_time_from_system())
	if list.is_empty():
		var empty := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("mail.empty"), Rect2(Vector2.ZERO, ci.size), 30, Px.MUTED), Vector2(ROW.x, 400))
		content.add_child(empty)
	for i in list.size():
		var m: Dictionary = list[i]
		var rw: Dictionary = m["reward"]
		var left := maxi(0, ceili((int(m["expires"]) - now) / 86400.0))
		var done := bool(m["claimed"])
		# 줄: 왼쪽 봉투, 가운데 제목 · 내용 · 보상과 남은 기간, 오른쪽 노란 받기 버튼
		var row := DrawLayer.make(func(ci: Control) -> void:
			Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
			Px.fit(ci, Px.tex("ic_mail"), Rect2(24, 31, 96, 72), Color(1, 1, 1, 0.45) if done else Color.WHITE)
			Px.text(ci, String(m["title"]), Rect2(140, 12, 390, 40), 28, Px.MUTED if done else Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(m["body"]), Rect2(140, 52, 390, 32), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.fit(ci, Px.tex(W.reward_icon(rw)), Rect2(140, 88, 30, 30))
			Px.text(ci, W.reward_text(rw), Rect2(176, 86, 170, 34), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.t("mail.left", [left]), Rect2(350, 86, 180, 34), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT), ROW)
		row.position = Vector2(0, i * 146)
		var get := PxButton.make("kit_btn_yellow" if not done else "kit_box", true, Vector2(138, 80))
		get.font_size = 26
		get.text_color = Px.MUTED if done else Color("#3a2a10")
		get.text = DB.t("mail.claimed") if done else DB.t("mail.get")
		get.position = Vector2(552, 27)
		get.disabled = done
		var idx := i
		get.pressed.connect(func() -> void:
			var g := Game.profile.claim_mail(idx)
			close()
			var p := Game.app.popup("reward", {"reward": rw, "items": g})
			p.closed.connect(func() -> void: Game.app.popup("mail")))
		row.add_child(get)
		content.add_child(row)
	content.custom_minimum_size = Vector2(ROW.x, maxf(400, list.size() * 146))
	_place(sc, LIST)
	var all := _wide("kit_btn_red", "icon_chest", DB.t("mail.get_all"), BTN_ALL)
	all.disabled = Game.profile.unclaimed_mail() == 0
	all.pressed.connect(func() -> void:
		var total := {}
		var items: Array = []
		for i in list.size():
			if not bool(list[i]["claimed"]):
				var r: Dictionary = list[i]["reward"]
				for k: String in r:
					if r[k] is int or r[k] is float:
						total[k] = int(total.get(k, 0)) + int(r[k])
				items.append_array(Game.profile.claim_mail(i))
		close()
		Game.app.popup("reward", {"reward": total, "items": items}))
	var del := _wide("kit_box", "act_trash", DB.t("mail.delete"), BTN_DEL)
	del.pressed.connect(func() -> void:
		Game.profile.delete_read_mail()
		close()
		Game.app.popup("mail"))


## 아래 큰 버튼: 왼쪽 끝에 아이콘 하나, 나머지 자리에 글자.
func _wide(part: String, icon_name: String, label: String, r: Rect2) -> PxButton:
	var b := PxButton.make(part, true, r.size)
	b.tooltip_text = label
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		Px.fit(btn, Px.tex(icon_name), Rect2(off + Vector2(24, (btn.size.y - 84) * 0.5), Vector2(84, 84)), Color(0.6, 0.6, 0.6) if btn.disabled else Color.WHITE)
		Px.text(btn, label, Rect2(off + Vector2(116, 0), Vector2(btn.size.x - 132, btn.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	_place(b, r)
	return b
