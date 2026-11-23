class_name Growth
extends RefCounted
## 성장 판 (개편 §9.1): the two panels the hero and troop detail screens share.
## 성급 판 = 별 6칸 · 성급 경험 막대 · 성급과 군주 레벨의 효과.
## 속성 판 = 속성 칸 · 가진 속성과 레벨 · 상성(강함 / 약함).
## Nothing here can be raised from the lobby: both grow by absorbing in battle.
## 장비 탭 = 무기 · 갑옷 · 장신구 칸 3개 + 가방 후보 (일반 장비와 보물 모두 같은 칸에 낀다, §11).

const SIZE := Vector2(904, 480)


## 성급 판 of hero / troop [param id] (owned).
static func star_panel(id: String) -> DrawLayer:
	var p: Dictionary = Game.profile.data
	return DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var w := ci.size.x
		var e := MetaRules.entry(p, id)
		var star := int(e.get("star", 1))
		var need := MetaRules.star_need(id, star)
		for i in 6:
			var c := Vector2(w * 0.5 + (i - 2.5) * 120, 84)
			Px.fit(ci, Px.tex("ic_star" if i < star else "ic_star_off"), Rect2(c - Vector2(44, 44), Vector2(88, 88)))
		if need < 0:
			Px.text(ci, DB.t("hero.max_star"), Rect2(0, 150, w, 56), 40, Px.GOLD)
		else:
			Px.text(ci, DB.t("hero.star_step", [star, star + 1]), Rect2(0, 146, w, 52), 38, Px.WHITE)
			var xp := int(e.get("xp", 0))
			Px.bar(ci, Rect2(150, 206, w - 300, 40), float(xp) / maxf(1.0, need), Color("#b070ff"))
			Px.text(ci, "%d / %d" % [xp, need], Rect2(150, 206, w - 300, 40), 26)
			Px.text(ci, DB.t("growth.star_hint"), Rect2(40, 252, w - 80, 36), 24, Px.GOLD)
		var st := MetaRules.unit_stats(p, id)
		var lines := [
			DB.t("hero.star_fx1", [int(round((float(DB.meta["star"]["mult"]) - 1.0) * 100.0))]),
			DB.t("growth.lord_fx", [int(p["lord_lv"]), int(round((MetaRules.lord_mult(p) - 1.0) * 100.0))]),
			DB.t("growth.base", [Px.num(int(st["atk"])), Px.num(int(st["def"])), Px.num(int(st["hp"]))]),
		]
		for i in lines.size():
			Px.text(ci, "· " + String(lines[i]), Rect2(70, 306 + i * 48, w - 140, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), SIZE)


## 속성 판 of hero / troop [param id] (owned).
static func trait_panel(id: String) -> DrawLayer:
	var p: Dictionary = Game.profile.data
	return DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var w := ci.size.x
		var star := MetaRules.unit_star(p, id)
		var slots := MetaRules.trait_slots(star)
		var traits := MetaRules.unit_traits(p, id)
		Px.text(ci, DB.t("growth.slots", [traits.size(), slots]), Rect2(30, 16, 400, 44), 32, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		for i in 3:
			var r := Rect2(30, 70 + i * 88, w - 60, 78)
			ci.draw_rect(r, Px.INK)
			ci.draw_rect(r.grow(-3), Color("#2a2018") if i < slots else Color("#1a1612"))
			if i < traits.size():
				var t: Dictionary = traits[i]
				var def := DB.trait_def(String(t["id"]))
				Px.text(ci, String(def.get("name", "")), Rect2(r.position + Vector2(18, 0), Vector2(170, r.size.y)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
				Px.text(ci, "Lv.%d" % int(t["lv"]), Rect2(r.position + Vector2(190, 0), Vector2(90, r.size.y)), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
				Px.text(ci, DB.trait_desc(String(t["id"]), int(t["lv"])), Rect2(r.position + Vector2(290, 0), Vector2(r.size.x - 306, r.size.y)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			elif i < slots:
				Px.text(ci, DB.t("growth.slot_empty"), r, 26, Px.MUTED)
			else:
				Px.text(ci, DB.t("growth.slot_locked", [3 if i == 1 else 5]), r, 26, Color("#6a6258"))
		Px.text(ci, DB.t("growth.trait_hint"), Rect2(30, 340, w - 60, 36), 24, Px.GOLD)
		# 상성 (§9.5)
		var lists := DB.counter_lists(DB.ctr_of(id))
		Px.text(ci, DB.t("growth.strong", [_names(lists["strong"])]), Rect2(30, 386, w * 0.5 - 40, 40), 28, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("growth.weak", [_names(lists["weak"])]), Rect2(w * 0.5, 386, w * 0.5 - 30, 40), 28, Color("#ff8a70"), HORIZONTAL_ALIGNMENT_LEFT), SIZE)


static func _names(cls_list: Array) -> String:
	if cls_list.is_empty():
		return DB.t("growth.none")
	var out: Array = []
	for c: String in cls_list:
		out.append(DB.cls_name(c))
	return " · ".join(out)


## 장비 탭 of hero / troop [param id] on [param scr] (canvas px, y 820~1460).
## [param slot] = the chosen slot; [param pick] is called with a slot id when one is
## tapped; [param rebuild] redraws the screen after a change.
static func gear_tab(scr: PxScreen, id: String, slot: String, pick: Callable, rebuild: Callable) -> void:
	var p: Dictionary = Game.profile.data
	var eq: Dictionary = MetaRules.entry(p, id).get("eq", {})
	var slots: Array = DB.meta["treasure"]["slots"]
	for i in slots.size():
		var s := String(slots[i])
		var r := Rect2(60 + i * 220, 824, 200, 230)
		if eq.has(s):
			var it := MetaRules.find_treasure(p, int(eq[s]))
			var cell := W.treasure_cell(it, Vector2(200, 200))
			cell.highlight = s == slot
			cell.pressed.connect(func() -> void: pick.call(s))
			scr.put(cell, Rect2(r.position, Vector2(200, 200)))
		else:
			var e := PxButton.make("tile", true, Vector2(200, 200))
			e.highlight = s == slot
			e.icon = Px.tex(String(W.SLOT_ICON[s]))
			e.icon_rect = Rect2(60, 50, 80, 80)
			e.modulate = Color(0.7, 0.7, 0.75)
			e.pressed.connect(func() -> void: pick.call(s))
			scr.put(e, Rect2(r.position, Vector2(200, 200)))
	var auto := PxButton.colored("wood", DB.t("hero.auto_equip"), Vector2(240, 110), 32)
	auto.pressed.connect(func() -> void:
		Game.profile.auto_equip(id)
		Sfx.play("pop")
		rebuild.call())
	scr.put(auto, Rect2(724, 834, 240, 100))
	var off := PxButton.colored("red", DB.t("hero.unequip"), Vector2(240, 90), 30)
	off.disabled = not eq.has(slot)
	off.pressed.connect(func() -> void:
		Game.profile.unequip(id, slot)
		rebuild.call())
	scr.put(off, Rect2(724, 950, 240, 90))
	# 장비 효과 합계 + 보물의 특수 능력
	var head := DrawLayer.make(func(ci: Control) -> void:
		# 글자 최소: 고른 칸은 아이콘으로, 합계는 능력치 아이콘 + 숫자
		Px.fit(ci, Px.tex(String(W.SLOT_ICON[slot])), Rect2(0, 0, 44, 44))
		if not DB.is_hero(id):
			Px.text(ci, DB.t("gear.troop_hint"), Rect2(300, 0, ci.size.x - 300, 44), 20, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		var st := MetaRules.unit_stats(p, id)
		var base := MetaRules.bare_stats(p, id)
		var parts: Array = []
		for k in ["atk", "def", "hp"]:
			var d := int(st[k]) - int(base[k])
			if d > 0:
				parts.append("%s +%d" % [DB.t("stat." + k), d])
		for k in ["crit", "crit_dmg", "aspd", "energy", "guard", "spd"]:
			if float(st[k]) > 0.0:
				parts.append("%s +%d%%" % [DB.t("stat." + k), int(round(float(st[k]) * 100.0))])
		for s2: String in eq:
			var gd := DB.treasure_def(String(MetaRules.find_treasure(p, int(eq[s2])).get("tid", "")))
			if String(gd.get("fx_desc", "")) != "":
				parts.append(String(gd["fx_desc"]))
		Px.paragraph(ci, " · ".join(parts) if not parts.is_empty() else "-", Rect2(0, 48, ci.size.x, 56), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	scr.put(head, Rect2(60, 1068, 904, 104))
	# 후보 목록: 이 칸에 낄 수 있는 것 전부 (보물 먼저, 그다음 주 능력치 순)
	var order: Array = DB.meta["treasure"]["rarity_order"]
	var cand: Array = []
	for it: Dictionary in p["treasures"]:
		if String(DB.treasure_def(String(it["tid"]))["slot"]) == slot:
			cand.append(it)
	cand.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := order.find(String(DB.treasure_def(String(a["tid"]))["rarity"]))
		var rb := order.find(String(DB.treasure_def(String(b["tid"]))["rarity"]))
		return ra > rb if ra != rb else MetaRules.treasure_main(a) > MetaRules.treasure_main(b))
	var content := W.scroll(scr, Rect2(60, 1176, 904, 280), func(sc: Control, rr: Rect2) -> void: scr.put(sc, rr))
	var cs := 168.0
	for i in cand.size():
		var it: Dictionary = cand[i]
		var cell := W.treasure_cell(it, Vector2(cs, cs))
		cell.position = Vector2((i % 5) * (cs + 16), (i / 5) * (cs + 16))
		var uid := int(it["uid"])
		cell.pressed.connect(func() -> void:
			var pop: PxPopup = Game.app.popup("treasure", {"uid": uid, "hero": id})
			pop.closed.connect(rebuild))
		content.add_child(cell)
	content.custom_minimum_size.y = ceili(cand.size() / 5.0) * (cs + 16)
	if cand.is_empty():
		var em := DrawLayer.make(func(ci: Control) -> void: Px.paragraph(ci, DB.t("treasure.empty"), Rect2(0, 0, ci.size.x, ci.size.y), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4))
		scr.put(em, Rect2(60, 1200, 904, 160))
