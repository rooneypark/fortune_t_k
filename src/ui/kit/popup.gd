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
## 그림 창 (2026-11-24, 공용): 제미나이 그림에서 떼어 낸 부품으로 그리는 창. setup()에서 use_art("wave") 처럼 켠다.
## 부품 = assets/ui/<art>_frame.png · <art>_title.png, 자리 = assets/ui/<art>_layout.json (화면 px).
## 판(panel)은 화면 전체 크기라 부품을 화면 자리 그대로 _place() 한다. 닫기는 공용 흰 X (layout "close").
var art := ""
var _art := false
## 제목 글자 크기 · 제목 띠 안의 글자 자리 (띠 크기 → 글자 칸). 창마다 바꿀 수 있다.
var title_size := 46
var title_box := func(sz: Vector2) -> Rect2: return Rect2(28, 10, sz.x - 56, sz.y - 28)
## 제목 띠 그림의 색 (패배 창은 잿빛으로).
var title_tint := Color.WHITE
static var _layouts: Dictionary = {}
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


## 그림 창을 켠다: <prefix>_frame 그림과 자리가 있으면 true. 없으면 선 UI 그대로.
func use_art(prefix: String) -> bool:
	art = prefix
	_art = Px.has_art(prefix + "_frame") and _r(prefix + "_frame").size != Vector2.ZERO
	if not _art:
		art = ""
	return _art


## 그림 부품의 화면 자리 (px). 없으면 빈 Rect2.
func _r(name: String) -> Rect2:
	var key := art if art != "" else "_"
	if not _layouts.has(key):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/%s_layout.json" % art)) if art != "" else null
		_layouts[key] = parsed if parsed is Dictionary else {}
	var r: Array = (_layouts[key] as Dictionary).get(name, [])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])) if r.size() == 4 else Rect2()


## 화면 자리 그대로 놓는다 (그림 창). [param where] = Rect2 또는 자리 이름.
func _place(c: Control, where: Variant) -> Control:
	var r: Rect2 = _r(String(where)) if where is String else where
	panel.add_child(c)
	c.position = r.position
	c.size = r.size
	return c


## 그림 한 장을 그리는 층 (누름을 받지 않는다).
func _pic(tex_name: String) -> DrawLayer:
	var d := DrawLayer.make(func(ci: Control) -> void: ci.draw_texture_rect(Px.tex(tex_name), Rect2(Vector2.ZERO, ci.size), false))
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return d


func _build_frame() -> void:
	if _art:
		_build_art_frame()
		return
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


## 그림 창의 틀: 어두운 막 + 창 틀 그림 + 제목 띠(제목 글자) + 공용 닫기.
func _build_art_frame() -> void:
	var dimmer := DrawLayer.make(func(ci: Control) -> void: ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.03, 0.05, 0.09, 0.72)))
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	dimmer.gui_input.connect(func(e: InputEvent) -> void:
		if dim_closes and e is InputEventMouseButton and e.pressed:
			close())
	add_child(dimmer)
	panel = Control.new()
	var vp := get_viewport_rect().size
	panel.position = Vector2(maxf(0.0, (vp.x - Px.CANVAS.x) * 0.5), (vp.y - Px.CANVAS.y) * 0.5)
	panel.size = Px.CANVAS
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	var frame := _pic(art + "_frame")
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	Px.rec(frame, "image", Rect2(), art + "_frame")
	_place(frame, art + "_frame")
	if title != "" and Px.has_art(art + "_title"):
		var tex := art + "_title"
		var head := DrawLayer.make(func(ci: Control) -> void:
			ci.draw_texture_rect(Px.tex(tex), Rect2(Vector2.ZERO, ci.size), false, title_tint)
			Px.text(ci, title, title_box.call(ci.size), title_size, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 7))
		head.mouse_filter = Control.MOUSE_FILTER_STOP
		_place(head, tex)
	if show_close:
		# 닫기 자리: "close" (예전 난이도 창은 "<art>_btn_close")
		var cr := _r("close") if _r("close").size != Vector2.ZERO else _r(art + "_btn_close")
		if cr.size != Vector2.ZERO:
			_place(W.close_button(close), cr)


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
