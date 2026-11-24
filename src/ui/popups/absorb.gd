extends PxPopup
## 흡수 창 (개편 §9.2): 먹이 → 받는 쪽.
## 같은 병종 = 성급 경험 (별 6칸 + 경험 막대, 오르면 별이 하나 늘어난다).
## 다른 병종 = 속성 선택: 먹이 병종의 속성 3장 중 1개 (이미 가진 속성은 레벨 +1,
## 칸이 차면 바꿀 속성 선택). 아래 속성 칸 3개가 추가 · 레벨업 · 교체를 미리 보여 준다. 고른 결과는 바로 계정에 남는다.

## {mode: "star", gained, star, xp, need} or {mode: "trait", trait, lv}
signal done(info: Dictionary)

var run: RunState
var food: UnitState
var target: UnitState
var mode := ""
var _choice := ""
var _replace := -1
var _cards: Array = []
var _repl_btns: Array = []
## 속성 칸은 최대 6개 (칸 = 성급, 2026-11-24). 3개씩 두 줄.
const SLOTS := 6
var _ok: PxButton
## 그림 창 (2026-11-24): 제미나이 완성 화면에서 떼어 낸 부품 (tools/import_absorb_ui.py → assets/ui/absorb_*.png,
## 자리 absorb_layout.json). 그림이 없으면 선 UI로 그린다.


func setup(p: Dictionary) -> void:
	run = p["run"]
	food = p["food"]
	target = p["target"]
	mode = String(run.absorb_check(food, target).get("mode", "star"))
	title = DB.t("absorb.title")
	panel_rect = Rect2(52, 330, 920, 1130) if mode == "trait" else Rect2(72, 480, 880, 840)
	_art = use_art("absorb")
	if _art:
		dim_closes = false


func build() -> void:
	if _art:
		_build_art()
		return
	var w := panel_rect.size.x
	# food -> target
	put(W.portrait(food.id, Vector2(170, 170)), Rect2(w * 0.5 - 300, 100, 170, 170))
	put(W.portrait(target.id, Vector2(170, 170), {"label": DB.t("battle.rank", [run.star_of(target)])}), Rect2(w * 0.5 + 130, 100, 170, 170))
	var arrow := DrawLayer.make(func(ci: Control) -> void:
		var c := ci.size * 0.5
		var pts := PackedVector2Array([c + Vector2(60, 0), c + Vector2(0, -44), c + Vector2(0, -18), c + Vector2(-70, -18), c + Vector2(-70, 18), c + Vector2(0, 18), c + Vector2(0, 44)])
		ci.draw_colored_polygon(pts, Px.GOLD)
		ci.draw_polyline(pts + PackedVector2Array([pts[0]]), Px.INK, 5.0))
	put(arrow, Rect2(w * 0.5 - 110, 130, 220, 110))
	var names := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, food.display_name(), Rect2(w * 0.5 - 330, 0, 230, 44), 30)
		Px.text(ci, target.display_name(), Rect2(w * 0.5 + 100, 0, 230, 44), 30, Px.GOLD))
	put(names, Rect2(0, 276, w, 44))
	if mode == "star":
		_build_star()
	else:
		_build_trait()


# ---------------------------------------------------------------- 그림 창 (2026-11-24)

## 그림 창: 얼굴 틀 · 화살표 · 이름, 그 아래는 모드에 따라 속성 카드 3장 + 속성 칸 6개 또는 성급 정보, 맨 아래 흡수하기.
func _build_art() -> void:
	for spot in ["face_food", "face_target"]:
		var r := _r(spot)
		_place(_pic("absorb_face_0" if spot == "face_food" else "absorb_face_1"), r)
		var u: UnitState = food if spot == "face_food" else target
		var inner := r.grow(-r.size.x * 0.13)
		var opts := {} if u == food else {"label": DB.t("battle.rank", [run.star_of(target)])}
		_place(W.portrait(u.id, inner.size, opts), inner)
		var nm := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, u.display_name(), Rect2(Vector2.ZERO, ci.size), 30, Px.GOLD if u == target else Px.WHITE))
		_place(nm, Rect2(r.position.x - 30, r.end.y + 2, r.size.x + 60, 40))
	_place(_pic("absorb_arrow"), _r("absorb_arrow"))
	if mode == "star":
		var c0 := _r("card_0")
		var s5 := _r("slot_5")
		_place(_star_info(), Rect2(c0.position.x, c0.position.y + 20, _r("card_2").end.x - c0.position.x, s5.end.y - c0.position.y - 20))
		set_process(true)
	else:
		_build_art_trait()
	_ok = _make_ok(true)
	_place(_ok, _r("absorb_btn_ok"))
	if mode != "star":
		_update_ok()


func _build_art_trait() -> void:
	var opts := run.trait_options(food, target)
	# 안내 두 줄: 고를 것 / 속성 칸 수 또는 고른 카드가 어디로 들어가는지
	var face := _r("face_food")
	var c0 := _r("card_0")
	# 안내 한 줄: 고르기 전 = "○○의 속성 하나를 고르세요 · 칸 n/m", 고른 뒤 = 들어갈 자리 안내 (추가 · 레벨업 · 교체)
	var head := DrawLayer.make(func(ci: Control) -> void:
		var msg := "%s · %s" % [DB.t("absorb.pick", [DB.troop_name(food.troop())]), DB.t("absorb.slots", [run.traits_of(target).size(), run.trait_slots(target)])]
		var col := Px.WHITE
		if _choice != "" and _is_new(_choice) and _full():
			msg = DB.t("absorb.replace")
			col = Color("#ffb070")
		elif _choice != "":
			msg = DB.t("absorb.slot_add") if _is_new(_choice) else DB.t("absorb.slot_up")
			col = Px.HP_GREEN
		Px.text(ci, msg, Rect2(Vector2.ZERO, ci.size), 26, col))
	_place(head, Rect2(c0.position.x, face.end.y + 42, _r("card_2").end.x - c0.position.x, maxf(36.0, c0.position.y - face.end.y - 46)))
	for i in opts.size():
		var o: Dictionary = opts[i]
		var tid := String(o["id"])
		var lv := int(o["lv"])
		var maxed := bool(o["maxed"])
		var r := _r("card_%d" % i)
		var b := PxButton.make("absorb_card_%d" % i, false, r.size)
		b.disabled = maxed
		b.press_depth = 2.0
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			# 카드 안쪽 어두운 칸에만 글자 (그림의 안쪽 칸 = 가로 14~86%, 세로 20~80%)
			var inner := Rect2(off + btn.size * Vector2(0.14, 0.2), btn.size * Vector2(0.72, 0.6))
			Px.text(btn, String(o["name"]), Rect2(inner.position + Vector2(0, 6), Vector2(inner.size.x, 40)), 30, Px.GOLD)
			var tag := DB.t("absorb.owned") if maxed else (DB.t("absorb.new") if lv == 0 else "Lv.%d → %d" % [lv, lv + 1])
			Px.text(btn, tag, Rect2(inner.position + Vector2(0, 48), Vector2(inner.size.x, 30)), 22, Px.MUTED if maxed else Px.HP_GREEN)
			Px.paragraph(btn, DB.trait_desc(tid, mini(lv + 1, MetaRules.trait_max())), Rect2(inner.position + Vector2(4, 86), Vector2(inner.size.x - 8, inner.size.y - 90)), 20, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)
		b.pressed.connect(func() -> void:
			_choice = tid
			_replace = -1
			for c: PxButton in _cards:
				c.highlight = c == b
			_refresh_slots())
		_cards.append(b)
		_place(b, r)
	for i in SLOTS:
		var idx := i
		var r := _r("slot_%d" % i)
		var sb := PxButton.make("absorb_slot_%d" % (i % 3), false, r.size)
		sb.press_depth = 0.0
		sb.overlay = func(btn: PxButton, off: Vector2) -> void: _draw_slot(btn, off, idx)
		sb.pressed.connect(func() -> void:
			if _choice == "" or not _is_new(_choice) or not _full() or idx >= run.traits_of(target).size():
				return
			_replace = idx
			_refresh_slots())
		_repl_btns.append(sb)
		_place(sb, r)
	set_process(true)


# ---------------------------------------------------------------- 같은 병종: 성급 경험

func _build_star() -> void:
	var w := panel_rect.size.x
	put(_star_info(), Rect2(40, 340, w - 80, 310))
	set_process(true)
	_ok = _make_ok(false)
	# 취소 버튼은 없다: 오른쪽 위 닫기(X)가 같은 일을 한다 (2026-11-24 민수 님). 흡수하기는 가운데.
	put(_ok, Rect2(w * 0.5 - 165, 670, 330, 120))


## 같은 병종: 별 6칸 + 경험 막대 + 오르는 능력치 (선 UI · 그림 창 공용).
func _star_info() -> DrawLayer:
	var xp := int(run.absorb_check(food, target).get("xp", 1))
	var e := run.account.unit_entry(target.id)
	var star := int(e.get("star", 1))
	var cur := int(e.get("xp", 0))
	var need := MetaRules.star_need(target.id, star)
	var up := need > 0 and cur + xp >= need
	return DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("absorb.rank_gain", [xp]), Rect2(0, 0, ci.size.x, 50), 34, Px.WHITE)
		# 별 6칸: 오를 별은 반짝인다
		for i in 6:
			var c := Vector2(ci.size.x * 0.5 + (i - 2.5) * 96, 100)
			var next := up and i == star
			var sz := 72.0 + (10.0 * sin(Time.get_ticks_msec() / 120.0) if next else 0.0)
			Px.fit(ci, Px.tex("ic_star" if i < star or next else "ic_star_off"), Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)),
				Color(1, 1, 1, 0.6 + 0.4 * sin(Time.get_ticks_msec() / 120.0)) if next else Color.WHITE)
		var bar := Rect2(60, 160, ci.size.x - 120, 44)
		Px.bar(ci, bar, float(cur) / maxf(1.0, need), Color("#b070ff"))
		var k2 := clampf(float(cur + xp) / maxf(1.0, need), 0.0, 1.0)
		ci.draw_rect(Rect2(bar.position + Vector2(5, 5), Vector2((bar.size.x - 10) * k2, bar.size.y - 10)), Color(1, 1, 1, 0.3 + 0.2 * sin(Time.get_ticks_msec() / 150.0)))
		if up:
			Px.text(ci, DB.t("absorb.rank_up", [star + 1]), Rect2(0, 214, ci.size.x, 50), 36, Px.GOLD)
			# 오르는 기초 능력치를 미리 보여 준다
			var st := MetaRules.unit_stats(run.account.data, target.id)
			var k := float(DB.meta["star"]["mult"])
			Px.text(ci, DB.t("absorb.stat_delta", [Px.num(int(st["atk"])), Px.num(int(float(st["atk"]) * k)), Px.num(int(st["hp"])), Px.num(int(float(st["hp"]) * k))]),
				Rect2(0, 262, ci.size.x, 40), 26, Px.HP_GREEN)
		else:
			Px.text(ci, "%d / %d" % [cur + xp, need], Rect2(0, 214, ci.size.x, 50), 32, Px.MUTED))


## 흡수하기 버튼 (선 UI: 노란 글자 버튼 / 그림 창: 화살표 그림 버튼).
func _make_ok(art: bool) -> PxButton:
	var b: PxButton
	if art:
		b = PxButton.make("absorb_btn_ok", false, _r("absorb_btn_ok").size)
		b.tooltip_text = DB.t("absorb.do")
	else:
		b = PxButton.colored("yellow", DB.t("absorb.do"), Vector2(330, 120), 40)
	if mode == "star":
		b.pressed.connect(_do_star)
	else:
		b.disabled = true
		b.pressed.connect(func() -> void:
			var tid := _choice
			if run.absorb_trait(food, target, tid, _replace):
				done.emit({"mode": "trait", "trait": tid, "lv": MetaRules.trait_level(run.account.data, target.id, tid)})
				close())
	return b


func _do_star() -> void:
	var res := run.absorb_star(food, target)
	if res.is_empty():
		close()
		return
	res["mode"] = "star"
	done.emit(res)
	close()


func _process(_d: float) -> void:
	for c in panel.get_children():
		if c is DrawLayer:
			c.queue_redraw()


# ---------------------------------------------------------------- 다른 병종: 속성 선택

func _full() -> bool:
	return run.traits_of(target).size() >= run.trait_slots(target)


func _build_trait() -> void:
	var w := panel_rect.size.x
	var opts := run.trait_options(food, target)
	var owned: Array = run.traits_of(target)
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("absorb.pick", [DB.troop_name(food.troop())]), Rect2(0, 0, ci.size.x, 44), 32)
		Px.text(ci, DB.t("absorb.slots", [owned.size(), run.trait_slots(target)]), Rect2(0, 44, ci.size.x, 36), 24, Px.MUTED))
	put(head, Rect2(20, 330, w - 40, 80))
	for i in opts.size():
		var o: Dictionary = opts[i]
		var tid := String(o["id"])
		var lv := int(o["lv"])
		var maxed := bool(o["maxed"])
		var b := PxButton.make("panel_small", true, Vector2(270, 250))
		b.disabled = maxed
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, String(o["name"]), Rect2(off + Vector2(10, 14), Vector2(250, 50)), 36, Px.GOLD)
			var tag := DB.t("absorb.owned") if maxed else (DB.t("absorb.new") if lv == 0 else "Lv.%d → Lv.%d" % [lv, lv + 1])
			Px.text(btn, tag, Rect2(off + Vector2(10, 66), Vector2(250, 36)), 26, Px.MUTED if maxed else Px.HP_GREEN)
			Px.paragraph(btn, DB.trait_desc(tid, mini(lv + 1, MetaRules.trait_max())), Rect2(off + Vector2(16, 112), Vector2(238, 124)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)
		b.pressed.connect(func() -> void:
			_choice = tid
			_replace = -1
			for c: PxButton in _cards:
				c.highlight = c == b
			_refresh_slots())
		_cards.append(b)
		put(b, Rect2(30 + i * 290, 420, 270, 250))
	# 속성 칸 3개 (2026-11-24): 받는 쪽의 칸을 늘 보여 준다 — 가진 속성 · 빈 칸(+) · 잠긴 칸(★n).
	# 카드를 고르면 들어갈 칸이 미리 빛난다: 빈 칸이면 추가(초록), 가진 속성이면 레벨업, 칸이 다 찼으면 바꿀 칸을 누른다(빨강).
	var hint := DrawLayer.make(func(ci: Control) -> void:
		var msg := ""
		var col := Px.MUTED
		if _choice != "" and _is_new(_choice) and _full():
			msg = DB.t("absorb.replace")
			col = Color("#ffb070")
		elif _choice != "":
			msg = DB.t("absorb.slot_add") if _is_new(_choice) else DB.t("absorb.slot_up")
			col = Px.HP_GREEN
		Px.text(ci, msg, Rect2(0, 0, ci.size.x, 40), 28, col))
	put(hint, Rect2(20, 690, w - 40, 40))
	for i in SLOTS:
		var idx := i
		var sb := PxButton.make("panel_slot", true, Vector2(260, 72))
		sb.overlay = func(btn: PxButton, off: Vector2) -> void: _draw_slot(btn, off, idx)
		sb.pressed.connect(func() -> void:
			# 칸이 다 찼고 새 속성을 골랐을 때만 바꿀 칸으로 고를 수 있다
			if _choice == "" or not _is_new(_choice) or not _full() or idx >= run.traits_of(target).size():
				return
			_replace = idx
			_refresh_slots())
		_repl_btns.append(sb)
		put(sb, Rect2(w * 0.5 - 3 * 135 + (i % 3) * 270, 740 + (i / 3) * 84, 260, 72))
	_ok = _make_ok(false)
	# 취소 버튼은 없다: 오른쪽 위 닫기(X)가 같은 일을 한다 (2026-11-24 민수 님). 흡수하기는 가운데.
	put(_ok, Rect2(w * 0.5 - 165, 980, 330, 120))


func _is_new(tid: String) -> bool:
	return MetaRules.trait_level(run.account.data, target.id, tid) == 0


func _refresh_slots() -> void:
	for c: PxButton in _repl_btns:
		c.queue_redraw()
	for c in panel.get_children():
		if c is DrawLayer:
			c.queue_redraw()
	_update_ok()


## 속성 칸 하나: 가진 속성(이름 Lv) / 빈 칸(+) / 잠긴 칸(자물쇠 ★n). 고른 카드가 들어갈 칸은 미리 보여 준다.
func _draw_slot(b: PxButton, off: Vector2, i: int) -> void:
	var r := Rect2(off, b.size)
	var owned: Array = run.traits_of(target)
	var open := run.trait_slots(target)
	var name_r := Rect2(r.position + Vector2(8, 0), Vector2(r.size.x - 16, r.size.y))
	if i >= open:
		# 잠긴 칸: 이 칸이 열리는 성급
		var need := 1
		while MetaRules.trait_slots(need) <= i and need < 6:
			need += 1
		Px.fit(b, Px.tex("ic_lock"), Rect2(r.position + Vector2(60, 20), Vector2(40, 40)), Color(1, 1, 1, 0.7))
		Px.text(b, DB.t("battle.rank", [need]), Rect2(r.position + Vector2(104, 0), Vector2(120, r.size.y)), 28, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		return
	var pick_new := _choice != "" and _is_new(_choice)
	if i < owned.size():
		var t: Dictionary = owned[i]
		var tid := String(t["id"])
		var lv := int(t["lv"])
		var tname := String(DB.trait_def(tid).get("name", ""))
		if _choice == tid:
			# 가진 속성 레벨업 미리 보기
			b.draw_rect(r.grow(-4), Color(0.37, 0.75, 0.23, 0.25))
			Px.text(b, "%s Lv.%d → %d" % [tname, lv, mini(lv + 1, MetaRules.trait_max())], name_r, 26, Px.HP_GREEN)
		elif pick_new and _full() and _replace == i:
			# 바꿀 칸 미리 보기: 빨간 X + 새 이름
			b.draw_rect(r.grow(-4), Color(0.85, 0.2, 0.2, 0.28))
			Px.text(b, "%s → %s" % [tname, String(DB.trait_def(_choice).get("name", ""))], name_r, 24, Color("#ffb070"))
		else:
			if pick_new and _full():
				b.draw_rect(r.grow(-2), Color(1, 0.69, 0.44, 0.35 + 0.25 * sin(Time.get_ticks_msec() / 160.0)), false, 4.0)
			Px.text(b, "%s Lv.%d" % [tname, lv], name_r, 28, Px.WHITE)
		return
	# 빈 칸: + 표시, 새 속성을 고르면 첫 빈 칸에 미리 들어간다
	if pick_new and i == owned.size():
		b.draw_rect(r.grow(-4), Color(0.37, 0.75, 0.23, 0.3))
		Px.text(b, "+ " + String(DB.trait_def(_choice).get("name", "")), name_r, 28, Px.HP_GREEN)
	else:
		Px.text(b, "+", name_r, 40, Color(1, 1, 1, 0.35))


## 이미 가진 속성(레벨 +1)은 칸이 차 있어도 바꿀 것을 고르지 않아도 된다.
func _update_ok() -> void:
	var has := _choice != "" and MetaRules.trait_level(run.account.data, target.id, _choice) > 0
	_ok.disabled = _choice == "" or (_full() and not has and _replace < 0)
