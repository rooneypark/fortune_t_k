extends PxScreen
## 병종 상세 (병종-장수-재설계 §3.6): 장수 상세와 같은 방식.
## 위: 병종 그림 · 이름 · 기본/정예 · 성급 · 전투력 · 공방체 · 특징, 이 병종 장수 2명, 이전/다음.
## 탭: 강화(공·방·체 줄 3개 + 일괄 강화) · 성급(별 6칸, 카드 n/필요, 성급 올리기).
## 영역: 위 정보판 A(60,160 904×540) · 탭 B(60,716 904×96) · 내용 C(60,820 904×600).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}

var id := ""
var tab := 0
var _t := 0.0


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.45
	id = String(params.get("id", "spear"))
	tab = int(params.get("tab", 0))
	_rebuild()
	set_process(true)


func back() -> bool:
	Game.app.goto("heroes", {"tab": 1})
	return true


func _process(delta: float) -> void:
	_t += delta
	for c in get_children():
		if c is DrawLayer and c.has_meta("anim"):
			c.queue_redraw()


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("troop.title"))
	_build_showcase()
	if not Game.profile.owns_troop(id):
		var go := PxButton.colored("yellow", DB.t("troop.go_recruit"), Vector2(520, 120), 44)
		go.pulse = true
		go.pressed.connect(func() -> void: Game.app.goto("recruit"))
		put(go, Rect2(252, 900, 520, 120))
		return
	put(W.tabs([DB.t("hero.tab_up"), DB.t("hero.tab_star")], tab, Vector2(904, 96),
		func(i: int) -> void:
			tab = i
			_rebuild(), ["yellow", "purple"]), Rect2(60, 716, 904, 96))
	if tab == 0:
		_build_upgrade()
	else:
		_build_star()


func _build_showcase() -> void:
	var owned := Game.profile.owns_troop(id)
	var d := DB.soldier(id)
	var tier := String(d.get("tier", "basic"))
	var panel := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size)), Vector2(904, 540))
	put(panel, Rect2(60, 160, 904, 540))
	var unit := UnitView.make(id, 300.0)
	if not owned:
		unit.set_gray(1.0)
	put(unit, Rect2(270, 560, 0, 0))
	var info := DrawLayer.make(func(ci: Control) -> void:
		var st: Dictionary = MetaRules.soldier_stats(Game.profile.data, id)
		var rr := Rect2(0, 0, 160, 46)
		ci.draw_rect(rr, Px.INK)
		ci.draw_rect(rr.grow(-3), Color("#6f9ad8") if tier == "elite" else Color("#5b6676"))
		Px.text(ci, DB.t("odds.tier_" + tier), rr, 26)
		Px.text(ci, DB.troop_name(id), Rect2(0, 54, 420, 80), 68, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 8)
		Px.stars(ci, Vector2(130, 158), int(Game.profile.troop(id).get("star", 0)), 6, 38.0)
		var cr := Rect2(0, 190, 170, 44)
		ci.draw_rect(cr, Px.INK)
		ci.draw_rect(cr.grow(-3), Color("#2a3340"))
		Px.fit(ci, Px.tex(String(DB.units["classes"][DB.cls_of(id)]["icon"])), Rect2(cr.position + Vector2(8, 6), Vector2(32, 32)))
		Px.text(ci, DB.cls_name(DB.cls_of(id)), Rect2(cr.position + Vector2(44, 0), Vector2(120, 44)), 26)
		Px.fit(ci, Px.tex("icon_sword"), Rect2(0, 250, 44, 44))
		Px.text(ci, Px.num(MetaRules.soldier_power(Game.profile.data, id)), Rect2(52, 244, 300, 56), 44, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		var y := 310.0
		for s: String in STATS:
			Px.fit(ci, Px.tex(String(STAT_ICON[s])), Rect2(0, y + 4, 30, 30))
			Px.text(ci, DB.t("stat." + s), Rect2(40, y, 90, 38), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, Px.num(int(st[s])), Rect2(130, y, 150, 38), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			y += 38
		Px.paragraph(ci, String(d.get("desc", "")), Rect2(0, 430, 420, 60), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), Vector2(420, 500))
	put(info, Rect2(520, 180, 420, 500))
	# 이 병종 장수 (슬롯에서 이 병종 줄에 끼면 합류)
	var hs := DB.heroes_of_troop(id)
	var cap := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("troop.heroes"), Rect2(Vector2.ZERO, ci.size), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT), Vector2(400, 30))
	put(cap, Rect2(84, 584, 400, 30))
	for i in hs.size():
		var h := String(hs[i])
		var pf := W.portrait(h, Vector2(76, 76))
		if not Game.profile.owns(h):
			pf.modulate = Color(0.35, 0.35, 0.4)
		put(pf, Rect2(84 + i * 200, 616, 76, 76))
		var nm := DrawLayer.make(func(ci: Control) -> void:
			Px.text(ci, DB.unit_name(h), Rect2(Vector2.ZERO, ci.size), 24, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), Vector2(110, 76))
		put(nm, Rect2(166 + i * 200, 616, 110, 76))
	# 이전/다음 병종
	var list: Array = DB.soldier_ids()
	var idx := list.find(id)
	for side in [-1, 1]:
		var sgn: int = side
		var b := W.arrow_button(side, func() -> void:
			id = String(list[posmod(idx + sgn, list.size())])
			_rebuild())
		put(b, Rect2(72 if side < 0 else 868, 330, 84, 96))


# ---------------------------------------------------------------- 강화

func _build_upgrade() -> void:
	var t := Game.profile.troop(id)
	var star := int(t["star"])
	var cap := MetaRules.upgrade_cap(star)
	var d := DB.soldier(id)
	for i in STATS.size():
		var s: String = STATS[i]
		var lv := int(t["up"][s])
		var cost := MetaRules.upgrade_cost(lv)
		var maxed := lv >= cap
		var row := DrawLayer.make(func(ci: Control) -> void:
			Px.draw_skin(ci, "panel_small", Rect2(Vector2.ZERO, ci.size))
			Px.fit(ci, Px.tex(String(STAT_ICON[s])), Rect2(22, 27, 52, 52))
			Px.text(ci, DB.t("stat." + s), Rect2(88, 8, 190, 44), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "Lv.%d / %d" % [lv, cap], Rect2(88, 54, 190, 30), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			var base := float(d.get(s, 0))
			Px.text(ci, Px.num(int(MetaRules.upgraded(base, star, lv))), Rect2(290, 0, 130, ci.size.y), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
			if not maxed:
				Px.text(ci, "▶", Rect2(430, 0, 40, ci.size.y), 28, Px.MUTED)
				Px.text(ci, Px.num(int(MetaRules.upgraded(base, star, lv + 1))), Rect2(470, 0, 160, ci.size.y), 34, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_LEFT)
			else:
				Px.text(ci, DB.t("hero.need_star_short"), Rect2(440, 0, 190, ci.size.y), 24, Color("#ffb070"), HORIZONTAL_ALIGNMENT_LEFT), Vector2(904, 106))
		put(row, Rect2(60, 820 + i * 118, 904, 106))
		var b := PxButton.colored("yellow", Px.short(cost), Vector2(250, 86), 32)
		b.icon = Px.tex("icon_gold")
		b.icon_rect = Rect2(16, 19, 46, 48)
		b.text_rect = Rect2(64, 0, 176, 86)
		b.disabled = maxed
		b.pressed.connect(func() -> void:
			var why := Game.profile.troop_upgrade_stat(id, s)
			if why != "":
				toast(why)
				Sfx.play("error")
			else:
				Sfx.play("rankup")
				_rebuild())
		put(b, Rect2(700, 830 + i * 118, 250, 86))
	var all := PxButton.colored("yellow", DB.t("hero.up_all"), Vector2(904, 88), 34)
	all.pressed.connect(func() -> void:
		var n := Game.profile.troop_upgrade_all(id)
		if n == 0:
			toast(DB.t("hero.up_none"))
			Sfx.play("error")
		else:
			Sfx.play("rankup")
			toast(DB.t("hero.up_done", [n]))
			_rebuild())
	put(all, Rect2(60, 1176, 904, 88))


# ---------------------------------------------------------------- 성급

func _build_star() -> void:
	var t := Game.profile.troop(id)
	var star := int(t["star"])
	var need := MetaRules.star_cost(star)
	var cards := int(t["cards"])
	var panel := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var w := ci.size.x
		for i in 6:
			var c := Vector2(w * 0.5 + (i - 2.5) * 120, 90)
			var sz := 92.0 + (8.0 * sin(_t * 4.0) if i == star and need > 0 else 0.0)
			Px.fit(ci, Px.tex("ic_star" if i < star else "ic_star_off"), Rect2(c - Vector2(sz, sz) * 0.5, Vector2(sz, sz)))
		if need < 0:
			Px.text(ci, DB.t("hero.max_star"), Rect2(0, 170, w, 60), 40, Px.GOLD)
			return
		Px.text(ci, DB.t("hero.star_step", [star, star + 1]), Rect2(0, 160, w, 60), 42, Px.WHITE)
		Px.fit(ci, Art.portrait(String(Art.of_unit(id)["art"])), Rect2(70, 238, 64, 64))
		Px.bar(ci, Rect2(150, 250, w - 300, 44), float(cards) / maxf(1.0, need), Color("#b070ff"))
		Px.text(ci, "%d / %d" % [cards, need], Rect2(150, 250, w - 300, 44), 28)
		Px.text(ci, "· " + DB.t("hero.star_fx1", [int(round((float(DB.meta["star"]["mult"]) - 1.0) * 100.0))]), Rect2(70, 320, w - 140, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "· " + DB.t("hero.star_fx2", [MetaRules.upgrade_cap(star), MetaRules.upgrade_cap(star + 1)]), Rect2(70, 368, w - 140, 44), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT), Vector2(904, 480))
	panel.set_meta("anim", true)
	put(panel, Rect2(60, 820, 904, 480))
	if need > 0:
		var ok := cards >= need
		var b := PxButton.colored("purple" if ok else "blue", DB.t("hero.star_up") if ok else DB.t("troop.go_recruit"), Vector2(560, 120), 44)
		b.pulse = ok
		b.pressed.connect(func() -> void:
			if not ok:
				Game.app.goto("recruit")
				return
			var why := Game.profile.troop_star_up(id)
			if why != "":
				toast(why)
				return
			Sfx.play("jackpot")
			toast(DB.t("hero.star_done", [int(Game.profile.troop(id)["star"])]))
			_rebuild())
		put(b, Rect2(232, 1316, 560, 120))
