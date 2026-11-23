extends PxPopup
## 확률 정보 (개편 §13): 캐릭터는 전투 중 슬롯에서만 나온다. 슬롯 한 칸의 당첨 확률,
## 당첨 칸이 장수일 확률, 장수 등급 · 병사 기본/정예 확률, 그리고 장수 · 병종마다
## "당첨 칸 하나에서 나올 확률"을 전부 적는다.


func setup(_p: Dictionary) -> void:
	title = DB.t("odds.title")
	panel_rect = Rect2(60, 230, 904, 1360)


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
		for i in lines.size():
			Px.text(ci, "· " + String(lines[i]), Rect2(0, i * 42, ci.size.x, 40), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("odds.per_win"), Rect2(0, 222, ci.size.x, 40), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT), Vector2(800, 270))
	put(head, Rect2(52, 100, 800, 270))
	# 목록: 장수(등급 높은 순) 다음 병종
	var rows: Array = []
	for r: String in ["ss", "s", "a", "b"]:
		for id: String in DB.hero_ids_of_rarity(r):
			rows.append([id, DB.rarity_name(r), DB.rarity_color(r), hero_p * Gacha.hero_chance(id)])
	for id: String in DB.soldier_ids():
		var tier := String(DB.soldier(id).get("tier", "basic"))
		rows.append([id, DB.t("odds.tier_" + tier), Color("#8a9aa8"), (1.0 - hero_p) * Gacha.soldier_chance(id)])
	var content := W.scroll(panel, Rect2(52, 380 + HEAD, 800, 940), func(sc: Control, r: Rect2) -> void:
		sc.position = r.position
		sc.size = r.size
		panel.add_child(sc))
	for i in rows.size():
		var row: Array = rows[i]
		var id := String(row[0])
		var line := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.22 if i % 2 == 0 else 0.1))
			Px.text(ci, DB.unit_name(id), Rect2(16, 0, 280, ci.size.y), 26, Px.WHITE if _has(id) else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, String(row[1]), Rect2(300, 0, 200, ci.size.y), 24, (row[2] as Color).lightened(0.2), HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "%.2f%%" % float(row[3]), Rect2(520, 0, ci.size.x - 536, ci.size.y), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT), Vector2(800, 52))
		line.position = Vector2(0, i * 54)
		content.add_child(line)
	content.custom_minimum_size.y = rows.size() * 54


func _has(id: String) -> bool:
	return Game.profile.owns(id) or Game.profile.owns_troop(id)
