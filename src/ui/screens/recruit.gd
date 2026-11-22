extends PxScreen
## 모집 (2026-11-22): 병사 모집 탭(골드, 병종 카드) · 장수 모집 탭(다이아·모집권,
## 확률·천장 공개, 10회 S 이상 확정). 처음엔 장수가 없고 병사 위주로 모은다.

## 0 = 병사 모집, 1 = 장수 모집(다이아), 2 = 골드 장수 모집
var tab := 0
var _t := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.35
	tab = 1 if not bool(Game.profile.data["tutorial"]["recruit"]) else clampi(int(params.get("tab", 0)), 0, 2)
	_rebuild()
	set_process(true)
	if not bool(Game.profile.data["tutorial"]["recruit"]) and Game.tutorial_done():
		var b: Control = get_meta("one_btn")
		var g := Guide.show_at(Game.app.overlay_layer, Rect2(b.position, b.size).grow(8), DB.t("tut.recruit_pull"))
		g.advanced.connect(g.queue_free)


func _process(delta: float) -> void:
	_t += delta
	for c in get_children():
		if c is DrawLayer and c.has_meta("anim"):
			c.queue_redraw()


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("tab.recruit"))
	put(W.tabs([DB.t("recruit.soldier"), DB.t("recruit.hero"), DB.t("recruit.gold_hero")], tab, Vector2(904, 96), func(i: int) -> void:
		tab = i
		_rebuild(), ["blue", "purple", "yellow"]), Rect2(60, 146, 904, 96))
	if tab == 0:
		_build_soldier()
		return
	if tab == 2:
		_build_gold()
		return
	var rc: Dictionary = DB.meta["recruit"]
	var banner := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		ci.draw_rect(r.grow(-5), Px.GOLD_DARK)
		Px.cover(ci, Px.tex("recruit_banner"), r.grow(-10))
		# shimmer
		var sx := fmod(_t * 300.0, ci.size.x + 600.0) - 300.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(sx, 10), Vector2(sx + 60, 10), Vector2(sx - 140, r.size.y - 10), Vector2(sx - 200, r.size.y - 10)]), Color(1, 1, 1, 0.10))
		ci.draw_rect(Rect2(10, r.size.y - 150, r.size.x - 20, 140), Color(0, 0, 0, 0.55))
		Px.text(ci, DB.t("recruit.banner_title"), Rect2(30, r.size.y - 146, r.size.x - 60, 70), 52, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 8)
		Px.text(ci, DB.t("recruit.banner_sub", [int(rc["odds"]["ss"])]), Rect2(30, r.size.y - 78, r.size.x - 60, 50), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	banner.set_meta("anim", true)
	put(banner, Rect2(40, 252, 944, 600))
	# 대표 장수 (SS)
	var legends: Array = DB.hero_ids_of_rarity("ss")
	legends.sort()
	for i in mini(3, legends.size()):
		var u := UnitView.make(String(legends[i]), 170.0)
		u.flip = i == 2
		put(u, Rect2(640 + i * 110, 690, 0, 0))
	var odds := PxButton.colored("blue", DB.t("recruit.odds"), Vector2(200, 80), 28)
	odds.pressed.connect(func() -> void: Game.app.popup("odds"))
	put(odds, Rect2(764, 272, 200, 72))
	# 천장
	var pity := int(Game.profile.data["pity"]["normal"])
	var pmax := int(rc["pity"])
	var pbar := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("recruit.pity", [pmax - pity]), Rect2(30, 14, ci.size.x - 60, 44), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(30, 66, ci.size.x - 60, 34), float(pity) / pmax, DB.rarity_color("ss"))
		Px.text(ci, "%d / %d" % [pity, pmax], Rect2(30, 66, ci.size.x - 60, 34), 22)
		Px.text(ci, DB.t("recruit.ten_rule"), Rect2(30, 110, ci.size.x - 60, 36), 24, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_LEFT))
	put(pbar, Rect2(60, 870, 904, 156))
	var tickets := int(Game.profile.data["tickets"])
	var tk := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_chip", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("ic_scroll"), Rect2(14, 12, 52, 52))
		Px.text(ci, DB.t("recruit.tickets", [tickets]), Rect2(72, 0, ci.size.x - 84, ci.size.y), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(tk, Rect2(60, 1042, 360, 72))
	var tut := not bool(Game.profile.data["tutorial"]["recruit"])
	var one := PxButton.colored("blue", DB.t("recruit.one"), Vector2(430, 180), 44)
	one.text_rect = Rect2(10, 22, 410, 70)
	if tut:
		one.sub = DB.t("recruit.free")
	elif tickets > 0:
		one.sub = DB.t("recruit.ticket_cost")
		one.sub_icon = Px.tex("ic_scroll")
	else:
		one.sub = Px.num(int(rc["cost_one"]))
		one.sub_icon = Px.tex("icon_diamond")
	one.sub_size = 34
	one.pressed.connect(func() -> void: _pull(1))
	put(one, Rect2(60, 1134, 430, 180))
	set_meta("one_btn", one)
	var ten := PxButton.colored("purple", DB.t("recruit.ten"), Vector2(430, 180), 44)
	ten.text_rect = Rect2(10, 40, 410, 56)
	ten.sub = Px.num(int(rc["cost_ten"]))
	ten.sub_icon = Px.tex("icon_diamond")
	ten.sub_size = 34
	ten.disabled = tut
	ten.overlay = func(b: PxButton, off: Vector2) -> void:
		var r := Rect2(off + Vector2(b.size.x - 164, 4), Vector2(160, 36))
		b.draw_rect(r, Px.INK)
		b.draw_rect(r.grow(-3), Color("#ff3b30"))
		Px.text(b, DB.t("recruit.ten_tag"), r, 22)
	ten.pressed.connect(func() -> void: _pull(10))
	put(ten, Rect2(534, 1134, 430, 180))


# ---------------------------------------------------------------- 병사 모집 (골드)

func _build_soldier() -> void:
	var sr: Dictionary = DB.meta["soldier_recruit"]
	var banner := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		ci.draw_rect(r, Px.INK)
		ci.draw_rect(r.grow(-4), Px.EDGE, false, 3.0)
		Px.text(ci, DB.t("recruit.soldier_title"), Rect2(30, 24, r.size.x - 60, 70), 52, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 8)
		Px.text(ci, DB.t("recruit.soldier_sub", [int(sr["odds"]["basic"]), int(sr["odds"]["elite"])]), Rect2(30, 96, r.size.x - 60, 44), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT))
	put(banner, Rect2(40, 252, 944, 600))
	# 병종 10종 미리보기 (보유 = 밝게, 미보유 = 실루엣)
	var ids: Array = DB.soldier_ids()
	for i in ids.size():
		var id := String(ids[i])
		var u := UnitView.make(id, 120.0)
		if not Game.profile.owns_troop(id):
			u.modulate = Color(0.15, 0.15, 0.2, 0.9)
		put(u, Rect2(150 + (i % 5) * 180, 560 + (i / 5) * 230, 0, 0))
	var odds := PxButton.colored("blue", DB.t("recruit.odds"), Vector2(200, 80), 28)
	odds.pressed.connect(func() -> void: Game.app.popup("odds", {"kind": "soldier"}))
	put(odds, Rect2(764, 272, 200, 72))
	var one := PxButton.colored("blue", DB.t("recruit.one"), Vector2(430, 180), 44)
	one.text_rect = Rect2(10, 22, 410, 70)
	one.sub = Px.num(int(sr["cost_one"]))
	one.sub_icon = Px.tex("icon_gold")
	one.sub_size = 34
	one.pressed.connect(func() -> void: _pull_soldier(1))
	put(one, Rect2(60, 1134, 430, 180))
	set_meta("one_btn", one)
	var ten := PxButton.colored("purple", DB.t("recruit.ten"), Vector2(430, 180), 44)
	ten.text_rect = Rect2(10, 40, 410, 56)
	ten.sub = Px.num(int(sr["cost_ten"]))
	ten.sub_icon = Px.tex("icon_gold")
	ten.sub_size = 34
	ten.pressed.connect(func() -> void: _pull_soldier(10))
	put(ten, Rect2(534, 1134, 430, 180))


# ---------------------------------------------------------------- 골드 장수 모집

func _build_gold() -> void:
	var gr: Dictionary = DB.meta["gold_recruit"]
	var left := Game.profile.gold_recruits_left()
	var banner := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.draw_skin(ci, "panel_slot", r)
		Px.text(ci, DB.t("recruit.gold_title"), Rect2(30, 24, 700, 70), 52, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 8)
		Px.text(ci, DB.t("recruit.gold_sub", [str(gr["odds"]["s"]), str(gr["odds"]["ss"])]), Rect2(30, 96, r.size.x - 60, 44), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("recruit.gold_note"), Rect2(30, 140, r.size.x - 60, 40), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT), Vector2(944, 600))
	put(banner, Rect2(40, 252, 944, 600))
	var shown: Array = DB.hero_ids_of_rarity("s")
	shown.sort()
	for i in mini(4, shown.size()):
		var u := UnitView.make(String(shown[i]), 170.0)
		put(u, Rect2(190 + i * 210, 760, 0, 0))
	var odds := PxButton.colored("blue", DB.t("recruit.odds"), Vector2(200, 72), 28)
	odds.pressed.connect(func() -> void: Game.app.popup("odds", {"kind": "hero_gold"}))
	put(odds, Rect2(764, 272, 200, 72))
	var lt := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_chip", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("recruit.gold_left", [left, int(gr["daily_max"])]), Rect2(20, 0, ci.size.x - 40, ci.size.y), 30, Px.WHITE), Vector2(420, 72))
	put(lt, Rect2(302, 1042, 420, 72))
	var one := PxButton.colored("yellow", DB.t("recruit.one"), Vector2(560, 180), 44)
	one.text_rect = Rect2(10, 22, 540, 70)
	one.sub = Px.num(int(gr["cost_one"]))
	one.sub_icon = Px.tex("icon_gold")
	one.sub_size = 34
	one.disabled = left <= 0
	one.pressed.connect(func() -> void:
		var res := Game.profile.recruit_gold(1)
		if String(res["error"]) != "":
			toast(String(res["error"]))
			Sfx.play("error")
			return
		var p: PxPopup = Game.app.popup("recruit_result", {"cards": res["cards"], "count": 1})
		p.closed.connect(_rebuild))
	put(one, Rect2(232, 1134, 560, 180))


func _pull_soldier(n: int) -> void:
	var res := Game.profile.recruit_soldiers(n)
	if String(res["error"]) != "":
		toast(String(res["error"]))
		Sfx.play("error")
		return
	var p: PxPopup = Game.app.popup("recruit_result", {"cards": res["cards"], "count": n, "kind": "soldier"})
	p.closed.connect(_rebuild)


func _pull(n: int) -> void:
	var res: Dictionary
	if not bool(Game.profile.data["tutorial"]["recruit"]):
		res = {"cards": [Game.profile.recruit_tutorial()], "error": ""}
	else:
		var rc: Dictionary = DB.meta["recruit"]
		var price := int(rc["cost_ten"]) if n >= 10 else int(rc["cost_one"])
		if int(Game.profile.data["tickets"]) < n and int(Game.profile.data["diamond"]) < price:
			toast(DB.t("common.no_diamond"))
			Sfx.play("error")
			return
		res = Game.profile.recruit(n)
	if String(res["error"]) != "":
		toast(String(res["error"]))
		Sfx.play("error")
		return
	var p: PxPopup = Game.app.popup("recruit_result", {"cards": res["cards"], "count": n})
	p.closed.connect(_rebuild)
