extends PxPopup
## 웨이브 승리: 제목 리본, 군량·성 체력·처치, 활약 장수, 다음 웨이브 적, 다음 웨이브 버튼.

var p: Dictionary


func setup(params: Dictionary) -> void:
	p = params
	title = DB.t("wave.title", [int(p["wave"])])
	panel_rect = Rect2(92, 470, 840, 860)
	ribbon_color = Color("#2a8a4a")
	dim_closes = false


func build() -> void:
	var rows := [["icon_rice", DB.t("wave.rice"), "+" + Px.num(int(p["rice"]))], ["icon_castle", DB.t("wave.castle"), "+" + str(int(p["castle"]))], ["ic_sword", DB.t("wave.kills"), str(int(p["kills"]))]]
	for i in rows.size():
		var it: Array = rows[i]
		var row := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.25))
			Px.fit(ci, Px.tex(String(it[0])), Rect2(16, 8, 56, 56))
			Px.text(ci, String(it[1]), Rect2(90, 0, 300, ci.size.y), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(it[2]), Rect2(380, 0, 320, ci.size.y), 38, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
		put(row, Rect2(60, 100 + i * 84, 720, 72))
	var mvp: UnitState = p.get("mvp")
	if mvp != null:
		put(W.portrait(mvp.id, Vector2(130, 130)), Rect2(60, 370, 130, 130))
		var info := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, DB.t("wave.mvp"), Rect2(0, 0, 500, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, mvp.display_name() + "  " + DB.t("battle.rank", [mvp.rank]), Rect2(0, 40, 520, 50), 36, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.t("wave.mvp_line", [Px.num(int(mvp.damage)), mvp.kills]), Rect2(0, 90, 520, 40), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		put(info, Rect2(210, 370, 560, 130))
	var nxt: Dictionary = p["next"]
	var foes := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("wave.next", [int(p["wave"]) + 1, int(p["total"])]), Rect2(0, 0, ci.size.x, 40), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		var x := 0.0
		var list: Array = (nxt["list"] as Array) + (nxt.get("flank", []) as Array)
		if String(nxt.get("boss", "")) != "":
			list = [[String(nxt["boss"]), 1]] + list
		for pair: Array in list:
			if x > ci.size.x - 110:
				break
			var a := Art.of_unit(String(pair[0]))
			var t := Art.portrait(String(a["art"]))
			var boss := DB.is_boss(String(pair[0]))
			ci.draw_rect(Rect2(x, 50, 96, 96), Px.INK)
			ci.draw_rect(Rect2(x + 4, 54, 88, 88), Color("#5a2a2a") if boss else Color("#3a3036"))
			Px.cover(ci, t, Rect2(x + 6, 56, 84, 84))
			Px.text(ci, "x%d" % int(pair[1]) if not boss else DB.t("battle.boss_short"), Rect2(x, 112, 92, 34), 24, Px.GOLD if boss else Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
			x += 106)
	put(foes, Rect2(60, 530, 720, 150))
	var ok := PxButton.colored("yellow", DB.t("wave.next_btn"), Vector2(400, 120), 40)
	ok.pressed.connect(close)
	put(ok, Rect2(220, 710, 400, 120))
