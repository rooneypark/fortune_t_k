extends PxScreen
## 전투 (화면 설계서 §4.2, GDD v5, 스테이지-흡수-합성-개편 §3.2): HUD 칩 · 성 체력 ·
## 가로 전장(왼쪽 성벽, 오른쪽에서 적, 가운데 띠가 공터) · 천명 슬롯 · 조작 판.
## 준비 → 전투 시작 → 웨이브 승리 → 준비 ... 10웨이브.
## 뽑힌 유닛은 바로 전장에 선다 (대기석 없음). 끌어서 자리 옮기기 / 흡수(준비 중에만),
## 밀기 · 책사 기술, 보스 경고, 결과, 튜토리얼.

var run: RunState
var field: BattleField
var slot_view: SlotView
var state := "prep"  # prep / fight / over
var stage := 1
var diff := 1
var tutorial := false
var tut_step := 0
var _rng := RandomNumberGenerator.new()
var _hud: Dictionary = {}
var _castle_flash := 0.0
var _castle_shake := 0.0
const LEVER_Y := 1400.0
var _lever: PxButton
var _lever_pull := 0.0
var _btn: Dictionary = {}
var _drag: Dictionary = {}
var _press_pos := Vector2.ZERO
var _banner: DrawLayer
var _banner_data: Dictionary = {}
var _hint: DrawLayer
var _hint_data: Dictionary = {}
var _guide: Guide
var _paused := false
var _t := 0.0
var _speed_i := 0
var _boss_overlay: Control
var _wave_kills := 0


func build() -> void:
	stage = int(params.get("stage", Game.next_stage["stage"]))
	diff = int(params.get("diff", Game.next_stage["diff"]))
	tutorial = bool(params.get("tutorial", false)) and not Game.tutorial_done()
	_rng.randomize()
	if params.has("seed"):
		_rng.seed = int(params["seed"])
	run = RunState.new(_rng, ["guanyu"] if tutorial else Game.sortie_heroes(), Game.sortie_troops(), stage, diff, Game.profile)
	run.changed.connect(_on_run_changed)
	Sfx.play_bgm("bgm_battle")
	# 전장
	field = BattleField.new()
	field.setup(run, Game.profile.data)
	field.shake_on = bool(Game.settings().get("shake", true))
	put(field, Rect2(0, 0, 1024, 1328), Pin.BOTTOM)
	field.castle_hit.connect(_on_castle_hit)
	field.wave_done.connect(_on_wave_done)
	field.enemy_killed.connect(func(_f: Fighter) -> void:
		run.stats["kills"] += 1
		_wave_kills += 1
		Sfx.play("hit", randf_range(0.9, 1.1)))
	field.ally_fell.connect(func(_f: Fighter) -> void:
		if tutorial and tut_step == 50:
			_show_hint(DB.t("tut.respawn"))
			tut_step = 51)
	field.boss_spawned.connect(func(_f: Fighter) -> void: Sfx.play("boss"))
	# 부활 대기 (전장 띠 위, 오른쪽 구석)
	var rings := DrawLayer.make(_draw_rings)
	put(rings, Rect2(884, 356, 140, 340), Pin.BOTTOM)
	_hud["rings"] = rings
	# 슬롯
	slot_view = SlotView.new()
	slot_view.bind(run.slot)
	slot_view.reels_stopped.connect(_on_reels_stopped)
	slot_view.reel_tapped.connect(_on_reel_tapped)
	put(slot_view, Rect2(0, 1328, 526, 464), Pin.BOTTOM)
	_build_controls()
	_build_hud()
	_banner = DrawLayer.make(_draw_banner)
	put(_banner, Rect2(0, 560, 1024, 220), Pin.MID)
	_hint = DrawLayer.make(_draw_hint)
	put(_hint, Rect2(40, 300, 944, 120), Pin.TOP)
	set_process(true)
	_refresh()
	_show_banner("%s · %s" % [DB.stage_name(stage), String(DB.difficulty(diff)["name"])], DB.t("battle.wave_n", [1, run.wave_count()]))
	if tutorial:
		_tut(10)


# ---------------------------------------------------------------- layout

func _chip(icon: String, r: Rect2) -> PxButton:
	var b := PxButton.make("panel_small", true, r.size)
	b.icon = Px.tex(icon)
	b.icon_rect = Rect2(12, 12, 62, 62)
	b.text_rect = Rect2(78, 0, r.size.x - 90, r.size.y)
	b.font_size = 36
	b.static_panel = true
	put(b, r)
	return b


func _build_hud() -> void:
	# 군량 칩: 누르면 금으로 가득 채운다 (개편 §13)
	_hud["rice"] = _chip("icon_rice", Rect2(24, 28, 188, 88))
	var rice_chip: PxButton = _hud["rice"]
	rice_chip.static_panel = false
	rice_chip.mouse_filter = Control.MOUSE_FILTER_STOP
	rice_chip.pressed.connect(W.ask_rice)
	_hud["army"] = _chip("icon_soldier", Rect2(216, 28, 188, 88))
	_hud["hero"] = _chip("icon_hero", Rect2(408, 28, 188, 88))
	_hud["wave"] = _chip("icon_flag", Rect2(600, 28, 196, 88))
	# 전장 칸 칩: 누르면 군량으로 한 칸 늘린다. 장수 칩은 전장의 장수 수만 보여 준다 (제한 없음).
	var army: PxButton = _hud["army"]
	army.static_panel = false
	army.mouse_filter = Control.MOUSE_FILTER_STOP
	army.pressed.connect(_buy_slot)
	var sp := PxButton.make("btn_small", true, Vector2(96, 88))
	sp.font_size = 36
	sp.text = "1x"
	sp.pressed.connect(_cycle_speed)
	put(sp, Rect2(808, 28, 96, 88))
	_hud["speed"] = sp
	var pause := PxButton.make("btn_pause")
	pause.pressed.connect(_pause)
	put(pause, Rect2(912, 28, 88, 88))
	var castle := DrawLayer.make(_draw_castle)
	put(castle, Rect2(26, 126, 968, 92))
	_hud["castle"] = castle
	var syn := DrawLayer.make(_draw_synergy)
	put(syn, Rect2(26, 226, 968, 120))
	_hud["syn"] = syn


func _build_controls() -> void:
	var panel := DrawLayer.make(func(ci: Control) -> void: Px.draw_skin(ci, "panel_ctrl", Rect2(Vector2.ZERO, ci.size)))
	put(panel, Rect2(526, 1328, 498, 464), Pin.BOTTOM)
	var plate := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "plate_lever", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("icon_rice"), Rect2(10, 8, 44, 44))
		var left := run.spins_left()
		Px.text(ci, "%d/%d" % [left, run.spins_max()], Rect2(54, 0, ci.size.x - 64, ci.size.y), 30, Px.WHITE if left > 0 and run.rice >= run.spin_cost() else Color("#ff8a80")))
	put(plate, Rect2(563, LEVER_Y + 236, 140, 60), Pin.BOTTOM)  # 비용은 레버 아래
	_hud["plate"] = plate
	_lever = PxButton.make("lever")
	_lever.sound = ""
	_lever.press_depth = 0.0
	_lever.overlay = func(b: PxButton, _off: Vector2) -> void: pass
	_lever.pressed.connect(_spin)
	put(_lever, Rect2(576, LEVER_Y, 112, 216), Pin.BOTTOM)
	# 버튼은 둘뿐: 전투 시작 · 책사. 재배치는 릴의 위아래 칸을 직접 누르고, 배속은 위쪽 HUD에 있다.
	var specs := [
		["battle", "btn_battle", Rect2(720, 1400, 256, 152), _start_wave],
		["advisor", "btn_advisor", Rect2(720, 1584, 256, 128), _advisor],
	]
	for s: Array in specs:
		var b := PxButton.make(String(s[1]))
		b.size = (s[2] as Rect2).size
		b.pressed.connect(s[3])
		b.tooltip_text = _ctrl_tip(String(s[0]))
		put(b, s[2], Pin.BOTTOM)
		_btn[s[0]] = b
	# 전투 중에는 남은 적 수를 모서리에 적는다.
	_btn["battle"].overlay = func(b: PxButton, off: Vector2) -> void:
		if state != "prep":
			_num(b, off, str(field.enemies_left()))


func _ctrl_tip(k: String) -> String:
	return DB.t("battle.start") if k == "battle" else DB.t("battle.advisor")


## Corner number on an icon-only button: outlined text, no plate.
func _num(b: PxButton, off: Vector2, s: String) -> void:
	var r := Rect2(Vector2(8, b.size.y - 44) + off, Vector2(b.size.x - 18, 38))
	Px.text(b, s, r, 30, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 8)


# ---------------------------------------------------------------- state

func _on_run_changed() -> void:
	_refresh()


func _refresh() -> void:
	(_hud["rice"] as PxButton).text = "%d/%d" % [run.rice, int(DB.rules["rice_max"])]
	(_hud["army"] as PxButton).text = "%d/%d" % [run.field.size(), run.field_cap]
	(_hud["hero"] as PxButton).text = str(run.heroes_on_field())
	(_hud["wave"] as PxButton).text = "%d/%d" % [mini(run.wave + 1, run.wave_count()), run.wave_count()]
	(_hud["speed"] as PxButton).text = "%dx" % int(field.speed)
	var busy := slot_view.spinning
	_btn["battle"].disabled = state != "prep" or busy
	_btn["battle"].pulse = state == "prep" and not busy and not run.field.is_empty() and not tutorial
	# 재배치: 꽝 줄의 위아래 칸을 누를 수 있는 동안 슬롯이 그 칸을 밝힌다
	slot_view.nudge_ready = run.can_nudge() and not busy
	_btn["advisor"].disabled = not run.advisor_ready() or busy
	_lever.disabled = busy or state == "over"
	for k in _btn:
		_btn[k].queue_redraw()
	_hud["plate"].queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_castle_flash = maxf(0.0, _castle_flash - delta * 2.0)
	_castle_shake = maxf(0.0, _castle_shake - delta * 3.0)
	_lever_pull = maxf(0.0, _lever_pull - delta * 3.0)
	_lever.position.y = LEVER_Y + dy(Pin.BOTTOM) + roundf(sin(_lever_pull * PI) * 40.0)
	_lever.scale.y = 1.0 - 0.2 * sin(_lever_pull * PI)
	for k in ["castle", "syn"]:
		_hud[k].queue_redraw()
	if state == "fight":
		_btn["battle"].queue_redraw()
	_hud["rings"].queue_redraw()
	_banner.queue_redraw()
	_hint.queue_redraw()
	if not _banner_data.is_empty():
		_banner_data["t"] = float(_banner_data["t"]) + delta
		if float(_banner_data["t"]) > float(_banner_data.get("life", 1.8)):
			_banner_data = {}
	if not _hint_data.is_empty():
		_hint_data["t"] = float(_hint_data["t"]) + delta
		if float(_hint_data["t"]) > 4.0:
			_hint_data = {}


# ---------------------------------------------------------------- slot

func _spin() -> void:
	if slot_view.spinning or state == "over":
		return
	if tutorial and not [10, 20, 30].has(tut_step):
		return
	var why := run.spin_block_reason()
	if why != "":
		toast(why)
		Sfx.play("error")
		return
	_lever_pull = 1.0
	_tut_before_spin()
	var r := run.spin()
	_pending_events = r["events"]
	if tutorial:
		_tut_after_spin_started()
	slot_view.spin_to_result(r["result"], Game.slot_speed())
	_refresh()


var _pending_events: Array = []


func _on_reels_stopped() -> void:
	var res := run.last_result
	var got: Array = []
	for e: Dictionary in _pending_events:
		if String(e["type"]) == "field":
			got.append(e["unit"])
	if got.is_empty():
		Sfx.play("miss")
	else:
		var hero := ""
		for u: UnitState in got:
			if hero == "" and u.is_hero():
				hero = u.id
		if bool(res.get("jackpot", false)):
			Sfx.play("jackpot")
			_show_banner(DB.t("slot.jackpot"), DB.t("slot.jackpot_sub"), Px.GOLD)
		elif hero != "":
			Sfx.play("jackpot")
			_show_banner(DB.t("slot.hero_line", [DB.unit_name(hero)]), DB.t("slot.hero_sub"), Px.GOLD)
		elif got.size() == 1:
			Sfx.play("win")
			_show_banner(DB.t("slot.win_one", [(got[0] as UnitState).display_name()]), "", Color("#7fe0ff"))
		else:
			Sfx.play("win")
			_show_banner(DB.t("slot.win_many", [got.size()]), "", Color("#7fe0ff"))
	_apply_events(_pending_events)
	_pending_events = []
	_refresh()
	if tutorial:
		_tut_after_stop()


func _apply_events(events: Array) -> void:
	field.sync()
	var msgs: Array = []
	for e: Dictionary in events:
		match String(e["type"]):
			"field":
				field.show_summon(e["unit"])
				Sfx.play("pop")
				if bool(e.get("new", false)):
					msgs.append(DB.t("battle.new_unit", [(e["unit"] as UnitState).display_name()]))
			"refund":
				msgs.append(DB.t("battle.refund", [int(e["rice"])]))
				Sfx.play("coin")
			"lost":
				if bool(e.get("new", false)):
					msgs.append(DB.t("battle.new_unit", [(e["unit"] as UnitState).display_name()]))
				msgs.append(DB.t("battle.lost", [(e["unit"] as UnitState).display_name()]))
	if not msgs.is_empty():
		_show_hint(" / ".join(msgs))


func _advisor() -> void:
	if not run.advisor_ready():
		return
	match run.advisor_type():
		"respin":
			slot_view.mode = "" if slot_view.mode == "respin" else "respin"
		_:
			run.use_advisor()
			_show_hint(String(DB.advisor_skill(run.advisor).get("desc", "")))
			Sfx.play("skill")
			_refresh()


## A reel was tapped. 책사 "한 칸 다시" (respin mode): the blank reel spins again.
## Otherwise 재배치: [param dir] +1 = the cell above was tapped and comes down,
## -1 = the cell below comes up.
func _on_reel_tapped(reel: int, dir: int) -> void:
	if slot_view.mode == "respin":
		var r2 := run.use_advisor(reel)
		if r2.is_empty():
			slot_view.mode = ""
			return
		_pending_events = r2["events"]
		slot_view.move_reel(reel, r2["result"], Game.slot_speed(), true)
		Sfx.play("lever")
		_refresh()
		return
	if tutorial and (tut_step != 32 or reel != 2 or dir != 1):
		return
	var r := run.nudge(reel, dir)
	if r.is_empty():
		toast(DB.t("battle.no_rice") if run.rice < run.nudge_cost() else DB.t("slot.nudge_tip"))
		return
	if tutorial:
		_close_guide()
	_pending_events = r["events"]
	slot_view.move_reel(reel, r["result"], Game.slot_speed())
	Sfx.play("whoosh")
	_refresh()


func _buy_slot() -> void:
	var cost := run.field_cap_cost()
	if cost < 0:
		toast(DB.t("battle.slot_max"))
		return
	var c := Game.app.popup("confirm", {"title": DB.t("battle.buy_army"), "text": DB.t("battle.buy_text", [cost]), "ok": DB.t("common.buy")})
	c.confirmed.connect(func() -> void:
		if not run.buy_field_cap():
			toast(DB.t("common.no_gold"))
		else:
			Sfx.play("coin")
			_refresh())


func _cycle_speed() -> void:
	_speed_i = (_speed_i + 1) % 3
	field.speed = float(DB.rules["speeds"][_speed_i])
	_refresh()


# ---------------------------------------------------------------- waves

func _start_wave() -> void:
	if state != "prep" or slot_view.spinning:
		return
	if run.field.is_empty():
		toast(DB.t("battle.need_unit"))
		return
	if tutorial and tut_step != 45:
		return
	slot_view.mode = ""
	var w := run.current_wave()
	if String(w.get("boss", "")) != "":
		_show_boss(String(w["boss"]))
		return
	_go_fight()


func _go_fight() -> void:
	state = "fight"
	_wave_kills = 0
	field.start_wave()
	Sfx.play("whoosh")
	if bool(run.current_wave().get("judge", false)):
		_show_banner(DB.t("battle.judge"), DB.t("battle.judge_sub"), Color("#ff8a3a"))
	_refresh()
	if tutorial and tut_step == 45:
		_tut(50)


func _on_castle_hit(dmg: float) -> void:
	if state != "fight":
		return
	run.damage_castle(dmg)
	_castle_flash = 1.0
	_castle_shake = 1.0
	Sfx.play("castle")
	if tutorial and tut_step < 52 and tut_step >= 50:
		_show_hint(DB.t("tut.castle"))
		tut_step = 52
	if run.castle_fallen():
		_defeat()


func _on_wave_done() -> void:
	if state != "fight":
		return
	var last := run.is_last_wave()
	var top := _mvp()
	var res := run.finish_wave()
	field.sync()
	if last:
		_victory()
		return
	state = "prep"
	Sfx.play("victory")
	var p := Game.app.popup("wave_clear", {"wave": run.wave, "total": run.wave_count(), "spins_left": run.spins_left(), "castle": res["castle"],
		"kills": _wave_kills, "mvp": top, "next": run.current_wave()})
	p.closed.connect(func() -> void:
		_refresh()
		if tutorial and tut_step < 60:
			_tut(60))
	_refresh()


func _mvp() -> UnitState:
	var best: UnitState = null
	for u in run.field:
		if best == null or u.damage > best.damage:
			best = u
	return best


func _victory() -> void:
	state = "over"
	field.fighting = false
	var stars := run.stars_earned(true)
	var out := Game.profile.finish_run(stage, diff, run.wave_count(), true, stars, run.stats)
	if tutorial or not Game.tutorial_done():
		Game.profile.data["tutorial"]["done"] = true
		Game.profile.changed.emit()
	Sfx.stop_bgm()
	Sfx.play("victory")
	Game.app.popup("result", {"victory": true, "stage": stage, "diff": diff, "out": out, "stats": run.stats, "mvp": _mvp_overall(),
		"castle": run.castle_ratio(), "waves": run.wave_count()})


func _mvp_overall() -> String:
	var best: UnitState = null
	for u in run.field:
		if best == null or u.damage > best.damage:
			best = u
	return best.id if best != null else ""


func _defeat() -> void:
	state = "over"
	field.fighting = false
	Sfx.play("defeat")
	var p := Game.app.popup("result", {"victory": false, "stage": stage, "diff": diff, "stats": run.stats, "mvp": _mvp_overall(),
		"castle": 0.0, "waves": run.wave, "can_continue": not run.continued})
	p.set_meta("battle", self)


## Called by the defeat pop-up: 이어하기 (다이아 100, once per run).
func continue_run() -> bool:
	var cost := int(DB.rules["continue_gold"])
	if not Game.profile.pay("gold", cost):
		toast(DB.t("common.no_gold"))
		return false
	run.revive()
	field.clear_enemies()
	state = "prep"
	field.sync()
	_refresh()
	_show_banner(DB.t("battle.continued"), DB.t("battle.wave_n", [run.wave + 1, run.wave_count()]))
	return true


## Called by the defeat pop-up or pause: record the run and leave.
func give_up() -> Dictionary:
	if state == "done":
		return {}
	state = "done"
	return Game.profile.finish_run(stage, diff, run.wave, false, 0, run.stats)


func _show_boss(id: String) -> void:
	var d := DB.enemy_def(id)
	var ov := Control.new()
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	var t0 := _t
	var dl := DrawLayer.make(func(ci: Control) -> void:
		var k := minf(1.0, (_t - t0) / 0.3)
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.25, 0.02, 0.02, 0.72 * k))
		var cy := ci.size.y * 0.42
		for i in 3:
			ci.draw_rect(Rect2(0, cy - 300 + i * 6, ci.size.x, 3), Color(1, 0.3, 0.2, 0.5))
			ci.draw_rect(Rect2(0, cy + 300 - i * 6, ci.size.x, 3), Color(1, 0.3, 0.2, 0.5))
		Px.ribbon(ci, Rect2(212, cy - 300, 600, 120), DB.t("battle.boss"), 56, Color("#a8241f"))
		Px.text(ci, String(d.get("name", "")), Rect2(0, cy + 150, ci.size.x, 80), 64, Px.GOLD)
		Px.text(ci, String(d.get("rule", "")), Rect2(60, cy + 230, ci.size.x - 120, 50), 32, Px.WHITE)
		var a := 0.5 + 0.5 * sin(_t * 4.0)
		Px.text(ci, DB.t("battle.tap_start"), Rect2(0, cy + 330, ci.size.x, 50), 32, Color(1, 1, 1, a)))
	dl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.add_child(dl)
	var u := UnitView.make(id, 300.0)
	u.height = Art.target_h(String(d.get("art", "enemy_brute"))) * float(d.get("scale", 1.0)) * 1.6
	u.position = Vector2(size.x * 0.5, size.y * 0.42 + 130)
	ov.add_child(u)
	ov.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and _t - t0 > 0.4:
			ov.queue_free()
			_go_fight())
	Game.app.overlay_layer.add_child(ov)
	_boss_overlay = ov
	Sfx.play("boss")


func _pause() -> void:
	if state == "over":
		return
	field.set_process(false)
	var p := Game.app.popup("pause", {})
	p.set_meta("battle", self)
	p.closed.connect(func() -> void:
		if is_instance_valid(field):
			field.set_process(true)
			field.shake_on = bool(Game.settings().get("shake", true)))


func back() -> bool:
	_pause()
	return true


# ---------------------------------------------------------------- drag & drop

func _gui_input(e: InputEvent) -> void:
	if state == "over":
		return
	var p := Vector2.ZERO
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		p = e.position
		if e.pressed:
			_press_pos = p
			_begin_drag(p)
		else:
			_end_drag(p)
	elif e is InputEventMouseMotion and not _drag.is_empty():
		_move_drag(e.position)


func _field_pos(p: Vector2) -> Vector2:
	return p - field.position


func _begin_drag(p: Vector2) -> void:
	_drag = {}
	var f := field.fighter_at(_field_pos(p))
	if f != null:
		_drag = {"src": "field", "unit": f.unit, "fighter": f}


func _drop_target(p: Vector2, d: Dictionary = _drag) -> Dictionary:
	if d.is_empty():
		return {"kind": "none", "ok": false, "label": ""}
	var u: UnitState = d["unit"]
	var fp := _field_pos(p)
	var f := field.fighter_at(fp)
	if f != null and f.unit != u:
		# 흡수는 준비 시간에만 (개편 §5).
		if state == "fight":
			return {"kind": "none", "ok": false, "label": DB.t("battle.no_absorb_fight")}
		return _absorb_target(u, f.unit)
	if field.in_zone(fp):
		return {"kind": "move", "ok": true, "label": ""}
	return {"kind": "none", "ok": false, "label": ""}


func _absorb_target(food: UnitState, target: UnitState) -> Dictionary:
	var chk := run.absorb_check(food, target)
	if not chk["ok"]:
		return {"kind": "none", "ok": false, "label": String(chk.get("reason", ""))}
	var label := DB.t("absorb.rank_label") if chk["mode"] == "star" else DB.t("absorb.trait_label")
	return {"kind": "absorb", "ok": true, "target": target, "label": label}


func _move_drag(p: Vector2) -> void:
	if _drag.is_empty() or p.distance_to(_press_pos) < 12.0:
		return
	_drag["moved"] = true
	var tgt := _drop_target(p, _drag)
	var u: UnitState = _drag["unit"]
	field.set_ghost({"pos": _field_pos(p) + Vector2(0, 40), "id": u.id, "ok": tgt["ok"], "label": tgt["label"]})


func _end_drag(p: Vector2) -> void:
	field.set_ghost({})
	if _drag.is_empty():
		return
	var d := _drag
	_drag = {}
	var u: UnitState = d["unit"]
	if not d.get("moved", false):
		_show_hint(_unit_line(u))
		return
	var tgt := _drop_target(p, d)
	if not tgt["ok"]:
		if String(tgt["label"]) != "":
			toast(String(tgt["label"]))
			Sfx.play("error")
		return
	match String(tgt["kind"]):
		"move":
			field.move_home(d["fighter"], _field_pos(p) + Vector2(0, 40))
			Sfx.play("click")
		"absorb":
			_open_absorb(u, tgt["target"])
	_refresh()


func _unit_line(u: UnitState) -> String:
	var s := "%s · %s · %s" % [u.display_name(), DB.cls_name(u.cls()), DB.t("battle.rank", [run.star_of(u)])]
	var names: Array = []
	for t: Dictionary in run.traits_of(u):
		names.append("%s %d" % [String(DB.trait_def(String(t["id"])).get("name", "")), int(t["lv"])])
	if not names.is_empty():
		s += " · " + ", ".join(names)
	return s


## 흡수 창을 열고, 결과를 전장에 보여 준다: 성급이 오르면 띠 + 오른 능력치,
## 아니면 성급 경험, 속성이면 얻은 속성과 레벨.
func _open_absorb(food: UnitState, target: UnitState) -> void:
	var before := MetaRules.unit_stats(Game.profile.data, target.id)
	var p := Game.app.popup("absorb", {"run": run, "food": food, "target": target})
	p.connect("done", func(info: Dictionary) -> void:
		field.sync()
		var f := field.ally_of(target)
		if f != null:
			field.burst(f.pos, Px.GOLD)
		if String(info.get("mode", "")) == "star":
			if int(info.get("gained", 0)) > 0:
				var after := MetaRules.unit_stats(Game.profile.data, target.id)
				Sfx.play("jackpot")
				_show_banner(DB.t("absorb.star_banner", [target.display_name(), int(info["star"])]),
					DB.t("absorb.stat_delta", [Px.num(int(before["atk"])), Px.num(int(after["atk"])), Px.num(int(before["hp"])), Px.num(int(after["hp"]))]), Px.GOLD)
			else:
				Sfx.play("rankup")
				_show_hint(DB.t("absorb.xp_hint", [target.display_name(), int(info.get("xp", 0)), int(info.get("need", 0))]))
		else:
			Sfx.play("rankup")
			_show_hint(DB.t("absorb.trait_got", [target.display_name(), String(DB.trait_def(String(info.get("trait", ""))).get("name", "")), int(info.get("lv", 1))]))
		_refresh())


# ---------------------------------------------------------------- drawing

func _draw_castle(ci: Control) -> void:
	var off := Vector2(roundf(sin(_t * 60.0) * 6.0 * _castle_shake), 0)
	var r := Rect2(off, ci.size)
	Px.draw_skin(ci, "panel_wide", r)
	Px.fit(ci, Px.tex("icon_castle"), Rect2(off + Vector2(24, 14), Vector2(72, 63)))
	var ratio := run.castle_ratio()
	var low := ratio <= 0.3 and int(_t * 4.0) % 2 == 0
	var col := Px.HP_RED if not low else Color("#ff6a5a")
	Px.bar(ci, Rect2(off + Vector2(112, 24), Vector2(700, 44)), ratio, col)
	if _castle_flash > 0.0:
		ci.draw_rect(Rect2(off + Vector2(112, 24), Vector2(700, 44)), Color(1, 0.2, 0.2, 0.45 * _castle_flash))
	Px.text(ci, "%d%%" % int(roundf(ratio * 100.0)), Rect2(off + Vector2(820, 0), Vector2(130, ci.size.y)), 38)


func _draw_synergy(ci: Control) -> void:
	var b := field.boss()
	var y := 0.0
	if b != null:
		var d := DB.enemy_def(b.id)
		ci.draw_rect(Rect2(0, 0, ci.size.x, 56), Color(0.1, 0.02, 0.02, 0.8))
		ci.draw_rect(Rect2(0, 0, ci.size.x, 3), Color("#ff5a4a"))
		Px.fit(ci, Px.tex("ic_boss"), Rect2(10, 8, 40, 40))
		Px.text(ci, String(d.get("name", "")), Rect2(56, 0, 180, 56), 30, Color("#ffb0a0"), HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(240, 12, 710, 32), b.ratio(), Color("#c83a8a"))
		y = 64.0
	var x := 0.0
	var list: Array = field.active_synergies()
	for s: Dictionary in list:
		var label := String(s["name"])
		var w := Px.text_width(label, 22) + 30
		if x + w > ci.size.x:
			break
		var c := Color("#5a3a22")
		if s["kind"] == "faction":
			c = DB.fac_color(String(s["key"])).darkened(0.2)
		elif s["kind"] == "bond":
			c = Color("#7a3a9a")
		# 같은 키트: 철테 칩 + 진영색 글씨 (색 상자 대신)
		Px.draw_skin(ci, "panel_chip", Rect2(x, y, w, 40))
		Px.text(ci, label, Rect2(x + 4, y, w - 8, 40), 22, c.lightened(0.55))
		x += w + 8


func _draw_rings(ci: Control) -> void:
	var n := 0
	for f in field.allies:
		if not f.dead or n >= 3:
			continue
		var r := Rect2(24, 20 + n * 112, 104, 104)
		var a := Art.of_unit(f.id)
		var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
		ci.draw_rect(r.grow(-14), Color("#2a2018"))
		if t != null:
			Px.cover(ci, t, r.grow(-16), Color(0.55, 0.55, 0.6))
		ci.draw_texture_rect(Px.tex("ring_respawn"), r, false)
		var k := clampf(f.respawn_t / maxf(0.1, f.respawn_max), 0.0, 1.0)
		ci.draw_arc(r.get_center(), 44, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k), 32, Px.GOLD, 6.0)
		Px.text(ci, str(ceili(f.respawn_t)), Rect2(r.position + Vector2(52, 56), Vector2(56, 48)), 34)
		n += 1


func _show_banner(title: String, sub: String = "", color: Color = Px.WHITE) -> void:
	_banner_data = {"title": title, "sub": sub, "color": color, "t": 0.0, "life": 1.6}


func _draw_banner(ci: Control) -> void:
	if _banner_data.is_empty():
		return
	var t := float(_banner_data["t"])
	var life := float(_banner_data["life"])
	var a := minf(1.0, t / 0.15) * minf(1.0, (life - t) / 0.3)
	var slide := (1.0 - minf(1.0, t / 0.2)) * 300.0
	ci.draw_rect(Rect2(0, 40, ci.size.x, 140), Color(0.03, 0.05, 0.09, 0.7 * a))
	ci.draw_rect(Rect2(0, 40, ci.size.x, 5), Color(Px.GOLD, a))
	ci.draw_rect(Rect2(0, 175, ci.size.x, 5), Color(Px.GOLD, a))
	var c: Color = _banner_data["color"]
	c.a = a
	var sub := String(_banner_data["sub"])
	Px.text(ci, String(_banner_data["title"]), Rect2(slide, 48 if sub != "" else 70, ci.size.x, 84), 64, c, HORIZONTAL_ALIGNMENT_CENTER, 10)
	if sub != "":
		Px.text(ci, sub, Rect2(-slide, 126, ci.size.x, 44), 30, Color(1, 1, 1, a))


func _show_hint(s: String) -> void:
	_hint_data = {"s": s, "t": 0.0}


func _draw_hint(ci: Control) -> void:
	if _hint_data.is_empty():
		return
	var t := float(_hint_data["t"])
	var a := minf(1.0, t / 0.15) * minf(1.0, (4.0 - t) / 0.4)
	var r := Rect2(0, 0, ci.size.x, 96)
	Px.draw_skin(ci, "panel_slot", r, Color(1, 1, 1, a))
	Px.paragraph(ci, String(_hint_data["s"]), Rect2(24, 14, ci.size.x - 48, 80), 28, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER)


# ---------------------------------------------------------------- tutorial (콘텐츠 §12)

# 슬롯 3칸: 첫 칸 창병 당첨 → 전부 꽝(세 번째 줄 위의 궁병을 재배치로 끌어옴) → 창병 + 관우.
const TUT_SPEAR := {"cells": ["spear", "", ""]}
const TUT_MISS := {"cells": ["", "", ""], "above": ["", "", "archer"], "below": ["", "", ""]}
const TUT_CLASS := {"cells": ["spear", "guanyu", ""]}


func _close_guide() -> void:
	if _guide != null and is_instance_valid(_guide):
		_guide.queue_free()
	_guide = null


func _guide_at(r: Rect2, text: String, anywhere := false) -> Guide:
	_close_guide()
	_guide = Guide.show_at(Game.app.overlay_layer, r, text, anywhere)
	return _guide


func _lever_rect() -> Rect2:
	return Rect2(556, LEVER_Y - 8.0 + dy(Pin.BOTTOM), 154, 312)


func _tut(step: int) -> void:
	tut_step = step
	match step:
		10:
			_guide_at(_lever_rect(), DB.t("tut.spin"))
		20:
			_guide_at(_lever_rect(), DB.t("tut.spin_again"))
		30:
			_guide_at(_lever_rect(), DB.t("tut.spin_third"))
		31:
			var g31 := _guide_at(Rect2(), DB.t("tut.nudge"), true)
			g31.advanced.connect(func() -> void: _tut(32))
		32:
			# 누를 칸 = 세 번째 줄 위에 살짝 보이는 궁병 — 누르면 가운데로 내려온다
			var tr := slot_view.peek_rect(2, -1)
			_guide_at(Rect2(slot_view.global_position + tr.position, tr.size), DB.t("tut.nudge_reel"))
		40:
			# 관우는 뽑히자마자 전장에 선다: 알려 주고 전투 시작으로.
			var g := _guide_at(Rect2(), DB.t("tut.drag"), true)
			g.advanced.connect(func() -> void: _tut(45))
		45:
			_guide_at(Rect2(_btn["battle"].position, _btn["battle"].size), DB.t("tut.battle"))
		50:
			_close_guide()
			_show_hint(DB.t("tut.wave"))
		60:
			var g2 := _guide_at(Rect2(), DB.t("tut.absorb"), true)
			g2.advanced.connect(func() -> void:
				_close_guide()
				_tut(70))
		70:
			tutorial = false
			Game.profile.data["tutorial"]["done"] = true
			Game.profile.changed.emit()
			_show_hint(DB.t("tut.free"))
			_refresh()


func _tut_before_spin() -> void:
	match tut_step:
		10:
			run.slot.forced = TUT_SPEAR.duplicate(true)
		20:
			run.slot.forced = TUT_MISS.duplicate(true)
		30:
			run.slot.forced = TUT_CLASS.duplicate(true)


func _tut_after_spin_started() -> void:
	_close_guide()


func _tut_after_stop() -> void:
	match tut_step:
		10:
			var g := _guide_at(Rect2(), DB.t("tut.jackpot"), true)
			g.advanced.connect(func() -> void: _tut(20))
		20:
			_tut(31)
		32:
			var g2 := _guide_at(Rect2(), DB.t("tut.nudge_done"), true)
			g2.advanced.connect(func() -> void: _tut(30))
		30:
			_tut(40)


# ---------------------------------------------------------------- screenshots / QA

## Scripted states for screenshots (App --demo=...).
func demo(name: String) -> void:
	match name:
		"tut_jackpot":
			while tut_step < 10:
				await get_tree().process_frame
			_spin()
		"tut_drag":
			Game.settings()["slot_speed"] = 2
			while tut_step < 10:
				await get_tree().process_frame
			for step_i in 3:
				if step_i == 1:
					_spin()
					for j in 300:
						await get_tree().process_frame
						if tut_step == 31: break
					_tut(32)
					_on_reel_tapped(2, 1)
					for j in 300:
						await get_tree().process_frame
						if _guide != null: break
					_guide.advanced.emit()
				else:
					_spin()
					for j in 300:
						await get_tree().process_frame
						if _guide != null or tut_step == 40: break
					if _guide != null and tut_step < 40:
						_guide.advanced.emit()
		"tut_nudge":
			Game.settings()["slot_speed"] = 2
			while tut_step < 10:
				await get_tree().process_frame
			_spin()
			while _guide == null:
				await get_tree().process_frame
			await get_tree().create_timer(0.3).timeout
			_guide.advanced.emit()
			for i in 200:
				await get_tree().process_frame
				if tut_step == 20 and not slot_view.spinning:
					break
			await get_tree().create_timer(0.3).timeout
			_spin()
			for i in 300:
				await get_tree().process_frame
				if tut_step == 31:
					break
			_tut(32)
		"prep", "fight", "boss", "absorb", "wave_clear":
			Game.settings()["slot_speed"] = 2
			Game.profile.add_rice(20)
			run.field_cap = maxi(run.field_cap, 8)  # 장면용: 다섯 번 돌려도 자리가 남게
			for cells: Array in [["spear", "guanyu", ""], ["archer", "", "shield"], ["", "huangzhong", "rider"], ["shield", "", ""]]:
				run.slot.forced = {"cells": cells}
				var r := run.spin()
				_apply_events(r["events"])
			slot_view.bind(run.slot)
			run.slot.forced = {"cells": ["xiahoudun", "", "spear"]}
			var r2 := run.spin()
			_pending_events = r2["events"]
			slot_view.spin_to_result(r2["result"], 0.0)
			if name == "boss":
				run.wave = 9
				_start_wave()
			elif name == "fight":
				run.wave = 2
				_go_fight()
				_cycle_speed()
			elif name == "absorb":
				var food: UnitState = null
				var target: UnitState = null
				for u in run.field:
					if target == null and u.is_hero():
						target = u
				for u in run.field:
					if food == null and target != null and u != target and u.cls() != target.cls():
						food = u
				if food != null and target != null:
					_open_absorb(food, target)
			elif name == "wave_clear":
				Game.app.popup("wave_clear", {"wave": 3, "total": run.wave_count(), "spins_left": run.spins_left(), "castle": 100,
					"kills": 24, "mvp": run.field[0] if not run.field.is_empty() else null, "next": run.current_wave()})
			_refresh()
