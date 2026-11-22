class_name PxControls
extends RefCounted
## Pixel slider, toggle and segmented choice for the settings pop-ups.


class Slide extends Control:
	signal changed(v: float)
	var value := 0.5
	var _drag := false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			_drag = e.pressed
			if e.pressed:
				_set_from(e.position.x)
		elif e is InputEventMouseMotion and _drag:
			_set_from(e.position.x)

	func _set_from(x: float) -> void:
		value = clampf((x - 20) / (size.x - 40), 0.0, 1.0)
		changed.emit(value)
		queue_redraw()

	func _draw() -> void:
		var y := size.y * 0.5
		var r := Rect2(20, y - 12, size.x - 40, 24)
		Px.bar(self, r, value, Px.GOLD)
		var kx := 20 + (size.x - 40) * value
		var k := Rect2(kx - 22, y - 26, 44, 52)
		Px.draw_skin(self, "btn_small", k)


class Toggle extends Control:
	signal changed(v: bool)
	var on := true

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			on = not on
			Sfx.play("click")
			changed.emit(on)
			queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Px.INK)
		draw_rect(r.grow(-4), Px.GREEN if on else Color("#3a4656"))
		var kw := size.y - 8
		var kx := size.x - kw - 4 if on else 4.0
		Px.draw_skin(self, "btn_small", Rect2(kx, 4, kw, kw))
		Px.text(self, "ON" if on else "OFF", Rect2(8 if on else size.x * 0.45, 0, size.x * 0.5, size.y), 24)


class Seg extends Control:
	signal changed(i: int)
	var items: Array = []
	var index := 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and not items.is_empty():
			index = clampi(int(e.position.x / (size.x / items.size())), 0, items.size() - 1)
			Sfx.play("click")
			changed.emit(index)
			queue_redraw()

	func _draw() -> void:
		var n := items.size()
		if n == 0:
			return
		var w := size.x / n
		for i in n:
			var r := Rect2(i * w + 2, 0, w - 4, size.y)
			Px.draw_skin(self, "tab_yellow" if i == index else "btn_small", r)
			Px.text(self, String(items[i]), r.grow(-6), 26, Px.WHITE)
