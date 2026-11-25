extends PxPopup
## 합성 창 (개편 §3.8). 골드는 들지 않는다.
## 위: 재료 합성 — 종류(무기 · 갑옷 · 보패) x 등급 칸, 같은 칸 재료 n개 → 그 종류 · 등급 장비 1개. 칸을 누르면 합성한다.
## 아래: 장비 합성 — 같은 등급 장비 n개(장착 안 한 것, 강화 낮은 것부터) → 한 단계 위 장비 1개. 왼쪽 칸을 누르면 등급이 바뀐다.
## 자리는 8차 시안(design/art/ui_src/합성8_완성화면.png)에서 잰 화면 px 그대로. 틀 · 칸 · 버튼은 공용 부품.

const FRAME := Rect2(124, 470, 775, 912)
const TITLE := Rect2(249, 432, 526, 99)
const CLOSE := Rect2(817, 450, 89, 86)
const ICON := Rect2(165, 553, 143, 121)        # 줄 머리(종류 아이콘). 줄 간격 130
const CELL := Rect2(315, 553, 133, 121)        # 첫 칸. 칸 간격 139
const HINT := Rect2(159, 948, 706, 105)
const FUSE_IN := Rect2(162, 1107, 129, 129)    # 첫 칸. 칸 간격 138
const ARROW := Rect2(586, 1139, 85, 72)
const FUSE_OUT := Rect2(686, 1097, 174, 153)
const GO := Rect2(146, 1257, 731, 109)

var _fuse_r := ""


func setup(_p: Dictionary) -> void:
	title = DB.t("synth.title")
	title_size = 40
	panel_rect = Rect2(60, 300, 904, 1180)
	use_kit(FRAME, TITLE, CLOSE)


func build() -> void:
	for c in panel.get_children():
		if c.has_meta("body"):
			c.queue_free()
	var cfg: Dictionary = DB.meta["treasure"]["materials"]
	var need := int(cfg["craft"])
	var fuse_need := int(cfg["fuse"])
	var rarities: Array = DB.meta["treasure"]["rarity_order"]
	var slots: Array = DB.meta["treasure"]["slots"]
	# ---- 재료 합성: 종류 3줄 x 등급 칸
	for row in slots.size():
		var slot := String(slots[row])
		var head := DrawLayer.make(func(ci: Control) -> void:
			Px.nine(ci, "dlg_chip_on", Rect2(Vector2.ZERO, ci.size))
			Px.fit(ci, Px.tex(String(W.SLOT_ICON[slot])), Rect2(Vector2(26, 16), Vector2(ci.size.x - 52, ci.size.y - 32))))
		head.tooltip_text = DB.t("slot." + slot)
		_body(head, Rect2(ICON.position + Vector2(0, row * 130), ICON.size))
		for col in mini(4, rarities.size()):
			var rarity := String(rarities[col])
			var have := Game.profile.material_count(slot, rarity)
			var b := PxButton.make("kit_box", true, CELL.size)
			b.disabled = have < need
			b.pulse = have >= need
			b.tooltip_text = DB.t("rarity_t." + rarity)
			b.overlay = func(btn: PxButton, off: Vector2) -> void:
				btn.draw_rect(Rect2(off + Vector2(18, btn.size.y - 26), Vector2(btn.size.x - 36, 6)), DB.rarity_color(rarity))
				Px.text(btn, "%d / %d" % [have, need], Rect2(off + Vector2(0, 6), Vector2(btn.size.x, btn.size.y - 34)), 30, Px.WHITE if have >= need else Px.MUTED)
			b.pressed.connect(func() -> void: _done(Game.profile.craft(slot, rarity)))
			_body(b, Rect2(CELL.position + Vector2(col * 139, row * 130), CELL.size))
	var hint := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("act_synth"), Rect2(28, 22, 72, 60))
		Px.text(ci, DB.t("synth.mats", [need]), Rect2(118, 10, ci.size.x - 140, 44), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("synth.odds"), Rect2(118, 54, ci.size.x - 140, 36), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	_body(hint, HINT)
	var line := DrawLayer.make(func(ci: Control) -> void: ci.draw_rect(Rect2(0, 0, ci.size.x, 4), Color(0.72, 0.56, 0.3)))
	_body(line, Rect2(156, 1073, 712, 4))
	# ---- 장비 합성: 같은 등급 n개 → 한 단계 위 1개
	var fusable: Array = []
	for r: String in rarities:
		if DB.next_rarity(r) != "":
			fusable.append(r)
	if not fusable.has(_fuse_r):
		_fuse_r = String(fusable[0])
		for r: String in fusable:
			if Game.profile.fuse_candidates(r).size() >= fuse_need:
				_fuse_r = r
				break
	var have_f := Game.profile.fuse_candidates(_fuse_r).size()
	var up := DB.next_rarity(_fuse_r)
	for i in 3:
		var cellb := PxButton.make("kit_box", true, FUSE_IN.size)
		cellb.tooltip_text = DB.t("synth.fuse_hint")
		var filled := i < have_f
		cellb.overlay = func(btn: PxButton, off: Vector2) -> void:
			var rc := DB.rarity_color(_fuse_r)
			btn.draw_rect(Rect2(off + Vector2(18, btn.size.y - 26), Vector2(btn.size.x - 36, 6)), rc)
			Px.fit(btn, Px.tex("icon_bag"), Rect2(off + Vector2(32, 22), Vector2(btn.size.x - 64, btn.size.y - 60)), Color(1, 1, 1, 1.0 if filled else 0.25))
		cellb.pressed.connect(func() -> void:
			_fuse_r = String(fusable[(fusable.find(_fuse_r) + 1) % fusable.size()])
			build())
		_body(cellb, Rect2(FUSE_IN.position + Vector2(i * 138, 0), FUSE_IN.size))
	_body(_pic("absorb_arrow"), ARROW)
	var outc := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		ci.draw_rect(Rect2(22, ci.size.y - 30, ci.size.x - 44, 6), DB.rarity_color(up))
		Px.text(ci, DB.t("rarity_t." + up), Rect2(0, 18, ci.size.x, 50), 30, DB.rarity_color(up).lightened(0.3))
		Px.text(ci, DB.t("synth.have", [have_f]), Rect2(0, 68, ci.size.x, 40), 22, Px.GOLD if have_f >= fuse_need else Px.MUTED))
	_body(outc, FUSE_OUT)
	var go := PxButton.make("kit_btn_red", true, GO.size)
	go.disabled = have_f < fuse_need
	go.overlay = func(btn: PxButton, off: Vector2) -> void:
		Px.fit(btn, Px.tex("act_synth"), Rect2(off + Vector2(30, 24), Vector2(72, 60)))
		Px.text(btn, DB.t("synth.fuse_row", [DB.t("rarity_t." + _fuse_r), fuse_need, DB.t("rarity_t." + up)]), Rect2(off + Vector2(120, 0), Vector2(btn.size.x - 150, btn.size.y)), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	go.pressed.connect(func() -> void: _done(Game.profile.fuse(_fuse_r)))
	_body(go, GO)


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
	if _art:
		_place(c, r)
	else:
		put(c, r)
