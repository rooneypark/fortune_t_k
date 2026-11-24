class_name SlotView
extends Control
## 천명 슬롯 cabinet (panel_slot, 526 x 464): three independent reels, one result
## cell each (개편 §9.9). Soldiers are drawn as their weapon icon, heroes as their
## portrait (§9.7). The cells above and below the result row peek in.
##
## Spin feel: every reel jerks back a little, runs fast with streaks, then slows
## down, overshoots and settles with a thump — one after the other from the left.
##
## 재배치: after a spin with a blank, the peeking cell above or below a blank reel
## can be tapped to pull it into the row (both ways).

signal reels_stopped
signal reel_tapped(reel: int, dir: int)

const CELL := Vector2(144, 180)
const COL_X := [38.0, 191.0, 344.0]
const ROW_Y := 142.0
const STEP_Y := 190.0
const WINDOW := Rect2(28, 32, 470, 400)
const ICON_DIR := "res://assets/ui/icons/"

var slot: SlotMachine
## Float strip index per reel (what is drawn in the result row).
var view: Array = [0.0, 0.0, 0.0]
var spinning := false
## True while a blank reel may be shifted (set by the battle screen).
var nudge_ready := false
## Reel indices that show a unit after the last stop.
var wins: Array = []
var _line_t := 0.0
var _t := 0.0
var _miss_t := -1.0
## Cells per second of each reel (for the streaks) and the thump after it stops.
var _speed: Array = [0.0, 0.0, 0.0]
var _last: Array = [0.0, 0.0, 0.0]
var _thump: Array = [0.0, 0.0, 0.0]
var _tick_t := 0.0
static var _weapon: Dictionary = {}

# ---- 그림 슬롯 (2026-11-24): 판 · 릴 · 화살표는 완성 화면에서 떼어 낸 그림 (tools/import_battle3_ui.py).
# 릴은 통째로 구른다: 릴 그림의 한 마디(battle_reel_tile = 크림색 띠 40 + 어두운 칸 92)를 위아래로 이어 붙인
# 끝없는 띠가, 칸 속의 얼굴 · 무기 아이콘과 함께 위에서 아래로 굴러간다. 보이는 곳은 릴 그림의 자리(147 x 308)뿐이다.
# 멈추면 가운데 칸이 결과이고, 위아래로 잘린 칸이 조금 보인다 (완성 화면과 같은 모습).
## 릴 그림 안의 칸 자리 (릴 그림 왼쪽 위 기준 px). 그림마다 다르므로 battle_layout.json 에서 읽는다
## (reel_hole · reel_hole_top · reel_hole_bot · reel_step · reel_inner, tools/import_battle3_ui.py). 없으면 예전 값.
static var HOLE := Rect2(27, 105, 93, 92)
static var HOLE_TOP := Rect2(27, 8, 93, 57)
static var HOLE_BOT := Rect2(27, 237, 93, 62)
## 칸에서 칸까지의 거리
static var ART_STEP := 132.0
## 릴 틀 안쪽 (띠가 구르는 곳). 비어 있으면 릴 그림 전체에서 구른다 (예전 그림)
static var REEL_INNER := Rect2()
## 그림이 있으면 true (없으면 예전처럼 선으로 그린다)
var art := false
var _reel_at: Array = []       # 릴 그림의 자리 (이 노드 안의 px)
var _arrow_up: Array = []
var _arrow_down: Array = []
static var _art_layout: Dictionary = {}


## 전투 UI 부품의 화면 자리 (assets/ui/battle_layout.json).
static func art_rect(name: String) -> Rect2:
	if _art_layout.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/battle_layout.json"))
		_art_layout = parsed if parsed is Dictionary else {"_": []}
	var r: Array = _art_layout.get(name, [])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])) if r.size() == 4 else Rect2()


func _init() -> void:
	size = Vector2(526, 464)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if art_rect("reel_hole").size != Vector2.ZERO:
		HOLE = art_rect("reel_hole")
		HOLE_TOP = art_rect("reel_hole_top")
		HOLE_BOT = art_rect("reel_hole_bot")
		ART_STEP = art_rect("reel_step").size.y
		REEL_INNER = art_rect("reel_inner")
	var panel := art_rect("battle_panel_slot")
	if panel.size != Vector2.ZERO and Px.has_art("battle_panel_slot") and Px.has_art("battle_reel_1"):
		art = true
		size = panel.size
		for i in 3:
			for pair: Array in [[_reel_at, "battle_reel_%d"], [_arrow_up, "battle_arrow_up_%d"], [_arrow_down, "battle_arrow_down_%d"]]:
				var r := art_rect(String(pair[1]) % (i + 1))
				(pair[0] as Array).append(Rect2(r.position - panel.position, r.size))


func _ready() -> void:
	set_process(true)


func bind(s: SlotMachine) -> void:
	slot = s
	for r in 3:
		view[r] = float(slot.stops[r])
		_last[r] = view[r]
	queue_redraw()


## Weapon icon of a troop (assets/ui/icons/wp_<id>.png), or null when there is none yet.
static func weapon_tex(id: String) -> Texture2D:
	if not _weapon.has(id):
		var path := ICON_DIR + "wp_" + id + ".png"
		_weapon[id] = Px.tex("wp_" + id) if (ResourceLoader.exists(path) or FileAccess.file_exists(path)) else null
	return _weapon[id]


## Animates every reel to the current stops of the slot. [param speed] 0 = instant.
func spin_to_result(res: Dictionary, speed: float) -> void:
	wins = res.get("wins", [])
	_line_t = 0.0
	if speed <= 0.0:
		for r in 3:
			view[r] = float(slot.stops[r])
			_last[r] = view[r]
		_finish()
		return
	spinning = true
	Sfx.play("lever")
	var done := [0]
	for r in 3:
		_roll_reel(r, (1.0 + 0.45 * r) * speed, 3 + r, func() -> void:
			done[0] += 1
			if done[0] == 3:
				_finish())


## One reel moves: a full spin or one cell up / down (재배치).
func move_reel(r: int, res: Dictionary, speed: float, full_spin := false) -> void:
	wins = res.get("wins", [])
	_line_t = 0.0
	if speed <= 0.0:
		view[r] = float(slot.stops[r])
		_last[r] = view[r]
		_finish()
		return
	spinning = true
	if full_spin:
		_roll_reel(r, 0.9 * speed, 2, _finish)
		return
	# 재배치: the shortest way to the new stop (one cell), with a small bounce
	var n := (slot.strips[r] as Array).size()
	var start: float = fposmod(float(view[r]), float(n))
	var target := float(slot.stops[r])
	var d := fposmod(target - start + n * 0.5, float(n)) - n * 0.5
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: view[r] = v, start, start + d, 0.26 * maxf(0.5, speed)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		view[r] = target
		_last[r] = target
		_thump[r] = 1.0
		Sfx.play("tick")
		_finish())


## Reel [param r] spins downward to its stop: a short jerk back, a long run that
## slows down, a little overshoot, then it settles.
func _roll_reel(r: int, time: float, turns: int, on_done: Callable) -> void:
	var n := (slot.strips[r] as Array).size()
	var target := float(slot.stops[r])
	var start: float = fposmod(float(view[r]), float(n))
	view[r] = start
	_last[r] = start
	# scrolling down = the index falls; add whole turns so every reel runs a while
	var end := target - n * turns
	while end > start - n * 1.5:
		end -= n
	var set_view := func(v: float) -> void: view[r] = v
	var tw := create_tween()
	tw.tween_method(set_view, start, start + 0.22, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(set_view, start + 0.22, end - 0.16, time).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_method(set_view, end - 0.16, end, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		view[r] = target
		_last[r] = target
		_speed[r] = 0.0
		_thump[r] = 1.0
		Sfx.play("tick", 0.85 + 0.12 * r)
		on_done.call())


func _finish() -> void:
	spinning = false
	_line_t = 0.0
	_miss_t = 0.0 if wins.is_empty() else -1.0
	queue_redraw()
	reels_stopped.emit()


func _process(delta: float) -> void:
	_t += delta
	_line_t += delta
	_tick_t -= delta
	if _miss_t >= 0.0:
		_miss_t += delta
	var loudest := 0.0
	for r in 3:
		var v := float(view[r])
		_speed[r] = absf(v - float(_last[r])) / maxf(0.001, delta)
		# a soft tick each time a cell passes the row, while the reel is still fast
		if spinning and floori(v) != floori(float(_last[r])):
			loudest = maxf(loudest, float(_speed[r]))
		_last[r] = v
		_thump[r] = maxf(0.0, float(_thump[r]) - delta * 5.0)
	if loudest > 3.0 and _tick_t <= 0.0:
		_tick_t = 0.07
		Sfx.play("tick", clampf(0.7 + loudest * 0.02, 0.7, 1.5))
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if spinning:
		return
	if not ((e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed)):
		return
	var p: Vector2 = e.position
	for r in 3:
		# 재배치: the peeking cell above comes down (+1), the one below goes up (-1)
		for off in [-1, 1]:
			if _can_pull(r, off) and peek_rect(r, off).grow_individual(6, 0, 6, 0).has_point(p):
				reel_tapped.emit(r, -off)
				accept_event()
				return


## True when the cell [param off] (-1 above / +1 below) of reel r can be pulled in now.
func _can_pull(r: int, off: int) -> bool:
	return nudge_ready and not spinning and slot != null and slot.cell(r) == "" and slot.peek(r, off) != ""


func _draw() -> void:
	if art:
		_draw_art()
		return
	Px.draw_skin(self, "panel_slot", Rect2(Vector2.ZERO, size))
	# recessed reel window: ink rim + light lip so every cell sits fully inside
	draw_rect(WINDOW.grow(6), Px.INK)
	draw_rect(Rect2(WINDOW.position.x - 3, WINDOW.end.y, WINDOW.size.x + 6, 3), Color("#b98250"))
	draw_rect(WINDOW, Color("#1a110a"))
	if slot == null:
		return
	for r in 3:
		_draw_reel(r)
	# the rows above and below the result row are dimmed, except a cell that can be pulled in
	for r in 3:
		for off in [-1, 1]:
			var pr := peek_rect(r, off)
			if _can_pull(r, off):
				var pulse := 0.55 + 0.45 * sin(_t * 6.0)
				draw_rect(pr.grow(-2), Color(Px.GOLD, 0.5 + 0.4 * pulse), false, 6.0)
				_arrow(Vector2(pr.get_center().x, pr.end.y - 26 if off < 0 else pr.position.y + 26), -off, pulse)
			else:
				draw_rect(Rect2(pr.position.x - 4, pr.position.y, pr.size.x + 8, pr.size.y), Color(0, 0, 0, 0.55))
	# glass shading top/bottom
	for i in 6:
		draw_rect(Rect2(WINDOW.position.x, WINDOW.position.y + i * 4, WINDOW.size.x, 4), Color(0, 0, 0, 0.3 - i * 0.05))
		draw_rect(Rect2(WINDOW.position.x, WINDOW.end.y - (i + 1) * 4, WINDOW.size.x, 4), Color(0, 0, 0, 0.3 - i * 0.05))
	# result row: a faint band + markers on both edges
	var my := ROW_Y + CELL.y * 0.5
	draw_rect(Rect2(WINDOW.position.x, ROW_Y - 5, WINDOW.size.x, 3), Color(Px.GOLD, 0.35))
	draw_rect(Rect2(WINDOW.position.x, ROW_Y + CELL.y + 2, WINDOW.size.x, 3), Color(Px.GOLD, 0.35))
	for x: float in [WINDOW.position.x - 2, WINDOW.end.x + 2]:
		var d := 1.0 if x < size.x * 0.5 else -1.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, my - 14), Vector2(x + 16 * d, my), Vector2(x, my + 14)]), Px.GOLD)
	if not spinning:
		_draw_wins()
	if not spinning and wins.is_empty() and _miss_t >= 0.0 and _miss_t < 0.9:
		var a := 1.0 - _miss_t / 0.9
		Px.text(self, DB.t("slot.miss"), Rect2(0, 180, size.x, 100), 64, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 10)


## 그림 슬롯: 판 → 릴 그림 → 칸 속의 얼굴 · 아이콘 → 화살표 → 당첨 표시.
func _draw_art() -> void:
	Px.rec(self, "image", Rect2(Vector2.ZERO, size), "battle_panel_slot")
	if Px.has_nine("battle_panel_slot"):
		Px.nine(self, "battle_panel_slot", Rect2(Vector2.ZERO, size))
	else:
		draw_texture_rect(Px.tex("battle_panel_slot"), Rect2(Vector2.ZERO, size), false)
	for r in 3:
		var rr: Rect2 = _reel_at[r]
		if slot != null:
			_draw_reel_art(r)
		else:
			draw_texture_rect(Px.tex("battle_reel_%d" % (r + 1)), rr, false)
		for off: int in [-1, 1]:
			var hole := _hole(r, off)
			var ar: Rect2 = _arrow_up[r] if off < 0 else _arrow_down[r]
			var at := Px.tex(("battle_arrow_up_%d" if off < 0 else "battle_arrow_down_%d") % (r + 1))
			if slot != null and _can_pull(r, off):
				# 끌어올 수 있는 칸: 금테가 깜빡이고 화살표가 밝아진다
				var pulse := 0.55 + 0.45 * sin(_t * 6.0)
				draw_rect(hole.grow(2), Color(Px.GOLD, 0.5 + 0.4 * pulse), false, 5.0)
				draw_texture_rect(at, ar.grow(4.0 * pulse), false)
			else:
				draw_rect(hole, Color(0, 0, 0, 0.45))
				draw_texture_rect(at, ar, false, Color(1, 1, 1, 0.4))
	if slot == null:
		return
	if not spinning:
		_draw_wins()
	if not spinning and wins.is_empty() and _miss_t >= 0.0 and _miss_t < 0.9:
		var a := 1.0 - _miss_t / 0.9
		var c: Rect2 = cell_rect(1)
		Px.text(self, DB.t("slot.miss"), Rect2(0, c.position.y, size.x, c.size.y), 64, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 10)


## 릴 r의 칸: off -1 위의 잘린 칸 · 0 가운데 칸 · +1 아래의 잘린 칸 (이 노드 안의 px).
func _hole(r: int, off: int) -> Rect2:
	var h: Rect2 = HOLE_TOP if off < 0 else (HOLE_BOT if off > 0 else HOLE)
	return Rect2((_reel_at[r] as Rect2).position + h.position, h.size)


func _draw_reel_art(r: int) -> void:
	var strip: Array = slot.strips[r]
	var n := strip.size()
	var v: float = view[r]
	var base := floori(v)
	var frac := v - base
	var blur := spinning and float(_speed[r]) > 2.5
	var dip := roundf(sin(float(_thump[r]) * PI) * 6.0)
	var outer: Rect2 = _reel_at[r]
	# 띠가 구르는 곳: 릴 틀 안쪽 (틀 그림이 있으면 틀은 가만히 있고 위에 덮는다)
	var framed := REEL_INNER.size != Vector2.ZERO and Px.has_art("battle_reel_frame")
	var rr: Rect2 = Rect2(outer.position + REEL_INNER.position, REEL_INNER.size) if framed else outer
	var mid := _hole(r, 0)
	var tile := Px.tex("battle_reel_tile")
	var gap := ART_STEP - HOLE.size.y   # 칸 위의 크림색 띠
	# 릴 뒤는 어두운 홈 (띠가 지나가며 덮는다)
	draw_rect(rr, Color("#1c1310"))
	for j in range(-3, 4):
		var y := (j - frac) * ART_STEP + dip
		# 띠 한 마디: 크림색 띠 + 칸
		var tr := Rect2(rr.position.x, mid.position.y - gap + y, rr.size.x, ART_STEP)
		if tile != null:
			_tex_clipped(tile, tr, Rect2(Vector2.ZERO, tile.get_size()), rr, Color.WHITE)
		# 칸 속의 얼굴 · 아이콘 (띠와 함께 움직인다)
		var rect := Rect2(mid.position + Vector2(0, y), mid.size)
		var clip := rect.intersection(rr)
		if clip.size.x > 0.0 and clip.size.y > 0.0:
			_draw_cell_art(String(strip[posmod(base + j, n)]), rect, clip, blur)
	if blur:
		# 빠르게 돌 때: 밝은 세로 줄이 릴을 타고 흐른다
		var k := clampf(float(_speed[r]) / 40.0, 0.0, 1.0)
		draw_rect(rr, Color(1, 1, 1, 0.04 + 0.06 * k))
		for i in 4:
			var sy := fposmod(-v * ART_STEP * 0.5 + i * 97.0, rr.size.y + 140.0) - 140.0
			var seg := Rect2(rr.position.x + 18.0 + i * 34.0, rr.position.y + sy, 4, 60.0 + 100.0 * k).intersection(rr)
			if seg.size.y > 0.0:
				draw_rect(seg, Color(1, 1, 1, 0.12 + 0.2 * k))
	# 릴의 위아래 끝: 둥근 통처럼 어두워진다 + 홈의 테두리
	for i in 5:
		var a := 0.42 - i * 0.08
		draw_rect(Rect2(rr.position.x, rr.position.y + i * 7, rr.size.x, 7), Color(0, 0, 0, a))
		draw_rect(Rect2(rr.position.x, rr.end.y - (i + 1) * 7, rr.size.x, 7), Color(0, 0, 0, a))
	if framed:
		draw_texture_rect(Px.tex("battle_reel_frame"), outer, false)
	else:
		draw_rect(rr, Color("#0e0a08"), false, 3.0)


## 칸 하나의 내용 (clip = 보이는 부분). 장수 = 세력색 바탕 + 초상, 병사 = 무기 아이콘, 꽝 = 빈 칸.
func _draw_cell_art(id: String, rect: Rect2, clip: Rect2, blur: bool) -> void:
	var whole := clip.size.y >= rect.size.y - 1.0
	if id == "":
		if whole and not blur:
			Px.text(self, DB.t("slot.miss"), rect, 34, Color(1, 1, 1, 0.25), HORIZONTAL_ALIGNMENT_CENTER, 0)
		return
	var hero := DB.is_hero(id)
	var mod := Color(1, 1, 1, 0.7) if blur else Color.WHITE
	if hero:
		_rect_clipped(rect, clip, DB.fac_color(DB.fac_of(id)).darkened(0.45))
	var inner := rect.grow(-4)
	var icon: Texture2D = null if hero else weapon_tex(id)
	if icon != null:
		var isz := icon.get_size()
		var ik := minf(inner.size.x / isz.x, inner.size.y / isz.y)
		_tex_clipped(icon, Rect2(inner.get_center() - isz * ik * 0.5, isz * ik), Rect2(Vector2.ZERO, isz), clip, mod)
	else:
		var a := Art.of_unit(id)
		var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
		if t != null:
			var ts := t.get_size()
			var k := maxf(inner.size.x / ts.x, inner.size.y / ts.y)
			var src_sz := inner.size / k
			_tex_clipped(t, inner, Rect2(Vector2((ts.x - src_sz.x) * 0.5, (ts.y - src_sz.y) * 0.15), src_sz), clip, mod)
	if hero:
		# 등급 색 테두리 (칸 안쪽 3px)
		var rc := DB.rarity_color(DB.rarity_of(id))
		for e: Rect2 in [Rect2(rect.position, Vector2(rect.size.x, 3)), Rect2(rect.position + Vector2(0, rect.size.y - 3), Vector2(rect.size.x, 3)),
				Rect2(rect.position, Vector2(3, rect.size.y)), Rect2(rect.position + Vector2(rect.size.x - 3, 0), Vector2(3, rect.size.y))]:
			_rect_clipped(e, clip, rc)
	# 이름 띠 (가운데 칸에 온전히 들어왔을 때만)
	if whole and not blur:
		var strip := Rect2(rect.position.x + 3, rect.end.y - 25, rect.size.x - 6, 22)
		draw_rect(strip, Color(0.05, 0.07, 0.1, 0.8))
		Px.text(self, DB.unit_name(id), strip, 18, Px.GOLD if hero else Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 3)


func _draw_reel(r: int) -> void:
	var strip: Array = slot.strips[r]
	var n := strip.size()
	var v: float = view[r]
	var base := floori(v)
	var frac := v - base
	var x: float = COL_X[r]
	var sp := float(_speed[r])
	var blur := spinning and sp > 2.5
	# the thump after a stop: the reel dips a few px and comes back
	var dip := roundf(sin(float(_thump[r]) * PI) * 7.0)
	for j in range(-2, 3):
		var y := ROW_Y + (j - frac) * STEP_Y + dip
		var id := String(strip[posmod(base + j, n)])
		var rect := Rect2(x, y, CELL.x, CELL.y)
		var clip := rect.intersection(WINDOW)
		if clip.size.y <= 0.0:
			continue
		_draw_cell(id, rect, clip, blur)
	if blur:
		# speed streaks: light vertical lines that run with the reel
		var col := Rect2(x, WINDOW.position.y, CELL.x, WINDOW.size.y)
		var k := clampf(sp / 40.0, 0.0, 1.0)
		draw_rect(col, Color(1, 1, 1, 0.05 + 0.07 * k))
		for i in 5:
			var sx := x + 14.0 + i * 29.0
			var sy := fposmod(-v * STEP_Y * 0.5 + i * 97.0, col.size.y + 160.0) - 160.0
			var seg := Rect2(sx, col.position.y + sy, 4, 60.0 + 120.0 * k).intersection(col)
			if seg.size.y > 0.0:
				draw_rect(seg, Color(1, 1, 1, 0.10 + 0.18 * k))


func _draw_cell(id: String, rect: Rect2, clip: Rect2, blur: bool) -> void:
	_rect_clipped(rect, clip, Px.INK)
	if id == "":
		# 꽝: an empty recessed tile
		_rect_clipped(rect.grow(-4), clip, Color("#3a2c20"))
		_rect_clipped(rect.grow(-8), clip, Color("#20160e"))
		if clip.size.y >= rect.size.y - 1.0 and not blur:
			Px.text(self, DB.t("slot.miss"), rect, 40, Color(1, 1, 1, 0.22), HORIZONTAL_ALIGNMENT_CENTER, 0)
		return
	var hero := DB.is_hero(id)
	var bgc := DB.fac_color(DB.fac_of(id)) if hero else Color("#6b5a48")
	_rect_clipped(rect.grow(-4), clip, DB.rarity_color(DB.rarity_of(id)) if hero else Color("#b49c7c"))
	_rect_clipped(rect.grow(-8), clip, bgc.darkened(0.35))
	_rect_clipped(Rect2(rect.position + Vector2(8, 8), Vector2(rect.size.x - 16, rect.size.y * 0.42)), clip, bgc.darkened(0.15))
	var inner := rect.grow(-10)
	inner.size.y -= 30
	var mod := Color(1, 1, 1, 0.7) if blur else Color.WHITE
	# 병사 = 무기 아이콘, 장수 = 초상화 (§9.7). 아이콘이 아직 없으면 초상화로 그린다.
	var icon: Texture2D = null if hero else weapon_tex(id)
	if icon != null:
		var isz := icon.get_size()
		var ik := minf(inner.size.x / isz.x, inner.size.y / isz.y)
		var dst := Rect2(inner.get_center() - isz * ik * 0.5, isz * ik)
		_tex_clipped(icon, dst, Rect2(Vector2.ZERO, isz), clip, mod)
	else:
		var a := Art.of_unit(id)
		var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
		if t != null:
			var ts := t.get_size()
			var k := maxf(inner.size.x / ts.x, inner.size.y / ts.y)
			var src_sz := inner.size / k
			_tex_clipped(t, inner, Rect2(Vector2((ts.x - src_sz.x) * 0.5, (ts.y - src_sz.y) * 0.15), src_sz), clip, mod)
	# name strip (장수는 이름, 병사는 병종 이름)
	var strip := Rect2(rect.position.x + 8, rect.end.y - 38, rect.size.x - 16, 30)
	var sv := strip.intersection(clip)
	if sv.size.y > 0.0:
		draw_rect(sv, Color(0.05, 0.07, 0.1, 0.85))
		if sv.size.y >= 28.0 and not blur:
			Px.text(self, DB.unit_name(id), strip, 22, Px.GOLD if hero else Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
	if blur:
		_rect_clipped(rect, clip, Color(0.6, 0.75, 1.0, 0.12))


func _rect_clipped(r: Rect2, clip: Rect2, c: Color) -> void:
	var i := r.intersection(clip)
	if i.size.x > 0.0 and i.size.y > 0.0:
		draw_rect(i, c)


## Draws [param src] of [param t] into [param dst], cut to [param clip].
func _tex_clipped(t: Texture2D, dst: Rect2, src: Rect2, clip: Rect2, mod: Color) -> void:
	var vis := dst.intersection(clip)
	if vis.size.x <= 0.0 or vis.size.y <= 0.0:
		return
	var k := dst.size / src.size
	var s2 := Rect2(src.position + (vis.position - dst.position) / k, vis.size / k)
	Px.rec(self, "image", vis, "reel_cell")
	draw_texture_rect_region(t, vis, s2, mod)


## The result cell box of one reel (local px), exactly as drawn.
func cell_rect(reel: int, _row: int = 0) -> Rect2:
	if art:
		return _hole(reel, 0)
	return Rect2(float(COL_X[reel]), ROW_Y, CELL.x, CELL.y)


## The visible part of the cell above (off -1) or below (off +1) the result cell:
## what is tapped to pull that cell into the row.
func peek_rect(reel: int, off: int) -> Rect2:
	if art:
		# 잘린 칸 + 그 바깥의 화살표까지 누를 수 있다
		return _hole(reel, off).merge(_arrow_up[reel] if off < 0 else _arrow_down[reel])
	var x := float(COL_X[reel])
	if off < 0:
		return Rect2(x, WINDOW.position.y, CELL.x, ROW_Y - 8 - WINDOW.position.y)
	return Rect2(x, ROW_Y + CELL.y + 8, CELL.x, WINDOW.end.y - (ROW_Y + CELL.y + 8))


## Gold frames on the winning cells; all three = 잭팟 (brighter, blinking longer).
func _draw_wins() -> void:
	if wins.is_empty():
		return
	var jackpot := wins.size() >= 3
	var blink := _line_t < (2.0 if jackpot else 1.2) and int(_line_t * 6.0) % 2 == 0
	for r: int in wins:
		var rect := cell_rect(r)
		draw_rect(rect.grow(-2), Color(Px.GOLD, 0.95 if blink else 0.7), false, 8.0)
		if blink:
			draw_rect(rect.grow(-8), Color(1, 1, 1, 0.2 if jackpot else 0.14))


## A small arrow: dir +1 points down, -1 points up.
func _arrow(c: Vector2, dir: int, a: float) -> void:
	var s := 18.0
	var pts := PackedVector2Array([c + Vector2(0, s * dir), c + Vector2(-s, -s * 0.5 * dir), c + Vector2(s, -s * 0.5 * dir)])
	var outer := PackedVector2Array([c + Vector2(0, (s + 7) * dir), c + Vector2(-s - 8, -(s * 0.5 + 5) * dir), c + Vector2(s + 8, -(s * 0.5 + 5) * dir)])
	draw_colored_polygon(outer, Color(Px.INK, a))
	draw_colored_polygon(pts, Color(Px.GOLD, a))
