class_name SlotView
extends Control
## 천명 슬롯 cabinet (panel_slot, 526 x 464): three clipped reels of faction-
## coloured portrait tiles that stop 0.35 s apart from the left, winning lines
## traced in gold, nudge / respin modes where tapping a reel acts on it.

signal reels_stopped
signal reel_tapped(reel: int, dir: int)

const CELL := Vector2(144, 126)
const COL_X := [38.0, 191.0, 344.0]
const ROW_Y := 38.0
const STEP_Y := 132.0
const WINDOW := Rect2(28, 32, 470, 400)

var slot: SlotMachine
## Float top index per reel (what is drawn).
var view: Array = [0.0, 0.0, 0.0]
var spinning := false
var mode := ""  # "", "nudge", "respin"
var lines: Array = []
var _line_t := 0.0
var _tweens: Array = []
var _t := 0.0
var _miss_t := 0.0
var _reel_win: Control


func _init() -> void:
	size = Vector2(526, 464)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _ready() -> void:
	set_process(true)


func bind(s: SlotMachine) -> void:
	slot = s
	for r in 3:
		view[r] = float(slot.stops[r])
	queue_redraw()


## Animates every reel to the slot's current stops. [param speed] 0 = instant.
func spin_to_result(res: Dictionary, speed: float) -> void:
	lines = res.get("lines", [])
	_line_t = 0.0
	mode = ""
	if speed <= 0.0:
		for r in 3:
			view[r] = float(slot.stops[r])
		_finish()
		return
	spinning = true
	Sfx.play("lever")
	var done := [0]
	for r in 3:
		var n := (slot.strips[r] as Array).size()
		var target := float(slot.stops[r])
		var start: float = view[r]
		# scroll downward: the index decreases; add full turns for the blur
		var turns := 2 + r
		var end := target - n * turns
		while end > start - n * 1.5:
			end -= n
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void:
			view[r] = v
			queue_redraw(), start, end, (0.75 + 0.35 * r) * speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			view[r] = target
			Sfx.play("tick", 0.9 + 0.1 * r)
			done[0] += 1
			if done[0] == 3:
				_finish())


## One reel slides by one tile (nudge / respin result).
func move_reel(r: int, res: Dictionary, speed: float, full_spin := false) -> void:
	lines = res.get("lines", [])
	_line_t = 0.0
	mode = ""
	var target := float(slot.stops[r])
	var start: float = view[r]
	var n := (slot.strips[r] as Array).size()
	var end := target
	if full_spin:
		end = target - n * 2
	else:
		# shortest way (nudge is one tile)
		var d := posmod(int(target) - int(roundf(start)), n)
		end = start + (d if d <= n / 2 else d - n)
	if speed <= 0.0:
		view[r] = target
		_finish()
		return
	spinning = true
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		view[r] = v
		queue_redraw(), start, end, (0.25 if not full_spin else 0.7) * speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		view[r] = target
		Sfx.play("tick")
		_finish())


func _finish() -> void:
	spinning = false
	_line_t = 0.0
	_miss_t = 0.0 if lines.is_empty() else -1.0
	queue_redraw()
	reels_stopped.emit()


func _process(delta: float) -> void:
	_t += delta
	_line_t += delta
	if _miss_t >= 0.0:
		_miss_t += delta
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if mode == "" or spinning:
		return
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed):
		var p: Vector2 = e.position
		for r in 3:
			var x: float = COL_X[r]
			if p.x >= x - 6 and p.x <= x + CELL.x + 6 and p.y >= WINDOW.position.y and p.y <= WINDOW.end.y:
				var dir := -1 if p.y < WINDOW.get_center().y else 1
				reel_tapped.emit(r, dir)
				accept_event()
				return


func _draw() -> void:
	Px.draw_skin(self, "panel_slot", Rect2(Vector2.ZERO, size))
	# recessed reel window: ink rim + light lip so every cell sits fully inside
	draw_rect(WINDOW.grow(6), Px.INK)
	draw_rect(Rect2(WINDOW.position.x - 3, WINDOW.end.y, WINDOW.size.x + 6, 3), Color("#b98250"))
	draw_rect(WINDOW, Color("#1a110a"))
	if slot == null:
		return
	for r in 3:
		_draw_reel(r)
	# glass shading top/bottom
	for i in 6:
		draw_rect(Rect2(WINDOW.position.x, WINDOW.position.y + i * 4, WINDOW.size.x, 4), Color(0, 0, 0, 0.32 - i * 0.05))
		draw_rect(Rect2(WINDOW.position.x, WINDOW.end.y - (i + 1) * 4, WINDOW.size.x, 4), Color(0, 0, 0, 0.32 - i * 0.05))
	# payline markers (5 lines) on the left edge
	if not spinning and not lines.is_empty():
		_draw_lines()
	if mode != "":
		_draw_mode()
	elif not spinning and lines.is_empty() and _miss_t >= 0.0 and _miss_t < 0.9 and slot.can_nudge:
		var a := 1.0 - _miss_t / 0.9
		Px.text(self, DB.t("slot.miss"), Rect2(0, 180, size.x, 100), 64, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 10)


func _draw_reel(r: int) -> void:
	var strip: Array = slot.strips[r]
	var n := strip.size()
	var v: float = view[r]
	var base := floori(v)
	var frac := v - base
	var x: float = COL_X[r]
	var blur := spinning and absf(v - float(slot.stops[r])) > 0.5
	# draw rows -1..3 clipped to the window
	for j in range(-1, 4):
		var y := ROW_Y + (j - frac) * STEP_Y
		var id := String(strip[posmod(base + j, n)])
		var rect := Rect2(x, y, CELL.x, CELL.y)
		var clip := rect.intersection(WINDOW)
		if clip.size.y <= 0.0:
			continue
		_draw_cell(id, rect, clip, blur, r, j)


func _draw_cell(id: String, rect: Rect2, clip: Rect2, blur: bool, reel: int, row: int) -> void:
	var fac := DB.fac_of(id)
	var hero := DB.is_hero(id)
	var bgc := DB.fac_color(fac) if hero else Color("#6b5a48")
	# frame + fill drawn only inside the clip
	_rect_clipped(rect, clip, Px.INK)
	_rect_clipped(rect.grow(-4), clip, DB.rarity_color(DB.rarity_of(id)) if hero else Color("#b49c7c"))
	_rect_clipped(rect.grow(-8), clip, bgc.darkened(0.35))
	_rect_clipped(Rect2(rect.position + Vector2(8, 8), Vector2(rect.size.x - 16, rect.size.y * 0.42)), clip, bgc.darkened(0.15))
	var a := Art.of_unit(id)
	var t := Art.hued_portrait(String(a["art"]), float(a["hue"]))
	if t != null:
		var inner := rect.grow(-10)
		inner.size.y -= 26
		var ts := t.get_size()
		var k := maxf(inner.size.x / ts.x, inner.size.y / ts.y)
		var src_sz := inner.size / k
		var src := Rect2(Vector2((ts.x - src_sz.x) * 0.5, (ts.y - src_sz.y) * 0.15), src_sz)
		var vis := inner.intersection(clip)
		if vis.size.y > 0.0 and vis.size.x > 0.0:
			var s2 := Rect2(src.position + (vis.position - inner.position) / k, vis.size / k)
			var mod := Color(1, 1, 1, 0.75) if blur else Color.WHITE
			Px.rec(self, "image", vis, "reel_cell")
			draw_texture_rect_region(t, vis, s2, mod)
	# class strip
	var strip := Rect2(rect.position.x + 8, rect.end.y - 34, rect.size.x - 16, 26)
	var sv := strip.intersection(clip)
	if sv.size.y > 0.0:
		draw_rect(sv, Color(0.05, 0.07, 0.1, 0.85))
		if sv.size.y >= 24.0:
			Px.fit(self, Px.tex(String(DB.units["classes"].get(DB.cls_of(id), {}).get("icon", "class_inf"))), Rect2(strip.position + Vector2((strip.size.x - 24) * 0.5, 1), Vector2(24, 24)))
	if blur:
		_rect_clipped(rect, clip, Color(0.6, 0.75, 1.0, 0.12))
	# winning cell flash
	if not spinning and not lines.is_empty() and row >= 0 and row <= 2:
		for l: Dictionary in lines:
			for c: Array in l["cells"]:
				if int(c[0]) == reel and int(c[1]) == row:
					var blink := _line_t < 1.2 and int(_line_t * 6.0) % 2 == 0
					var col := _kind_color(l)
					draw_rect(rect.grow(-2), Color(col, 0.9 if blink else 0.65), false, 8.0)
					if blink:
						draw_rect(rect.grow(-8), Color(1, 1, 1, 0.18))


func _rect_clipped(r: Rect2, clip: Rect2, c: Color) -> void:
	var i := r.intersection(clip)
	if i.size.x > 0.0 and i.size.y > 0.0:
		draw_rect(i, c)


func _kind_color(l: Dictionary) -> Color:
	match String(l["kind"]):
		"unit":
			return Px.GOLD
	if not (l.get("heroes", []) as Array).is_empty():
		return Px.GOLD
	return Color("#7fe0ff")


## Tap area of one reel half (local px): dir -1 = upper half, +1 = lower half.
## Same box _gui_input uses, so tutorial highlights match the real touch area.
func tap_rect(reel: int, dir: int) -> Rect2:
	var x: float = COL_X[reel]
	var mid := WINDOW.get_center().y
	if dir < 0:
		return Rect2(x, WINDOW.position.y, CELL.x, mid - WINDOW.position.y)
	return Rect2(x, mid, CELL.x, WINDOW.end.y - mid)


## One visible cell box (local px), exactly as drawn.
func cell_rect(reel: int, row: int) -> Rect2:
	return Rect2(float(COL_X[reel]), ROW_Y + row * STEP_Y, CELL.x, CELL.y)


func cell_center(reel: int, row: int) -> Vector2:
	return Vector2(float(COL_X[reel]) + CELL.x * 0.5, ROW_Y + row * STEP_Y + CELL.y * 0.5)


func _draw_lines() -> void:
	var k := minf(1.0, _line_t / 0.35)
	for l: Dictionary in lines:
		var cells: Array = l["cells"]
		var a := cell_center(int(cells[0][0]), int(cells[0][1]))
		var b := cell_center(int(cells[2][0]), int(cells[2][1]))
		var e := a.lerp(b, k)
		var c := _kind_color(l)
		draw_line(a, e, Px.INK, 16.0)
		draw_line(a, e, c, 9.0)
		draw_line(a, e, Color(1, 1, 1, 0.7), 3.0)


func _draw_mode() -> void:
	var pulse := 0.55 + 0.45 * sin(_t * 6.0)
	draw_rect(WINDOW, Color(0, 0, 0, 0.25))
	for r in 3:
		var x: float = COL_X[r] + CELL.x * 0.5
		if mode == "nudge":
			_arrow(Vector2(x, WINDOW.position.y + 60), -1, pulse)
			_arrow(Vector2(x, WINDOW.end.y - 60), 1, pulse)
		else:
			draw_rect(Rect2(COL_X[r], WINDOW.position.y + 4, CELL.x, WINDOW.size.y - 8), Color(Px.GOLD, 0.25 * pulse), false, 6.0)
			Px.text(self, "↻", Rect2(COL_X[r], WINDOW.get_center().y - 50, CELL.x, 100), 80, Color(Px.GOLD, pulse), HORIZONTAL_ALIGNMENT_CENTER, 8)


func _arrow(c: Vector2, dir: int, a: float) -> void:
	var s := 34.0
	var pts := PackedVector2Array([c + Vector2(0, s * dir), c + Vector2(-s, -s * 0.2 * dir), c + Vector2(s, -s * 0.2 * dir)])
	var outer := PackedVector2Array([c + Vector2(0, (s + 8) * dir), c + Vector2(-s - 10, -(s * 0.2 + 6) * dir), c + Vector2(s + 10, -(s * 0.2 + 6) * dir)])
	draw_colored_polygon(outer, Color(Px.INK, a))
	draw_colored_polygon(pts, Color(Px.GOLD, a))
