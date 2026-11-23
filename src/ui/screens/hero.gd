extends PxScreen
## 장수 상세 (메타 §3.4·3.5·3.8): 일러스트·이름·희귀도·성급·세력·병종·전투력,
## 이전/다음 장수, 탭 성장(별 6칸, 성급 경험, 군주 레벨 효과, 인연) ·
## 속성(속성 칸, 상성) · 보물(칸 3개, 자동 장착, 합계).
## 성급과 속성은 여기서 올릴 수 없다: 전투 중 흡수로만 오른다 (개편 §9.1).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}

var id := ""
var tab := 0
var slot := "weapon"
var _t := 0.0
var _flash := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.45
	id = String(params.get("id", "guanyu"))
	tab = int(params.get("tab", 0))
	_rebuild()
	set_process(true)


func back() -> bool:
	var from := String(params.get("from", "heroes"))
	if from == "lobby" and dialog:
		Game.app.close_dialog()
	else:
		Game.app.goto(from)
	return true


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(0.0, _flash - delta * 2.0)
	for c in get_children():
		if c is DrawLayer and c.has_meta("anim"):
			c.queue_redraw()


func _owned() -> bool:
	return Game.profile.owns(id)


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("hero.title"))
	_build_showcase()
	if not _owned():
		var info := DrawLayer.make(func(ci: Control) -> void:
			Px.paragraph(ci, DB.t("hero.not_owned"), Rect2(0, 0, ci.size.x, ci.size.y), 32, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4))
		put(info, Rect2(100, 860, 824, 140))
		_build_skill(Rect2(60, 1200, 904, 220))
		return
	put(W.tabs([DB.t("hero.tab_up"), DB.t("hero.tab_star"), DB.t("hero.tab_treasure")], tab, Vector2(904, 96),
		func(i: int) -> void:
			tab = i
			_rebuild(), ["yellow", "purple", "green"]), Rect2(60, 716, 904, 96))
	match tab:
		0:
			put(Growth.star_panel(id), Rect2(60, 820, 904, 480))
			_build_skill(Rect2(60, 1310, 904, 130))
		1:
			put(Growth.trait_panel(id), Rect2(60, 820, 904, 480))
		2:
			Growth.gear_tab(self, id, slot, func(s: String) -> void:
				slot = s
				_rebuild(), _rebuild)


# ---------------------------------------------------------------- showcase

func _build_showcase() -> void:
	var owned := _owned()
	var fac := DB.fac_of(id)
	var rar := DB.rarity_of(id)
	var fc := DB.fac_color(fac)
	var backdrop := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		ci.draw_rect(r.grow(-5), DB.rarity_color(rar))
		ci.draw_rect(r.grow(-10), fc.darkened(0.6))
		# rays
		var c := Vector2(260, 330)
		for i in 12:
			var a := TAU * i / 12.0 + _t * 0.15
			var pts := PackedVector2Array([c, c + Vector2(cos(a), sin(a)) * 700, c + Vector2(cos(a + 0.14), sin(a + 0.14)) * 700])
			ci.draw_colored_polygon(pts, Color(fc.lightened(0.2), 0.10))
		ci.draw_rect(Rect2(10, r.size.y - 150, r.size.x - 20, 140), Color(0, 0, 0, 0.35)))
	backdrop.set_meta("anim", true)
	backdrop.clip_contents = true
	put(backdrop, Rect2(40, 146, 944, 560))
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.illustration(String(a["art"]))
	pic.cover = false
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.92)
	put(pic, Rect2(70, 160, 420, 420))
	var unit := UnitView.make(id, 200.0)
	if not owned:
		unit.set_gray(1.0)
	put(unit, Rect2(830, 560, 0, 0))
	var info := DrawLayer.make(func(ci: Control) -> void:
		var st: Dictionary = MetaRules.hero_stats(Game.profile.data, id)
		# rarity ribbon
		var rr := Rect2(0, 0, 220, 50)
		ci.draw_rect(rr, Px.INK)
		ci.draw_rect(rr.grow(-3), DB.rarity_color(rar))
		Px.text(ci, DB.rarity_name(rar), rr, 28)
		Px.text(ci, DB.unit_name(id), Rect2(0, 56, 420, 90), 76, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 8)
		Px.stars(ci, Vector2(130, 168), Game.profile.star_of(id) if owned else 0, 6, 40.0)
		# faction + class chips
		var fr := Rect2(0, 200, 120, 46)
		ci.draw_rect(fr, Px.INK)
		ci.draw_rect(fr.grow(-3), fc)
		Px.text(ci, DB.fac_name(fac), fr, 26)
		var cr := Rect2(130, 200, 150, 46)
		ci.draw_rect(cr, Px.INK)
		ci.draw_rect(cr.grow(-3), Color("#3a2615"))
		Px.fit(ci, Px.tex(String(DB.units["classes"][DB.cls_of(id)]["icon"])), Rect2(cr.position + Vector2(8, 7), Vector2(32, 32)))
		Px.text(ci, DB.cls_name(DB.cls_of(id)), Rect2(cr.position + Vector2(40, 0), Vector2(104, 46)), 26)
		if owned:
			Px.fit(ci, Px.tex("icon_sword"), Rect2(0, 266, 48, 48))
			Px.text(ci, Px.num(MetaRules.power_of(st)), Rect2(56, 258, 300, 64), 48, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var y := 336.0
		for s: String in STATS:
			Px.fit(ci, Px.tex(String(STAT_ICON[s])), Rect2(0, y + 4, 30, 30))
			Px.text(ci, DB.t("stat." + s), Rect2(40, y, 90, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, Px.num(int(st[s])), Rect2(130, y, 140, 40), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			y += 40)
	put(info, Rect2(520, 160, 420, 470))
	# 이전/다음
	var list := _nav_list()
	var idx := list.find(id)
	for side in [-1, 1]:
		var s: int = side
		var b := W.arrow_button(side, func() -> void:
			id = String(list[posmod(idx + s, list.size())])
			_rebuild())
		put(b, Rect2(44 if side < 0 else 896, 330, 84, 96))
	if owned and not DB.advisor_skill(id).is_empty():
		var adv := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.2, 0.1, 0.3, 0.85))
			Px.text(ci, DB.t("hero.advisor", [String(DB.advisor_skill(id)["name"])]), Rect2(10, 0, ci.size.x - 20, ci.size.y), 24, Color("#e0b0ff")))
		put(adv, Rect2(60, 588, 470, 40))
	var skill := DB.hero(id).get("skill", {}) as Dictionary
	var sk := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("hero.skill", [String(skill.get("name", ""))]), Rect2(0, 0, ci.size.x, 40), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, String(skill.get("desc", "")), Rect2(0, 40, ci.size.x, 40), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(sk, Rect2(60, 626, 600, 78))


func _nav_list() -> Array:
	var out: Array = []
	for h: String in DB.hero_ids():
		if Game.profile.owns(h) == _owned():
			out.append(h)
	if not out.has(id):
		out.append(id)
	return out


func _build_skill(r: Rect2) -> void:
	var bonds: Array = []
	for b: Dictionary in DB.units["bonds"]:
		if (b["heroes"] as Array).has(id):
			bonds.append(b)
	var d := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("hero.bonds"), Rect2(24, 12, 300, 40), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var y := 56.0
		for b: Dictionary in bonds:
			if y > ci.size.y - 40:
				break
			var names: Array = []
			var have := 0
			for h: String in b["heroes"]:
				names.append(DB.unit_name(h))
				if Game.profile.owns(h):
					have += 1
			var on := have >= int(b["need"])
			Px.text(ci, String(b["name"]), Rect2(24, y, 170, 36), 24, Px.HP_GREEN if on else Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(b["desc"]), Rect2(200, y, 330, 36), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "·".join(names), Rect2(530, y, ci.size.x - 550, 36), 20, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
			y += 40
		if bonds.is_empty():
			Px.text(ci, DB.t("hero.no_bond"), Rect2(24, 60, ci.size.x - 48, 40), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	put(d, r)
