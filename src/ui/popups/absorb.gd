extends PxPopup
## 흡수 확인 (GDD §3.4): 먹이 → 받는 쪽. 같은 병종 = 등급 경험 막대,
## 다른 병종 = 특성 카드 3장 중 1개 (칸이 차면 바꿀 특성 선택).

signal done(gained: int)

var run: RunState
var food: UnitState
var target: UnitState
var mode := ""
var _choice := ""
var _replace := -1
var _cards: Array = []
var _repl_btns: Array = []
var _ok: PxButton


func setup(p: Dictionary) -> void:
	run = p["run"]
	food = p["food"]
	target = p["target"]
	mode = String(run.absorb_check(food, target).get("mode", "rank"))
	title = DB.t("absorb.title")
	panel_rect = Rect2(52, 380, 920, 1040) if mode == "trait" else Rect2(72, 520, 880, 760)


func build() -> void:
	var w := panel_rect.size.x
	# food -> target
	put(W.portrait(food.id, Vector2(170, 170)), Rect2(w * 0.5 - 300, 100, 170, 170))
	put(W.portrait(target.id, Vector2(170, 170), {"label": DB.t("battle.rank", [target.rank])}), Rect2(w * 0.5 + 130, 100, 170, 170))
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
	if mode == "rank":
		_build_rank()
	else:
		_build_trait()


func _build_rank() -> void:
	var w := panel_rect.size.x
	var chk := run.absorb_check(food, target)
	var xp := int(chk.get("xp", 1))
	var info := DrawLayer.make(func(ci: Control) -> void:
		var th: Array = DB.rules["rank_absorbs"]
		var nxt := target.next_threshold()
		var cur := target.xp
		var lo := int(th[target.rank - 1])
		var hi := nxt if nxt > 0 else cur
		var after := cur + xp
		Px.text(ci, DB.t("absorb.rank_gain", [xp]), Rect2(0, 0, ci.size.x, 50), 34, Px.WHITE)
		var bar := Rect2(60, 70, ci.size.x - 120, 44)
		Px.bar(ci, bar, float(cur - lo) / maxf(1.0, float(hi - lo)), Px.GOLD)
		var k2 := clampf(float(after - lo) / maxf(1.0, float(hi - lo)), 0.0, 1.0)
		ci.draw_rect(Rect2(bar.position + Vector2(5, 5), Vector2((bar.size.x - 10) * k2, bar.size.y - 10)), Color(1, 1, 1, 0.3 + 0.2 * sin(Time.get_ticks_msec() / 150.0)))
		var up := UnitState.rank_for(after) > target.rank
		Px.text(ci, DB.t("absorb.rank_up", [UnitState.rank_for(after)]) if up else "%d / %d" % [after - lo, hi - lo], Rect2(0, 126, ci.size.x, 50), 32, Px.GOLD if up else Px.MUTED))
	put(info, Rect2(40, 340, w - 80, 180))
	set_process(true)
	_ok = PxButton.colored("yellow", DB.t("absorb.do"), Vector2(330, 120), 40)
	_ok.pressed.connect(func() -> void:
		var g := run.absorb_rank(food, target)
		done.emit(maxi(0, g))
		close())
	put(_ok, Rect2(w * 0.5 + 20, 580, 330, 120))
	var no := PxButton.colored("blue", DB.t("common.cancel"), Vector2(330, 120), 40)
	no.pressed.connect(close)
	put(no, Rect2(w * 0.5 - 350, 580, 330, 120))


func _process(_d: float) -> void:
	for c in panel.get_children():
		if c is DrawLayer:
			c.queue_redraw()


func _build_trait() -> void:
	var w := panel_rect.size.x
	var opts := run.trait_options(food, target)
	var full := target.traits.size() >= target.trait_slots()
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("absorb.pick", [DB.cls_name(food.cls())]), Rect2(0, 0, ci.size.x, 44), 32)
		Px.text(ci, DB.t("absorb.slots", [target.traits.size(), target.trait_slots()]), Rect2(0, 44, ci.size.x, 36), 24, Px.MUTED))
	put(head, Rect2(20, 330, w - 40, 80))
	for i in opts.size():
		var o: Dictionary = opts[i]
		var tid := String(o["id"])
		var owned := bool(o["owned"])
		var b := PxButton.make("panel_small", true, Vector2(270, 250))
		b.disabled = owned
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.fit(btn, Px.tex(String(DB.units["classes"][food.cls()]["icon"])), Rect2(off + Vector2(105, 16), Vector2(60, 60)))
			Px.text(btn, String(o["name"]), Rect2(off + Vector2(10, 80), Vector2(250, 50)), 36, Px.GOLD)
			Px.paragraph(btn, String(o["desc"]), Rect2(off + Vector2(16, 136), Vector2(238, 100)), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)
			if owned:
				Px.text(btn, DB.t("absorb.owned"), Rect2(off + Vector2(0, 200), Vector2(270, 40)), 24, Px.MUTED)
		b.pressed.connect(func() -> void:
			_choice = tid
			for c: PxButton in _cards:
				c.highlight = c == b
			_update_ok())
		_cards.append(b)
		put(b, Rect2(30 + i * 290, 420, 270, 250))
	if full:
		var lab := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("absorb.replace"), Rect2(0, 0, ci.size.x, 40), 28, Color("#ffb070")))
		put(lab, Rect2(20, 690, w - 40, 40))
		for i in target.traits.size():
			var td := DB.trait_def(target.traits[i])
			var rb := PxButton.colored("purple", String(td.get("name", "")), Vector2(200, 80), 30)
			var idx := i
			rb.pressed.connect(func() -> void:
				_replace = idx
				for c: PxButton in _repl_btns:
					c.highlight = c == rb
				_update_ok())
			_repl_btns.append(rb)
			put(rb, Rect2(w * 0.5 - target.traits.size() * 105 + i * 210, 740, 200, 80))
	_ok = PxButton.colored("yellow", DB.t("absorb.do"), Vector2(330, 120), 40)
	_ok.disabled = true
	_ok.pressed.connect(func() -> void:
		if run.absorb_trait(food, target, _choice, _replace):
			done.emit(0)
			close())
	put(_ok, Rect2(w * 0.5 + 20, 880, 330, 120))
	var no := PxButton.colored("blue", DB.t("common.cancel"), Vector2(330, 120), 40)
	no.pressed.connect(close)
	put(no, Rect2(w * 0.5 - 350, 880, 330, 120))


func _update_ok() -> void:
	var full := target.traits.size() >= target.trait_slots()
	_ok.disabled = _choice == "" or (full and _replace < 0)
