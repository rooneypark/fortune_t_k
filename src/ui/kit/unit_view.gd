class_name UnitView
extends Control
## An animated unit standing on its feet (bottom centre of the control):
## lobby heroes, recruit cards, battle-clear MVP. Idle loop + gentle breathing.

var unit_id := ""
var art := ""
var height := 150.0
var action := "idle":
	set(v):
		action = v
		_t = 0.0
var flip := false
var breathe := true
var _t := 0.0
var _mat: ShaderMaterial


static func make(id: String, h: float) -> UnitView:
	var v := UnitView.new()
	v.set_unit(id)
	v.height = h
	return v


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = Px.unit_material()
	material = _mat


func set_unit(id: String) -> void:
	unit_id = id
	var a := Art.of_unit(id)
	art = String(a["art"])
	_mat.set_shader_parameter("hue", float(a["hue"]))
	_t = randf() * 3.0
	queue_redraw()


func set_gray(g: float) -> void:
	_mat.set_shader_parameter("gray", g)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ready() -> void:
	set_process(true)


func _draw() -> void:
	var fr := Art.frames(art, action)
	if fr.is_empty():
		return
	var t: Texture2D = fr[int(_t * Art.fps(art, action)) % fr.size()]
	var idle_h := Art.frame_h(art)
	var k := height / maxf(1.0, idle_h)
	var sy := 1.0 + (sin(_t * 3.2) * 0.025 if breathe else 0.0)
	var sz := t.get_size() * k
	sz.y *= sy
	var pos := Vector2(size.x * 0.5 - sz.x * 0.5, size.y - sz.y)
	# shadow
	draw_rect(Rect2(size.x * 0.5 - height * 0.22, size.y - 6, height * 0.44, 8), Color(0, 0, 0, 0.22))
	Px.tex_rect(self, t, Rect2(pos.round(), sz.round()), Color.WHITE, flip)
