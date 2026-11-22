extends PxPopup
## 임무: 일일 · 주간 · 업적 탭. 진행 바, 받기 / 바로가기.

var tab := 0


func setup(p: Dictionary) -> void:
	title = DB.t("missions.title")
	tab = int(p.get("tab", 0))
	panel_rect = Rect2(60, 260, 904, 1280)
	Game.profile.refresh_periods()


func build() -> void:
	var scopes := ["daily", "weekly", "achievements"]
	var scope: String = scopes[tab]
	put(W.tabs([DB.t("missions.daily"), DB.t("missions.weekly"), DB.t("missions.achieve")], tab, Vector2(800, 90), func(i: int) -> void:
		close()
		Game.app.popup("missions", {"tab": i}), ["green", "blue", "purple"]), Rect2(52, 96, 800, 90))
	var list: Array = (DB.missions[scope] as Array).duplicate()
	var order := {"ready": 0, "progress": 1, "claimed": 2}
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(order[Game.profile.mission_state(a, scope)]) < int(order[Game.profile.mission_state(b, scope)]))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var content := Control.new()
	sc.add_child(content)
	for i in list.size():
		var mi: Dictionary = list[i]
		var st := Game.profile.mission_state(mi, scope)
		var prog := mini(Game.profile.mission_progress(mi, scope), int(mi["need"]))
		var row := W.row_panel(Vector2(800, 160))
		row.position = Vector2(0, i * 172)
		var rw: Dictionary = mi["reward"]
		row.overlay = func(b: PxButton, off: Vector2) -> void:
			var ic := Rect2(off + Vector2(20, 22), Vector2(116, 116))
			b.draw_rect(ic, Px.INK)
			b.draw_rect(ic.grow(-4), Color("#2b1c11"))
			Px.fit(b, Px.tex(W.reward_icon(rw)), Rect2(ic.position + Vector2(20, 10), Vector2(76, 76)))
			Px.text(b, W.reward_text(rw), Rect2(ic.position + Vector2(0, 80), Vector2(116, 32)), 22, Px.WHITE)
			Px.text(b, String(mi["name"]), Rect2(off + Vector2(160, 22), Vector2(420, 50)), 32, Px.MUTED if st == "claimed" else Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.bar(b, Rect2(off + Vector2(160, 88), Vector2(410, 34)), float(prog) / maxi(1, int(mi["need"])), Color("#9be27a"))
			Px.text(b, "%d / %d" % [prog, int(mi["need"])], Rect2(off + Vector2(160, 88), Vector2(410, 34)), 22)
		var btn: PxButton
		match st:
			"ready":
				btn = PxButton.colored("yellow", DB.t("mail.get"), Vector2(180, 100), 32)
				btn.pulse = true
				btn.pressed.connect(func() -> void:
					var g := Game.profile.claim_mission(mi, scope)
					close()
					var p := Game.app.popup("reward", {"reward": rw, "items": g})
					p.closed.connect(func() -> void: Game.app.popup("missions", {"tab": tab})))
			"claimed":
				btn = PxButton.colored("blue", DB.t("mail.claimed"), Vector2(180, 100), 30)
				btn.disabled = true
			_:
				btn = PxButton.colored("wood", DB.t("missions.go"), Vector2(180, 100), 32)
				var route := String(mi.get("go", ""))
				btn.disabled = route == ""
				btn.pressed.connect(func() -> void:
					close()
					Game.app.goto(route))
		btn.position = Vector2(600, 30)
		row.add_child(btn)
		content.add_child(row)
	content.custom_minimum_size = Vector2(800, list.size() * 172)
	put(sc, Rect2(52, 210, 800, 1020))
