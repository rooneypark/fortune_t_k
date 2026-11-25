class_name PxControls
extends RefCounted
## Pixel slider, toggle and segmented choice for the settings pop-ups.


class Slide extends Control:
	signal changed(v: float)
	var value := 0.5
	var _drag := false
	## 그림 막대 (공용, tools/import_kit8_ui.py → ctl_track · ctl_track_fill · ctl_knob): 그림이 있으면 저절로 쓴다.
	## 없으면 선 UI로 그린다.
	var track_tex: Texture2D
	var fill_tex: Texture2D
	var knob_tex: Texture2D
	## 홈 자리 (이 컨트롤 안, px)와 양끝 테두리 폭. 비어 있으면 컨트롤 가운데에 그림 높이로.
	var track_rect := Rect2()
	var cap := 16.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_READY and track_tex == null and Px.has_art("ctl_track"):
			track_tex = Px.tex("ctl_track")
			fill_tex = Px.tex("ctl_track_fill")
			knob_tex = Px.tex("ctl_knob")

	func _span() -> Vector2:
		if track_tex != null and track_rect.size == Vector2.ZERO:
			var th := minf(track_tex.get_size().y, size.y)
			track_rect = Rect2(0, (size.y - th) * 0.5, size.x, th)
		if track_tex != null:
			return Vector2(track_rect.position.x + cap, track_rect.size.x - cap * 2.0)
		return Vector2(20, size.x - 40)

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
		var sp := _span()
		value = clampf((x - sp.x) / sp.y, 0.0, 1.0)
		changed.emit(value)
		queue_redraw()

	func _draw() -> void:
		if track_tex != null:
			var sp := _span()
			var t := track_rect
			draw_texture_rect(track_tex, t, false)
			var fw := sp.x - t.position.x + sp.y * value
			var tw := fill_tex.get_size()
			draw_texture_rect_region(fill_tex, Rect2(t.position, Vector2(fw, t.size.y)), Rect2(0, 0, tw.x * fw / t.size.x, tw.y))
			var ks := knob_tex.get_size()
			draw_texture_rect(knob_tex, Rect2(Vector2(sp.x + sp.y * value - ks.x * 0.5, (size.y - ks.y) * 0.5), ks), false)
			return
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
		# 8차 시안: 띠(켜짐 초록 · 꺼짐 어두운 갈색) + 노란 네모 손잡이. 글자는 쓰지 않는다.
		var r := Rect2(0, 5, size.x, size.y - 10)
		draw_rect(r, Px.INK)
		draw_rect(r.grow(-4), Color("#3f9a3c") if on else Color("#4a3a2c"))
		var kw := size.y
		var k := Rect2(size.x - kw if on else 0.0, 0, kw, kw)
		draw_rect(k, Px.INK)
		draw_rect(k.grow(-4), Color("#f4b93a"))
		draw_rect(Rect2(k.position + Vector2(4, 4), Vector2(kw - 8, 5)), Color("#ffd874"))


class Seg extends Control:
	signal changed(i: int)
	var items: Array = []
	var index := 0
	## 그림 칸 (공용, ctl_cell · ctl_cell_on): 그림이 있으면 저절로 쓴다. 없으면 선 UI로 그린다.
	var cell_tex: Texture2D
	var cell_on_tex: Texture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _notification(what: int) -> void:
		if what == NOTIFICATION_READY and cell_tex == null and Px.has_art("ctl_cell"):
			cell_tex = Px.tex("ctl_cell")
			cell_on_tex = Px.tex("ctl_cell_on")

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
		if cell_tex != null:
			for i in n:
				var r := Rect2(i * w, 0, w, size.y)
				draw_texture_rect(cell_on_tex if i == index else cell_tex, r, false)
				Px.text(self, String(items[i]), r.grow(-8), 26, Px.WHITE if i == index else Px.MUTED)
			return
		for i in n:
			var r := Rect2(i * w + 2, 0, w - 4, size.y)
			Px.draw_skin(self, "tab_yellow" if i == index else "btn_small", r)
			Px.text(self, String(items[i]), r.grow(-6), 26, Px.WHITE)
