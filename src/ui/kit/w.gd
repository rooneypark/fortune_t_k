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
		var plus := PxButton.make("btn_plus", false, Vector2(h * 0.66, h * 0.66))
		plus.position = Vector2(sz.x - h * 0.66 - h * 0.13, h * 0.17)
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
		(func() -> void: Game.app.goto("shop", {"tab": 2})) if plus else Callable())


static func diamond_chip(sz: Vector2, plus := true) -> PxButton:
	return chip("icon_diamond", func() -> String: return Px.num(int(Game.profile.data["diamond"])), sz,
		(func() -> void: Game.app.goto("shop", {"tab": 1})) if plus else Callable())


## Square back button (◀) at the top left.
static func back_button(on_back: Callable) -> PxButton:
	return arrow_button(-1, on_back, Vector2(100, 92))


## Common top row for sub screens: back · title ribbon · gold · diamond.
static func top_bar(screen: PxScreen, title: String, show_back := true) -> void:
	if screen.dialog:
		return
	if show_back:
		screen.put(back_button(func() -> void: screen.back()), Rect2(28, 32, 100, 92))
	var rib := DrawLayer.make(func(ci: Control) -> void: Px.ribbon(ci, Rect2(Vector2.ZERO, ci.size), title, 46))
	screen.put(rib, Rect2(140, 22, 380, 110))
	screen.put(gold_chip(Vector2(232, 76)), Rect2(530, 40, 232, 76))
	screen.put(diamond_chip(Vector2(232, 76)), Rect2(772, 40, 232, 76))


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


## Collection card: illustration, rarity frame, faction badge, name, stars, power.
static func hero_card(id: String, sz: Vector2, opts: Dictionary = {}) -> PxButton:
	var b := PxButton.new()
	b.size = sz
	b.press_depth = 3.0
	var owned: bool = opts.get("owned", true)
	var fac := DB.fac_of(id)
	var rar := DB.rarity_of(id)
	var rc := DB.rarity_color(rar)
	var bg := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		ci.draw_rect(r.grow(-4), rc.darkened(0.2) if owned else Color("#4a3e33"))
		ci.draw_rect(r.grow(-9), (DB.fac_color(fac).darkened(0.45)) if owned else Color("#2a221b"))
		ci.draw_rect(Rect2(9, 9, r.size.x - 18, (r.size.y - 18) * 0.5), (DB.fac_color(fac).darkened(0.25)) if owned else Color("#332a21")), sz)
	b.add_child(bg)
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.illustration(String(a["art"])) if bool(opts.get("big", true)) else Art.portrait(String(a["art"]))
	pic.position = Vector2(9, 9)
	pic.size = Vector2(sz.x - 18, sz.y - 18)
	pic.focus_y = 0.12
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.9)
	b.add_child(pic)
	var stars := int(opts.get("stars", Game.profile.star_of(id) if owned else 0))
	var lv := MetaRules.hero_level(Game.profile.data, id) if owned else 0
	var ov := DrawLayer.make(func(ci: Control) -> void:
		var w := ci.size.x
		var h := ci.size.y
		var band := Rect2(6, h - h * 0.2 - 6, w - 12, h * 0.2)
		if owned and bool(opts.get("rank", true)):
			W.draw_rank(ci, band, stars, lv, clampf(w / 9.0, 12, 24))
		if bool(opts.get("new", false)):
			var nr := Rect2(w - 74, 8, 66, 34)
			ci.draw_rect(nr, Px.INK)
			ci.draw_rect(nr.grow(-3), Color("#ff3b30"))
			Px.text(ci, "NEW", nr, 22)
		if opts.has("tag"):
			var tr := Rect2(8, h * 0.5, w - 16, 40)
			ci.draw_rect(tr, Color(0, 0, 0, 0.6))
			Px.text(ci, String(opts["tag"]), tr, 24, Px.GOLD)
		if bool(opts.get("selected", false)):
			ci.draw_rect(Rect2(Vector2(2, 2), ci.size - Vector2(4, 4)), Px.GOLD, false, 7.0), sz)
	b.add_child(ov)
	return b


## Row panel used by lists (missions, mail, settings).
static func row_panel(sz: Vector2) -> PxButton:
	var p := PxButton.make("panel_small", true, sz)
	p.static_panel = true
	return p


static func dark_panel(sz: Vector2) -> PxButton:
	var p := PxButton.make("panel_slot", true, sz)
	p.static_panel = true
	return p


## Small reward strip: icons + amounts (gold / diamond / tickets / boxes ...).
static func reward_text(rw: Dictionary) -> String:
	var parts: Array = []
	for k: String in rw:
		match k:
			"gold":
				parts.append("골드 " + Px.num(int(rw[k])))
			"diamond":
				parts.append("다이아 " + Px.num(int(rw[k])))
			"tickets":
				parts.append("모집권 " + str(int(rw[k])))
			"boxes":
				parts.append("보물 상자 " + str(int(rw[k])))
			"skin":
				parts.append(String(rw[k]))
			"treasure":
				parts.append(String(DB.treasure_def(String(rw[k])).get("name", "보물")))
	return " · ".join(parts)


static func reward_icon(rw: Dictionary) -> String:
	for k in ["diamond", "gold", "tickets", "boxes", "treasure", "skin"]:
		if rw.has(k):
			match k:
				"diamond":
					return "icon_diamond"
				"gold":
					return "icon_gold"
				"tickets":
					return "ic_scroll"
				"boxes", "treasure":
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
		else:
			b.highlight = true
		b.position = Vector2(i * (w + 8.0), 0 if i == selected else 6)
		var idx := i
		b.pressed.connect(func() -> void: on_pick.call(idx))
		root.add_child(b)
	return root


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
const CLOSE := Vector2(88, 88)
const ARROW := Vector2(84, 96)


## Red X used by every pop-up and tab dialog.
static func close_button(on_close: Callable) -> PxButton:
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


## Queue / lineup slot (전투 대기열 · 편성 칸), same look everywhere.
## state: "unit" | "empty" | "locked". [param label] is shown for locked slots.
static func draw_unit_slot(ci: CanvasItem, r: Rect2, id: String, stars: int, lv: int, state := "unit", label := "") -> void:
	Px.draw_skin(ci, "tile", r)
	var inner := r.grow(-12)
	match state:
		"empty":
			ci.draw_rect(inner, Color(0, 0, 0, 0.28))
			var c := inner.get_center()
			var pc := Color("#c99a5e", 0.35)
			ci.draw_rect(Rect2(c - Vector2(15, 3), Vector2(30, 6)), pc)
			ci.draw_rect(Rect2(c - Vector2(3, 15), Vector2(6, 30)), pc)
		"locked":
			ci.draw_rect(inner, Color(0, 0, 0, 0.45))
			Px.fit(ci, Px.tex("ic_lock"), Rect2(inner.get_center() - Vector2(18, 26), Vector2(36, 36)))
			if label != "":
				Px.text(ci, label, Rect2(inner.position.x, inner.end.y - 30, inner.size.x, 28), 20, Px.MUTED)
		_:
			var a := Art.of_unit(id)
			var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
			var hero: bool = DB.units["heroes"].has(id)
			ci.draw_rect(inner, (DB.fac_color(DB.fac_of(id)) if hero else Color("#6b5a48")).darkened(0.35))
			if t != null:
				Px.cover(ci, t, inner)
			if hero:
				ci.draw_rect(inner.grow(-1.5), DB.rarity_color(DB.rarity_of(id)), false, 3.0)
			W.draw_rank(ci, Rect2(inner.position.x, inner.end.y - 26, inner.size.x, 24), stars, lv, 20.0)


## In-battle bench/merge slot: uses merge tier (1단/2단/3단) + tier border colour,
## visually distinct from meta star rank (★).
static func draw_battle_slot(ci: CanvasItem, r: Rect2, id: String, rank: int) -> void:
	Px.draw_skin(ci, "tile", r)
	var inner := r.grow(-12)
	var a := Art.of_unit(id)
	var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
	var hero: bool = DB.units["heroes"].has(id)
	ci.draw_rect(inner, (DB.fac_color(DB.fac_of(id)) if hero else Color("#6b5a48")).darkened(0.35))
	if t != null:
		Px.cover(ci, t, inner)
	var tc := Color("#b8aa90") if rank <= 1 else (Color("#3cc8e8") if rank == 2 else Color("#ffaa22"))
	ci.draw_rect(inner.grow(-1.5), tc, false, 3.0 if rank <= 1 else 4.0)
	var badge := Rect2(inner.end.x - 46, inner.end.y - 26, 44, 24)
	ci.draw_rect(badge, Px.INK)
	ci.draw_rect(badge.grow(-2), tc.darkened(0.68))
	Px.text(ci, "%d단" % maxi(1, rank), badge, 17, tc)
