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
## 배경 그림의 배율과, 로고 판 가운데가 놓인 화면 자리 (_draw 가 적는다)
var _bg_k := 1.0
var _board := Vector2(512, 297)


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
	# 로고 판(배경 그림, x 145~880 · y 210~385) 위에 게임 이름
	put(_logo, Rect2(0, 190, 1024, 520))
	_tap = DrawLayer.make(_draw_tap)
	put(_tap, Rect2(0, 1340, 1024, 120), Pin.BOTTOM)
	var foot := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, "v0.1.0 · " + DB.t("intro.proto"), Rect2(20, 0, 984, 40), 22, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_RIGHT, 3))
	put(foot, Rect2(0, 1740, 1024, 40), Pin.BOTTOM)
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	# 8차 배경에는 로고 판이 그려져 있다: 배경이 움직이면 로고가 판에서 벗어나므로 크기를 고정한다
	_bg_zoom = 1.0
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
	# 배경은 화면을 덮게 같은 비율로 키워 가운데에 놓는다. 로고 판(그림의 512, 297)이 화면 어디에 오는지 적어 둔다.
	var t := Px.tex("intro_bg")
	_bg_k = maxf(size.x / 1024.0, size.y / 1792.0) * _bg_zoom
	var r := Rect2((size - Vector2(1024, 1792) * _bg_k) * 0.5, Vector2(1024, 1792) * _bg_k)
	draw_texture_rect(t, r, false)
	_board = r.position + Vector2(512, 297) * _bg_k
	# soft dark gradient top & bottom for legibility
	for i in 12:
		draw_rect(Rect2(0, i * 20, size.x, 20), Color(0.05, 0.03, 0.1, 0.35 - i * 0.028))
	for i in 16:
		draw_rect(Rect2(0, size.y - (i + 1) * 30, size.x, 30), Color(0.04, 0.03, 0.08, 0.5 - i * 0.03))


func _draw_petals(ci: Control) -> void:
	for p: Array in _petal_data:
		var c: Color = [Color("#ffb7c9"), Color("#ffd6e0"), Color("#f48fb1")][p[4]]
		var s := 6.0 + (p[4] as int) * 2.0
		ci.draw_rect(Rect2(Vector2(p[0], p[1]).round(), Vector2(s, s * (0.5 + 0.5 * absf(sin(_t * 2.0 + p[3]))))), c)


func _draw_logo(ci: Control) -> void:
	var bob := roundf(sin(_t * 1.6) * 6.0)
	var f := Px.font()
	var title := DB.t("game.title")
	var sz := int(round(118.0 * _bg_k))
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	# 이름은 로고 판 가운데에 가만히 (판이 움직이지 않으므로), 부제 · 한 줄 소개는 판 아래에서 살짝 떠다닌다
	var c := _board - ci.position
	var p := Vector2(c.x - w * 0.5, c.y + sz * 0.36).round()
	Px.rec(ci, "text", Rect2(p.x, p.y - f.get_ascent(sz), f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x, f.get_height(sz)), title)
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 22, Px.INK)
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 12, Color("#a8241f"))
	ci.draw_string_outline(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 8, Color("#7a4a10"))
	ci.draw_string(f, p, title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Px.GOLD)
	ci.draw_string(f, p + Vector2(0, -6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color("#fff3b0", 0.55))
	# shine sweep
	var sx := fmod(_t * 380.0, 1800.0) - 400.0
	for k in 3:
		ci.draw_rect(Rect2(sx + k * 18, c.y - 70 * _bg_k, 10, 140 * _bg_k).intersection(Rect2(c.x - 350 * _bg_k, c.y - 76 * _bg_k, 700 * _bg_k, 152 * _bg_k)), Color(1, 1, 1, 0.12))
	Px.ribbon(ci, Rect2(c.x - 250, c.y + 112 * _bg_k + bob, 500, 96), DB.t("game.subtitle"), 38)
	Px.text(ci, DB.t("intro.tagline"), Rect2(c.x - 512, c.y + 222 * _bg_k + bob, 1024, 60), 32, Color("#fff3d6"), HORIZONTAL_ALIGNMENT_CENTER, 6)


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
