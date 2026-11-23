class_name App
extends Control
## Root of the game (main.tscn): one screen at a time, pop-ups above it, and an
## overlay for toasts, the fade and the tutorial guide. Screens are scenes in
## res://src/ui/screens/<route>.tscn; pop-ups are scripts in src/ui/popups.

signal dialog_changed(route: String)

## Bottom-tab screens open as a dialog over the castle-gate lobby (민수 님 피드백),
## between the lobby's top HUD and its bottom tab bar.
const DIALOG_ROUTES := ["heroes", "hero", "troop", "arena", "shop"]
## Dialog frame in canvas px; content shows screen coords x 32..992, y 146..1462.
const DIALOG_RECT := Rect2(16, 212, 992, 1520)
const DIALOG_INSET := 16.0
## Band above the dialog frame for the close X (inside the dialog container).
const DIALOG_HEAD := 32.0
const DIALOG_ORIGIN := Vector2(32, 146)

var screen_layer: Control
var dialog_layer: Control
var dialog: PxScreen
var dialog_route := ""
var _dialog_frame: Control
var popup_layer: Control
var overlay_layer: Control
var current: PxScreen
var route := ""
var _fade: ColorRect
var _busy := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var th := Theme.new()
	th.default_font = Px.font()
	th.default_font_size = 32
	theme = th
	var layer_z := {"screen_layer": 0, "dialog_layer": 1000, "popup_layer": 2000, "overlay_layer": 3000}
	for n in ["screen_layer", "dialog_layer", "popup_layer", "overlay_layer"]:
		var c := Control.new()
		c.name = n
		c.z_index = int(layer_z[n])
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
		set(n, c)
	_fade = ColorRect.new()
	_fade.color = Color(0.04, 0.06, 0.1, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(_fade)
	Game.app = self
	get_tree().set_auto_accept_quit(false)
	var start := "intro"
	var start_params := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--route="):
			start = a.substr(8)
		elif a.begins_with("--params="):
			var parsed: Variant = JSON.parse_string(a.substr(9))
			if parsed is Dictionary:
				start_params = parsed
	goto(start, start_params, false)
	_shot_mode()


## Screenshot helper for docs/QA: --shot=<png> [--shot_after=sec] [--popup=name]
## [--demo=name] (calls current.demo(name)). Saves the viewport and quits.
func _shot_mode() -> void:
	var shot := ""
	var after := 1.5
	var pop := ""
	var demo := ""
	var pop_params: Dictionary = {}
	var win := Vector2i(1024, 1792)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot_window="):
			var wh := a.substr(14).split("x")
			win = Vector2i(int(wh[0]), int(wh[1]))
		if a.begins_with("--shot="):
			shot = a.substr(7)
		elif a.begins_with("--shot_after="):
			after = float(a.substr(13))
		elif a.begins_with("--popup="):
			pop = a.substr(8)
		elif a.begins_with("--demo="):
			demo = a.substr(7)
		elif a.begins_with("--popup_params="):
			var pp: Variant = JSON.parse_string(a.substr(15))
			if pp is Dictionary:
				pop_params = pp
	if shot == "":
		return
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = win
	await get_tree().create_timer(0.3).timeout
	print("shot window: ", get_window().size, " screen: ", DisplayServer.screen_get_size(), " scale: ", DisplayServer.screen_get_scale())
	var target: PxScreen = dialog if dialog != null else current
	if demo != "" and target != null and target.has_method("demo"):
		target.call("demo", demo)
	if pop != "":
		popup(pop, pop_params)
	await get_tree().create_timer(after).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot)
	print("shot saved: ", shot)
	get_tree().quit()


## Every visible Control box = an "area" (container). Draws must stay inside
## their own node's area; children inside their parent's (unless it scrolls).
func _record_areas(n: Node) -> void:
	for c in n.get_children():
		if c is Control and (c as Control).is_visible_in_tree():
			var ctl := c as Control
			var r := ctl.get_global_rect()
			var nm := String(ctl.name)
			var is_layer := nm.ends_with("_layer")
			if not is_layer and r.size.x >= 2 and r.size.y >= 2 and r.size.x < 2000:
				var parent_clip := ctl.get_parent() is Control and ((ctl.get_parent() as Control).clip_contents or ctl.get_parent() is ScrollContainer)
				Px.records.append({"kind": "area", "x": roundi(r.position.x), "y": roundi(r.position.y), "w": roundi(r.size.x),
					"h": roundi(r.size.y), "label": ctl.get_class() if ctl.get_script() == null else String((ctl.get_script() as Script).resource_path.get_file().get_basename()),
					"node": String(ctl.get_path()), "extra": {"clip": ctl.clip_contents or ctl is ScrollContainer, "parent_clip": parent_clip}})
		_record_areas(c)


func _redraw_all(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	for c in n.get_children():
		_redraw_all(c)


## Switches screen with a short fade. Pop-ups are closed. Tab routes open as a
## dialog over the lobby.
func goto(name: String, params: Dictionary = {}, fade := true) -> void:
	if _busy:
		return
	if DIALOG_ROUTES.has(name):
		if route != "lobby":
			await _goto_screen("lobby", {}, fade)
		open_dialog(name, params)
		return
	close_dialog(false)
	await _goto_screen(name, params, fade)


func _goto_screen(name: String, params: Dictionary, fade: bool) -> void:
	if _busy:
		return
	_busy = true
	if fade and current != null:
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.12)
		await tw.finished
	for p in popup_layer.get_children():
		p.queue_free()
	if current != null:
		current.queue_free()
	var path := "res://src/ui/screens/%s.tscn" % name
	var scene: PackedScene = load(path)
	current = scene.instantiate()
	route = name
	screen_layer.add_child(current)
	current.enter(params)
	if fade:
		var tw2 := create_tween()
		tw2.tween_property(_fade, "color:a", 0.0, 0.16)
	else:
		_fade.color.a = 0.0
	_busy = false


## Opens pop-up [param name] (src/ui/popups/<name>.gd) and returns it.
func popup(name: String, params: Dictionary = {}) -> PxPopup:
	var script: GDScript = load("res://src/ui/popups/%s.gd" % name)
	var p: PxPopup = script.new()
	popup_layer.add_child(p)
	p.open(params)
	return p


func top_popup() -> PxPopup:
	var n := popup_layer.get_child_count()
	return popup_layer.get_child(n - 1) as PxPopup if n > 0 else null


func toast(s: String, color: Color = Px.WHITE) -> void:
	var l := Px.label(s, 40, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var bgp := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Color(0.05, 0.08, 0.13, 0.85))
		ci.draw_rect(Rect2(0, 0, r.size.x, 4), Px.GOLD)
		ci.draw_rect(Rect2(0, r.size.y - 4, r.size.x, 4), Px.GOLD))
	var w := minf(980.0, Px.text_width(s, 40) + 120.0)
	bgp.size = Vector2(w, 96)
	bgp.position = Vector2((size.x - w) * 0.5, size.y * 0.42)
	l.size = bgp.size
	bgp.add_child(l)
	overlay_layer.add_child(bgp)
	var tw := bgp.create_tween()
	bgp.modulate.a = 0.0
	tw.tween_property(bgp, "modulate:a", 1.0, 0.1)
	tw.tween_interval(1.1)
	tw.tween_property(bgp, "modulate:a", 0.0, 0.3)
	tw.tween_callback(bgp.queue_free)


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("ui_cancel"):
		_on_back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		Game.save_now()
		get_tree().quit()
	elif what == NOTIFICATION_RESIZED and _dialog_frame != null:
		_layout_dialog_frame(_dialog_frame)


func _on_back() -> void:
	var p := top_popup()
	if p != null:
		p.close()
		return
	if dialog != null:
		dialog.back()
		return
	if current != null:
		current.back()


## Exit confirm from the lobby.
func confirm_quit() -> void:
	var c := popup("confirm", {"title": DB.t("quit.title"), "text": DB.t("quit.text"), "ok": DB.t("quit.ok")})
	c.confirmed.connect(func() -> void:
		Game.save_now()
		get_tree().quit())


# ---------------------------------------------------------------- tab dialogs

func open_dialog(name: String, params: Dictionary = {}) -> void:
	for p in popup_layer.get_children():
		p.queue_free()
	var fresh := _dialog_frame == null
	if fresh:
		_build_dialog_frame()
	if dialog != null:
		dialog.queue_free()
	var scene: PackedScene = load("res://src/ui/screens/%s.tscn" % name)
	dialog = scene.instantiate()
	dialog.dialog = true
	dialog.set_anchors_preset(Control.PRESET_TOP_LEFT)
	dialog.position = -DIALOG_ORIGIN
	dialog.size = Px.CANVAS
	dialog_route = name
	var clip: Control = _dialog_frame.get_meta("clip")
	clip.add_child(dialog)
	dialog.enter(params)
	clip.modulate.a = 0.0
	var tw := clip.create_tween()
	tw.tween_property(clip, "modulate:a", 1.0, 0.12)
	if fresh:
		_dialog_frame.scale = Vector2(0.96, 0.96)
		var tw2 := _dialog_frame.create_tween()
		tw2.tween_property(_dialog_frame, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	dialog_changed.emit(name)


func close_dialog(animate := true) -> void:
	if _dialog_frame == null:
		return
	var f := _dialog_frame
	_dialog_frame = null
	dialog = null
	dialog_route = ""
	dialog_changed.emit(route)
	if animate:
		var tw := f.create_tween()
		tw.tween_property(f, "modulate:a", 0.0, 0.1)
		tw.tween_callback(f.queue_free)
	else:
		f.queue_free()


## Dialog frame rect for the current window: centred when wider than 1024,
## taller by the extra height on long phones.
func _dialog_rect() -> Rect2:
	var extra := maxf(0.0, size.y - Px.CANVAS.y)
	return Rect2(DIALOG_RECT.position + Vector2(maxf(0.0, (size.x - Px.CANVAS.x) * 0.5), 0), DIALOG_RECT.size + Vector2(0, extra))


## Re-places the frame and its parts after a window resize (PC 창 크기 변경).
func _layout_dialog_frame(f: Control) -> void:
	var r := _dialog_rect()
	f.position = r.position - Vector2(0, DIALOG_HEAD)
	f.size = r.size + Vector2(0, DIALOG_HEAD)
	f.pivot_offset = f.size * 0.5
	(f.get_meta("bg") as Control).size = r.size
	(f.get_meta("clip") as Control).size = r.size - Vector2(DIALOG_INSET, DIALOG_INSET) * 2.0
	(f.get_meta("close") as Control).position = Vector2(r.size.x - W.CLOSE.x - 4, DIALOG_HEAD - 24)


func _build_dialog_frame() -> void:
	var r := _dialog_rect()
	var f := Control.new()
	f.position = r.position - Vector2(0, DIALOG_HEAD)
	f.size = r.size + Vector2(0, DIALOG_HEAD)
	f.pivot_offset = f.size * 0.5
	f.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_layer.add_child(f)
	var bg := DrawLayer.make(func(ci: Control) -> void:
		var rr := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(rr.grow(6), Color(0, 0, 0, 0.35))
		Px.draw_skin(ci, "panel_ctrl", rr)
		var inner := rr.grow(-DIALOG_INSET)
		if not Px.LINE_UI:
			Px.cover(ci, Px.tex("menu_bg"), inner)
			ci.draw_rect(inner, Color(0.08, 0.05, 0.03, 0.55)), r.size)
	bg.position = Vector2(0, DIALOG_HEAD)
	f.add_child(bg)
	f.set_meta("bg", bg)
	var clip := Control.new()
	clip.position = Vector2(DIALOG_INSET, DIALOG_INSET + DIALOG_HEAD)
	clip.size = r.size - Vector2(DIALOG_INSET, DIALOG_INSET) * 2.0
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_PASS
	f.add_child(clip)
	f.set_meta("clip", clip)
	var x := W.close_button(func() -> void:
		if dialog != null:
			dialog.back())
	x.position = Vector2(r.size.x - W.CLOSE.x - 4, DIALOG_HEAD - 24)
	f.add_child(x)
	f.set_meta("close", x)
	_dialog_frame = f
