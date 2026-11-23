extends PxScreen
## 병종 상세 (병종-장수-재설계 §3.6): 장수 상세와 같은 방식.
## 위: 병종 그림 · 이름 · 기본/정예 · 성급 · 전투력 · 공방체 · 특징, 이 병종 장수 2명, 이전/다음.
## 탭: 성장(별 6칸, 성급 경험, 군주 레벨 효과) · 속성(속성 칸, 상성) · 장비(무기 · 갑옷 · 장신구).
## 병종이 낀 장비는 그 병종의 모든 병사에게 적용된다 (개편 §11).
## 성급과 속성은 전투 중 흡수로만 오른다 (개편 §9.1).
## 영역: 위 정보판 A(60,160 904×540) · 탭 B(60,716 904×96) · 내용 C(60,820 904×600).

const STATS := ["atk", "def", "hp"]
const STAT_ICON := {"atk": "ic_sword", "def": "ic_shield", "hp": "ic_heart"}

var id := ""
var tab := 0
var slot := "weapon"
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
		var info := DrawLayer.make(func(ci: Control) -> void:
			Px.paragraph(ci, DB.t("troop.not_owned"), Rect2(Vector2.ZERO, ci.size), 32, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER, 4))
		put(info, Rect2(100, 860, 824, 140))
		return
	put(W.tabs([DB.t("hero.tab_up"), DB.t("hero.tab_star"), DB.t("hero.tab_treasure")], tab, Vector2(904, 96),
		func(i: int) -> void:
			tab = i
			_rebuild(), ["yellow", "purple", "green"]), Rect2(60, 716, 904, 96))
	match tab:
		0:
			put(Growth.star_panel(id), Rect2(60, 820, 904, 480))
		1:
			put(Growth.trait_panel(id), Rect2(60, 820, 904, 480))
		_:
			Growth.gear_tab(self, id, slot, func(s: String) -> void:
				slot = s
				_rebuild(), _rebuild)


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
