extends PxScreen
## 인트로: 성문 노을 배경, 금빛 로고, 행군하는 장수들, 꽃잎, "화면을 눌러 시작".

var _t := 0.0
var _logo: DrawLayer
var _tap: DrawLayer
var _petals: DrawLayer
var _petal_data: Array = []
var _march: Array = []
var _leaving := false
var _bg_zoom := 1.0


func build() -> void:
	Sfx.play_bgm("bgm_lobby")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 46:
		_petal_data.append([rng.randf() * 1024.0, rng.randf() * 1792.0, rng.randf_range(30, 80), rng.randf_range(0, TAU), rng.randi_range(0, 2)])
	var parade := ["guanyu", "zhangfei", "zhaoyun", "huangzhong", "spear", "shield", "archer", "rider"]
	for i in parade.size():
		var u := UnitView.make(parade[i], 170.0 if DB.is_hero(parade[i]) else 140.0)
		u.action = "walk"
		u.breathe = false
		put(u, Rect2(980 - i * 150, 1600, 0, 0), Pin.BOTTOM)
		_march.append(u)
	_petals = DrawLayer.make(_draw_petals)
	put(_petals, Rect2(0, 0, 1024, 1792))
	_logo = DrawLayer.make(_draw_logo)
	put(_logo, Rect2(0, 230, 1024, 520), Pin.MID)
	_tap = DrawLayer.make(_draw_tap)
	put(_tap, Rect2(0, 1340, 1024, 120), Pin.BOTTOM)
	var foot := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, "v0.1.0 · " + DB.t("intro.proto"), Rect2(20, 0, 984, 40), 22, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	put(foot, Rect2(0, 1740, 1024, 40), Pin.BOTTOM)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	_bg_zoom = 1.0 + 0.04 * sin(_t * 0.25)
	for i in _march.size():
		var u: UnitView = _march[i]
		u.position.x += delta * 70.0
		if u.position.x > 1180:
			u.position.x -= 1400
	for p: Array in _petal_data:
		p[1] += delta * p[2]
		p[0] += sin(_t + p[3]) * delta * 40.0
		if p[1] > 1800:
			p[1] = -20
	queue_redraw()
	_logo.queue_redraw()
	_tap.queue_redraw()
	_petals.queue_redraw()


func _draw() -> void:
	var t := Px.tex("intro_bg")
	var sz := size * _bg_zoom
	Px.cover(self, t, Rect2((size - sz) * 0.5, sz))
	# soft dark gradient top & bottom for legibility
	for i in 12:
		draw_rect(Rect2(0, i * 20, size.x, 20), Color(0.05, 0.03, 0.1, 0.35 - i * 0.028))
	for i in 16:
		draw_rect(Rect2(0, size.y - (i + 1) * 30, size.x, 30), Color(0.04, 0.03, 0.08, 0.5 - i * 0.03))


func _draw_road(ci: Control) -> void:
	ci.draw_rect(Rect2(0, 250, 1024, 30), Color(0.15, 0.09, 0.06, 0.55))


func _draw_petals(ci: Control) -> void:
	for p: Array in _petal_data:
		var c: Color = [Color("#ffb7c9"), Color("#ffd6e0"), Color("#f48fb1")][p[4]]
		var s := 6.0 + (p[4] as int) * 2.0
		ci.draw_rect(Rect2(Vector2(p[0], p[1]).round(), Vector2(s, s * (0.5 + 0.5 * absf(sin(_t * 2.0 + p[3]))))), c)


func _draw_logo(ci: Control) -> void:
	var bob := roundf(sin(_t * 1.6) * 6.0)
	var f := Px.font()
	var title := DB.t("game.title")
	var sz := 168
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	var p := Vector2((1024 - w) * 0.5, 210 + bob).round()
	Px.rec(ci, "text", Rect2(p.x, p.y - f.get_ascent(sz), f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x, f.get_height(sz)), title)
	ci.draw_string_outline(f, p + Vector2(0, 14), title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 36, Color(0, 0, 0, 0.45))
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 36, Px.INK)
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 20, Color("#a8241f"))
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 8, Color("#7a4a10"))
	ci.draw_string(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Px.GOLD)
	ci.draw_string(f, p + Vector2(0, -6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("#fff3b0", 0.55))
	# shine sweep
	var sx := fmod(_t * 380.0, 1800.0) - 400.0
	for k in 3:
		ci.draw_rect(Rect2(sx + k * 18, p.y - 140, 10, 170), Color(1, 1, 1, 0.12))
	Px.ribbon(ci, Rect2(232, 270 + bob, 560, 110), DB.t("game.subtitle"), 44)
	Px.text(ci, DB.t("intro.tagline"), Rect2(0, 410 + bob, 1024, 60), 34, Color("#fff3d6"), HORIZONTAL_ALIGNMENT_CENTER, 6)


func _draw_tap(ci: Control) -> void:
	var a := 0.45 + 0.55 * absf(sin(_t * 2.4))
	var r := Rect2(212, 20, 600, 84)
	ci.draw_rect(r, Color(0.05, 0.06, 0.1, 0.55 * a))
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 4), Color(Px.GOLD, a))
	ci.draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Color(Px.GOLD, a))
	Px.text(ci, DB.t("intro.tap"), r, 40, Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 6)


func _gui_input(e: InputEvent) -> void:
	if _leaving:
		return
	if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed):
		_leaving = true
		Sfx.play("whoosh")
		var tw := create_tween()
		tw.tween_property(_logo, "scale", Vector2(1.06, 1.06), 0.12)
		tw.tween_callback(func() -> void:
			if Game.tutorial_done():
				Game.app.goto("lobby")
			else:
				Game.app.goto("lobby", {"tutorial": true}))


func back() -> bool:
	get_tree().quit()
	return true
