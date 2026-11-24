class_name W
extends RefCounted
## Widget factory: currency chips, top bar, bottom tab bar, portraits, hero
## cards and settings controls, all from the cut parts (화면 설계서 §2).

const SLOT_ICON := {"weapon": "ic_sword", "armor": "ic_shield", "charm": "ic_orb"}


## Currency chip (panel + icon + live number + optional plus).
static func chip(icon_name: String, getter: Callable, sz: Vector2, on_plus: Callable = Callable()) -> PxButton:
	var p := PxButton.make("panel_chip", true, sz)
	p.static_panel = not on_plus.is_valid()
	var h := sz.y
	p.icon = Px.tex(icon_name)
	p.icon_rect = Rect2(Vector2(h * 0.12, h * 0.12), Vector2(h * 0.76, h * 0.76))
	p.font_size = int(h * 0.32)
	var plus_w := h * 0.66 if on_plus.is_valid() else 0.0
	p.text_rect = Rect2(Vector2(h * 0.92, 0), Vector2(sz.x - h * 0.92 - plus_w - h * 0.2, h))
	p.text_align = HORIZONTAL_ALIGNMENT_RIGHT
	p.text = str(getter.call())
	if on_plus.is_valid():
		p.static_panel = false
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.pressed.connect(on_plus)
		var ps := roundf(h * 0.66 / 4.0) * 4.0
		var plus := PxButton.make("btn_plus", false, Vector2(ps, ps))
		plus.position = Vector2(sz.x - ps - roundf(h * 0.13 / 4.0) * 4.0, roundf((h - ps) * 0.5))
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(plus)
	var refresh := func() -> void:
		if is_instance_valid(p):
			p.text = str(getter.call())
	Game.profile.changed.connect(refresh)
	p.tree_exiting.connect(func() -> void:
		if Game.profile.changed.is_connected(refresh):
			Game.profile.changed.disconnect(refresh))
	return p


static func gold_chip(sz: Vector2, plus := true) -> PxButton:
	return chip("icon_gold", func() -> String: return Px.num(int(Game.profile.data["gold"])), sz,
		(func() -> void: Game.app.goto("shop", {"tab": 1})) if plus else Callable())


## 군량 칩: 지금 / 최대. "+"를 누르면 금으로 가득 채울지 묻는다 (개편 §13).
static func rice_chip(sz: Vector2, plus := true) -> PxButton:
	return chip("icon_rice", func() -> String: return "%d/%d" % [Game.profile.rice_now(), int(DB.rules["rice_max"])], sz,
		ask_rice if plus else Callable())


## 군량 즉시 충전: asks, then pays 금 and fills 군량.
static func ask_rice() -> void:
	var p := Game.profile
	var cost := p.rice_refill_cost()
	if cost <= 0:
		Game.app.toast(DB.t("rice.full"))
		return
	var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("rice.title"),
		"text": DB.t("rice.ask", [Px.num(cost), p.rice_now(), int(DB.rules["rice_max"])]), "ok": DB.t("common.buy")})
	c.connect("confirmed", func() -> void:
		var why := p.refill_rice()
		if why != "":
			Game.app.toast(why)
			Sfx.play("error")
		else:
			Sfx.play("coin")
			Game.app.toast(DB.t("rice.done")))


## Square back button (◀) at the top left.
static func back_button(on_back: Callable) -> PxButton:
	return arrow_button(-1, on_back, Vector2(100, 92))


## Common top row for sub screens: back · title ribbon · 금 · 군량.
static func top_bar(screen: PxScreen, title: String, show_back := true) -> void:
	if screen.dialog:
		return
	if show_back:
		screen.put(back_button(func() -> void: screen.back()), Rect2(28, 32, 100, 92))
	var rib := DrawLayer.make(func(ci: Control) -> void: Px.ribbon(ci, Rect2(Vector2.ZERO, ci.size), title, 46))
	screen.put(rib, Rect2(140, 22, 380, 110))
	screen.put(gold_chip(Vector2(232, 76)), Rect2(530, 40, 232, 76))
	screen.put(rice_chip(Vector2(232, 76)), Rect2(772, 40, 232, 76))


## Face portrait in a faction-coloured tile with rarity frame and optional stars.
## [param owned] false = dark silhouette.
static func portrait(id: String, sz: Vector2, opts: Dictionary = {}) -> Control:
	var root := Control.new()
	root.size = sz
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fac := DB.fac_of(id)
	var rar := DB.rarity_of(id)
	var owned: bool = opts.get("owned", true)
	var bgc := DB.fac_color(fac) if fac != "" else Color("#5b6b7e")
	var bg := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		ci.draw_rect(r.grow(-4), bgc.darkened(0.35) if owned else Color("#332a21"))
		ci.draw_rect(Rect2(4, 4, r.size.x - 8, r.size.y * 0.45), (bgc if owned else Color("#36404e")).darkened(0.1)), sz)
	root.add_child(bg)
	var a := Art.of_unit(id)
	var face := ArtRect.new()
	face.texture = Art.portrait(String(a["art"]))
	face.position = Vector2(6, 6)
	face.size = sz - Vector2(12, 12)
	face.focus_y = 0.2
	face.set_look(float(a["hue"]), float(opts.get("gray", 0.0)), 0.0 if owned else 0.92)
	root.add_child(face)
	var ov := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		var rc := DB.rarity_color(rar)
		ci.draw_rect(r.grow(-2), rc if owned else Color("#4a5566"), false, 5.0)
		ci.draw_rect(r, Px.INK, false, 3.0)
		if opts.has("stars") and owned:
			Px.stars(ci, Vector2(ci.size.x * 0.5, ci.size.y - 16), int(opts["stars"]), int(opts.get("star_total", 6)), minf(24.0, ci.size.x / 7.0))
		if opts.has("label"):
			Px.text(ci, String(opts["label"]), Rect2(0, ci.size.y - 40, ci.size.x, 36), int(opts.get("label_size", 24)))
, sz)
	root.add_child(ov)
	return root


## Row panel used by lists (missions, mail, settings).
static func row_panel(sz: Vector2) -> PxButton:
	var p := PxButton.make("panel_small", true, sz)
	p.static_panel = true
	return p


## Small reward strip: icons + amounts (gold / diamond / tickets / boxes ...).
static func reward_text(rw: Dictionary) -> String:
	var parts: Array = []
	for k: String in rw:
		match k:
			"gold":
				parts.append("금 " + Px.num(int(rw[k])))
			"diamond":
				parts.append("금 " + Px.num(int(rw[k]) * Profile.DIAMOND_GOLD))
			"rice":
				parts.append("군량 " + str(int(rw[k])))
			"tickets":
				parts.append("군량 " + str(int(rw[k]) * Profile.TICKET_RICE))
			"mats":
				parts.append("보물 재료 " + str(int(rw[k])))
			"material":
				parts.append(DB.t("synth.mat_name", [DB.t("rarity_t." + String(rw[k]["rarity"])), DB.t("slot." + String(rw[k]["slot"]))]))
			"skin":
				parts.append(String(rw[k]))
			"treasure":
				parts.append(String(DB.treasure_def(String(rw[k])).get("name", "보물")))
	return " · ".join(parts)


static func reward_icon(rw: Dictionary) -> String:
	for k in ["gold", "diamond", "rice", "tickets", "mats", "material", "treasure", "skin"]:
		if rw.has(k):
			match k:
				"gold", "diamond":
					return "icon_gold"
				"rice", "tickets":
					return "icon_rice"
				"mats", "material", "treasure":
					return "icon_chest"
				"skin":
					return "icon_hero"
	return "icon_chest"


## Touch-scrollable area. Returns the content Control (children placed in
## content-local px; set content.custom_minimum_size.y to the total height).
static func scroll(screen: Control, r: Rect2, put_fn: Callable = Callable()) -> Control:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.scroll_deadzone = 12
	sc.size = r.size
	var content := Control.new()
	content.custom_minimum_size = Vector2(r.size.x, r.size.y)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	sc.add_child(content)
	if put_fn.is_valid():
		put_fn.call(sc, r)
	else:
		sc.position = r.position
		screen.add_child(sc)
	return content


## Tab strip (segmented chunky tabs). [param on_pick] gets the index.
static func tabs(labels: Array, selected: int, sz: Vector2, on_pick: Callable, colors: Array = []) -> Control:
	var root := Control.new()
	root.size = sz
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := labels.size()
	var w := (sz.x - (n - 1) * 8.0) / n
	for i in n:
		var b := PxButton.colored("wood_on" if i == selected else "wood", String(labels[i]), Vector2(w, sz.y if i == selected else sz.y - 6), 32)
		if i != selected:
			b.text_color = Px.MUTED
		elif not Px.has_nine("dlg_tab_on"):
			b.highlight = true
		# 공용 다이얼로그 탭 그림 (고른 탭 금테 · 안 고른 탭 회색, 9-slice)
		if Px.has_nine("dlg_tab_on"):
			b.part = "dlg_tab_on" if i == selected else "dlg_tab_off"
		b.position = Vector2(i * (w + 8.0), 0 if i == selected else 6)
		var idx := i
		b.pressed.connect(func() -> void: on_pick.call(idx))
		root.add_child(b)
	return root


## 공용 다이얼로그 카드 칸 (장수 · 병사 · 장비 칸): 그림(dlg_card, 9-slice)이 있으면 그것, 없으면 선 UI 판.
static func card_part() -> String:
	return "dlg_card" if Px.has_nine("dlg_card") else "panel_slot"


## 공용 고르기 칩 (진영 · 종류 거르기, 내것만 등): 고른 칩 금테 · 안 고른 칩 회색 (dlg_chip_on/off, 9-slice).
static func pick_chip(label: String, on: bool, sz: Vector2) -> PxButton:
	var art := Px.has_nine("dlg_chip_on")
	var b := PxButton.make(("dlg_chip_on" if on else "dlg_chip_off") if art else "btn_small", true, sz)
	b.font_size = 24
	b.set_label(label)
	b.highlight = on and not art
	if art and not on:
		b.text_color = Px.MUTED
	return b


## Dark rounded section panel with optional title.
static func section(sz: Vector2, title: String = "") -> DrawLayer:
	return DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.draw_skin(ci, "panel_slot", r)
		if title != "":
			Px.text(ci, title, Rect2(24, 12, ci.size.x - 48, 44), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT), sz)


## Treasure tile: slot icon on rarity colour, +level, wearer face.
static func treasure_cell(it: Dictionary, sz: Vector2) -> PxButton:
	var d := DB.treasure_def(String(it["tid"]))
	var rc := DB.rarity_color(String(d["rarity"]))
	var b := PxButton.new()
	b.size = sz
	var owner := MetaRules.treasure_owner(Game.profile.data, int(it["uid"]))
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var r := Rect2(off, btn.size)
		btn.draw_rect(r, Px.INK)
		btn.draw_rect(r.grow(-4), rc)
		btn.draw_rect(r.grow(-10), rc.darkened(0.55))
		btn.draw_rect(Rect2(r.position + Vector2(10, 10), Vector2(r.size.x - 20, r.size.y * 0.4)), rc.darkened(0.4))
		Px.fit(btn, Px.tex(String(W.SLOT_ICON[String(d["slot"])])), Rect2(r.position + r.size * 0.22, r.size * 0.56))
		Px.text(btn, "+%d" % int(it["lv"]), Rect2(r.position + Vector2(10, 8), Vector2(r.size.x - 20, 36)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		Px.text(btn, String(d["name"]), Rect2(r.position + Vector2(6, r.size.y - 40), Vector2(r.size.x - 12, 34)), 20, Px.WHITE)
		if owner != "":
			var fr := Rect2(r.position + Vector2(10, 10), Vector2(50, 50))
			btn.draw_rect(fr, Px.INK)
			Px.cover(btn, Art.hued_portrait(String(Art.of_unit(owner)["art"]), float(Art.of_unit(owner)["hue"])), fr.grow(-3))
	return b


## Compact rank tag on a transparent background: small star(s) for 성급 and
## "Lv N" in outlined text (민수 님 피드백: 받침 판 없음).
static func draw_rank(ci: CanvasItem, r: Rect2, stars: int, lv: int, size: float = 22.0) -> void:
	var lab := "Lv%d" % lv if lv > 0 else ""
	var fs := int(size * 1.05)
	var gap := size * 0.92
	var sw := gap * stars
	var tw := Px.text_width(lab, fs) if lab != "" else 0.0
	var x := r.position.x + (r.size.x - sw - (6.0 + tw if lab != "" else 0.0)) * 0.5
	var y := r.position.y + (r.size.y - size) * 0.5
	var st := Px.tex("ic_star")
	for i in stars:
		var sr := Rect2(x + i * gap, y, size, size)
		Px.fit(ci, st, sr.grow(2.0), Px.INK)
		Px.fit(ci, st, sr)
	if lab != "":
		Px.text(ci, lab, Rect2(x + sw + 6.0, r.position.y, tw + 6.0, r.size.y), fs, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)


# ---------------------------------------------------------------- shared kit
# 민수 님 원칙: 모든 화면이 같은 부품을 쓴다 (크기 · 여백 · 색 · 글꼴 · 상태).

const BTN := Vector2(240, 96)
const BTN_WIDE := Vector2(560, 110)
const CLOSE := Vector2(96, 88)   # 닫기 그림(btn_close) 비율에 맞춤
const ARROW := Vector2(84, 96)


## Red X used by every pop-up and tab dialog. 그림(btn_close: 흰 X 붉은 버튼, 2026-11-24)이 있으면 그 그림.
static func close_button(on_close: Callable) -> PxButton:
	if Px.has_art("btn_close"):
		var pic := PxButton.make("btn_close", false, CLOSE)
		pic.pressed.connect(on_close)
		return pic
	var x := PxButton.colored("red", "", CLOSE)
	x.overlay = func(b: PxButton, off: Vector2) -> void:
		var c := b.size * 0.5 + off + Vector2(0, -2)
		for sgn in [-1, 1]:
			b.draw_line(c + Vector2(-17, -17 * sgn), c + Vector2(17, 17 * sgn), Px.INK, 15)
			b.draw_line(c + Vector2(-17, -17 * sgn), c + Vector2(17, 17 * sgn), Px.WHITE, 8)
	x.pressed.connect(on_close)
	return x


## Wood arrow button (◀ ▶) for prev / next.
static func arrow_button(side: int, on_tap: Callable, sz := ARROW) -> PxButton:
	# 공용 화살표 그림 (◀ btn_prev · ▶ btn_next, tools/import_detail_ui.py)
	var pic := "btn_prev" if side < 0 else "btn_next"
	if Px.has_art(pic):
		var a := PxButton.make(pic, false, sz)
		a.pressed.connect(on_tap)
		return a
	var b := PxButton.make("btn_small", true, sz)
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var c := btn.size * 0.5 + off + Vector2(0, -2)
		var pts := PackedVector2Array([c + Vector2(16 * side, 0), c + Vector2(-12 * side, -20), c + Vector2(-12 * side, 20)])
		var o := PackedVector2Array([c + Vector2(22 * side, 0), c + Vector2(-16 * side, -27), c + Vector2(-16 * side, 27)])
		btn.draw_colored_polygon(o, Px.INK)
		btn.draw_colored_polygon(pts, Px.WHITE)
	b.pressed.connect(on_tap)
	return b


## Player portrait frame: wood frame, clean avatar bust, outlined label (no plate).
static func portrait_frame(id: String, sz: Vector2, label := "") -> PxButton:
	var b := PxButton.make("frame_portrait", true, sz)
	var a := Art.of_unit(id)
	var tex := Art.avatar(String(a["art"]))
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var inner := Rect2(off + Vector2(12, 12), btn.size - Vector2(24, 24))
		Px.fit(btn, tex, Rect2(inner.position, Vector2(inner.size.x, inner.size.x)))
		if label != "":
			Px.text(btn, label, Rect2(off + Vector2(0, btn.size.y - 52), Vector2(btn.size.x, 40)), 30, Px.GOLD)
	return b


