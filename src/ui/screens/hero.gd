extends PxScreen
## 장수 상세 (메타 §3.4·3.5·3.8): 일러스트·이름·희귀도·성급·세력·병종·전투력,
## 이전/다음 장수, 탭 강화(공·방·체 줄 3개, 모두 강화, 기술, 인연) ·
## 성급(별 6칸, 카드 n/필요, 효과, 성급 올리기) · 보물(칸 3개, 자동 장착, 합계).

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
		var go := PxButton.colored("yellow", DB.t("hero.go_recruit"), Vector2(520, 140), 44)
		go.pulse = true
		go.pressed.connect(func() -> void: Game.app.goto("recruit"))
		put(go, Rect2(252, 1040, 520, 120))
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
			_build_upgrade()
		1:
			_build_star()
		2:
			_build_treasure()


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


# ---------------------------------------------------------------- 강화

func _build_upgrade() -> void:
	var h := Game.profile.hero(id)
	var star := int(h["star"])
	var cap := MetaRules.upgrade_cap(star)
	var base := MetaRules.base_stats(id)
	for i in STATS.size():
		var s: String = STATS[i]
		var lv := int(h["up"][s])
		var cost := MetaRules.upgrade_cost(lv)
		var maxed := lv >= cap
		var row := DrawLayer.make(func(ci: Control) -> void:
			Px.draw_skin(ci, "panel_small", Rect2(Vector2.ZERO, ci.size))
			Px.fit(ci, Px.tex(String(STAT_ICON[s])), Rect2(22, 30, 52, 52))
			Px.text(ci, DB.t("stat." + s), Rect2(88, 8, 190, 44), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "Lv.%d / %d" % [lv, cap], Rect2(88, 54, 190, 30), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			var cur := MetaRules.upgraded(float(base[s]), star, lv)
			var nxt := MetaRules.upgraded(float(base[s]), star, lv + 1)
			Px.text(ci, Px.num(int(cur)), Rect2(290, 0, 130, ci.size.y), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
			if not maxed:
				Px.text(ci, "▶", Rect2(430, 0, 40, ci.size.y), 28, Px.MUTED)
				Px.text(ci, Px.num(int(nxt)), Rect2(470, 0, 130, ci.size.y), 34, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_LEFT)
			else:
				Px.text(ci, DB.t("hero.need_star_short"), Rect2(440, 0, 170, ci.size.y), 24, Color("#ffb070"), HORIZONTAL_ALIGNMENT_LEFT)
			Px.bar(ci, Rect2(88, ci.size.y - 22, 520, 14), float(lv) / maxf(1.0, cap), Px.GOLD))
		put(row, Rect2(60, 820 + i * 118, 904, 106))
		var b := PxButton.colored("yellow", Px.short(cost), Vector2(250, 86), 32)
		b.icon = Px.tex("icon_gold")
		b.icon_rect = Rect2(16, 19, 46, 48)
		b.text_rect = Rect2(64, 0, 176, 86)
		b.disabled = maxed
		b.pressed.connect(func() -> void:
			var why := Game.profile.upgrade_stat(id, s)
			if why != "":
				toast(why)
				Sfx.play("error")
			else:
				Sfx.play("rankup")
				_rebuild())
		put(b, Rect2(700, 830 + i * 118, 250, 86))
	var all := PxButton.colored("yellow", DB.t("hero.up_all"), Vector2(904, 100), 38)
	all.pressed.connect(func() -> void:
		var n := Game.profile.upgrade_all(id)
		if n == 0:
			toast(DB.t("hero.up_none"))
			Sfx.play("error")
		else:
			Sfx.play("rankup")
			toast(DB.t("hero.up_done", [n]))
			_rebuild())
	put(all, Rect2(60, 1176, 904, 88))
	_build_skill(Rect2(60, 1276, 904, 150))


# ---------------------------------------------------------------- 성급

func _build_star() -> void:
	var h := Game.profile.hero(id)
	var star := int(h["star"])
	var need := MetaRules.star_cost(star)
	var cards := int(h["cards"])
	var panel := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var w := ci.size.x
		for i in 6:
			var c := Vector2(w * 0.5 + (i - 2.5) * 120, 90)
			var on := i < star
			var sz := 92.0 + (8.0 * sin(_t * 4.0) if i == star and need > 0 else 0.0)
			Px.fit(ci, Px.tex("ic_star" if on else "ic_star_off"), Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)))
		if need < 0:
			Px.text(ci, DB.t("hero.max_star"), Rect2(0, 170, w, 60), 40, Px.GOLD)
			return
		Px.text(ci, DB.t("hero.star_step", [star, star + 1]), Rect2(0, 160, w, 60), 42, Px.WHITE)
		# 카드 막대
		Px.fit(ci, Art.hued_portrait(String(Art.of_unit(id)["art"]), float(Art.of_unit(id)["hue"])), Rect2(70, 238, 64, 64))
		Px.bar(ci, Rect2(150, 250, w - 300, 44), float(cards) / maxf(1.0, need), Color("#b070ff"))
		Px.text(ci, "%d / %d" % [cards, need], Rect2(150, 250, w - 300, 44), 28)
		var lines := [DB.t("hero.star_fx1", [int(round((float(DB.meta["star"]["mult"]) - 1.0) * 100.0))]),
			DB.t("hero.star_fx2", [MetaRules.upgrade_cap(star), MetaRules.upgrade_cap(star + 1)]),
			DB.t("hero.star_fx3", [Px.num(MetaRules.hero_power(Game.profile.data, id)), Px.num(int(MetaRules.hero_power(Game.profile.data, id) * float(DB.meta["star"]["mult"])))])]
		for i in lines.size():
			Px.text(ci, "· " + String(lines[i]), Rect2(70, 320 + i * 48, w - 140, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), Vector2(904, 500))
	panel.set_meta("anim", true)
	put(panel, Rect2(60, 820, 904, 480))
	if need > 0:
		var ok := cards >= need
		var b := PxButton.colored("purple" if ok else "blue", DB.t("hero.star_up") if ok else DB.t("hero.go_recruit"), Vector2(560, 130), 44)
		b.pulse = ok
		b.pressed.connect(func() -> void:
			if not ok:
				Game.app.goto("recruit")
				return
			var why := Game.profile.star_up(id)
			if why != "":
				toast(why)
				return
			Sfx.play("jackpot")
			toast(DB.t("hero.star_done", [Game.profile.star_of(id)]))
			_rebuild())
		put(b, Rect2(232, 1316, 560, 120))


# ---------------------------------------------------------------- 보물

func _build_treasure() -> void:
	var h := Game.profile.hero(id)
	var eq: Dictionary = h["eq"]
	var slots: Array = DB.meta["treasure"]["slots"]
	for i in slots.size():
		var s := String(slots[i])
		var r := Rect2(60 + i * 220, 824, 200, 230)
		if eq.has(s):
			var it := MetaRules.find_treasure(Game.profile.data, int(eq[s]))
			var cell := W.treasure_cell(it, Vector2(200, 200))
			cell.highlight = s == slot
			cell.pressed.connect(func() -> void:
				slot = s
				_rebuild())
			put(cell, Rect2(r.position, Vector2(200, 200)))
		else:
			var e := PxButton.make("tile", true, Vector2(200, 200))
			e.highlight = s == slot
			e.icon = Px.tex(String(W.SLOT_ICON[s]))
			e.icon_rect = Rect2(60, 50, 80, 80)
			e.modulate = Color(0.7, 0.7, 0.75)
			e.pressed.connect(func() -> void:
				slot = s
				_rebuild())
			put(e, Rect2(r.position, Vector2(200, 200)))
		var lab := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("slot." + s), Rect2(0, 0, ci.size.x, ci.size.y), 26, Px.MUTED))
		put(lab, Rect2(r.position + Vector2(0, 200), Vector2(200, 34)))
	var auto := PxButton.colored("wood", DB.t("hero.auto_equip"), Vector2(240, 110), 32)
	auto.pressed.connect(func() -> void:
		Game.profile.auto_equip(id)
		Sfx.play("pop")
		_rebuild())
	put(auto, Rect2(724, 834, 240, 100))
	var off := PxButton.colored("red", DB.t("hero.unequip"), Vector2(240, 90), 30)
	off.disabled = not eq.has(slot)
	off.pressed.connect(func() -> void:
		Game.profile.unequip(id, slot)
		_rebuild())
	put(off, Rect2(724, 950, 240, 90))
	# 후보 목록
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("hero.bag_slot", [DB.t("slot." + slot)]), Rect2(0, 0, ci.size.x, 44), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var st: Dictionary = MetaRules.hero_stats(Game.profile.data, id)
		var base := MetaRules.hero_stats({"heroes": {id: {"star": h["star"], "up": h["up"], "eq": {}}}}, id)
		var parts: Array = []
		for k in ["atk", "def", "hp"]:
			var d := int(st[k]) - int(base[k])
			if d > 0:
				parts.append("%s +%d" % [DB.t("stat." + k), d])
		for k in ["crit", "crit_dmg", "aspd", "energy", "guard", "spd"]:
			if float(st[k]) > 0.0:
				parts.append("%s +%d%%" % [DB.t("stat." + k), int(round(float(st[k]) * 100.0))])
		Px.text(ci, DB.t("hero.treasure_sum") + "  " + (" · ".join(parts) if not parts.is_empty() else "-"), Rect2(0, 44, ci.size.x, 36), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(head, Rect2(60, 1068, 904, 84))
	var cand: Array = []
	for it: Dictionary in Game.profile.data["treasures"]:
		if String(DB.treasure_def(String(it["tid"]))["slot"]) == slot:
			cand.append(it)
	cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return MetaRules.treasure_main(a) > MetaRules.treasure_main(b))
	var content := W.scroll(self, Rect2(60, 1156, 904, 300), func(sc: Control, rr: Rect2) -> void: put(sc, rr))
	var cs := 168.0
	for i in cand.size():
		var it: Dictionary = cand[i]
		var cell := W.treasure_cell(it, Vector2(cs, cs))
		cell.position = Vector2((i % 5) * (cs + 16), (i / 5) * (cs + 16))
		var uid := int(it["uid"])
		cell.pressed.connect(func() -> void:
			var p: PxPopup = Game.app.popup("treasure", {"uid": uid, "hero": id})
			p.closed.connect(_rebuild))
		content.add_child(cell)
	content.custom_minimum_size.y = ceili(cand.size() / 5.0) * (cs + 16)
	if cand.is_empty():
		var em := DrawLayer.make(func(ci: Control) -> void: Px.paragraph(ci, DB.t("treasure.empty"), Rect2(0, 0, ci.size.x, ci.size.y), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4))
		put(em, Rect2(60, 1200, 904, 160))
