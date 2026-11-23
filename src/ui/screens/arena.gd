extends PxScreen
## 군웅대전 (콘텐츠-기획-v5 §7): 하루 무료 5회(04:00 초기화), 추가 입장 다이아,
## 매판 군공(승 20 / 패 5), 군웅 상점(§7.1). 대전 자체는 서버가 필요해서 아직
## 결과만 정하는 임시 판정이다.

var _t := 0.0
var _art: DrawLayer


func build() -> void:
	bg = Px.tex("stage_bg")
	bg_dim = 0.45
	set_process(true)
	W.top_bar(self, DB.t("tab.arena"))
	_art = DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.draw_skin(ci, "panel_ctrl", r)
		var bob := roundf(sin(_t * 2.0) * 6.0)
		Px.fit(ci, Px.tex("icon_swords"), Rect2(r.size.x * 0.5 - 110, 60 + bob, 220, 220))
		Px.text(ci, DB.t("arena.title"), Rect2(0, 290, r.size.x, 80), 60, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 8)
		Px.paragraph(ci, DB.t("arena.desc"), Rect2(60, 380, r.size.x - 120, 100), 28, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 6)
		var st := Game.profile.sync_arena_entries()
		var n := int(st["entries"])
		var er := Rect2(120, 500, r.size.x - 240, 120)
		ci.draw_rect(er, Px.INK)
		ci.draw_rect(er.grow(-4), Color("#2b1c11"))
		Px.text(ci, DB.t("arena.entries", [n, int(st["max"]) + int(st["bought"])]), Rect2(er.position.x, er.position.y + 8, er.size.x, 54), 40, Px.GOLD if n > 0 else Color("#ff8a80"))
		Px.text(ci, DB.t("arena.refill", [Profile.format_hms(int(st["next_sec"]))]), Rect2(er.position.x, er.position.y + 64, er.size.x, 44), 28, Px.WHITE)
		var hr := Rect2(120, 640, r.size.x - 240, 90)
		ci.draw_rect(hr, Px.INK)
		ci.draw_rect(hr.grow(-4), Color("#241810"))
		Px.fit(ci, Px.tex("icon_medal"), Rect2(hr.position.x + 24, hr.position.y + 14, 62, 62))
		Px.text(ci, DB.t("arena.honor", [Px.num(int(Game.profile.data["honor"]))]), hr, 34, Px.GOLD)
		var power := 0
		for id: String in Game.lineup():
			power += MetaRules.hero_power(Game.profile.data, id)
		Px.text(ci, DB.t("arena.power", [Px.num(power)]), Rect2(0, 750, r.size.x, 50), 30, Px.WHITE), Vector2(904, 840))
	put(_art, Rect2(60, 220, 904, 840))
	var tw := _art.create_tween().set_loops()
	tw.tween_callback(_art.queue_redraw).set_delay(0.2)
	# 추가 입장 · 군웅 상점
	var buy := PxButton.colored("purple", DB.t("arena.buy"), Vector2(420, 120), 34)
	buy.sub = str(int(DB.meta["arena"]["extra_cost"]))
	buy.sub_icon = Px.tex("icon_gold")
	buy.pressed.connect(_ask_buy)
	put(buy, Rect2(70, 1090, 420, 120))
	var shop := PxButton.colored("yellow", DB.t("arena.shop"), Vector2(420, 120), 34)
	shop.icon = Px.tex("icon_medal")
	shop.icon_rect = Rect2(28, 26, 68, 68)
	shop.text_rect = Rect2(90, 0, 320, 120)
	shop.pressed.connect(func() -> void:
		var p := Game.app.popup("arena_shop")
		p.closed.connect(_art.queue_redraw))
	put(shop, Rect2(534, 1090, 420, 120))
	var go := PxButton.colored("red", DB.t("arena.fight"), Vector2(500, 130), 42)
	go.icon = Px.tex("icon_swords")
	go.icon_rect = Rect2(46, 30, 68, 68)
	go.text_rect = Rect2(100, 0, 360, 130)
	go.pressed.connect(_fight)
	put(go, Rect2(262, 1250, 500, 130))


func _fight() -> void:
	if not Game.profile.use_arena_entry():
		toast(DB.t("arena.no_entry"))
		Sfx.play("error")
		return
	# 임시 판정: 서버·대전 규칙이 들어오기 전까지는 항상 승리로 처리한다.
	var hn := Game.profile.finish_arena(true)
	Sfx.play("victory")
	toast(DB.t("arena.win", [hn]))
	_art.queue_redraw()


func _ask_buy() -> void:
	var st := Game.profile.sync_arena_entries()
	if int(st["bought"]) >= int(st["buy_max"]):
		toast(DB.t("arena.buy_limit"))
		Sfx.play("error")
		return
	var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("arena.buy"),
		"text": DB.t("arena.buy_confirm", [int(st["buy_cost"]), int(st["bought"]), int(st["buy_max"])]), "ok": DB.t("common.buy")})
	c.connect("confirmed", func() -> void:
		var err := Game.profile.buy_arena_entry()
		if err != "":
			toast(err)
			Sfx.play("error")
		else:
			Sfx.play("coin")
		_art.queue_redraw())


func _process(delta: float) -> void:
	_t += delta
