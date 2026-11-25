extends PxScreen
## 상점 (개편 §13): 추천 · 금 · 군량 · 꾸러미 탭. 현금으로 파는 것은 금뿐이고,
## 군량은 금으로 채운다. 결제는 "개발용 가상 결제" — 실제 돈이 나가지 않는다.
## 자리는 8차 시안(design/art/ui_src/상점8_완성화면.png)에서 잰 화면 px 그대로:
## 탭 4개 / (추천 탭만) 배너 칸 / 상품 줄 — 줄마다 왼쪽 그림 틀 · 가운데 이름과 설명 · 오른쪽 노란 값 버튼.

const TAB_AT := Vector2(121, 346)
const AREA := Rect2(120, 464, 783, 1006)       # 줄이 구르는 칸 (안쪽 판 안)
const ROW := Vector2(783, 162)                  # 상품 줄
const ROW_STEP := 180.0
const PIC := Rect2(20, 17, 128, 128)            # 줄 안의 그림 틀
const PRICE := Rect2(588, 46, 177, 70)          # 줄 안의 값 버튼
const BANNER_H := 212.0

var tab := 0
var _t := 0.0


## 8차 시안 좌표(화면 px 그대로)로 짠 화면이다 — app.gd 가 창 틀 안에 그대로 놓는다.
func native8() -> bool:
	return true


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
	put(W.icon_tabs(["tab_pick", "icon_gold", "icon_rice", "tab_pack"], tab, 175, func(i: int) -> void:
		tab = i
		Sfx.play("click")
		_rebuild(), [DB.t("shop.t_rec"), DB.t("shop.t_dia"), DB.t("shop.t_gold"), DB.t("shop.t_pack")]), Rect2(TAB_AT, Vector2(700, 101)))
	var c := W.scroll(self, AREA, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var h := 0.0
	match tab:
		0: h = _rec(c)
		1: h = _dia(c)
		2: h = _gold(c)
		3: h = _pack(c)
	var note := DrawLayer.make(func(ci: Control) -> void:
		Px.paragraph(ci, DB.t("shop.mock_note"), Rect2(Vector2.ZERO, ci.size), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4), Vector2(ROW.x, 56))
	note.position = Vector2(0, h + 4)
	c.add_child(note)
	c.custom_minimum_size.y = h + 66


## 상품 줄 하나: 금테 어두운 줄 + 왼쪽 그림 틀(아이콘) + 가운데 글자(draw 가 그린다) + 오른쪽 값 버튼.
## [param price] 가 "" 이면 값 버튼이 없다.
func _row(c: Control, y: float, icon: String, draw: Callable, price: String, on_buy: Callable, disabled := false, price_icon := "") -> void:
	var row := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.nine(ci, "kit_box", PIC)
		if icon != "":
			Px.fit(ci, Px.tex(icon), PIC.grow(-22))
		draw.call(ci, Rect2(PIC.end.x + 20, 14, PRICE.position.x - PIC.end.x - 34, ROW.y - 28)), ROW)
	row.position = Vector2(0, y)
	c.add_child(row)
	if price == "":
		return
	var b := PxButton.make("kit_btn_yellow", true, PRICE.size)
	b.font_size = 26
	b.text_color = Color("#3a2a10")
	b.text = price
	if price_icon != "":
		b.icon = Px.tex(price_icon)
		b.icon_rect = Rect2(14, 16, 38, 38)
		b.text_rect = Rect2(52, 0, PRICE.size.x - 62, PRICE.size.y)
	b.position = Vector2(0, y) + PRICE.position
	b.disabled = disabled
	b.pressed.connect(on_buy)
	c.add_child(b)


# ------------------------------------------------------------------ 추천

func _rec(c: Control) -> float:
	var sh := DB.shop
	# 배너 칸
	var ban := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.nine(ci, "kit_box", r)
		var inner := r.grow(-14)
		Px.cover(ci, Px.tex("shop_banner"), inner)
		ci.draw_rect(Rect2(inner.position.x + inner.size.x * 0.5, inner.position.y, inner.size.x * 0.5, inner.size.y), Color(0.16, 0.1, 0.06, 0.55))
		Px.paragraph(ci, DB.t("shop.banner"), Rect2(r.size.x * 0.52, 30, r.size.x * 0.44, r.size.y - 60), 34, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 6), Vector2(ROW.x, BANNER_H))
	c.add_child(ban)
	var y := BANNER_H + 18
	# 월정액
	var mo: Dictionary = sh["monthly"]
	var now := int(Time.get_unix_time_from_system())
	var until := int(Game.profile.data["shop"]["monthly_until"])
	var days_left := maxi(0, ceili((until - now) / 86400.0))
	_row(c, y, "icon_gold", func(ci: Control, r: Rect2) -> void:
		Px.text(ci, String(mo["name"]), Rect2(r.position, Vector2(r.size.x, 40)), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, String(mo["desc"]), Rect2(r.position + Vector2(0, 42), Vector2(r.size.x, 30)), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("shop.monthly_now", [Px.num(int(mo["now"]))]), Rect2(r.position + Vector2(0, 72), Vector2(r.size.x, 28)), 20, Color("#9be27a"), HORIZONTAL_ALIGNMENT_LEFT)
		if days_left > 0:
			Px.text(ci, DB.t("shop.monthly_left", [days_left]), Rect2(r.position + Vector2(0, 102), Vector2(r.size.x, 28)), 20, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT)
		else:
			Px.text(ci, DB.t("shop.value", [Px.num(int(mo["daily"]) * int(mo["days"]) + int(mo["now"]))]), Rect2(r.position + Vector2(0, 102), Vector2(r.size.x, 28)), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT),
		Px.won(int(mo["price"])), func() -> void: _buy("monthly", String(mo["name"]), String(mo["desc"]), int(mo["price"])))
	y += ROW_STEP
	# 첫 꾸러미
	var p0: Dictionary = sh["packages"][0]
	return _pack_row(c, p0, y)


# ------------------------------------------------------------------ 금 (현금으로 사는 유일한 재화)

func _dia(c: Control) -> float:
	var sh := DB.shop
	var list: Array = sh["gold_packs"]
	for i in list.size():
		var p: Dictionary = list[i]
		var first: bool = bool(sh["first_double"]) and not Game.profile.data["shop"]["first"].has(String(p["id"]))
		_row(c, i * ROW_STEP, "icon_gold", func(ci: Control, r: Rect2) -> void:
			Px.text(ci, DB.t("shop.dia_name", [Px.num(int(p["amount"]))]), Rect2(r.position + Vector2(0, 14), Vector2(r.size.x, 46)), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			if first:
				var fr := Rect2(r.position + Vector2(0, 70), Vector2(150, 40))
				ci.draw_rect(fr, Px.INK)
				ci.draw_rect(fr.grow(-3), Color("#c8352e"))
				Px.text(ci, DB.t("shop.first"), fr, 20)
				Px.text(ci, "+" + Px.num(int(p["amount"])), Rect2(fr.end.x + 12, fr.position.y, 200, 40), 24, Color("#ff8a80"), HORIZONTAL_ALIGNMENT_LEFT),
			Px.won(int(p["price"])),
			func() -> void: _buy(String(p["id"]), DB.t("shop.dia_name", [Px.num(int(p["amount"]))]),
				DB.t("shop.first_desc", [Px.num(int(p["amount"]) * 2)]) if first else DB.t("shop.dia_desc", [Px.num(int(p["amount"]))]), int(p["price"])))
	return list.size() * ROW_STEP


# ------------------------------------------------------------------ 군량 (금으로 채운다)

func _gold(c: Control) -> float:
	var p := Game.profile
	var cap := int(DB.rules["rice_max"])
	var cost := p.rice_refill_cost()
	_row(c, 0, "icon_rice", func(ci: Control, r: Rect2) -> void:
		Px.text(ci, DB.t("rice.name"), Rect2(r.position, Vector2(r.size.x, 42)), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.paragraph(ci, DB.t("rice.desc", [int(DB.rules["rice_price"]), p.rice_now(), cap]), Rect2(r.position + Vector2(0, 44), Vector2(r.size.x, 52)), 18, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 3)
		var nxt := p.rice_next_sec()
		Px.text(ci, DB.t("rice.full") if nxt <= 0 else DB.t("rice.next", [Profile.format_hms(nxt)]), Rect2(r.position + Vector2(0, 102), Vector2(r.size.x, 28)), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT),
		Px.num(cost) if cost > 0 else DB.t("rice.full"), func() -> void:
			var why := p.refill_rice()
			if why != "":
				toast(why)
				Sfx.play("error")
			else:
				Sfx.play("coin")
				toast(DB.t("rice.done"))
				_rebuild(), cost <= 0, "icon_gold" if cost > 0 else "")
	_row(c, ROW_STEP, "icon_rice", func(ci: Control, r: Rect2) -> void:
		Px.paragraph(ci, DB.t("rice.rule"), Rect2(r.position, Vector2(r.size.x + PRICE.size.x + 10, r.size.y)), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 4), "", Callable())
	return ROW_STEP * 2


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
	var sold := bought >= lim
	_row(c, y, "tab_pack", func(ci: Control, r: Rect2) -> void:
		Px.text(ci, String(p["name"]), Rect2(r.position, Vector2(r.size.x - 110, 40)), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("shop.limit", [bought, lim]), Rect2(r.position + Vector2(r.size.x - 110, 0), Vector2(110, 40)), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		# 들어 있는 것: 아이콘 + 수 (한 줄)
		for k in icons.size():
			var it: Array = icons[k]
			var at := r.position + Vector2(k * 136, 56)
			Px.fit(ci, Px.tex(String(it[0])), Rect2(at, Vector2(52, 52)))
			Px.text(ci, String(it[1]), Rect2(at + Vector2(56, 0), Vector2(78, 52)), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT),
		DB.t("shop.sold_out") if sold else Px.won(int(p["price"])),
		func() -> void: _buy(String(p["id"]), String(p["name"]), String(p["desc"]), int(p["price"])), sold)
	return y + ROW_STEP


func _buy(id: String, name: String, desc: String, price: int) -> void:
	var p: PxPopup = Game.app.popup("purchase", {"id": id, "name": name, "desc": desc, "price": price})
	p.closed.connect(_rebuild)
