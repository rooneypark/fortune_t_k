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


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("tab.items") if mode == "items" else DB.t("tab.heroes"))
	if mode != "items":
		put(W.tabs([DB.t("heroes.tab_heroes"), DB.t("heroes.tab_troops")], mini(tab, 1), Vector2(904, 88),
			func(i: int) -> void:
				tab = i
				_rebuild(), ["green", "blue"]), Rect2(60, 146, 904, 88))
		_put_dex(DB.t("dex.heroes", [(Game.profile.data["heroes"] as Dictionary).size(), DB.hero_ids().size()]) if tab == 0 else "")
	else:
		var have := {}
		for it: Dictionary in Game.profile.data["treasures"]:
			have[String(it["tid"])] = true
		_put_dex("%d/%d" % [have.size(), (DB.meta["treasure"]["list"] as Array).size()], "icon_bag")
	match tab:
		0:
			_build_heroes()
		1:
			_build_troops()
		_:
			_build_treasures()


# ---------------------------------------------------------------- 장수 + 병영 통합

func _build_heroes() -> void:
	# 내것만 / 전체 토글
	var tog := PxButton.make("btn_small", true, Vector2(148, 64))
	tog.set_label(DB.t("heroes.mine") if only_owned else DB.t("heroes.all"))
	tog.font_size = 24
	tog.highlight = only_owned
	tog.pressed.connect(func() -> void:
		only_owned = not only_owned
		_rebuild())
	put(tog, Rect2(60, 250, 148, 64))
	# 세력 색상 칩 (다시 누르면 해제)
	var fac_list := ["wei", "shu", "wu", "qun"]
	for i in fac_list.size():
		var f: String = fac_list[i]
		var b := PxButton.make("btn_small", true, Vector2(98, 64))
		b.text = DB.fac_name(f)
		b.font_size = 24
		b.highlight = f == fac
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			btn.draw_rect(Rect2(off + Vector2(10, btn.size.y - 12), Vector2(btn.size.x - 20, 5)), DB.fac_color(f))
		b.pressed.connect(func() -> void:
			fac = "" if fac == f else f
			_rebuild())
		put(b, Rect2(236 + i * 108, 250, 98, 64))
	var owned_n := (Game.profile.data["heroes"] as Dictionary).size()
	var cnt := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, "%d/%d" % [owned_n, DB.hero_ids().size()], Rect2(0, 0, ci.size.x, ci.size.y), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	put(cnt, Rect2(760, 250, 204, 64))
	# 장수 그리드 (전투력순 정렬 없음, 보유=초상+별+레벨, 미보유=어두운 실루엣, 투명 배경)
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
	var area := Rect2(40, 328, 944, 1120)
	var content := W.scroll(self, area, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var cw := 222.0
	var chh := 224.0
	for i in ids.size():
		var id: String = ids[i]
		var tile := _hero_tile(id, Vector2(cw, chh))
		tile.position = Vector2(4 + (i % 4) * (cw + 12), 4 + (i / 4) * (chh + 12))
		content.add_child(tile)
	content.custom_minimum_size.y = 8 + ceili(ids.size() / 4.0) * (chh + 12)


func _hero_tile(id: String, sz: Vector2) -> PxButton:
	var owned := Game.profile.owns(id)
	var b := PxButton.new()
	b.size = sz
	# 칸마다 사각 영역(테두리) — 그림·글자는 이 안에만 들어간다
	b.part = "panel_slot"
	b.nine = true
	b.press_depth = 3.0 if owned else 0.0
	b.static_panel = not owned
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.portrait(String(a["art"]))
	pic.cover = false
	pic.focus_y = 0.2
	pic.position = Vector2(16, 4)
	pic.size = Vector2(sz.x - 32, sz.y - 46)
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.96)
	b.add_child(pic)
	if owned:
		var h: Dictionary = Game.profile.hero(id)
		var stars := int(h.get("star", 1))
		var ov := DrawLayer.make(func(ci: Control) -> void:
			W.draw_rank(ci, Rect2(4, sz.y - 38, sz.x - 8, 34), stars, 0, 20.0), sz)
		b.add_child(ov)
		b.pressed.connect(func() -> void: Game.app.goto("hero", {"id": id}))
	return b


# ---------------------------------------------------------------- 병종 (병사 카드)

func _build_troops() -> void:
	var tl: Array = Game.sortie_troops()
	var owned_n := (Game.profile.data["troops"] as Dictionary).size()
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("heroes.troop_owned", [owned_n, DB.soldier_ids().size()]), Rect2(0, 0, 360, ci.size.y), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("heroes.troop_hint"), Rect2(380, 0, ci.size.x - 380, ci.size.y), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	put(head, Rect2(60, 250, 904, 64))
	var ids: Array = DB.soldier_ids()
	var area := Rect2(40, 328, 944, 1120)
	var content := W.scroll(self, area, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var cw := 222.0
	var chh := 260.0
	for i in ids.size():
		var tile := _troop_tile(String(ids[i]), Vector2(cw, chh), tl.has(ids[i]))
		tile.position = Vector2(4 + (i % 4) * (cw + 12), 4 + (i / 4) * (chh + 12))
		content.add_child(tile)
	content.custom_minimum_size.y = 8 + ceili(ids.size() / 4.0) * (chh + 12)


func _troop_tile(id: String, sz: Vector2, in_lineup: bool) -> PxButton:
	var owned := Game.profile.owns_troop(id)
	var b := PxButton.new()
	b.size = sz
	# 칸마다 사각 영역(테두리) — 그림·글자는 이 안에만 들어간다
	b.part = "panel_slot"
	b.nine = true
	b.press_depth = 3.0 if owned else 0.0
	b.static_panel = not owned
	var a := Art.of_unit(id)
	var pic := ArtRect.new()
	pic.texture = Art.portrait(String(a["art"]))
	pic.cover = false
	pic.focus_y = 0.2
	pic.position = Vector2(16, 4)
	pic.size = Vector2(sz.x - 32, sz.y - 96)
	pic.set_look(float(a["hue"]), 0.0, 0.0 if owned else 0.96)
	b.add_child(pic)
	var t: Dictionary = Game.profile.troop(id)
	var stars := int(t.get("star", 0))
	var xp := int(t.get("xp", 0))
	var need := MetaRules.star_need(id, stars) if owned else -1
	# 간략 스펙: 이름 · 별 · 전투력 · 공/체 (자세한 속성과 강화는 누르면 병종 상세)
	var ov := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.troop_name(id), Rect2(8, sz.y - 94, sz.x - 16, 30), 26, Px.WHITE if owned else Px.MUTED)
		if owned:
			var st: Dictionary = MetaRules.soldier_stats(Game.profile.data, id)
			W.draw_rank(ci, Rect2(8, sz.y - 64, sz.x * 0.5, 26), stars, 0, 18.0)
			Px.text(ci, "%d/%d" % [xp, need] if need > 0 else "MAX", Rect2(sz.x * 0.5, sz.y - 64, sz.x * 0.5 - 8, 26), 18, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
			Px.fit(ci, Px.tex("ic_sword"), Rect2(8, sz.y - 34, 22, 22))
			Px.text(ci, Px.short(MetaRules.soldier_power(Game.profile.data, id)), Rect2(34, sz.y - 36, sz.x * 0.5 - 34, 28), 20, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "%d/%d" % [int(st["atk"]), int(st["hp"])], Rect2(sz.x * 0.5, sz.y - 36, sz.x * 0.5 - 8, 28), 18, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT), sz)
	b.add_child(ov)
	b.pressed.connect(func() -> void: Game.app.goto("troop", {"id": id}))
	return b


# ---------------------------------------------------------------- 보물

func _build_treasures() -> void:
	# 내것만 / 전체 토글
	var tog := PxButton.make("btn_small", true, Vector2(148, 64))
	tog.set_label(DB.t("heroes.mine") if only_owned else DB.t("heroes.all"))
	tog.font_size = 24
	tog.highlight = only_owned
	tog.pressed.connect(func() -> void:
		only_owned = not only_owned
		_rebuild())
	put(tog, Rect2(60, 252, 148, 64))
	# 슬롯 아이콘 필터 (텍스트 없음)
	var slots := ["", "weapon", "armor", "charm"]
	var icons := ["icon_bag", "ic_sword", "ic_shield", "ic_orb"]
	for i in slots.size():
		var s: String = slots[i]
		var ic: String = icons[i]
		var b := PxButton.make("btn_small", true, Vector2(84, 64))
		b.icon = Px.tex(ic)
		b.icon_rect = Rect2(20, 10, 44, 44)
		b.highlight = s == slot_filter
		b.pressed.connect(func() -> void:
			slot_filter = s
			_rebuild())
		put(b, Rect2(224 + i * 94, 252, 84, 64))
	# 보유 보물 + 미보유 도감 실루엣
	var owned_items: Array = []
	var owned_tids := {}
	for it: Dictionary in Game.profile.data["treasures"]:
		var tid := String(it["tid"])
		owned_tids[tid] = true
		if slot_filter == "" or String(DB.treasure_def(tid)["slot"]) == slot_filter:
			owned_items.append(it)
	var rank := {"legend": 4, "epic": 3, "rare": 2, "common": 1}
	owned_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := int(rank[String(DB.treasure_def(String(a["tid"]))["rarity"])])
		var rb := int(rank[String(DB.treasure_def(String(b["tid"]))["rarity"])])
		return ra > rb if ra != rb else int(a["lv"]) > int(b["lv"]))
	var catalog_missing: Array = []
	if not only_owned:
		for d: Dictionary in DB.meta["treasure"]["list"]:
			var tid := String(d["id"])
			if not owned_tids.has(tid) and (slot_filter == "" or String(d["slot"]) == slot_filter):
				catalog_missing.append(d)
		catalog_missing.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var ra := int(rank[String(a["rarity"])])
			var rb := int(rank[String(b["rarity"])])
			return ra > rb if ra != rb else String(a["id"]) < String(b["id"]))
	var cnt := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, "%d/%d" % [(Game.profile.data["treasures"] as Array).size(), int(DB.meta["treasure"]["bag_max"])], Rect2(0, 0, ci.size.x, ci.size.y), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	put(cnt, Rect2(640, 252, 324, 64))
	var area := Rect2(40, 330, 944, 960)   # 아래 재료 줄 · 하단 탭 위에서 끝나게 (2026-11-23)
	var content := W.scroll(self, area, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var cs := 176.0
	var total := owned_items.size() + catalog_missing.size()
	for i in owned_items.size():
		var it: Dictionary = owned_items[i]
		var cell := _treasure_tile(it, Vector2(cs, cs), true)
		cell.position = Vector2(4 + (i % 5) * (cs + 12), 4 + (i / 5) * (cs + 12))
		var uid := int(it["uid"])
		cell.pressed.connect(func() -> void:
			var p: PxPopup = Game.app.popup("treasure", {"uid": uid})
			p.closed.connect(_rebuild))
		content.add_child(cell)
	for j in catalog_missing.size():
		var idx := owned_items.size() + j
		var d: Dictionary = catalog_missing[j]
		var cell := _treasure_tile({"tid": d["id"], "lv": 0, "uid": -1}, Vector2(cs, cs), false)
		cell.position = Vector2(4 + (idx % 5) * (cs + 12), 4 + (idx / 5) * (cs + 12))
		content.add_child(cell)
	content.custom_minimum_size.y = 8 + ceili(maxi(1, total) / 5.0) * (cs + 12)
	# 재료 요약 + 합성 (개편 §3.8): 보물은 합성으로만 얻는다
	var mats := DrawLayer.make(func(ci: Control) -> void:
		# 글자 없이: 재료 종류 아이콘(M 96) + 개수만
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var mat_slots: Array = DB.meta["treasure"]["slots"]
		for i in mat_slots.size():
			var slot := String(mat_slots[i])
			var n := 0
			for r: String in DB.meta["treasure"]["rarity_order"]:
				n += Game.profile.material_count(slot, r)
			Px.fit(ci, Px.tex(String(SLOT_ICON[slot])), Rect2(28 + i * 210, 22, 96, 96))
			Px.text(ci, "×%d" % n, Rect2(128 + i * 210, 22, 90, 96), 34, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	put(mats, Rect2(60, 1300, 904, 140))
	var synth := PxButton.colored("purple", DB.t("synth.open"), Vector2(220, 104), 36)
	synth.pressed.connect(func() -> void:
		var p: PxPopup = Game.app.popup("synth", {})
		p.closed.connect(_rebuild))
	put(synth, Rect2(724, 1318, 220, 104))


func _treasure_tile(it: Dictionary, sz: Vector2, owned: bool) -> PxButton:
	var d := DB.treasure_def(String(it["tid"]))
	var rc := DB.rarity_color(String(d["rarity"]))
	var b := PxButton.new()
	b.size = sz
	# 칸마다 사각 영역(테두리) — 그림·글자는 이 안에만 들어간다
	b.part = "panel_slot"
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
		Px.text(ci, text, Rect2(Vector2.ZERO, ci.size), 28 if ic != "" else 24, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	put(d, Rect2(564, 246 if mode != "items" else 200, 400, 34))
