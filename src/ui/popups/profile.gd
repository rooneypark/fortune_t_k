extends PxPopup
## 주공 정보: 대표 장수 얼굴, 레벨 · 경험치, 전투력, 기록, 대표 장수 바꾸기.


func setup(_p: Dictionary) -> void:
	title = DB.t("profile.title")
	panel_rect = Rect2(60, 330, 904, 1100)


func build() -> void:
	var d := Game.profile.data
	var face := W.portrait_frame(String(d["avatar"]), Vector2(220, 220))
	face.static_panel = true
	put(face, Rect2(50, 110, 220, 220))
	var info := DrawLayer.make(func(ci: Control) -> void:
		var lv := int(d["lord_lv"])
		Px.text(ci, String(d["name"]), Rect2(0, 0, ci.size.x, 60), 46, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("profile.lv", [lv]), Rect2(0, 66, ci.size.x, 44), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		var need := MetaRules.lord_exp_need(lv)
		Px.bar(ci, Rect2(0, 118, ci.size.x, 32), float(d["lord_exp"]) / maxi(1, need), Color("#9be27a"))
		Px.text(ci, "%s / %s" % [Px.num(int(d["lord_exp"])), Px.num(need)], Rect2(0, 118, ci.size.x, 32), 22)
		var power := 0
		for id: String in Game.lineup():
			power += MetaRules.hero_power(d, id)
		Px.text(ci, DB.t("profile.power", [Px.num(power)]), Rect2(0, 164, ci.size.x, 44), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT), Vector2(560, 220))
	put(info, Rect2(300, 110, 560, 220))
	var st: Dictionary = d["stats"]
	var rows := [["profile.runs", int(st["runs"])], ["profile.victories", int(st["victories"])], ["profile.jackpots", int(st["jackpots"])],
		["profile.kills", int(st["kills"])], ["profile.heroes", (d["heroes"] as Dictionary).size()], ["profile.honor", int(d["honor"])]]
	var tbl := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		for i in rows.size():
			var r := Rect2(30 + (i % 2) * 382, 24 + (i / 2) * 76, 360, 64)
			Px.text(ci, DB.t(String(rows[i][0])), Rect2(r.position, Vector2(200, r.size.y)), 28, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, Px.num(int(rows[i][1])), Rect2(r.position + Vector2(200, 0), Vector2(r.size.x - 220, r.size.y)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(804, 270))
	put(tbl, Rect2(50, 360, 804, 270))
	var cap := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("profile.avatar"), Rect2(Vector2.ZERO, ci.size), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT), Vector2(804, 50))
	put(cap, Rect2(50, 650, 804, 50))
	var ids: Array = (d["heroes"] as Dictionary).keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return MetaRules.hero_power(d, a) > MetaRules.hero_power(d, b))
	for i in mini(10, ids.size()):
		var id := String(ids[i])
		var b := PxButton.new()
		b.size = Vector2(148, 148)
		var pic := W.portrait(id, Vector2(148, 148))
		b.add_child(pic)
		if id == String(d["avatar"]):
			b.overlay = func(btn: PxButton, off: Vector2) -> void: btn.draw_rect(Rect2(off + Vector2(2, 2), btn.size - Vector2(4, 4)), Px.GOLD, false, 7.0)
		b.pressed.connect(func() -> void:
			d["avatar"] = id
			Game.profile.changed.emit()
			close()
			Game.app.popup("profile"))
		put(b, Rect2(50 + (i % 5) * 162, 710 + (i / 5) * 162, 148, 148))
