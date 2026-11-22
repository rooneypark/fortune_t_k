extends PxPopup
## 우편함: 제목 · 내용 · 보상 · 남은 기간, 받기 / 모두 받기 / 읽은 우편 삭제.


func setup(_p: Dictionary) -> void:
	title = DB.t("mail.title")
	panel_rect = Rect2(60, 260, 904, 1280)
	Game.profile.seed_welcome_mail()


func build() -> void:
	var list: Array = Game.profile.data["mail"]
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var content := Control.new()
	sc.add_child(content)
	var now := int(Time.get_unix_time_from_system())
	if list.is_empty():
		var empty := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("mail.empty"), Rect2(Vector2.ZERO, ci.size), 34, Px.MUTED), Vector2(800, 400))
		content.add_child(empty)
	for i in list.size():
		var m: Dictionary = list[i]
		var row := W.row_panel(Vector2(800, 190))
		row.position = Vector2(0, i * 206)
		var rw: Dictionary = m["reward"]
		var left := maxi(0, ceili((int(m["expires"]) - now) / 86400.0))
		var done := bool(m["claimed"])
		row.overlay = func(b: PxButton, off: Vector2) -> void:
			var ic := Rect2(off + Vector2(24, 30), Vector2(130, 130))
			b.draw_rect(ic, Px.INK)
			b.draw_rect(ic.grow(-4), Color("#2b1c11"))
			Px.fit(b, Px.tex(W.reward_icon(rw)), ic.grow(-18), Color(1, 1, 1, 0.45) if done else Color.WHITE)
			Px.text(b, W.reward_text(rw), Rect2(ic.position + Vector2(0, 92), Vector2(130, 36)), 22, Px.WHITE)
			Px.text(b, String(m["title"]), Rect2(off + Vector2(180, 24), Vector2(400, 50)), 34, Px.MUTED if done else Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(b, String(m["body"]), Rect2(off + Vector2(180, 78), Vector2(400, 40)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(b, DB.t("mail.left", [left]), Rect2(off + Vector2(180, 124), Vector2(400, 40)), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		var get := PxButton.colored("blue" if done else "yellow", DB.t("mail.claimed") if done else DB.t("mail.get"), Vector2(190, 100), 32)
		get.position = Vector2(590, 45)
		get.disabled = done
		var idx := i
		get.pressed.connect(func() -> void:
			var g := Game.profile.claim_mail(idx)
			close()
			var p := Game.app.popup("reward", {"reward": rw, "items": g})
			p.closed.connect(func() -> void: Game.app.popup("mail")))
		row.add_child(get)
		content.add_child(row)
	content.custom_minimum_size = Vector2(800, maxf(400, list.size() * 206))
	put(sc, Rect2(52, 110, 800, 960))
	var del := PxButton.colored("blue", DB.t("mail.delete"), Vector2(360, 120), 34)
	del.pressed.connect(func() -> void:
		Game.profile.delete_read_mail()
		close()
		Game.app.popup("mail"))
	put(del, Rect2(52, 1110, 360, 120))
	var all := PxButton.colored("yellow", DB.t("mail.get_all"), Vector2(360, 120), 34)
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
	put(all, Rect2(492, 1110, 360, 120))
