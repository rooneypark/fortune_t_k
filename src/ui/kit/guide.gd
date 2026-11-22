class_name Guide
extends Control
## Tutorial guide (콘텐츠 §12): darkens the screen except a highlighted hole,
## bounces a pointing hand at it and shows 제갈량's speech bubble. Input inside
## the hole passes through; [signal advanced] fires when the hole (or anywhere,
## when [member tap_anywhere]) is tapped.

signal advanced

var hole := Rect2()
var text := ""
var tap_anywhere := false
var bubble_top := true
var _t := 0.0
var _face: ArtRect
var _dragging := false


static func show_at(parent: Control, r: Rect2, s: String, anywhere := false) -> Guide:
	var g := Guide.new()
	g.hole = r
	g.text = s
	g.tap_anywhere = anywhere
	g.bubble_top = r.get_center().y > 900
	parent.add_child(g)
	return g


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face = ArtRect.new()
	_face.texture = Art.portrait("zhugeliang")
	_face.size = Vector2(150, 150)
	add_child(_face)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _input(e: InputEvent) -> void:
	if not (e is InputEventMouseButton or e is InputEventScreenTouch):
		return
	var local_ev: InputEvent = make_input_local(e)
	var pos: Vector2 = local_ev.position if (local_ev is InputEventMouseButton or local_ev is InputEventScreenTouch) else e.position
	var inside := hole.has_point(pos)
	if not tap_anywhere:
		if e.is_pressed():
			if inside:
				_dragging = true
				return
		else:
			var was_dragging := _dragging
			_dragging = false
			if inside:
				advanced.emit()
				return
			if was_dragging:
				return  # allow drag release to reach underlying control so drags cleanly resolve/snap back
	get_viewport().set_input_as_handled()
	if tap_anywhere and not e.is_pressed():
		advanced.emit()


func _draw() -> void:
	var full := Rect2(Vector2.ZERO, size)
	var dim := Color(0.02, 0.04, 0.08, 0.62)
	if hole.size == Vector2.ZERO:
		draw_rect(full, dim)
	else:
		draw_rect(Rect2(0, 0, size.x, hole.position.y), dim)
		draw_rect(Rect2(0, hole.end.y, size.x, size.y - hole.end.y), dim)
		draw_rect(Rect2(0, hole.position.y, hole.position.x, hole.size.y), dim)
		draw_rect(Rect2(hole.end.x, hole.position.y, size.x - hole.end.x, hole.size.y), dim)
		var a := 0.6 + 0.4 * sin(_t * 6.0)
		# 테두리는 구멍 경계 안쪽에 (구멍보다 커 보이지 않게)
		draw_rect(hole.grow(-2), Color(Px.GOLD, a), false, 4.0)
		_draw_hand(hole.get_center() + Vector2(hole.size.x * 0.25, hole.size.y * 0.3 + absf(sin(_t * 5.0)) * 22.0))
	var by := 140.0 if bubble_top else size.y - 420.0
	if hole.size == Vector2.ZERO:
		by = size.y * 0.5 - 140
	var br := Rect2(190, by, 790, 230)
	Px.draw_skin(self, "panel_slot", br)
	Px.paragraph(self, text, Rect2(br.position + Vector2(30, 30), br.size - Vector2(60, 50)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	if tap_anywhere:
		Px.text(self, "▼ " + DB.t("guide.tap"), Rect2(br.end.x - 260, br.end.y - 50, 240, 40), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	Px.draw_skin(self, "frame_portrait", Rect2(22, by + 22, 174, 174))
	_face.position = Vector2(34, by + 34)


func _draw_hand(p: Vector2) -> void:
	# chunky pixel pointing hand (finger up-left)
	var s := 6.0
	var rows := [
		"..XX......",
		".XWWX.....",
		".XWWX.....",
		".XWWXXXX..",
		".XWWWWWWXX",
		"XXWWWWWWWX",
		"XWWWWWWWWX",
		"XWWWWWWWWX",
		".XWWWWWWX.",
		"..XXXXXX..",
	]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			draw_rect(Rect2(p + Vector2(x * s - 12, y * s - 6), Vector2(s, s)), Px.INK if ch == "X" else Color.WHITE)
