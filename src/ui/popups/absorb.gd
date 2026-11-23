extends PxPopup
## 흡수 창 (개편 §9.2): 먹이 → 받는 쪽.
## 같은 병종 = 성급 경험 (별 6칸 + 경험 막대, 오르면 별이 하나 늘어난다).
## 다른 병종 = 속성 선택: 먹이 병종의 속성 3장 중 1개 (이미 가진 속성은 레벨 +1,
## 칸이 차면 바꿀 속성 선택). 고른 결과는 바로 계정에 남는다.

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
var _ok: PxButton


func setup(p: Dictionary) -> void:
	run = p["run"]
	food = p["food"]
	target = p["target"]
	mode = String(run.absorb_check(food, target).get("mode", "star"))
	title = DB.t("absorb.title")
	panel_rect = Rect2(52, 380, 920, 1040) if mode == "trait" else Rect2(72, 480, 880, 840)


func build() -> void:
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


# ---------------------------------------------------------------- 같은 병종: 성급 경험

func _build_star() -> void:
	var w := panel_rect.size.x
	var xp := int(run.absorb_check(food, target).get("xp", 1))
	var e := run.account.unit_entry(target.id)
	var star := int(e.get("star", 1))
	var cur := int(e.get("xp", 0))
	var need := MetaRules.star_need(target.id, star)
	var up := need > 0 and cur + xp >= need
	var info := DrawLayer.make(func(ci: Control) -> void:
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
	put(info, Rect2(40, 340, w - 80, 310))
	set_process(true)
	_ok = PxButton.colored("yellow", DB.t("absorb.do"), Vector2(330, 120), 40)
	_ok.pressed.connect(func() -> void:
		var res := run.absorb_star(food, target)
		if res.is_empty():
			close()
			return
		res["mode"] = "star"
		done.emit(res)
		close())
	put(_ok, Rect2(w * 0.5 + 20, 670, 330, 120))
	var no := PxButton.colored("blue", DB.t("common.cancel"), Vector2(330, 120), 40)
	no.pressed.connect(close)
	put(no, Rect2(w * 0.5 - 350, 670, 330, 120))


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
			for c: PxButton in _cards:
				c.highlight = c == b
			_update_ok())
		_cards.append(b)
		put(b, Rect2(30 + i * 290, 420, 270, 250))
	if _full():
		var lab := DrawLayer.make(func(ci: Control) -> void: Px.text(ci, DB.t("absorb.replace"), Rect2(0, 0, ci.size.x, 40), 28, Color("#ffb070")))
		put(lab, Rect2(20, 690, w - 40, 40))
		for i in owned.size():
			var t: Dictionary = owned[i]
			var td := DB.trait_def(String(t["id"]))
			var rb := PxButton.colored("purple", "%s Lv.%d" % [String(td.get("name", "")), int(t["lv"])], Vector2(260, 80), 28)
			var idx := i
			rb.pressed.connect(func() -> void:
				_replace = idx
				for c: PxButton in _repl_btns:
					c.highlight = c == rb
				_update_ok())
			_repl_btns.append(rb)
			put(rb, Rect2(w * 0.5 - owned.size() * 135 + i * 270, 740, 260, 80))
	_ok = PxButton.colored("yellow", DB.t("absorb.do"), Vector2(330, 120), 40)
	_ok.disabled = true
	_ok.pressed.connect(func() -> void:
		var tid := _choice
		if run.absorb_trait(food, target, tid, _replace):
			done.emit({"mode": "trait", "trait": tid, "lv": MetaRules.trait_level(run.account.data, target.id, tid)})
			close())
	put(_ok, Rect2(w * 0.5 + 20, 880, 330, 120))
	var no := PxButton.colored("blue", DB.t("common.cancel"), Vector2(330, 120), 40)
	no.pressed.connect(close)
	put(no, Rect2(w * 0.5 - 350, 880, 330, 120))


## 이미 가진 속성(레벨 +1)은 칸이 차 있어도 바꿀 것을 고르지 않아도 된다.
func _update_ok() -> void:
	var has := _choice != "" and MetaRules.trait_level(run.account.data, target.id, _choice) > 0
	_ok.disabled = _choice == "" or (_full() and not has and _replace < 0)
