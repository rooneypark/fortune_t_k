class_name PxPopup
extends Control
## Modal pop-up: dim + framed panel + ribbon title + close button. Content is
## placed in panel-local px with [method put]. Tapping the dim closes it when
## [member dim_closes] is set.

signal closed

var title := ""
var panel_rect := Rect2(60, 300, 904, 1100)
var dim_closes := true
var show_close := true
var ribbon_color := Color("#c8352e")
var panel: Control
var _built := false
## Header band above the frame (ribbon + close X) — inside the panel container.
const HEAD := 64.0


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func open(p: Dictionary = {}) -> void:
	setup(p)
	_build_frame()
	build()
	_built = true
	panel.pivot_offset = panel.size * 0.5
	panel.scale = Vector2(0.85, 0.85)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("whoosh")


## Override: read params before the frame is built (title, panel_rect).
func setup(_p: Dictionary) -> void:
	pass


## Override: add content with put().
func build() -> void:
	pass


func _build_frame() -> void:
	var dimmer := DrawLayer.make(func(ci: Control) -> void: ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.03, 0.05, 0.09, 0.72)))
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if dim_closes and e is InputEventMouseButton and e.pressed:
			close())
	add_child(dimmer)
	panel = Control.new()
	var vp := get_viewport_rect().size
	panel.position = panel_rect.position + Vector2(maxf(0.0, (vp.x - Px.CANVAS.x) * 0.5), (vp.y - Px.CANVAS.y) * 0.5 - HEAD)
	panel.size = panel_rect.size + Vector2(0, HEAD)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var frame := DrawLayer.make(_draw_frame, panel_rect.size)
	frame.position = Vector2(0, HEAD)
	panel.add_child(frame)
	if title != "":
		var rib := DrawLayer.make(func(ci: Control) -> void: Px.ribbon(ci, Rect2(Vector2.ZERO, ci.size), title, 52, ribbon_color), Vector2(minf(560, panel.size.x - 40), 124))
		rib.position = Vector2((panel.size.x - rib.size.x) * 0.5, HEAD - 58)
		panel.add_child(rib)
	if show_close:
		var x := W.close_button(close)
		x.position = Vector2(panel.size.x - W.CLOSE.x - 4, HEAD - 30)
		panel.add_child(x)


func _draw_frame(ci: Control) -> void:
	var r := Rect2(Vector2.ZERO, ci.size)
	Px.draw_skin(ci, "panel_ctrl", r)


## Places [param c] at panel-local rect [param r].
func put(c: Control, r: Rect2) -> Control:
	panel.add_child(c)
	c.position = r.position + Vector2(0, HEAD)
	if r.size != Vector2.ZERO:
		c.size = r.size
	return c


func close() -> void:
	if is_queued_for_deletion():
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(func() -> void:
		closed.emit()
		queue_free())
