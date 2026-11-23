extends PxPopup
## 군웅 상점 (콘텐츠-기획-v5 §7.1, 메타 §3.10): 군공으로만 산다, 매주 초기화.
## 영웅 보물 · 군량 · 금 줄. (장수 카드는 없앴다: 성급은 전투 중 흡수로만 오른다.)

const ROW_H := 132.0

var _body: Control


func setup(_p: Dictionary) -> void:
	title = DB.t("arena_shop.title")
	panel_rect = Rect2(40, 520, 944, 680)


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
	for item_id in ["treasure", "rice", "gold"]:
		_body.add_child(_item_row(item_id, Rect2(30, y, w - 60, ROW_H - 10)))
		y += ROW_H


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
	buy.pressed.connect(func() -> void: _buy(item_id))
	row.add_child(buy)
	return row


func _buy(item_id: String) -> void:
	var res := Game.profile.buy_arena_item(item_id)
	if not bool(res["ok"]):
		Game.app.toast(String(res["error"]))
		Sfx.play("error")
		return
	Sfx.play("coin")
	Game.app.toast(DB.t("shop.bought"))
	_rebuild()
