extends PxPopup
## 군웅 상점 (콘텐츠-기획-v5 §7.1, 메타 §3.10): 군공으로만 산다, 매주 초기화.
## 위: 보물 · 모집권 · 골드 줄. 아래: 보유 장수 중 골라 카드 1장 (희귀도별 값).

const ROW_H := 132.0
const CARD := Vector2(182, 236)

var _body: Control


func setup(_p: Dictionary) -> void:
	title = DB.t("arena_shop.title")
	panel_rect = Rect2(40, 170, 944, 1460)


func build() -> void:
	_body = Control.new()
	put(_body, Rect2(0, 0, panel_rect.size.x, panel_rect.size.y))
	_rebuild()


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	var w := panel_rect.size.x
	var head := DrawLayer.make(func(ci: Control) -> void:
		Px.fit(ci, Px.tex("icon_medal"), Rect2(0, 6, 64, 64))
		Px.text(ci, DB.t("arena.honor", [Px.num(int(Game.profile.data["honor"]))]), Rect2(76, 0, 400, 76), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("arena_shop.note"), Rect2(0, 78, ci.size.x, 36), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT), Vector2(w - 80, 116))
	head.position = Vector2(40, 100)
	_body.add_child(head)
	var y := 210.0
	for item_id in ["treasure", "tickets", "gold"]:
		_body.add_child(_item_row(item_id, Rect2(30, y, w - 60, ROW_H - 10)))
		y += ROW_H
	# 장수 카드
	var card_it := Game.profile.arena_item("card")
	var bought := Game.profile.arena_bought("card")
	var limit := int(card_it["limit"])
	var sec := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("arena_shop.card"), Rect2(0, 0, 300, 56), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("arena_shop.limit", [bought, limit]), Rect2(320, 0, ci.size.x - 320, 56), 26, Px.GOLD if bought < limit else Color("#ff8a80"), HORIZONTAL_ALIGNMENT_RIGHT)
		Px.text(ci, DB.t("arena_shop.pick"), Rect2(0, 56, ci.size.x, 36), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT), Vector2(w - 80, 92))
	sec.position = Vector2(40, y + 6)
	_body.add_child(sec)
	var ids := _card_heroes()
	var top := y + 110.0
	var area := Rect2(36, top, w - 72, panel_rect.size.y - top - 30)
	var content := W.scroll(_body, area, func(sc: ScrollContainer, r: Rect2) -> void:
		sc.position = r.position
		_body.add_child(sc))
	var cols := 4
	var gap := (area.size.x - CARD.x * cols) / (cols - 1)
	for i in ids.size():
		var id := String(ids[i])
		var price := Game.profile.arena_price("card", id)
		var b := W.hero_card(id, CARD, {"big": false, "tag": "%s" % Px.num(price)})
		b.position = Vector2((i % cols) * (CARD.x + gap), floorf(i / float(cols)) * (CARD.y + 16))
		b.pressed.connect(_ask_card.bind(id, price))
		content.add_child(b)
	content.custom_minimum_size.y = ceilf(ids.size() / float(cols)) * (CARD.y + 16)


## Owned heroes that can still use a card, highest rarity first.
func _card_heroes() -> Array:
	var out: Array = []
	var max_star := int(DB.meta["star"]["max"])
	for r: String in ["ss", "s", "a", "b"]:
		for id: String in DB.hero_ids_of_rarity(r):
			if Game.profile.owns(id) and Game.profile.star_of(id) < max_star:
				out.append(id)
	return out


func _item_row(item_id: String, r: Rect2) -> Control:
	var it := Game.profile.arena_item(item_id)
	var price := int(it["cost"])
	var limit := int(it["limit"])
	var bought := Game.profile.arena_bought(item_id)
	var icon := "icon_chest" if item_id == "treasure" else W.reward_icon({item_id: 1})
	var row := W.row_panel(r.size)
	row.position = r.position
	var ov := DrawLayer.make(func(ci: Control) -> void:
		Px.fit(ci, Px.tex(icon), Rect2(24, 14, 90, 90))
		Px.text(ci, DB.t("arena_shop." + item_id), Rect2(136, 12, 400, 50), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("arena_shop.%s_desc" % item_id), Rect2(136, 62, 400, 34), 22, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("arena_shop.limit", [bought, limit]), Rect2(136, 90, 400, 26), 20, Px.GOLD if bought < limit else Color("#ff8a80"), HORIZONTAL_ALIGNMENT_LEFT), r.size)
	row.add_child(ov)
	var buy := PxButton.colored("yellow" if bought < limit else "blue", Px.num(price) if bought < limit else DB.t("arena_shop.sold_out"), Vector2(250, 92), 32)
	if bought < limit:
		buy.icon = Px.tex("icon_medal")
		buy.icon_rect = Rect2(18, 18, 56, 56)
		buy.text_rect = Rect2(70, 0, 170, 92)
	buy.position = Vector2(r.size.x - 270, (r.size.y - 92) * 0.5)
	buy.pressed.connect(func() -> void: _buy(item_id, ""))
	row.add_child(buy)
	return row


func _ask_card(id: String, price: int) -> void:
	var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("arena_shop.card"),
		"text": "%s\n%s" % [DB.unit_name(id), DB.t("arena.honor", [Px.num(price)])], "ok": DB.t("common.buy")})
	c.connect("confirmed", func() -> void: _buy("card", id))


func _buy(item_id: String, hero_id: String) -> void:
	var res := Game.profile.buy_arena_item(item_id, hero_id)
	if not bool(res["ok"]):
		Game.app.toast(String(res["error"]))
		Sfx.play("error")
		return
	Sfx.play("coin")
	if item_id == "card":
		Game.app.toast(DB.t("arena_shop.bought", [DB.unit_name(hero_id)]))
	else:
		Game.app.toast(DB.t("shop.bought"))
	_rebuild()
