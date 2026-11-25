class_name Detail8
extends RefCounted
## 장수 · 병종 상세 화면 (2026-11-25, 8차 시안 design/art/ui_src/장수상세8_완성화면.png 의 자리 그대로).
## hero.gd · troop.gd 가 같이 쓴다. 좌표는 화면 px (창 틀 안쪽에 그대로 놓인다 — native8).
##
## 위에서 아래로: 탭 3개(성급 · 속성 · 장비) / 얼굴 칸 + 이름 · 표시 판 2개 · 능력치 3줄 / 인연 띠 /
## 장비 칸 3개(늘 보인다, 누르면 장비 탭) / 자동 장착 · 해제 / 내용 판(고른 탭의 내용).
## 성급과 속성은 여기서 올릴 수 없다: 전투 중 흡수로만 오른다 (개편 §9.1).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}
const TABS := Rect2(121, 346, 702, 101)
const FACE := Rect2(147, 470, 308, 305)
const NAME := Rect2(472, 469, 407, 79)
const TAG_A := Rect2(473, 557, 148, 60)
const TAG_B := Rect2(625, 557, 212, 60)
const STAT_ROW := Rect2(475, 628, 376, 50)      # 첫 줄. 줄 간격 53
const BOND := Rect2(126, 796, 771, 83)
const SLOT := Rect2(172, 898, 218, 170)         # 첫 칸. 칸 간격 231
const BTN_AUTO := Rect2(126, 1087, 379, 75)
const BTN_OFF := Rect2(519, 1087, 378, 75)
const BOX := Rect2(126, 1183, 771, 252)


static func build(scr: PxScreen, id: String, tab: int, slot: String, on_tab: Callable, on_slot: Callable, rebuild: Callable, on_nav: Callable) -> void:
	var p: Dictionary = Game.profile.data
	var hero := DB.is_hero(id)
	var owned: bool = Game.profile.owns(id) if hero else Game.profile.owns_troop(id)
	scr.put(W.icon_tabs(["tab_growth", "tab_trait", "tab_gear"], tab, 234, on_tab,
		[DB.t("hero.tab_up"), DB.t("hero.tab_star"), DB.t("hero.tab_treasure")]), TABS)
	_top(scr, id, hero, owned, on_nav)
	_bond(scr, id, hero)
	_slots(scr, id, tab, slot, owned, on_slot, rebuild)
	var box := DrawLayer.make(func(ci: Control) -> void: Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size)))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(box, BOX)
	if not owned:
		var info := DrawLayer.make(func(ci: Control) -> void:
			Px.paragraph(ci, DB.t("hero.not_owned") if hero else DB.t("troop.not_owned"), Rect2(20, 20, ci.size.x - 40, 110), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4)
			_skill_lines(ci, id, 150.0))
		scr.put(info, BOX)
		return
	match tab:
		0:
			scr.put(_star_box(id), BOX)
		1:
			scr.put(_trait_box(id), BOX)
		_:
			_gear_box(scr, id, slot, rebuild)


# ---------------------------------------------------------------- 위: 얼굴 · 이름 · 능력치

static func _top(scr: PxScreen, id: String, hero: bool, owned: bool, on_nav: Callable) -> void:
	var p: Dictionary = Game.profile.data
	var fc: Color = DB.fac_color(DB.fac_of(id)) if hero else Color("#8a8f98")
	var face := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size).grow(-14), Color(fc, 0.2)))
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(face, FACE)
	var a := Art.of_unit(id)
	if hero:
		var pic := ArtRect.new()
		pic.texture = Art.illustration(String(a["art"]))
		pic.cover = false
		pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.92)
		scr.put(pic, Rect2(FACE.position + Vector2(18, 14), Vector2(FACE.size.x - 36, FACE.size.y - 70)))
	else:
		var unit := UnitView.make(id, 220.0)
		if not owned:
			unit.set_gray(1.0)
		scr.put(unit, Rect2(FACE.get_center().x, FACE.end.y - 62, 0, 0))
	var star: int = MetaRules.unit_star(p, id) if owned else 0
	var stars := DrawLayer.make(func(ci: Control) -> void: Px.stars(ci, Vector2(ci.size.x * 0.5, ci.size.y * 0.5), star, 6, 34.0))
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(stars, Rect2(FACE.position.x + 14, FACE.end.y - 54, FACE.size.x - 28, 40))
	for side in [-1, 1]:
		var s: int = side
		var b := W.arrow_button(side, func() -> void: on_nav.call(s), Vector2(58, 77))
		scr.put(b, Rect2(111 if side < 0 else 855, 592, 58, 77))
	var st: Dictionary = MetaRules.unit_stats(p, id)
	var power: int = MetaRules.power_of(MetaRules.hero_stats(p, id)) if hero else MetaRules.soldier_power(p, id)
	var info := DrawLayer.make(func(ci: Control) -> void:
		var o := NAME.position
		# 이름 띠: 이름 (왼쪽) · 전투력 (오른쪽)
		var nr := Rect2(NAME.position - o, NAME.size)
		Px.nine(ci, "kit_box", nr)
		Px.text(ci, DB.unit_name(id) if hero else DB.troop_name(id), Rect2(nr.position + Vector2(22, 0), Vector2(220, nr.size.y)), 42, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 7)
		if owned:
			Px.fit(ci, Px.tex("icon_swords"), Rect2(nr.position + Vector2(246, 20), Vector2(40, 40)))
			Px.text(ci, Px.num(power), Rect2(nr.position + Vector2(290, 0), Vector2(nr.size.x - 306, nr.size.y)), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		# 표시 판 2개: 등급 / 진영 · 병종
		var ta := Rect2(TAG_A.position - o, TAG_A.size)
		Px.nine(ci, "kit_box", ta)
		if hero:
			Px.text(ci, DB.rarity_name(DB.rarity_of(id)), ta, 26, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 6)
		else:
			var tier := String(DB.soldier(id).get("tier", "basic"))
			Px.text(ci, DB.t("odds.tier_" + tier), ta, 24, Color("#9ec3ff") if tier == "elite" else Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
		var tb := Rect2(TAG_B.position - o, TAG_B.size)
		Px.nine(ci, "kit_box", tb)
		Px.fit(ci, Px.tex(String(DB.units["classes"][DB.cls_of(id)]["icon"])), Rect2(tb.position + Vector2(16, 14), Vector2(32, 32)))
		var who := DB.cls_name(DB.cls_of(id))
		if hero:
			who = "%s · %s" % [DB.fac_name(DB.fac_of(id)), who]
		Px.text(ci, who, Rect2(tb.position + Vector2(54, 0), Vector2(tb.size.x - 66, tb.size.y)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		if hero:
			var fl := Rect2(tb.position + Vector2(56, tb.size.y - 17), Vector2(40, 4))
			ci.draw_rect(fl.grow(1), Color(0, 0, 0, 0.55))
			ci.draw_rect(fl, fc)
		# 능력치 3줄
		for i in STATS.size():
			var s := String(STATS[i])
			var r := Rect2(STAT_ROW.position - o + Vector2(0, i * 53), STAT_ROW.size)
			Px.nine(ci, "kit_box", r)
			Px.fit(ci, Px.tex(String(STAT_ICON[s])), Rect2(r.position + Vector2(18, 10), Vector2(30, 30)))
			Px.text(ci, DB.t("stat." + s), Rect2(r.position + Vector2(58, 0), Vector2(120, r.size.y)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, Px.num(int(st[s])), Rect2(r.position + Vector2(180, 0), Vector2(r.size.x - 200, r.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(info, Rect2(NAME.position, Vector2(NAME.size.x, STAT_ROW.end.y + 106 - NAME.position.y)))


## 필살기 두 줄 (장수만): 이름 + 설명.
static func _skill_lines(ci: Control, id: String, y: float) -> void:
	if not DB.is_hero(id):
		return
	var skill := DB.hero(id).get("skill", {}) as Dictionary
	Px.text(ci, DB.t("hero.skill", [String(skill.get("name", ""))]), Rect2(22, y, ci.size.x - 44, 30), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	Px.text(ci, String(skill.get("desc", "")), Rect2(22, y + 30, ci.size.x - 44, 28), 18, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)


# ---------------------------------------------------------------- 인연 띠

static func _bond(scr: PxScreen, id: String, hero: bool) -> void:
	var lines: Array = []        # [이름, 설명, 켜짐]
	if hero:
		for b: Dictionary in DB.units["bonds"]:
			if (b["heroes"] as Array).has(id):
				var have := 0
				for h: String in b["heroes"]:
					if Game.profile.owns(h):
						have += 1
				lines.append([String(b["name"]), String(b["desc"]), have >= int(b["need"])])
	else:
		var names: Array = []
		for h: String in DB.heroes_of_troop(id):
			names.append(DB.unit_name(h))
		if not names.is_empty():
			lines.append([DB.t("troop.heroes"), " · ".join(names), true])
	var d := DrawLayer.make(func(ci: Control) -> void:
		# 인연 띠 (dlg_bond): 왼쪽 끝 금색 매듭 뒤부터 글자. 두 줄까지.
		Px.nine(ci, "dlg_bond", Rect2(Vector2.ZERO, ci.size))
		var lx := 96.0
		if lines.is_empty():
			Px.text(ci, DB.t("hero.no_bond"), Rect2(lx, 0, ci.size.x - lx - 20, ci.size.y), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			return
		var n := mini(2, lines.size())
		var lh := (ci.size.y - 20.0) / n
		for i in n:
			var l: Array = lines[i]
			var y := 10.0 + i * lh
			Px.text(ci, String(l[0]), Rect2(lx, y, 190, lh), 22, Px.HP_GREEN if bool(l[2]) else Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(l[1]), Rect2(lx + 196, y, ci.size.x - lx - 216, lh), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(d, BOND)


# ---------------------------------------------------------------- 장비 칸 3개 + 자동 장착 · 해제

static func _slots(scr: PxScreen, id: String, tab: int, slot: String, owned: bool, on_slot: Callable, rebuild: Callable) -> void:
	var p: Dictionary = Game.profile.data
	var eq: Dictionary = MetaRules.entry(p, id).get("eq", {}) if owned else {}
	var slots: Array = DB.meta["treasure"]["slots"]
	for i in slots.size():
		var s := String(slots[i])
		var r := Rect2(SLOT.position + Vector2(i * 231, 0), SLOT.size)
		var cell: PxButton
		if eq.has(s):
			cell = W.treasure_cell(MetaRules.find_treasure(p, int(eq[s])), r.size)
		else:
			cell = PxButton.make("kit_box", true, r.size)
			cell.icon = Px.tex(String(W.SLOT_ICON[s]))
			cell.icon_rect = Rect2((r.size.x - 88) * 0.5, (r.size.y - 88) * 0.5, 88, 88)
			cell.modulate = Color(0.62, 0.62, 0.66)
		cell.highlight = owned and tab == 2 and s == slot
		cell.disabled = not owned
		cell.pressed.connect(func() -> void: on_slot.call(s))
		scr.put(cell, r)
	# 자동 장착 (파랑 · 별) · 해제 (빨강 · 화살표): 아이콘은 그림에 있고 글자만 쓴다
	var auto := PxButton.make("btn_auto", false, BTN_AUTO.size)
	auto.tooltip_text = DB.t("hero.auto_equip")
	auto.disabled = not owned
	auto.overlay = func(b: PxButton, off: Vector2) -> void:
		Px.text(b, DB.t("hero.auto_equip"), Rect2(off + Vector2(84, 0), Vector2(b.size.x - 104, b.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	auto.pressed.connect(func() -> void:
		Game.profile.auto_equip(id)
		Sfx.play("pop")
		rebuild.call())
	scr.put(auto, BTN_AUTO)
	var unequip := PxButton.make("btn_unequip", false, BTN_OFF.size)
	unequip.tooltip_text = DB.t("hero.unequip")
	unequip.disabled = not eq.has(slot)
	unequip.overlay = func(b: PxButton, off: Vector2) -> void:
		Px.text(b, DB.t("hero.unequip"), Rect2(off + Vector2(84, 0), Vector2(b.size.x - 104, b.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	unequip.pressed.connect(func() -> void:
		Game.profile.unequip(id, slot)
		rebuild.call())
	scr.put(unequip, BTN_OFF)


# ---------------------------------------------------------------- 내용 판: 성급

static func _star_box(id: String) -> DrawLayer:
	var p: Dictionary = Game.profile.data
	var d := DrawLayer.make(func(ci: Control) -> void:
		var w := ci.size.x
		var e := MetaRules.entry(p, id)
		var star := int(e.get("star", 1))
		var need := MetaRules.star_need(id, star)
		if need < 0:
			Px.text(ci, DB.t("hero.max_star"), Rect2(22, 14, w - 44, 40), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		else:
			Px.text(ci, DB.t("hero.star_step", [star, star + 1]), Rect2(22, 14, 200, 40), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			var xp := int(e.get("xp", 0))
			var br := Rect2(230, 18, w - 252, 32)
			Px.bar(ci, br, float(xp) / maxf(1.0, need), Color("#b070ff"))
			Px.text(ci, "%d / %d" % [xp, need], br, 22)
		Px.text(ci, DB.t("growth.star_hint"), Rect2(22, 58, w - 44, 26), 18, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var st := MetaRules.unit_stats(p, id)
		var lines := [
			DB.t("hero.star_fx1", [int(round((float(DB.meta["star"]["mult"]) - 1.0) * 100.0))]),
			DB.t("growth.lord_fx", [int(p["lord_lv"]), int(round((MetaRules.lord_mult(p) - 1.0) * 100.0))]),
			DB.t("growth.base", [Px.num(int(st["atk"])), Px.num(int(st["def"])), Px.num(int(st["hp"]))]),
		]
		for i in lines.size():
			Px.text(ci, "· " + String(lines[i]), Rect2(22, 90 + i * 30, w - 44, 28), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		_skill_lines(ci, id, 184.0))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


# ---------------------------------------------------------------- 내용 판: 속성

static func _trait_box(id: String) -> DrawLayer:
	var p: Dictionary = Game.profile.data
	var d := DrawLayer.make(func(ci: Control) -> void:
		var w := ci.size.x
		var star := MetaRules.unit_star(p, id)
		var slots := MetaRules.trait_slots(star)
		var traits := MetaRules.unit_traits(p, id)
		Px.text(ci, DB.t("growth.slots", [traits.size(), slots]), Rect2(22, 10, 300, 32), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("growth.trait_hint"), Rect2(330, 10, w - 352, 32), 16, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		# 속성 칸 6개 (칸 = 성급): 두 줄로 3칸씩
		var cw := (w - 44 - 16) / 3.0
		for i in 6:
			var r := Rect2(22 + (i % 3) * (cw + 8), 48 + (i / 3) * 66, cw, 60)
			Px.nine(ci, "kit_box", r, Color.WHITE if i < slots else Color(0.6, 0.6, 0.6))
			if i < traits.size():
				var t: Dictionary = traits[i]
				var def := DB.trait_def(String(t["id"]))
				Px.text(ci, "%s Lv.%d" % [String(def.get("name", "")), int(t["lv"])], Rect2(r.position + Vector2(12, 4), Vector2(r.size.x - 24, 28)), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
				Px.text(ci, DB.trait_desc(String(t["id"]), int(t["lv"])), Rect2(r.position + Vector2(12, 30), Vector2(r.size.x - 24, 24)), 15, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			elif i < slots:
				Px.text(ci, DB.t("growth.slot_empty"), r, 20, Px.MUTED)
			else:
				Px.text(ci, DB.t("growth.slot_locked", [i + 1]), r, 18, Color("#8a8072"))
		# 상성 (§9.5)
		var lists := DB.counter_lists(DB.ctr_of(id))
		Px.text(ci, DB.t("growth.strong", [Growth._names(lists["strong"])]), Rect2(22, 190, w * 0.5 - 30, 40), 22, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("growth.weak", [Growth._names(lists["weak"])]), Rect2(w * 0.5, 190, w * 0.5 - 22, 40), 22, Color("#ff8a70"), HORIZONTAL_ALIGNMENT_LEFT))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


# ---------------------------------------------------------------- 내용 판: 장비 (효과 합계 + 이 칸에 낄 수 있는 것)

static func _gear_box(scr: PxScreen, id: String, slot: String, rebuild: Callable) -> void:
	var p: Dictionary = Game.profile.data
	var eq: Dictionary = MetaRules.entry(p, id).get("eq", {})
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.fit(ci, Px.tex(String(W.SLOT_ICON[slot])), Rect2(18, 10, 40, 40))
		var st := MetaRules.unit_stats(p, id)
		var base := MetaRules.bare_stats(p, id)
		var parts: Array = []
		for k in ["atk", "def", "hp"]:
			var dv := int(st[k]) - int(base[k])
			if dv > 0:
				parts.append("%s +%d" % [DB.t("stat." + k), dv])
		for k in ["crit", "crit_dmg", "aspd", "energy", "guard", "spd"]:
			if float(st[k]) > 0.0:
				parts.append("%s +%d%%" % [DB.t("stat." + k), int(round(float(st[k]) * 100.0))])
		for s2: String in eq:
			var gd := DB.treasure_def(String(MetaRules.find_treasure(p, int(eq[s2])).get("tid", "")))
			if String(gd.get("fx_desc", "")) != "":
				parts.append(String(gd["fx_desc"]))
		var hint := "" if DB.is_hero(id) else DB.t("gear.troop_hint") + "  "
		Px.paragraph(ci, hint + (" · ".join(parts) if not parts.is_empty() else "-"), Rect2(66, 8, ci.size.x - 86, 46), 18, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scr.put(head, Rect2(BOX.position, Vector2(BOX.size.x, 60)))
	# 후보: 이 칸에 낄 수 있는 것 전부 (희귀한 것 먼저, 그다음 주 능력치 순)
	var order: Array = DB.meta["treasure"]["rarity_order"]
	var cand: Array = []
	for it: Dictionary in p["treasures"]:
		if String(DB.treasure_def(String(it["tid"]))["slot"]) == slot:
			cand.append(it)
	cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := order.find(String(DB.treasure_def(String(a["tid"]))["rarity"]))
		var rb := order.find(String(DB.treasure_def(String(b["tid"]))["rarity"]))
		return ra > rb if ra != rb else MetaRules.treasure_main(a) > MetaRules.treasure_main(b))
	var area := Rect2(BOX.position.x + 16, BOX.position.y + 62, BOX.size.x - 32, BOX.size.y - 78)
	if cand.is_empty():
		var em := DrawLayer.make(func(ci: Control) -> void: Px.paragraph(ci, DB.t("treasure.empty"), Rect2(Vector2.ZERO, ci.size), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4))
		em.mouse_filter = Control.MOUSE_FILTER_IGNORE
		scr.put(em, area)
		return
	var content := W.scroll(scr, area, func(sc: Control, rr: Rect2) -> void: scr.put(sc, rr))
	var cs := 136.0
	for i in cand.size():
		var it: Dictionary = cand[i]
		var cell := W.treasure_cell(it, Vector2(cs, cs))
		cell.position = Vector2((i % 5) * (cs + 14.5), (i / 5) * (cs + 12))
		var uid := int(it["uid"])
		cell.pressed.connect(func() -> void:
			var pop: PxPopup = Game.app.popup("treasure", {"uid": uid, "hero": id})
			pop.closed.connect(rebuild))
		content.add_child(cell)
	content.custom_minimum_size.y = ceili(cand.size() / 5.0) * (cs + 12)
