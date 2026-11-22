extends PxScreen
## 가방 (장수 탭 · 병종 탭 · 보물 탭, 2026-11-22):
## 편성은 스테이지 → 출정 → 출정 편성 창에서 한다 (src/ui/popups/lineup.gd).
## 이미지 중심 · 텍스트 최소화 · 내것만/전체 토글 · 미보유 어두운 그림자 실루엣.

const FACS := ["", "wei", "shu", "wu", "qun"]
const SLOT_ICON := {"weapon": "ic_sword", "armor": "ic_shield", "charm": "ic_orb"}

var tab := 0
var fac := ""
var only_owned := false
var slot_filter := ""


func build() -> void:
	bg = Px.tex("menu_bg")
	bg_dim = 0.35
	tab = clampi(int(params.get("tab", 0)), 0, 2)
	_rebuild()


func _rebuild() -> void:
	clear_children()
	W.top_bar(self, DB.t("tab.heroes"))
	put(W.tabs([DB.t("heroes.tab_heroes"), DB.t("heroes.tab_troops"), DB.t("heroes.tab_treasure")], tab, Vector2(904, 88),
		func(i: int) -> void:
			tab = i
			_rebuild(), ["green", "blue", "purple"]), Rect2(60, 146, 904, 88))
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
	tog.text = DB.t("heroes.mine") if only_owned else DB.t("heroes.all")
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
	var area := Rect2(40, 328, 944, 1260)
	var content := W.scroll(self, area, func(sc: Control, r: Rect2) -> void: put(sc, r))
	var cw := 222.0
	var chh := 224.0
	for i in ids.size():
		var id: String = ids[i]
		var tile := _hero_tile(id, Vector2(cw, chh))
		tile.position = Vector2(4 + (i % 4) * (cw + 12), 4 + (i / 4) * (chh + 12))
		content.add_child(tile)
	content.custom_minimum_size.y = 8 + ceili(ids.size() / 4.0) * (chh + 12)


func _build_barracks_strip() -> void:
	var cap := MetaRules.barracks_cap(Game.lord_lv())
	var classes := ["inf", "arc", "cav", "str"]
	var reps := {"inf": "spear", "arc": "archer", "cav": "rider", "str": "fire"}
	for i in classes.size():
		var cls: String = classes[i]
		var x := 60.0 + i * 228.0
		var y := 248.0
		var lv: Dictionary = Game.profile.data["barracks"][cls]
		var panel := W.section(Vector2(218, 156))
		put(panel, Rect2(x, y, 218, 156))
		# 병종 아이콘 (좌측 상단)
		var head := DrawLayer.make(func(ci: Control) -> void:
			var rep := String(reps[cls])
			var t := Art.portrait(String(Art.of_unit(rep)["art"]))
			if t != null:
				Px.fit(ci, t, Rect2(0, 0, 56, 56))
			Px.fit(ci, Px.tex(String(DB.units["classes"][cls]["icon"])), Rect2(36, 32, 26, 26)))
		put(head, Rect2(x + 8, y + 6, 64, 60))
		for j in 2:
			var stat: String = ["atk", "hp"][j]
			var l := int(lv[stat])
			var cost := MetaRules.barracks_cost(l)
			var ic := "ic_sword" if j == 0 else "ic_heart"
			var b := PxButton.make("panel_small", true, Vector2(138, 62))
			b.disabled = l >= cap
			b.overlay = func(btn: PxButton, off: Vector2) -> void:
				var r := Rect2(off, btn.size)
				Px.fit(btn, Px.tex(ic), Rect2(r.position + Vector2(8, 8), Vector2(28, 28)))
				Px.text(btn, "Lv%d" % l, Rect2(r.position + Vector2(40, 2), Vector2(88, 28)), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
				Px.fit(btn, Px.tex("icon_gold"), Rect2(r.position + Vector2(8, 34), Vector2(22, 22)))
				Px.text(btn, Px.short(cost) if l < cap else "MAX", Rect2(r.position + Vector2(34, 30), Vector2(96, 28)), 20, Px.WHITE if Game.profile.can_pay("gold", cost) else Color("#ff8a80"), HORIZONTAL_ALIGNMENT_LEFT)
			b.pressed.connect(func() -> void:
				var why := Game.profile.upgrade_barracks(cls, stat)
				if why != "":
					toast(why)
					Sfx.play("error")
				else:
					Sfx.play("rankup")
					_rebuild())
			put(b, Rect2(x + 72, y + 12 + j * 68, 138, 62))


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
		var lv := MetaRules.hero_level(Game.profile.data, id)
		var need := MetaRules.star_cost(stars)
		b.badge = need > 0 and int(h.get("cards", 0)) >= need
		var ov := DrawLayer.make(func(ci: Control) -> void:
			W.draw_rank(ci, Rect2(4, sz.y - 38, sz.x - 8, 34), stars, lv, 20.0), sz)
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
	var area := Rect2(40, 328, 944, 1260)
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
	var cards := int(t.get("cards", 0))
	var need := MetaRules.star_cost(stars) if owned else -1
	b.badge = need > 0 and cards >= need
	# 간략 스펙: 이름 · 별 · 전투력 · 공/체 (자세한 속성과 강화는 누르면 병종 상세)
	var ov := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.troop_name(id), Rect2(8, sz.y - 94, sz.x - 16, 30), 26, Px.WHITE if owned else Px.MUTED)
		if owned:
			var st: Dictionary = MetaRules.soldier_stats(Game.profile.data, id)
			W.draw_rank(ci, Rect2(8, sz.y - 64, sz.x * 0.5, 26), stars, 0, 18.0)
			Px.text(ci, "%d/%s" % [cards, str(need) if need > 0 else "-"], Rect2(sz.x * 0.5, sz.y - 64, sz.x * 0.5 - 8, 26), 18, Px.GOLD if need > 0 and cards >= need else Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
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
	tog.text = DB.t("heroes.mine") if only_owned else DB.t("heroes.all")
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
	var area := Rect2(40, 330, 944, 1040)
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
	# 보물 상자 (아이콘 + 천장 카운트 + 열기 버튼)
	var box := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.fit(ci, Px.tex("icon_chest"), Rect2(26, 20, 110, 100))
		var left := int(DB.meta["treasure"]["box"]["pity"]) - int(Game.profile.data["pity"]["box"])
		Px.text(ci, "%d/%d" % [left, int(DB.meta["treasure"]["box"]["pity"])], Rect2(150, 44, 200, 52), 34, Color("#ffb070"), HORIZONTAL_ALIGNMENT_LEFT))
	put(box, Rect2(60, 1396, 904, 140))
	var buy := PxButton.colored("purple", Px.num(int(DB.shop["box_cost"])), Vector2(220, 104), 34)
	buy.icon = Px.tex("icon_diamond")
	buy.icon_rect = Rect2(22, 28, 48, 48)
	buy.text_rect = Rect2(74, 0, 126, 104)
	buy.pressed.connect(func() -> void:
		var g := Game.profile.buy_box()
		if g.has("error"):
			toast(String(g["error"]))
			Sfx.play("error")
			return
		Sfx.play("jackpot")
		var p: PxPopup = Game.app.popup("reward", {"title": DB.t("treasure.got"), "reward": {}, "items": [g]})
		p.closed.connect(_rebuild))
	put(buy, Rect2(724, 1414, 220, 104))


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
