class_name ArtRect
extends Control
## A picture drawn through the unit shader (hue shift for borrowed art, grey,
## silhouette). [member cover] crops to fill, [member focus_y] picks which part
## of a tall picture stays visible (0 = top, 0.5 = centre).

var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
var cover := true
var focus_y := 0.3
var zoom := 1.0
var flip := false
var _mat: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_mat = Px.unit_material()
	material = _mat


func set_look(hue: float, gray: float = 0.0, silhouette: float = 0.0) -> ArtRect:
	_mat.set_shader_parameter("hue", hue)
	_mat.set_shader_parameter("gray", gray)
	_mat.set_shader_parameter("silhouette", silhouette)
	return self


func _draw() -> void:
	if texture == null:
		return
	var ts := texture.get_size()
	var r := Rect2(Vector2.ZERO, size)
	if cover:
		var k := maxf(size.x / ts.x, size.y / ts.y) * zoom
		var src_size := size / k
		var sx := (ts.x - src_size.x) * 0.5
		var sy := clampf((ts.y - src_size.y) * focus_y, 0.0, maxf(0.0, ts.y - src_size.y))
		var src := Rect2(Vector2(sx, sy), src_size)
		Px.tex_rect(self, texture, r, Color.WHITE, flip, Vector2.ZERO, src)
	else:
		var k := minf(size.x / ts.x, size.y / ts.y) * zoom
		var sz := (ts * k).round()
		var dst := Rect2(((size - sz) * Vector2(0.5, 1.0)).round(), sz)
		Px.tex_rect(self, texture, dst, Color.WHITE, flip)
