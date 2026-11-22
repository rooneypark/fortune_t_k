extends PxScreen
## 스테이지 선택 (콘텐츠 §2): 장 제목 + 좌우 화살표, 장 별 상자, 스테이지 카드 8장
## (클리어·선택·잠김), 웨이브 수·보스·첫 클리어 보상·권장 전투력, 출정 버튼.

var chapter := 1
var selected := 1
var _t := 0.0


func build() -> void:
	bg = Px.tex("stage_bg")
	bg_dim = 0.25
	var last := String(Game.profile.data["progress"]["last"]).split("-")
	chapter = int(params.get("chapter", int(last[0])))
	selected = int(params.get("stage", int(last[1])))
	if not Game.profile.is_unlocked(chapter, selected):
		selected = 1
	_rebuild()
	set_process(true)


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("stage.title"))
	var ch := DB.chapter(chapter)
	# 장 두루마리
	var head := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.draw_skin(ci, "plate_title", r)
		Px.text(ci, DB.t("stage.chapter", [chapter, String(ch.get("name", ""))]), Rect2(60, 14, r.size.x - 120, 64), 46, Px.WHITE)
		Px.text(ci, DB.t("stage.enemy", [String(ch.get("enemy", ""))]), Rect2(100, 74, r.size.x - 200, 40), 26, Px.GOLD))
	put(head, Rect2(60, 146, 904, 120))
	for side in [-1, 1]:
		var target: int = chapter + side
		var a := W.arrow_button(side, func() -> void:
			chapter = target
			selected = 1
			_rebuild())
		a.disabled = target < 1 or target > DB.chapters().size()
		put(a, Rect2(72 if side < 0 else 868, 158, 84, 96))
	# 장 별 상자
	var stars := Game.profile.chapter_stars(chapter)
	var chests: Array = DB.stages["chapter_chests"]
	var bar := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0.03, 0.05, 0.09, 0.72))
		Px.fit(ci, Px.tex("ic_star"), Rect2(16, 18, 40, 40))
		Px.text(ci, "%d / 24" % stars, Rect2(60, 0, 140, ci.size.y), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(200, 26, 560, 26), stars / 24.0, Px.GOLD))
	put(bar, Rect2(60, 276, 904, 64))
	for i in chests.size():
		var c: Dictionary = chests[i]
		var key := "%d-%d" % [chapter, i]
		var got: bool = (Game.profile.data["progress"].get("chests", {}) as Dictionary).has(key)
		var b := PxButton.make("", false, Vector2(70, 64))
		b.icon = Px.tex("icon_chest")
		b.icon_rect = Rect2(0, 0, 70, 56)
		b.disabled = got
		b.pulse = not got and stars >= int(c["stars"])
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, str(int(c["stars"])), Rect2(off + Vector2(0, 38), Vector2(70, 26)), 22, Px.WHITE)
		b.pressed.connect(func() -> void: _claim_chest(i, c))
		put(b, Rect2(260 + 560 * float(c["stars"]) / 24.0 - 35, 276, 70, 64))
	# 스테이지 카드 8장
	for s in range(1, 9):
		var col := (s - 1) % 2
		var row := (s - 1) / 2
		put(_card(s), Rect2(60 + col * 460, 352 + row * 168, 444, 158))
	# 상세
	put(_detail(), Rect2(60, 1022, 904, 352))
	var go := PxButton.colored("yellow", DB.t("stage.go"), Vector2(560, 110), 46)
	go.pulse = true
	go.sound = "whoosh"
	go.icon = Px.tex("icon_sword")
	go.icon_rect = Rect2(76, 18, 74, 74)
	# 출정 = 편성 창 (장수 최대 3 + 병종 = 슬롯 릴) → 편성 창의 출정으로 전투
	go.pressed.connect(func() -> void: Game.app.popup("lineup", {"chapter": chapter, "stage": selected}))
	put(go, Rect2(232, 1386, 560, 110))


func _card(s: int) -> PxButton:
	var unlocked := Game.profile.is_unlocked(chapter, s)
	var st := Game.profile.stars_of(DB.stage_key(chapter, s))
	var b := PxButton.make("panel_small", true, Vector2(444, 180))
	b.disabled = not unlocked
	b.highlight = s == selected
	var boss := DB.stage_boss(chapter, s)
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var r := Rect2(off + Vector2(14, 14), Vector2(130, btn.size.y - 28))
		btn.draw_rect(r, Px.INK)
		btn.draw_rect(r.grow(-4), Color("#5a2a1a") if boss != "" else Color("#3e2817"))
		if boss != "":
			Px.cover(btn, Art.portrait(String(Art.of_unit(boss)["art"])), r.grow(-8), Color.WHITE if unlocked else Color(0.3, 0.3, 0.3))
			Px.fit(btn, Px.tex("ic_boss"), Rect2(r.position + Vector2(4, 4), Vector2(36, 36)))
		else:
			Px.text(btn, "%d-%d" % [chapter, s], r, 44, Px.WHITE if unlocked else Px.MUTED)
		Px.text(btn, "%d-%d" % [chapter, s] if boss != "" else "", Rect2(off + Vector2(160, 14), Vector2(120, 40)), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(btn, DB.stage_name(chapter, s), Rect2(off + Vector2(160, 50), Vector2(270, 52)), 36, Px.WHITE if unlocked else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		if unlocked:
			Px.stars(btn, off + Vector2(220, btn.size.y - 30), st, 3, 36.0)
			if st == 0:
				btn.draw_rect(Rect2(off + Vector2(330, 116), Vector2(100, 40)), Color("#c8352e"))
				Px.text(btn, "NEW", Rect2(off + Vector2(330, 116), Vector2(100, 40)), 24)
		else:
			Px.fit(btn, Px.tex("ic_lock"), Rect2(off + Vector2(360, 100), Vector2(56, 56)))
	b.pressed.connect(func() -> void:
		selected = s
		_rebuild())
	return b


func _detail() -> Control:
	var boss := DB.stage_boss(chapter, selected)
	var rec := DB.recommended_power(chapter, selected)
	var mine := 0
	for id: String in Game.lineup():
		mine += MetaRules.hero_power(Game.profile.data, id)
	var first := Game.profile.stars_of(DB.stage_key(chapter, selected)) == 0
	var waves := DB.stage_waves(chapter, selected)
	return DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, "%d-%d  %s" % [chapter, selected, DB.stage_name(chapter, selected)], Rect2(30, 18, 600, 56), 42, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("stage.waves", [waves.size()]), Rect2(640, 18, 240, 56), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		# 권장 전투력
		Px.fit(ci, Px.tex("icon_sword"), Rect2(30, 92, 44, 44))
		var ok := mine >= rec
		Px.text(ci, DB.t("stage.power", [Px.num(mine), Px.num(rec)]), Rect2(84, 86, 560, 56), 30, Px.HP_GREEN if ok else Color("#ff8a70"), HORIZONTAL_ALIGNMENT_LEFT)
		# 적 구성
		Px.text(ci, DB.t("stage.foes"), Rect2(30, 152, 200, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		var seen := {}
		var x := 30.0
		for w: Dictionary in waves:
			for pair: Array in (w["list"] as Array) + (w["flank"] as Array):
				var id := String(pair[0])
				if seen.has(id) or x > 560:
					continue
				seen[id] = true
				ci.draw_rect(Rect2(x, 196, 80, 80), Px.INK)
				ci.draw_rect(Rect2(x + 3, 199, 74, 74), Color("#3a3036"))
				Px.cover(ci, Art.hued_portrait(String(Art.of_unit(id)["art"]), float(DB.chapter(chapter).get("hue", 0.0))), Rect2(x + 5, 201, 70, 70))
				x += 88
		if boss != "":
			var r := Rect2(620, 150, 250, 190)
			ci.draw_rect(r, Px.INK)
			ci.draw_rect(r.grow(-4), Color("#5a1a1a"))
			Px.cover(ci, Art.portrait(String(Art.of_unit(boss)["art"])), r.grow(-8))
			ci.draw_rect(Rect2(r.position.x + 4, r.end.y - 48, r.size.x - 8, 44), Color(0, 0, 0, 0.65))
			Px.text(ci, DB.t("stage.boss", [String(DB.enemy_def(boss).get("name", ""))]), Rect2(r.position.x, r.end.y - 48, r.size.x, 44), 26, Color("#ffb0a0"))
		# 첫 클리어 보상
		var rw := Rect2(30, 290, 580, 52)
		ci.draw_rect(rw, Color(0, 0, 0, 0.3))
		Px.text(ci, DB.t("stage.first") if first else DB.t("stage.cleared"), Rect2(rw.position + Vector2(14, 0), Vector2(250, 52)), 26, Px.GOLD if first else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		if first:
			Px.fit(ci, Px.tex("icon_diamond"), Rect2(rw.position + Vector2(250, 8), Vector2(40, 36)))
			Px.text(ci, str(int(DB.stages["first_clear_diamond"])), Rect2(rw.position + Vector2(296, 0), Vector2(80, 52)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.fit(ci, Px.tex("icon_chest"), Rect2(rw.position + Vector2(380, 8), Vector2(44, 36)))
			Px.text(ci, DB.t("stage.treasure"), Rect2(rw.position + Vector2(430, 0), Vector2(150, 52)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), Vector2(904, 360))


func _claim_chest(i: int, c: Dictionary) -> void:
	var stars := Game.profile.chapter_stars(chapter)
	if stars < int(c["stars"]):
		toast(DB.t("stage.chest_need", [int(c["stars"])]))
		return
	var prog: Dictionary = Game.profile.data["progress"]
	if not prog.has("chests"):
		prog["chests"] = {}
	prog["chests"]["%d-%d" % [chapter, i]] = true
	var rw := c.duplicate()
	rw.erase("stars")
	Game.profile.grant(rw)
	Game.app.popup("reward", {"reward": rw})
	_rebuild()
