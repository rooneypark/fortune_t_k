extends PxPopup
## 합성 창 (개편 §3.8). 골드는 들지 않는다.
## 위: 재료 합성 — 종류(무기·갑옷·보패) × 등급 칸, 같은 칸 재료 3개 → 그 종류·등급 보물 1개.
## 아래: 보물 합성 — 같은 등급 보물 3개(장착 안 한 것, 강화 낮은 것부터) → 한 단계 위 보물 1개.
## 나오는 보물은 그 종류·등급 안에서 같은 확률이다 (창에 적는다).

const CELL := Vector2(168, 100)


func setup(_p: Dictionary) -> void:
	title = DB.t("synth.title")
	panel_rect = Rect2(60, 300, 904, 1180)


func build() -> void:
	for c in panel.get_children():
		if c.has_meta("body"):
			c.queue_free()
	var cfg: Dictionary = DB.meta["treasure"]["materials"]
	var need := int(cfg["craft"])
	var fuse_need := int(cfg["fuse"])
	var rarities: Array = DB.meta["treasure"]["rarity_order"]
	var slots: Array = DB.meta["treasure"]["slots"]
	# ---- 재료 합성
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("synth.mats", [need]), Rect2(0, 0, ci.size.x, 40), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		for i in rarities.size():
			var r := String(rarities[i])
			Px.text(ci, DB.t("rarity_t." + r), Rect2(140 + i * 178, 46, CELL.x, 36), 26, DB.rarity_color(r).lightened(0.3)))
	_body(head, Rect2(30, 96, 844, 84))
	for row in slots.size():
		var slot := String(slots[row])
		var label := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, DB.t("slot." + slot), Rect2(Vector2.ZERO, ci.size), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
		_body(label, Rect2(30, 186 + row * 110, 130, CELL.y))
		for col in rarities.size():
			var rarity := String(rarities[col])
			var have := Game.profile.material_count(slot, rarity)
			var b := PxButton.make("panel_small", true, CELL)
			b.disabled = have < need
			b.pulse = have >= need
			b.overlay = func(btn: PxButton, off: Vector2) -> void:
				btn.draw_rect(Rect2(off + Vector2(8, btn.size.y - 14), Vector2(btn.size.x - 16, 6)), DB.rarity_color(rarity))
				Px.text(btn, "%d / %d" % [have, need], Rect2(off, Vector2(btn.size.x, btn.size.y - 10)), 32, Px.WHITE if have >= need else Px.MUTED)
			b.pressed.connect(func() -> void: _done(Game.profile.craft(slot, rarity)))
			_body(b, Rect2(170 + col * 178, 186 + row * 110, CELL.x, CELL.y))
	# ---- 보물 합성
	var head2 := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("synth.fuse", [fuse_need]), Rect2(0, 0, ci.size.x, 40), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("synth.fuse_hint"), Rect2(0, 40, ci.size.x, 34), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	_body(head2, Rect2(30, 540, 844, 76))
	var row_i := 0
	for r: String in rarities:
		var up := DB.next_rarity(r)
		if up == "":
			continue
		var have := Game.profile.fuse_candidates(r).size()
		var line := DrawLayer.make(func(ci: Control) -> void:
			Px.draw_skin(ci, "panel_small", Rect2(Vector2.ZERO, ci.size))
			ci.draw_rect(Rect2(12, 12, 10, ci.size.y - 24), DB.rarity_color(r))
			Px.text(ci, DB.t("synth.fuse_row", [DB.t("rarity_t." + r), fuse_need, DB.t("rarity_t." + up)]), Rect2(36, 0, 400, ci.size.y), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.t("synth.have", [have]), Rect2(440, 0, 160, ci.size.y), 26, Px.GOLD if have >= fuse_need else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
		_body(line, Rect2(30, 626 + row_i * 112, 844, 100))
		var go := PxButton.colored("purple" if have >= fuse_need else "blue", DB.t("synth.do"), Vector2(200, 80), 32)
		go.disabled = have < fuse_need
		go.pressed.connect(func() -> void: _done(Game.profile.fuse(r)))
		_body(go, Rect2(660, 636 + row_i * 112, 200, 80))
		row_i += 1
	var foot := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("synth.odds"), Rect2(Vector2.ZERO, ci.size), 22, Px.MUTED))
	_body(foot, Rect2(30, 980, 844, 40))
	var ok := PxButton.colored("yellow", DB.t("common.ok"), Vector2(360, 110), 40)
	ok.pressed.connect(close)
	_body(ok, Rect2(272, 1040, 360, 110))


## Shows what a 합성 made (or why it failed) and redraws the counts.
func _done(res: Dictionary) -> void:
	if not bool(res.get("ok", false)):
		Game.app.toast(String(res.get("error", "")))
		Sfx.play("error")
		return
	Sfx.play("jackpot")
	Game.app.popup("reward", {"title": DB.t("treasure.got"), "reward": {}, "items": [res["item"]]})
	build()


func _body(c: Control, r: Rect2) -> void:
	c.set_meta("body", true)
	put(c, r)
