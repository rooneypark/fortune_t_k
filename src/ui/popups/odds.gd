extends PxPopup
## 확률 정보 (메타 §3.9): 희귀도별 확률, 확정 규칙 2줄, 장수별 확률 목록(스크롤).


var kind := "hero"


func setup(p: Dictionary) -> void:
	kind = String(p.get("kind", "hero"))
	title = DB.t("odds.title")
	panel_rect = Rect2(60, 230, 904, 1360) if kind in ["hero", "hero_gold"] else Rect2(60, 420, 904, 900)
	if kind == "soldier":
		panel_rect = Rect2(60, 480, 904, 760)


func build() -> void:
	if kind == "box":
		_build_box()
		return
	if kind == "soldier":
		_build_soldier()
		return
	var gold := kind == "hero_gold"
	var rc: Dictionary = DB.meta["gold_recruit" if gold else "recruit"]
	var head := DrawLayer.make(func(ci: Control) -> void:
		var x := 0.0
		for r: String in ["b", "a", "s", "ss"]:
			var box := Rect2(x, 0, 188, 120)
			ci.draw_rect(box, Px.INK)
			ci.draw_rect(box.grow(-4), DB.rarity_color(r).darkened(0.35))
			Px.text(ci, DB.rarity_name(r), Rect2(box.position + Vector2(0, 8), Vector2(188, 44)), 30, Px.WHITE)
			Px.text(ci, "%s%%" % str(rc["odds"][r]), Rect2(box.position + Vector2(0, 54), Vector2(188, 60)), 44, Px.GOLD)
			x += 204
		if gold:
			Px.text(ci, "· " + DB.t("odds.rule_gold", [Px.num(int(rc["cost_one"])), int(rc["daily_max"])]), Rect2(0, 140, ci.size.x, 40), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "· " + DB.t("odds.rule_gold_pity"), Rect2(0, 182, ci.size.x, 40), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		else:
			Px.text(ci, "· " + DB.t("odds.rule_pity", [int(rc["pity"])]), Rect2(0, 140, ci.size.x, 40), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "· " + DB.t("odds.rule_ten"), Rect2(0, 182, ci.size.x, 40), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "· " + DB.t("odds.rule_box", [int(DB.meta["treasure"]["box"]["pity"])]), Rect2(0, 224, ci.size.x, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT), Vector2(800, 270))
	put(head, Rect2(52, 100, 800, 270))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var content := Control.new()
	sc.add_child(content)
	var ids: Array = []
	for r: String in ["ss", "s", "a", "b"]:
		var l: Array = DB.hero_ids_of_rarity(r)
		l.sort()
		ids.append_array(l)
	for i in ids.size():
		var id := String(ids[i])
		var row := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.22 if i % 2 == 0 else 0.1))
			var a := Art.of_unit(id)
			Px.cover(ci, Art.hued_portrait(String(a["art"]), float(a["hue"])), Rect2(8, 4, 48, 48))
			Px.text(ci, DB.unit_name(id), Rect2(70, 0, 220, ci.size.y), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.rarity_name(DB.rarity_of(id)), Rect2(300, 0, 200, ci.size.y), 24, DB.rarity_color(DB.rarity_of(id)).lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT)
			var ch := Gacha.gold_hero_chance(DB.rarity_of(id)) if gold else Gacha.hero_chance(DB.rarity_of(id))
			Px.text(ci, "%.3f%%" % ch, Rect2(500, 0, 290, ci.size.y), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(800, 56))
		row.position = Vector2(0, i * 58)
		content.add_child(row)
	content.custom_minimum_size = Vector2(800, ids.size() * 58)
	put(sc, Rect2(52, 390, 800, 900))


## 병사 모집 (골드): 기본 / 정예 비율과 병종별 확률.
func _build_soldier() -> void:
	var sr: Dictionary = DB.meta["soldier_recruit"]
	var ids: Array = DB.soldier_ids()
	var body := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("odds.soldier_rule", [int(sr["odds"]["basic"]), int(sr["odds"]["elite"])]), Rect2(0, 0, ci.size.x, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		for i in ids.size():
			var id := String(ids[i])
			var y := 60.0 + i * 50.0
			ci.draw_rect(Rect2(0, y, ci.size.x, 46), Color(0, 0, 0, 0.22 if i % 2 == 0 else 0.1))
			Px.text(ci, DB.troop_name(id), Rect2(16, y, 290, 46), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.t("odds.tier_" + String(DB.soldier(id).get("tier", "basic"))), Rect2(320, y, 200, 46), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "%.2f%%" % Gacha.soldier_chance(id), Rect2(540, y, ci.size.x - 556, 46), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(800, 580))
	put(body, Rect2(52, 110, 800, 580))


## 보물 상자: 등급별 확률 + 천장(30회 안에 영웅 등급 이상).
func _build_box() -> void:
	var box: Dictionary = DB.meta["treasure"]["box"]
	var pity := int(Game.profile.data["pity"]["box"])
	var body := DrawLayer.make(func(ci: Control) -> void:
		var rs := ["common", "rare", "epic", "legend"]
		for i in rs.size():
			var r: String = rs[i]
			var row := Rect2(0, i * 110, ci.size.x, 96)
			ci.draw_rect(row, Px.INK)
			ci.draw_rect(row.grow(-4), DB.rarity_color(r).darkened(0.45))
			Px.fit(ci, Px.tex("rarity_" + r), Rect2(16, row.position.y + 12, 72, 72))
			Px.text(ci, DB.t("rarity_t." + r), Rect2(110, row.position.y, 300, 96), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "%s%%" % str(box["odds"][r]), Rect2(430, row.position.y, ci.size.x - 460, 96), 44, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		Px.text(ci, "· " + DB.t("odds.rule_box", [int(box["pity"])]), Rect2(0, 456, ci.size.x, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("odds.box_left", [maxi(1, int(box["pity"]) - pity)]), Rect2(0, 510, ci.size.x, 44), 28, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(0, 566, ci.size.x, 32), float(pity) / int(box["pity"]), DB.rarity_color("epic")), Vector2(800, 620))
	put(body, Rect2(52, 110, 800, 620))
