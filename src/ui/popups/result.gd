extends PxPopup
## 결과: 승리 (리본, n-n 클리어, 별, 기록 4칸, 최고 활약, 보상, 로비로/다음) /
## 패배 ("성이 함락되었다", 이어하기 다이아 100 출정당 1회, 기록, 보상).

var p: Dictionary
var victory := false
var _t := 0.0
var _out: Dictionary = {}
## 재료 종류 → 아이콘 (임시 그림)
const MAT_ICON := {"weapon": "ic_sword", "armor": "ic_shield", "charm": "ic_orb"}


func setup(params: Dictionary) -> void:
	p = params
	victory = bool(p["victory"])
	title = DB.t("result.victory") if victory else DB.t("result.defeat")
	ribbon_color = Color("#c8901c") if victory else Color("#4a5566")
	panel_rect = Rect2(52, 300, 920, 1260)
	dim_closes = false
	show_close = false
	_out = p.get("out", {})
	# 8차 시안(결과8_시안1.png)의 자리 그대로, 틀 · 제목 띠 · 칸 · 버튼은 공용 부품. 승리는 금색 제목 띠, 패배는 잿빛.
	# 패배 + 이어하기가 있으면 버튼이 한 줄 더 있어 창이 길다.
	var tall := not victory and bool(p.get("can_continue", false))
	use_kit(Rect2(116, 426, 792, 858 + (124 if tall else 0)), Rect2(244, 384, 536, 100), Rect2(), "kit_frame", "kit_title_gold" if victory else "kit_title")
	title_size = 42
	if not victory:
		title_tint = Color(0.6, 0.6, 0.66)


func build() -> void:
	if _art:
		_build_art()
		return
	var w := panel_rect.size.x
	var head := DrawLayer.make(func(ci: Control) -> void:
		var s := DB.t("result.clear", ["%d %s" % [int(p["stage"]), String(DB.difficulty(int(p["diff"]))["name"])]]) if victory else DB.t("result.fallen")
		# 별(클리어 등급)은 보여 주지 않는다: 깼으면 깬 것이다 (2026-11-23).
		Px.text(ci, s, Rect2(0, 0, ci.size.x, 60), 44, Px.WHITE))
	put(head, Rect2(20, 100, w - 40, 220))
	var st: Dictionary = p["stats"]
	var cells := [[DB.t("result.waves"), "%d/%d" % [int(p["waves"]), 10]], [DB.t("result.kills"), Px.num(int(st.get("kills", 0)))],
		[DB.t("result.spins"), str(int(st.get("spins", 0)))], [DB.t("result.jackpots"), str(int(st.get("jackpots", 0)))]]
	for i in cells.size():
		var c: Array = cells[i]
		var box := DrawLayer.make(func(ci: Control) -> void:
			Px.box(ci, Rect2(Vector2.ZERO, ci.size), Px.PANEL_DEEP, Px.EDGE)
			ci.draw_rect(Rect2(8, 8, ci.size.x - 16, ci.size.y - 16), Px.PANEL_DEEP)
			Px.text(ci, String(c[0]), Rect2(0, 10, ci.size.x, 36), 24, Px.MUTED)
			Px.text(ci, String(c[1]), Rect2(0, 48, ci.size.x, 56), 40, Px.WHITE))
		put(box, Rect2(30 + i * 215, 330, 200, 116))
	var mvp := String(p.get("mvp", ""))
	if mvp != "":
		put(W.portrait(mvp, Vector2(120, 120)), Rect2(40, 470, 120, 120))
		var ml := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, DB.t("result.mvp"), Rect2(0, 6, 400, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, DB.unit_name(mvp), Rect2(0, 48, 500, 56), 42, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		put(ml, Rect2(180, 470, 600, 120))
	# rewards
	var rw := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, 0.28))
		_draw_rewards(ci))
	put(rw, Rect2(30, 610, w - 60, 190))
	if not victory and bool(p.get("can_continue", false)):
		var cont := PxButton.colored("purple", DB.t("result.continue"), Vector2(560, 130), 40)
		cont.sub = Px.num(int(DB.rules["continue_gold"]))
		cont.sub_icon = Px.tex("icon_gold")
		cont.pulse = true
		cont.pressed.connect(func() -> void:
			var b: Node = Game.app.current
			if b != null and b.has_method("continue_run") and b.continue_run():
				close())
		put(cont, Rect2(180, 830, 560, 130))
	var home := PxButton.colored("blue", DB.t("result.lobby"), Vector2(380, 130), 40)
	home.pressed.connect(func() -> void: _leave("lobby"))
	put(home, Rect2(60, 1000, 380, 130))
	var again_label := DB.t("result.next") if victory and int(p["stage"]) < DB.stage_count() else DB.t("result.again")
	var again := PxButton.colored("yellow", again_label, Vector2(380, 130), 40)
	again.pressed.connect(func() -> void: _leave("again"))
	put(again, Rect2(480, 1000, 380, 130))
	if bool(p.get("tutorial", false)) and victory:
		again.disabled = true
		home.pulse = true
	set_process(true)


# ---------------------------------------------------------------- 그림 창 (8차 시안 자리)

const HEAD_AT := Rect2(148, 512, 728, 90)
const CELL := Rect2(148, 625, 175, 121)        # 기록 칸 4개. 칸 간격 184
const MVP_FACE := Rect2(154, 763, 143, 137)
const MVP_INFO := Rect2(309, 763, 561, 137)
const REWARD := Rect2(148, 916, 728, 185)
const BTN_Y := 1123.0


## 그림 창: 한 줄 요약 · 기록 4칸 · 최고 활약 · 보상 칸 · (패배: 이어하기) · 로비로 · 다음/다시.
func _build_art() -> void:
	var head := DrawLayer.make(func(ci: Control) -> void:
		var s := DB.t("result.clear", ["%d %s" % [int(p["stage"]), String(DB.difficulty(int(p["diff"]))["name"])]]) if victory else DB.t("result.fallen")
		Px.text(ci, s, Rect2(Vector2.ZERO, ci.size), 38, Px.GOLD if victory else Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 7))
	_place(head, HEAD_AT)
	var st: Dictionary = p["stats"]
	var cells := [[DB.t("result.waves"), "%d/%d" % [int(p["waves"]), 10]], [DB.t("result.kills"), Px.num(int(st.get("kills", 0)))],
		[DB.t("result.spins"), str(int(st.get("spins", 0)))], [DB.t("result.jackpots"), str(int(st.get("jackpots", 0)))]]
	for i in cells.size():
		var c: Array = cells[i]
		var box := DrawLayer.make(func(ci: Control) -> void:
			Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
			Px.text(ci, String(c[0]), Rect2(0, 16, ci.size.x, 34), 22, Px.MUTED)
			Px.text(ci, String(c[1]), Rect2(0, 52, ci.size.x, 52), 36, Px.GOLD))
		_place(box, Rect2(CELL.position + Vector2(i * 184.3, 0), CELL.size))
	var mvp := String(p.get("mvp", ""))
	var face := DrawLayer.make(func(ci: Control) -> void: Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size)))
	_place(face, MVP_FACE)
	if mvp != "":
		var inner := MVP_FACE.grow(-16)
		_place(W.portrait(mvp, inner.size), inner)
	var ml := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("result.mvp"), Rect2(28, 18, ci.size.x - 56, 36), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.unit_name(mvp) if mvp != "" else "-", Rect2(28, 58, ci.size.x - 56, 56), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	_place(ml, MVP_INFO)
	var rw := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		ci.draw_set_transform(Vector2(14, 8))
		_draw_rewards(ci)
		ci.draw_set_transform(Vector2.ZERO))
	_place(rw, REWARD)
	var by := BTN_Y
	if not victory and bool(p.get("can_continue", false)):
		# 이어하기: 보라 버튼 (금괴 + 값)
		var cont := PxButton.make("kit_btn_purple", true, Vector2(467, 110))
		cont.pulse = true
		cont.overlay = func(b: PxButton, off: Vector2) -> void:
			Px.text(b, DB.t("result.continue"), Rect2(off + Vector2(16, 0), Vector2(b.size.x * 0.56, b.size.y)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
			Px.fit(b, Px.tex("icon_gold"), Rect2(off + Vector2(b.size.x * 0.6, b.size.y * 0.5 - 22), Vector2(48, 44)))
			Px.text(b, Px.num(int(DB.rules["continue_gold"])), Rect2(off + Vector2(b.size.x * 0.6 + 54, 0), Vector2(b.size.x * 0.4 - 70, b.size.y)), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		cont.pressed.connect(func() -> void:
			var b: Node = Game.app.current
			if b != null and b.has_method("continue_run") and b.continue_run():
				close())
		_place(cont, Rect2(278, by, 467, 110))
		by += 124
	# 로비로 (어두운 버튼) · 다음/다시 (빨간 버튼)
	var home := PxButton.make("kit_box", true, Vector2(354, 110))
	home.font_size = 34
	home.text = DB.t("result.lobby")
	home.pressed.connect(func() -> void: _leave("lobby"))
	_place(home, Rect2(148, by, 354, 110))
	var again := PxButton.make("kit_btn_red", true, Vector2(354, 110))
	again.font_size = 34
	again.text = DB.t("result.next") if victory and int(p["stage"]) < DB.stage_count() else DB.t("result.again")
	again.pressed.connect(func() -> void: _leave("again"))
	_place(again, Rect2(522, by, 354, 110))
	if bool(p.get("tutorial", false)) and victory:
		again.disabled = true
		home.pulse = true
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	for c in panel.get_children():
		if c is DrawLayer:
			c.queue_redraw()


func _leave(where: String) -> void:
	if not victory:
		var b: Node = Game.app.current
		if b != null and b.has_method("give_up"):
			b.give_up()
	var s := int(p["stage"])
	var d := int(p["diff"])
	if where == "lobby":
		Game.app.goto("lobby")
		return
	# 깼으면 다음 스테이지: 스테이지가 바뀔 때마다 난이도를 묻는다 (2026-11-24). 졌으면 같은 곳을 다시.
	if victory and s < DB.stage_count():
		Game.app.goto("lobby", {"ask_diff": s + 1})
		return
	Game.next_stage = {"stage": s, "diff": d}
	Game.app.goto("battle", {"stage": s, "diff": d})


## 보상 칸 속: 금 · 경험 · 첫 클리어 · 전리품 아이콘과 숫자.
func _draw_rewards(ci: Control) -> void:
	Px.text(ci, DB.t("result.rewards"), Rect2(20, 0, 160, 50), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	var items: Array = []
	if victory or _out.has("gold"):
		items.append(["icon_gold", Px.num(int(_out.get("gold", 0)))])
		items.append(["ic_scroll", DB.t("result.exp", [int(_out.get("lord_exp", 0))])])
	if int(_out.get("first_gold", 0)) > 0:
		items.append(["icon_gold", DB.t("result.first", [int(_out["first_gold"])])])
	# 전리품: 재료 하나하나를 종류 아이콘 + 등급 색 테두리로 (무기 · 갑옷 · 장신구)
	for m: Dictionary in _out.get("materials", []):
		items.append([MAT_ICON.get(String(m.get("slot", "")), "icon_chest"), DB.t("rarity_t." + String(m.get("rarity", "common"))), DB.rarity_color(String(m.get("rarity", "common")))])
	if items.is_empty():
		Px.text(ci, DB.t("result.after"), Rect2(20, 60, ci.size.x - 40, 80), 26, Px.MUTED)
	var step := minf(205.0, (ci.size.x - 20.0) / maxf(1.0, items.size()))
	for i in items.size():
		var it: Array = items[i]
		var x := 20 + i * step
		var ir := Rect2(x + step * 0.5 - 38, 56, 76, 70)
		if it.size() > 2:
			ci.draw_rect(ir.grow(6), Color(0, 0, 0, 0.4))
			ci.draw_rect(ir.grow(6), it[2] as Color, false, 4.0)
		Px.fit(ci, Px.tex(String(it[0])), ir)
		Px.text(ci, String(it[1]), Rect2(x, 130, step - 4, 40), 24, (it[2] as Color).lightened(0.3) if it.size() > 2 else Px.GOLD)
