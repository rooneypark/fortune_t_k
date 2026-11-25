extends PxPopup
## 확률 정보 (개편 §13): 캐릭터는 전투 중 슬롯에서만 나온다. 슬롯 한 칸의 당첨 확률,
## 당첨 칸이 장수일 확률, 장수 등급 · 병사 기본/정예 확률, 그리고 장수 · 병종마다
## "당첨 칸 하나에서 나올 확률"을 전부 적는다.


## 틀은 우편함과 같은 큰 창(kit_frame2), 위는 규칙 칸 · 아래는 목록 칸 (금테 어두운 칸).
const FRAME := Rect2(85, 363, 853, 1042)
const TITLE := Rect2(249, 362, 526, 98)
const CLOSE := Rect2(817, 379, 90, 87)
const RULES := Rect2(152, 480, 720, 262)
const LIST := Rect2(152, 754, 720, 608)


func setup(_p: Dictionary) -> void:
	title = DB.t("odds.title")
	title_size = 40
	panel_rect = Rect2(60, 230, 904, 1360)
	use_kit(FRAME, TITLE, CLOSE, "kit_frame2")


func build() -> void:
	var hero_p := SlotMachine.hero_chance()
	var ho := Gacha.hero_odds()
	var so := Gacha.soldier_odds()
	var head := DrawLayer.make(func(ci: Control) -> void:
		var lines := [
			DB.t("odds.slot_rule", [int(round(SlotMachine.win_chance() * 100.0))]),
			DB.t("odds.slot_hero", [int(round(hero_p * 100.0))]),
			DB.t("odds.slot_grades", [str(ho["b"]), str(ho["a"]), str(ho["s"]), str(ho["ss"])]),
			DB.t("odds.slot_tiers", [str(so["basic"]), str(so["elite"])]),
			DB.t("odds.slot_new"),
		]
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		for i in lines.size():
			Px.text(ci, "· " + String(lines[i]), Rect2(22, 14 + i * 38, ci.size.x - 44, 36), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("odds.per_win"), Rect2(22, 212, ci.size.x - 44, 36), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(head, RULES)
	var back := DrawLayer.make(func(ci: Control) -> void: Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size)))
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(back, LIST)
	# 목록: 장수(등급 높은 순) 다음 병종
	var rows: Array = []
	for r: String in ["ss", "s", "a", "b"]:
		for id: String in DB.hero_ids_of_rarity(r):
			rows.append([id, DB.rarity_name(r), DB.rarity_color(r), hero_p * Gacha.hero_chance(id)])
	for id: String in DB.soldier_ids():
		var tier := String(DB.soldier(id).get("tier", "basic"))
		rows.append([id, DB.t("odds.tier_" + tier), Color("#8a9aa8"), (1.0 - hero_p) * Gacha.soldier_chance(id)])
	var area := LIST.grow(-16)
	var content := W.scroll(panel, area, func(sc: Control, r: Rect2) -> void:
		sc.position = r.position
		sc.size = r.size
		panel.add_child(sc))
	for i in rows.size():
		var row: Array = rows[i]
		var id := String(row[0])
		var line := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.22 if i % 2 == 0 else 0.1))
			Px.text(ci, DB.unit_name(id), Rect2(16, 0, 260, ci.size.y), 24, Px.WHITE if _has(id) else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(row[1]), Rect2(280, 0, 180, ci.size.y), 22, (row[2] as Color).lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "%.2f%%" % float(row[3]), Rect2(470, 0, ci.size.x - 486, ci.size.y), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(688, 46))
		line.position = Vector2(0, i * 48)
		content.add_child(line)
	content.custom_minimum_size.y = rows.size() * 48


func _has(id: String) -> bool:
	return Game.profile.owns(id) or Game.profile.owns_troop(id)
