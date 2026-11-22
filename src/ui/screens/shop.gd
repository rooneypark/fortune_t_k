extends PxScreen
## 상점 (화면-배치표 07-shop / 메타 §3.9): 추천·다이아·골드·패키지 탭.
## 결제는 "개발용 가상 결제" — 실제 돈이 나가지 않는다. 다이아로 군량은 살 수 없다.

var tab := 0
var _t := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.35
	tab = int(params.get("tab", 0))
	set_process(true)
	_rebuild()


func _process(delta: float) -> void:
	_t += delta


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("tab.shop"))
	put(W.tabs([DB.t("shop.t_rec"), DB.t("shop.t_dia"), DB.t("shop.t_gold"), DB.t("shop.t_pack")], tab, Vector2(944, 96), func(i: int) -> void:
		tab = i
		Sfx.play("click")
		_rebuild(), ["red", "purple", "yellow", "green"]), Rect2(40, 146, 944, 96))
	var area := Rect2(40, 262, 944, 1320)
	var c := W.scroll(self, area, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var h := 0.0
	match tab:
		0: h = _rec(c)
		1: h = _dia(c)
		2: h = _gold(c)
		3: h = _pack(c)
	var note := DrawLayer.make(func(ci: Control) -> void:
		Px.paragraph(ci, DB.t("shop.mock_note"), Rect2(Vector2.ZERO, ci.size), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4), Vector2(944, 70))
	note.position = Vector2(0, h + 10)
	c.add_child(note)
	c.custom_minimum_size.y = h + 90


func _card(c: Control, r: Rect2, draw: Callable, on_tap: Callable = Callable()) -> PxButton:
	var b := PxButton.new()
	b.size = r.size
	b.position = r.position
	b.press_depth = 3.0
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var rr := Rect2(off, btn.size)
		Px.draw_skin(btn, "panel_slot", rr)
		draw.call(btn, rr)
	if on_tap.is_valid():
		b.pressed.connect(on_tap)
	else:
		b.static_panel = true
	c.add_child(b)
	return b


func _price_btn(c: Control, r: Rect2, label: String, color: String, icon: String, on_tap: Callable, disabled := false) -> PxButton:
	var b := PxButton.colored(color, label, r.size, 30)
	if icon != "":
		b.icon = Px.tex(icon)
		b.icon_rect = Rect2(14, (r.size.y - 44) * 0.5, 44, 44)
		b.text_rect = Rect2(54, 0, r.size.x - 64, r.size.y)
	b.position = r.position
	b.disabled = disabled
	b.pressed.connect(on_tap)
	c.add_child(b)
	return b


# ------------------------------------------------------------------ 추천

func _rec(c: Control) -> float:
	var sh := DB.shop
	var y := 0.0
	# 배너
	var ban := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		Px.cover(ci, Px.tex("shop_banner"), r.grow(-5))
		var sx := fmod(_t * 260.0, r.size.x + 500.0) - 250.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, 5), Vector2(sx + 50, 5), Vector2(sx - 110, r.size.y - 5), Vector2(sx - 160, r.size.y - 5)]), Color(1, 1, 1, 0.12))
		for k in 8:
			ci.draw_rect(Rect2(r.size.x * 0.5 + k * 30, 5, r.size.x * 0.5 - k * 30 - 5, r.size.y - 10), Color(0.24, 0.12, 0.05, 0.07))
		Px.paragraph(ci, DB.t("shop.banner"), Rect2(r.size.x * 0.52, 60, r.size.x * 0.45, r.size.y - 120), 48, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 8), Vector2(944, 330))
	ban.set_process(true)
	ban.set_meta("anim", true)
	var tw := ban.create_tween().set_loops()
	tw.tween_callback(ban.queue_redraw).set_delay(1.0 / 30.0)
	c.add_child(ban)
	y += 350
	# 월정액
	var mo: Dictionary = sh["monthly"]
	var now := int(Time.get_unix_time_from_system())
	var until := int(Game.profile.data["shop"]["monthly_until"])
	var days_left := maxi(0, ceili((until - now) / 86400.0))
	_card(c, Rect2(0, y, 944, 250), func(b: PxButton, r: Rect2) -> void:
		Px.fit(b, Px.tex("icon_diamond"), Rect2(r.position + Vector2(30, 40), Vector2(150, 150)))
		Px.text(b, String(mo["name"]), Rect2(r.position + Vector2(210, 26), Vector2(440, 54)), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, String(mo["desc"]), Rect2(r.position + Vector2(210, 86), Vector2(440, 40)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.monthly_now", [int(mo["now"])]), Rect2(r.position + Vector2(210, 128), Vector2(440, 40)), 26, Color("#9be27a"), HORIZONTAL_ALIGNMENT_LEFT)
		if days_left > 0:
			Px.text(b, DB.t("shop.monthly_left", [days_left]), Rect2(r.position + Vector2(210, 172), Vector2(440, 40)), 26, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.value", [int(mo["daily"]) * int(mo["days"]) + int(mo["now"])]), Rect2(r.position + Vector2(660, 30), Vector2(250, 40)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	_price_btn(c, Rect2(676, y + 140, 240, 90), Px.won(int(mo["price"])), "yellow", "", func() -> void: _buy("monthly", String(mo["name"]), String(mo["desc"]), int(mo["price"])))
	y += 270
	# 보물 상자
	var cost := int(sh["box_cost"])
	_card(c, Rect2(0, y, 944, 250), func(b: PxButton, r: Rect2) -> void:
		var bob := roundf(sin(_t * 3.0) * 4.0)
		Px.fit(b, Px.tex("icon_chest"), Rect2(r.position + Vector2(30, 40 + bob), Vector2(150, 150)))
		Px.text(b, DB.t("shop.box"), Rect2(r.position + Vector2(210, 26), Vector2(440, 54)), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.box_desc"), Rect2(r.position + Vector2(210, 86), Vector2(460, 40)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		var bx: Dictionary = DB.meta["treasure"]["box"]
		Px.text(b, DB.t("odds.box_left", [maxi(1, int(bx["pity"]) - int(Game.profile.data["pity"]["box"]))]), Rect2(r.position + Vector2(210, 128), Vector2(460, 40)), 26, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT))
	var ob := PxButton.colored("blue", DB.t("recruit.odds"), Vector2(200, 70), 26)
	ob.position = Vector2(716, y + 22)
	ob.pressed.connect(func() -> void: Game.app.popup("odds", {"kind": "box"}))
	c.add_child(ob)
	_price_btn(c, Rect2(676, y + 140, 240, 90), Px.num(cost), "purple", "icon_diamond", func() -> void:
		var g := Game.profile.buy_box()
		if g.has("error"):
			toast(String(g["error"]))
			Sfx.play("error")
			return
		var p: PxPopup = Game.app.popup("reward", {"title": DB.t("treasure.got"), "reward": {}, "items": [g]})
		p.closed.connect(_rebuild))
	y += 270
	# 첫 꾸러미
	var p0: Dictionary = sh["packages"][0]
	y = _pack_row(c, p0, y)
	return y


# ------------------------------------------------------------------ 다이아

func _dia(c: Control) -> float:
	var sh := DB.shop
	var list: Array = sh["diamonds"]
	var cw := 300.0
	var ch := 380.0
	for i in list.size():
		var p: Dictionary = list[i]
		var first: bool = bool(sh["first_double"]) and not Game.profile.data["shop"]["first"].has(String(p["id"]))
		var r := Rect2((i % 3) * (cw + 22), (i / 3) * (ch + 22), cw, ch)
		var size_k := 0.55 + 0.09 * i
		_card(c, r, func(b: PxButton, rr: Rect2) -> void:
			var s := 170.0 * size_k
			Px.fit(b, Px.tex("icon_diamond"), Rect2(rr.position + Vector2((cw - s) * 0.5, 130 - s * 0.5), Vector2(s, s)))
			Px.text(b, Px.num(int(p["amount"])), Rect2(rr.position + Vector2(0, 222), Vector2(cw, 50)), 40, Px.WHITE)
			if first:
				var fr := Rect2(rr.position + Vector2(0, 16), Vector2(170, 44))
				b.draw_rect(fr, Px.INK)
				b.draw_rect(fr.grow(-3), Color("#ff3b30"))
				Px.text(b, DB.t("shop.first"), fr, 24)
				Px.text(b, "+" + Px.num(int(p["amount"])), Rect2(rr.position + Vector2(0, 186), Vector2(cw, 36)), 26, Color("#ff8a80")))
		_price_btn(c, Rect2(r.position + Vector2(20, 286), Vector2(cw - 40, 76)), Px.won(int(p["price"])), "yellow", "",
			func() -> void: _buy(String(p["id"]), DB.t("shop.dia_name", [Px.num(int(p["amount"]))]),
				DB.t("shop.first_desc", [Px.num(int(p["amount"]) * 2)]) if first else DB.t("shop.dia_desc", [Px.num(int(p["amount"]))]), int(p["price"])))
	return ceili(list.size() / 3.0) * (ch + 22)


# ------------------------------------------------------------------ 골드

func _gold(c: Control) -> float:
	var list: Array = DB.shop["gold"]
	var y := 0.0
	for i in list.size():
		var g: Dictionary = list[i]
		_card(c, Rect2(0, y, 944, 200), func(b: PxButton, r: Rect2) -> void:
			for k in i + 1:
				Px.fit(b, Px.tex("icon_gold"), Rect2(r.position + Vector2(40 + k * 34, 36 - k * 8), Vector2(120, 120)))
			Px.text(b, DB.t("shop.gold_name", [Px.num(int(g["gold"]))]), Rect2(r.position + Vector2(260, 40), Vector2(400, 56)), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(b, DB.t("shop.gold_desc") + " · " + DB.t("shop.gold_left", [Game.profile.gold_buys_left()]), Rect2(r.position + Vector2(260, 104), Vector2(400, 40)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		var idx := i
		_price_btn(c, Rect2(676, y + 56, 240, 90), Px.num(int(g["cost"])), "purple", "icon_diamond", func() -> void:
			var c2: PxPopup = Game.app.popup("confirm", {"title": DB.t("shop.t_gold"), "text": DB.t("shop.gold_confirm", [int(g["cost"]), Px.num(int(g["gold"]))]), "ok": DB.t("common.buy")})
			c2.confirmed.connect(func() -> void:
				var err := Game.profile.buy_gold(idx)
				if err != "":
					toast(err)
					Sfx.play("error")
				else:
					Sfx.play("coin")
					toast(DB.t("shop.bought"))))
		y += 220
	var info := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("icon_rice"), Rect2(24, 24, 72, 72))
		Px.paragraph(ci, DB.t("shop.rice_rule"), Rect2(116, 16, ci.size.x - 136, ci.size.y - 32), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4), Vector2(944, 130))
	info.position = Vector2(0, y)
	c.add_child(info)
	return y + 150


# ------------------------------------------------------------------ 패키지

func _pack(c: Control) -> float:
	var y := 0.0
	for p: Dictionary in DB.shop["packages"]:
		y = _pack_row(c, p, y)
	return y


func _pack_row(c: Control, p: Dictionary, y: float) -> float:
	var bought := int(Game.profile.data["shop"]["packages"].get(String(p["id"]), 0))
	var lim := int(p["limit"])
	var icons: Array = []
	if p.has("tickets"):
		icons.append(["ic_scroll", "×%d" % int(p["tickets"])])
	if p.has("gold"):
		icons.append(["icon_gold", Px.short(int(p["gold"]))])
	if p.has("diamond"):
		icons.append(["icon_diamond", Px.num(int(p["diamond"]))])
	if p.has("boxes"):
		icons.append(["icon_chest", "×%d" % int(p["boxes"])])
	_card(c, Rect2(0, y, 944, 260), func(b: PxButton, r: Rect2) -> void:
		Px.text(b, String(p["name"]), Rect2(r.position + Vector2(30, 20), Vector2(600, 54)), 38, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.limit", [bought, lim]), Rect2(r.position + Vector2(640, 26), Vector2(274, 40)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		for k in icons.size():
			var it: Array = icons[k]
			var cell := Rect2(r.position + Vector2(30 + k * 150, 86), Vector2(136, 150))
			b.draw_rect(cell, Px.INK)
			b.draw_rect(cell.grow(-3), Color("#2b1c11"))
			Px.fit(b, Px.tex(String(it[0])), Rect2(cell.position + Vector2(28, 12), Vector2(80, 80)))
			Px.text(b, String(it[1]), Rect2(cell.position + Vector2(0, 98), Vector2(136, 44)), 28, Px.WHITE))
	var sold := bought >= lim
	_price_btn(c, Rect2(676, y + 150, 240, 90), DB.t("shop.sold_out") if sold else Px.won(int(p["price"])), "yellow", "",
		func() -> void: _buy(String(p["id"]), String(p["name"]), String(p["desc"]), int(p["price"])), sold)
	return y + 280


func _buy(id: String, name: String, desc: String, price: int) -> void:
	var p: PxPopup = Game.app.popup("purchase", {"id": id, "name": name, "desc": desc, "price": price})
	p.closed.connect(_rebuild)
