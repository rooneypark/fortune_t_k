extends PxPopup
## 결과: 승리 (리본, n-n 클리어, 별, 기록 4칸, 최고 활약, 보상, 로비로/다음) /
## 패배 ("성이 함락되었다", 이어하기 다이아 100 출정당 1회, 기록, 보상).

var p: Dictionary
var victory := false
var _t := 0.0
var _out: Dictionary = {}


func setup(params: Dictionary) -> void:
	p = params
	victory = bool(p["victory"])
	title = DB.t("result.victory") if victory else DB.t("result.defeat")
	ribbon_color = Color("#c8901c") if victory else Color("#4a5566")
	panel_rect = Rect2(52, 300, 920, 1260)
	dim_closes = false
	show_close = false
	_out = p.get("out", {})


func build() -> void:
	var w := panel_rect.size.x
	var head := DrawLayer.make(func(ci: Control) -> void:
		var s := DB.t("result.clear", ["%d-%d" % [int(p["chapter"]), int(p["stage"])]]) if victory else DB.t("result.fallen")
		Px.text(ci, s, Rect2(0, 0, ci.size.x, 60), 44, Px.WHITE)
		if victory:
			var stars := int(_out.get("stars", 0))
			for i in 3:
				var k := clampf((_t - 0.25 * i) / 0.25, 0.0, 1.0)
				var sz := 96.0 * (1.0 + 0.4 * (1.0 - k)) if k > 0.0 else 0.0
				var c := Vector2(ci.size.x * 0.5 + (i - 1) * 130, 130)
				Px.fit(ci, Px.tex("ic_star_off"), Rect2(c - Vector2(48, 48), Vector2(96, 96)))
				if i < stars and k > 0.0:
					Px.fit(ci, Px.tex("ic_star"), Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)))
			var rules: Array = DB.stages["star_rules"]
			Px.text(ci, " · ".join(rules), Rect2(0, 184, ci.size.x, 34), 22, Px.MUTED))
	put(head, Rect2(20, 100, w - 40, 220))
	var st: Dictionary = p["stats"]
	var cells := [[DB.t("result.waves"), "%d/%d" % [int(p["waves"]), 10]], [DB.t("result.kills"), Px.num(int(st.get("kills", 0)))],
		[DB.t("result.spins"), str(int(st.get("spins", 0)))], [DB.t("result.jackpots"), str(int(st.get("jackpots", 0)))]]
	for i in cells.size():
		var c: Array = cells[i]
		var box := DrawLayer.make(func(ci: Control) -> void:
			Px.box(ci, Rect2(Vector2.ZERO, ci.size), Px.PANEL_DEEP, Px.EDGE)
			ci.draw_rect(Rect2(8, 8, ci.size.x - 16, ci.size.y - 16), Px.PANEL_DEEP)
			Px.text(ci, String(c[0]), Rect2(0, 10, ci.size.x, 36), 24, Px.MUTED)
			Px.text(ci, String(c[1]), Rect2(0, 48, ci.size.x, 56), 40, Px.WHITE))
		put(box, Rect2(30 + i * 215, 330, 200, 116))
	var mvp := String(p.get("mvp", ""))
	if mvp != "":
		put(W.portrait(mvp, Vector2(120, 120)), Rect2(40, 470, 120, 120))
		var ml := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, DB.t("result.mvp"), Rect2(0, 6, 400, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.unit_name(mvp), Rect2(0, 48, 500, 56), 42, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		put(ml, Rect2(180, 470, 600, 120))
	# rewards
	var rw := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.28))
		Px.text(ci, DB.t("result.rewards"), Rect2(20, 0, 160, 50), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		if int(_out.get("rice_left", 0)) > 0:
			Px.text(ci, DB.t("result.rice_gold", [Px.num(int(_out["rice_left"])), Px.num(int(_out["rice_gold"]))]),
				Rect2(200, 0, ci.size.x - 220, 50), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		var items: Array = []
		if victory or _out.has("gold"):
			items.append(["icon_gold", Px.num(int(_out.get("gold", 0)))])
			items.append(["ic_scroll", DB.t("result.exp", [int(_out.get("lord_exp", 0))])])
		if int(_out.get("diamond", 0)) > 0:
			items.append(["icon_diamond", DB.t("result.first", [int(_out["diamond"])])])
		var tr: Dictionary = _out.get("treasure", {})
		if not tr.is_empty():
			items.append(["icon_chest", String(DB.treasure_def(String(tr["tid"])).get("name", ""))])
		if items.is_empty():
			Px.text(ci, DB.t("result.after"), Rect2(20, 60, ci.size.x - 40, 80), 26, Px.MUTED)
		for i in items.size():
			var it: Array = items[i]
			var x := 20 + i * 205
			Px.fit(ci, Px.tex(String(it[0])), Rect2(x + 60, 56, 76, 70))
			Px.text(ci, String(it[1]), Rect2(x, 130, 196, 40), 24, Px.GOLD))
	put(rw, Rect2(30, 610, w - 60, 190))
	if not victory and bool(p.get("can_continue", false)):
		var cont := PxButton.colored("purple", DB.t("result.continue"), Vector2(560, 130), 40)
		cont.sub = "100"
		cont.sub_icon = Px.tex("icon_diamond")
		cont.pulse = true
		cont.pressed.connect(func() -> void:
			var b: Node = Game.app.current
			if b != null and b.has_method("continue_run") and b.continue_run():
				close())
		put(cont, Rect2(180, 830, 560, 130))
	var home := PxButton.colored("blue", DB.t("result.lobby"), Vector2(380, 130), 40)
	home.pressed.connect(func() -> void: _leave("lobby"))
	put(home, Rect2(60, 1000, 380, 130))
	var again_label := DB.t("result.next") if victory and int(p["stage"]) < 8 else DB.t("result.again")
	var again := PxButton.colored("yellow", again_label, Vector2(380, 130), 40)
	again.pressed.connect(func() -> void: _leave("again"))
	put(again, Rect2(480, 1000, 380, 130))
	if bool(p.get("tutorial", false)) and victory:
		again.disabled = true
		home.pulse = true
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	for c in panel.get_children():
		if c is DrawLayer:
			c.queue_redraw()


func _leave(where: String) -> void:
	if not victory:
		var b: Node = Game.app.current
		if b != null and b.has_method("give_up"):
			b.give_up()
	var c := int(p["chapter"])
	var s := int(p["stage"])
	if where == "lobby":
		Game.app.goto("lobby", {"tutorial_recruit": bool(p.get("tutorial", false)) and victory})
		return
	if victory and s < 8:
		s += 1
	elif victory and c < DB.chapters().size():
		c += 1
		s = 1
	Game.next_stage = {"chapter": c, "stage": s}
	Game.app.goto("battle", {"chapter": c, "stage": s})
