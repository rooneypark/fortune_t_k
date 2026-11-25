extends PxScreen
## 장수(장수 탭 · 병종 탭) 또는 아이템(장비 가방) — 로비 오른쪽 메뉴 두 개가 여는 화면 (개편 §13).
## 둘 다 도감이다: 아직 없는 것은 어두운 그림자로 보이고 위에 "도감 n / 전체"를 적는다.
## 편성은 없다: 보유한 병종·장수 전부가 슬롯에 나온다 (스테이지-흡수-합성-개편 §3.2).
## 이미지 중심 · 텍스트 최소화 · 내것만/전체 토글 · 미보유 어두운 그림자 실루엣.

const FACS := ["", "wei", "shu", "wu", "qun"]
const SLOT_ICON := {"weapon": "ic_sword", "armor": "ic_shield", "charm": "ic_orb"}

var tab := 0
## "units" = 장수 · 병종, "items" = 아이템
var mode := "units"
var fac := ""
var only_owned := false
var slot_filter := ""


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.35
	tab = clampi(int(params.get("tab", 0)), 0, 2)
	mode = String(params.get("mode", "items" if tab == 2 else "units"))
	if mode == "items":
		tab = 2
	_rebuild()


## 8차 시안 좌표(화면 px 그대로)로 짠 화면이다 — app.gd 가 창 틀 안에 그대로 놓는다.
func native8() -> bool:
	return true


## 자리 (design/art/ui_src/장수목록8_완성화면.png · 가방8_완성화면.png 에서 잰 값)
const TAB_AT := Vector2(121, 346)          # 탭 줄 왼쪽 위
const ROW_Y := 472.0                        # 탭 아래 첫 줄 (칩 · 개수 칸)
const GRID_X := 121.0                       # 목록이 구르는 칸의 왼쪽
const CARD := Vector2(183, 206)             # 장수 · 병사 카드 (얼굴 칸 + 이름 띠)
const CARD_STEP := Vector2(196, 226)
const SLOT := Vector2(143, 136)             # 가방의 장비 칸
const SLOT_STEP := Vector2(157, 151)


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("tab.items") if mode == "items" else DB.t("tab.heroes"))
	if mode != "items":
		put(W.icon_tabs(["tab_hero", "tab_soldier"], mini(tab, 1), 258,
			func(i: int) -> void:
				tab = i
				_rebuild(), [DB.t("heroes.tab_heroes"), DB.t("heroes.tab_troops")]), Rect2(TAB_AT, Vector2(516, 101)))
		_put_dex(DB.t("dex.heroes", [(Game.profile.data["heroes"] as Dictionary).size(), DB.hero_ids().size()]) if tab == 0 else "")
	match tab:
		0:
			_build_heroes()
		1:
			_build_troops()
		_:
			_build_treasures()


# ---------------------------------------------------------------- 장수 + 병영 통합

func _build_heroes() -> void:
	# 칩 5개 한 줄: 내것만 / 전체 토글 + 세력 4개 (다시 누르면 해제)
	var tog := W.pick_chip(DB.t("heroes.mine") if only_owned else DB.t("heroes.all"), only_owned, Vector2(143, 61))
	tog.pressed.connect(func() -> void:
		only_owned = not only_owned
		_rebuild())
	put(tog, Rect2(127, ROW_Y, 143, 61))
	var fac_list := ["wei", "shu", "wu", "qun"]
	for i in fac_list.size():
		var f: String = fac_list[i]
		var b := W.pick_chip(DB.fac_name(f), f == fac, Vector2(143, 61))
		b.text_rect = Rect2(8, 4, 127, 40)
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			# 진영 색 줄: 칩 테두리 안쪽, 글자 아래
			var lr := Rect2(off + Vector2(26, btn.size.y - 19), Vector2(btn.size.x - 52, 5))
			btn.draw_rect(lr.grow(1), Color(0, 0, 0, 0.55))
			btn.draw_rect(lr, DB.fac_color(f))
		b.pressed.connect(func() -> void:
			fac = "" if fac == f else f
			_rebuild())
		put(b, Rect2(127 + (i + 1) * 157, ROW_Y, 143, 61))
	var ids: Array = []
	for id: String in DB.hero_ids():
		if (fac == "" or DB.fac_of(id) == fac) and (not only_owned or Game.profile.owns(id)):
			ids.append(id)
	var tier := {"ss": 4, "s": 3, "a": 2, "b": 1}
	ids.sort_custom(func(a: String, b: String) -> bool:
		var oa := Game.profile.owns(a)
		var ob := Game.profile.owns(b)
		if oa != ob:
			return oa
		var ta := int(tier.get(DB.rarity_of(a), 0))
		var tb := int(tier.get(DB.rarity_of(b), 0))
		if ta != tb:
			return ta > tb
		return a < b)
	var content := _grid_area(548)
	for i in ids.size():
		var tile := _hero_tile(String(ids[i]), CARD)
		tile.position = Vector2(6 + (i % 4) * CARD_STEP.x, 6 + (i / 4) * CARD_STEP.y)
		content.add_child(tile)
	content.custom_minimum_size.y = 12 + ceili(ids.size() / 4.0) * CARD_STEP.y


## 목록이 구르는 칸: y [param top] 부터 안쪽 판 아래 끝(1470)까지.
func _grid_area(top: float) -> Control:
	return W.scroll(self, Rect2(GRID_X, top, 790, 1470 - top), func(sc: Control, r: Rect2) -> void: put(sc, r))


func _hero_tile(id: String, sz: Vector2) -> PxButton:
	var owned := Game.profile.owns(id)
	var b := PxButton.new()
	b.size = sz
	# 칸마다 사각 영역(테두리) — 그림·글자는 이 안에만 들어간다
	b.part = W.card_part()
	b.nine = true
	b.press_depth = 3.0 if owned else 0.0
	b.static_panel = not owned
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.portrait(String(a["art"]))
	pic.cover = false
	pic.focus_y = 0.2
	# 얼굴은 카드의 얼굴 칸(위), 별은 이름 띠(아래 62px)
	pic.position = Vector2(14, 12)
	pic.size = Vector2(sz.x - 28, sz.y - 84)
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.96)
	b.add_child(pic)
	if owned:
		var h: Dictionary = Game.profile.hero(id)
		var stars := int(h.get("star", 1))
		var ov := DrawLayer.make(func(ci: Control) -> void:
			W.draw_rank(ci, Rect2(8, sz.y - 52, sz.x - 16, 40), stars, 0, 22.0), sz)
		b.add_child(ov)
		b.pressed.connect(func() -> void: Game.app.goto("hero", {"id": id}))
	return b


# ---------------------------------------------------------------- 병종 (병사 카드)

func _build_troops() -> void:
	var tl: Array = Game.sortie_troops()
	var owned_n := (Game.profile.data["troops"] as Dictionary).size()
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("heroes.troop_owned", [owned_n, DB.soldier_ids().size()]), Rect2(22, 0, 300, ci.size.y), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("heroes.troop_hint"), Rect2(330, 0, ci.size.x - 352, ci.size.y), 20, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	put(head, Rect2(127, ROW_Y, 770, 61))
	var ids: Array = DB.soldier_ids()
	var content := _grid_area(548)
	for i in ids.size():
		var tile := _troop_tile(String(ids[i]), CARD, tl.has(ids[i]))
		tile.position = Vector2(6 + (i % 4) * CARD_STEP.x, 6 + (i / 4) * CARD_STEP.y)
		content.add_child(tile)
	content.custom_minimum_size.y = 12 + ceili(ids.size() / 4.0) * CARD_STEP.y


func _troop_tile(id: String, sz: Vector2, in_lineup: bool) -> PxButton:
	var owned := Game.profile.owns_troop(id)
	var b := PxButton.new()
	b.size = sz
	# 칸마다 사각 영역(테두리) — 그림·글자는 이 안에만 들어간다
	b.part = W.card_part()
	b.nine = true
	b.press_depth = 3.0 if owned else 0.0
	b.static_panel = not owned
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.portrait(String(a["art"]))
	pic.cover = false
	pic.focus_y = 0.2
	pic.position = Vector2(14, 12)
	pic.size = Vector2(sz.x - 28, sz.y - 84)
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.96)
	b.add_child(pic)
	var t: Dictionary = Game.profile.troop(id)
	var stars := int(t.get("star", 0))
	var xp := int(t.get("xp", 0))
	var need := MetaRules.star_need(id, stars) if owned else -1
	# 이름 띠: 이름 + 별 (전투력 · 공/체 · 성급 경험은 누르면 나오는 병종 상세에)
	var ov := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.troop_name(id), Rect2(10, sz.y - 54, sz.x - 20, 26), 22, Px.WHITE if owned else Px.MUTED)
		if owned:
			W.draw_rank(ci, Rect2(10, sz.y - 31, sz.x - 20, 20), stars, 0, 15.0), sz)
	b.add_child(ov)
	b.pressed.connect(func() -> void: Game.app.goto("troop", {"id": id}))
	return b


# ---------------------------------------------------------------- 보물

func _build_treasures() -> void:
	# 탭 3개 = 장비 종류 (무기 · 갑옷 · 보패)
	var slots: Array = DB.meta["treasure"]["slots"]
	if not slots.has(slot_filter):
		slot_filter = String(slots[0])
	var icons: Array = []
	for s: String in slots:
		icons.append(String(SLOT_ICON[s]))
	put(W.icon_tabs(icons, slots.find(slot_filter), 215,
		func(i: int) -> void:
			slot_filter = String(slots[i])
			_rebuild()), Rect2(TAB_AT, Vector2(215 * icons.size(), 101)))
	# 보유 장비 + 미보유 도감 실루엣 (이 종류만)
	var owned_items: Array = []
	var owned_tids := {}
	for it: Dictionary in Game.profile.data["treasures"]:
		var tid := String(it["tid"])
		owned_tids[tid] = true
		if String(DB.treasure_def(tid)["slot"]) == slot_filter:
			owned_items.append(it)
	var rank := {"legend": 4, "epic": 3, "rare": 2, "common": 1}
	owned_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := int(rank[String(DB.treasure_def(String(a["tid"]))["rarity"])])
		var rb := int(rank[String(DB.treasure_def(String(b["tid"]))["rarity"])])
		return ra > rb if ra != rb else int(a["lv"]) > int(b["lv"]))
	var catalog_missing: Array = []
	for d: Dictionary in DB.meta["treasure"]["list"]:
		var tid := String(d["id"])
		if not owned_tids.has(tid) and String(d["slot"]) == slot_filter:
			catalog_missing.append(d)
	catalog_missing.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := int(rank[String(a["rarity"])])
		var rb := int(rank[String(b["rarity"])])
		return ra > rb if ra != rb else String(a["id"]) < String(b["id"]))
	# 개수 칸: 가방 n/최대 · 도감 · 이 종류의 재료 수. 오른쪽 끝에 합성 버튼.
	var have := {}
	for it: Dictionary in Game.profile.data["treasures"]:
		have[String(it["tid"])] = true
	var mats := 0
	for r: String in DB.meta["treasure"]["rarity_order"]:
		mats += Game.profile.material_count(slot_filter, r)
	var strip := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("icon_bag"), Rect2(22, 18, 44, 44))
		Px.text(ci, "%d/%d" % [(Game.profile.data["treasures"] as Array).size(), int(DB.meta["treasure"]["bag_max"])], Rect2(74, 0, 150, ci.size.y), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		# 도감: 모은 종류 / 전체 종류
		Px.text(ci, "%d/%d" % [have.size(), (DB.meta["treasure"]["list"] as Array).size()], Rect2(230, 0, 190, ci.size.y), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.fit(ci, Px.tex(String(SLOT_ICON[slot_filter])), Rect2(ci.size.x - 190, 18, 44, 44))
		Px.text(ci, "×%d" % mats, Rect2(ci.size.x - 140, 0, 120, ci.size.y), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	put(strip, Rect2(127, ROW_Y, 630, 81))
	var synth := PxButton.make("dlg_chip_on", true, Vector2(113, 81))
	synth.icon = Px.tex("act_synth")
	synth.icon_rect = Rect2(20, 12, 73, 57)
	synth.tooltip_text = DB.t("synth.open")
	synth.pressed.connect(func() -> void:
		var p: PxPopup = Game.app.popup("synth", {})
		p.closed.connect(_rebuild))
	put(synth, Rect2(780, ROW_Y, 113, 81))
	var content := _grid_area(571)
	var total := owned_items.size() + catalog_missing.size()
	for i in owned_items.size():
		var it: Dictionary = owned_items[i]
		var cell := _treasure_tile(it, SLOT, true)
		cell.position = Vector2(6 + (i % 5) * SLOT_STEP.x, 6 + (i / 5) * SLOT_STEP.y)
		var uid := int(it["uid"])
		cell.pressed.connect(func() -> void:
			var p: PxPopup = Game.app.popup("treasure", {"uid": uid})
			p.closed.connect(_rebuild))
		content.add_child(cell)
	for j in catalog_missing.size():
		var idx := owned_items.size() + j
		var d: Dictionary = catalog_missing[j]
		var cell := _treasure_tile({"tid": d["id"], "lv": 0, "uid": -1}, SLOT, false)
		cell.position = Vector2(6 + (idx % 5) * SLOT_STEP.x, 6 + (idx / 5) * SLOT_STEP.y)
		content.add_child(cell)
	# 빈 칸: 시안처럼 6줄(30칸)이 차 보이게 남는 자리는 빈 금테 칸으로
	for k in range(total, 30):
		var blank := DrawLayer.make(func(ci: Control) -> void: Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size), Color(1, 1, 1, 0.6)), SLOT)
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		blank.position = Vector2(6 + (k % 5) * SLOT_STEP.x, 6 + (k / 5) * SLOT_STEP.y)
		content.add_child(blank)
	content.custom_minimum_size.y = 12 + ceili(maxi(30, total) / 5.0) * SLOT_STEP.y


func _treasure_tile(it: Dictionary, sz: Vector2, owned: bool) -> PxButton:
	var d := DB.treasure_def(String(it["tid"]))
	var rc := DB.rarity_color(String(d["rarity"]))
	var b := PxButton.new()
	b.size = sz
	# 장비 칸: 금테 어두운 칸 (kit_box) — 그림·글자는 이 안에만 들어간다
	b.part = "kit_box"
	b.nine = true
	b.static_panel = not owned
	b.press_depth = 3.0 if owned else 0.0
	var owner := MetaRules.treasure_owner(Game.profile.data, int(it["uid"])) if owned else ""
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		var r := Rect2(off, btn.size)
		var icon_r := Rect2(r.position + r.size * 0.18, r.size * 0.64)
		var tex := Px.tex(String(SLOT_ICON[String(d["slot"])]))
		if not owned:
			Px.fit(btn, tex, icon_r, Color(0.04, 0.03, 0.03, 0.78))
			return
		Px.fit(btn, tex, icon_r.grow(4.0), Color(rc, 0.55))
		Px.fit(btn, tex, icon_r)
		Px.text(btn, "+%d" % int(it["lv"]), Rect2(r.position + Vector2(8, 6), Vector2(r.size.x - 16, 36)), 28, rc.lightened(0.25), HORIZONTAL_ALIGNMENT_RIGHT)
		if owner != "":
			var fr := Rect2(r.position + Vector2(8, 8), Vector2(46, 46))
			btn.draw_rect(fr, Px.INK)
			Px.cover(btn, Art.hued_portrait(String(Art.of_unit(owner)["art"]), float(Art.of_unit(owner)["hue"])), fr.grow(-3))
	return b


## 도감 수 (화면 위 오른쪽).
func _put_dex(text: String, ic: String = "") -> void:
	if text == "":
		return
	var d := DrawLayer.make(func(ci: Control) -> void:
		if ic != "":
			# 도감: 아이콘 + 숫자만 (글자 최소)
			var w := Px.text_width(text, 28)
			Px.fit(ci, Px.tex(ic), Rect2(ci.size.x - w - 44, 0, 34, 34))
		Px.text(ci, text, Rect2(Vector2.ZERO, ci.size), 28 if ic != "" else 20, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	put(d, Rect2(646, 418, 250, 26))
