extends PxScreen
## 상점 (개편 §13): 추천 · 금 · 군량 · 꾸러미 탭. 현금으로 파는 것은 금뿐이고,
## 군량은 금으로 채운다. 결제는 "개발용 가상 결제" — 실제 돈이 나가지 않는다.

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
		Px.fit(b, Px.tex("icon_gold"), Rect2(r.position + Vector2(30, 40), Vector2(150, 150)))
		Px.text(b, String(mo["name"]), Rect2(r.position + Vector2(210, 26), Vector2(440, 54)), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, String(mo["desc"]), Rect2(r.position + Vector2(210, 86), Vector2(440, 40)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.monthly_now", [Px.num(int(mo["now"]))]), Rect2(r.position + Vector2(210, 128), Vector2(440, 40)), 26, Color("#9be27a"), HORIZONTAL_ALIGNMENT_LEFT)
		if days_left > 0:
			Px.text(b, DB.t("shop.monthly_left", [days_left]), Rect2(r.position + Vector2(210, 172), Vector2(440, 40)), 26, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("shop.value", [Px.num(int(mo["daily"]) * int(mo["days"]) + int(mo["now"]))]), Rect2(r.position + Vector2(660, 30), Vector2(250, 40)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	_price_btn(c, Rect2(676, y + 140, 240, 90), Px.won(int(mo["price"])), "yellow", "", func() -> void: _buy("monthly", String(mo["name"]), String(mo["desc"]), int(mo["price"])))
	y += 270
	# 첫 꾸러미
	var p0: Dictionary = sh["packages"][0]
	y = _pack_row(c, p0, y)
	return y


# ------------------------------------------------------------------ 금 (현금으로 사는 유일한 재화)

func _dia(c: Control) -> float:
	var sh := DB.shop
	var list: Array = sh["gold_packs"]
	var cw := 300.0
	var ch := 380.0
	for i in list.size():
		var p: Dictionary = list[i]
		var first: bool = bool(sh["first_double"]) and not Game.profile.data["shop"]["first"].has(String(p["id"]))
		var r := Rect2((i % 3) * (cw + 22), (i / 3) * (ch + 22), cw, ch)
		var size_k := 0.55 + 0.09 * i
		_card(c, r, func(b: PxButton, rr: Rect2) -> void:
			var s := 170.0 * size_k
			Px.fit(b, Px.tex("icon_gold"), Rect2(rr.position + Vector2((cw - s) * 0.5, 130 - s * 0.5), Vector2(s, s)))
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


# ------------------------------------------------------------------ 군량 (금으로 채운다)

func _gold(c: Control) -> float:
	var p := Game.profile
	var cap := int(DB.rules["rice_max"])
	var cost := p.rice_refill_cost()
	_card(c, Rect2(0, 0, 944, 220), func(b: PxButton, r: Rect2) -> void:
		Px.fit(b, Px.tex("icon_rice"), Rect2(r.position + Vector2(40, 40), Vector2(140, 140)))
		Px.text(b, DB.t("rice.name"), Rect2(r.position + Vector2(220, 30), Vector2(440, 56)), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(b, DB.t("rice.desc", [int(DB.rules["rice_price"]), p.rice_now(), cap]), Rect2(r.position + Vector2(220, 94), Vector2(440, 40)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		var nxt := p.rice_next_sec()
		Px.text(b, DB.t("rice.full") if nxt <= 0 else DB.t("rice.next", [Profile.format_hms(nxt)]), Rect2(r.position + Vector2(220, 140), Vector2(440, 40)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	_price_btn(c, Rect2(676, 66, 240, 90), Px.num(cost) if cost > 0 else DB.t("rice.full"), "yellow" if cost > 0 else "blue", "icon_gold" if cost > 0 else "", func() -> void:
		var why := p.refill_rice()
		if why != "":
			toast(why)
			Sfx.play("error")
		else:
			Sfx.play("coin")
			toast(DB.t("rice.done"))
			_rebuild(), cost <= 0)
	var info := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("icon_rice"), Rect2(24, 24, 72, 72))
		Px.paragraph(ci, DB.t("rice.rule"), Rect2(116, 16, ci.size.x - 136, ci.size.y - 32), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4), Vector2(944, 130))
	info.position = Vector2(0, 240)
	c.add_child(info)
	return 390.0


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
	if p.has("rice"):
		icons.append(["icon_rice", "×%d" % int(p["rice"])])
	if p.has("gold"):
		icons.append(["icon_gold", Px.short(int(p["gold"]))])
	if p.has("mats"):
		icons.append(["icon_chest", "×%d" % int(p["mats"])])
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
