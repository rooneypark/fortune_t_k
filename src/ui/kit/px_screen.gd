class_name PxScreen
extends Control
## Base for every screen. Children are placed in logical px (1024 x 1792).
## On taller phones the extra height is split: TOP stays at the top edge,
## BOTTOM at the bottom edge, MID keeps the centre (화면 설계서 §1).

enum Pin { TOP, MID, BOTTOM }

## Background texture drawn full screen (cover).
var bg: Texture2D
var bg_dim := 0.0
var params: Dictionary = {}
## True when shown as a dialog over the lobby (App.DIALOG_ROUTES): no own
## background, no pin offsets, no top bar / tab bar (the lobby keeps those).
var dialog := false
var _placed: Array = []


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Called by the app after the screen enters the tree.
func enter(p: Dictionary) -> void:
	params = p
	build()


## Override: create the children.
func build() -> void:
	pass


## Override: back button / device back. Return true when handled.
func back() -> bool:
	if dialog:
		Game.app.close_dialog()
	else:
		Game.app.goto("lobby")
	return true


func put(c: Control, r: Rect2, pin: Pin = Pin.TOP) -> Control:
	if dialog and c.has_meta("tab_bar"):
		c.queue_free()
		return c
	if c.get_parent() == null:
		add_child(c)
	_placed.append([c, r, pin])
	_place(c, r, pin)
	return c


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		for p: Array in _placed:
			if is_instance_valid(p[0]):
				_place(p[0], p[1], p[2])
		queue_redraw()


func dy(pin: Pin) -> float:
	if dialog:
		return 0.0
	var extra := size.y - Px.CANVAS.y
	match pin:
		Pin.BOTTOM:
			return extra
		Pin.MID:
			return extra * 0.5
	return 0.0


## PC 창처럼 가로가 1024보다 넓으면 1024 배치를 가운데로 (오른쪽 가방 · 모집이 왼쪽 열과 대칭 유지).
func dx() -> float:
	if dialog:
		return 0.0
	return maxf(0.0, (size.x - Px.CANVAS.x) * 0.5)


func _place(c: Control, r: Rect2, pin: Pin) -> void:
	c.position = r.position + Vector2(dx(), dy(pin))
	if r.size != Vector2.ZERO:
		c.size = r.size


func _draw() -> void:
	if bg != null and not dialog:
		Px.cover(self, bg, Rect2(Vector2.ZERO, size))
		if bg_dim > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.13, bg_dim))


func clear_children() -> void:
	for c in get_children():
		c.queue_free()
	_placed.clear()


func toast(s: String) -> void:
	Game.app.toast(s)
