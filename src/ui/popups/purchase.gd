extends PxPopup
## 결제 확인 (개발용 가상 결제). 실제 스토어 결제 연동 전이라 돈은 나가지 않는다.
## Params: id, name, desc, price.

var _p: Dictionary


func setup(p: Dictionary) -> void:
	_p = p
	title = DB.t("purchase.title")
	panel_rect = Rect2(92, 500, 840, 760)


func build() -> void:
	var body := DrawLayer.make(func(ci: Control) -> void:
		var r := Rect2(Vector2.ZERO, ci.size)
		Px.text(ci, String(_p["name"]), Rect2(0, 0, r.size.x, 64), 44, Px.GOLD)
		Px.paragraph(ci, String(_p["desc"]), Rect2(0, 76, r.size.x, 90), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
		var pr := Rect2(150, 190, r.size.x - 300, 90)
		ci.draw_rect(pr, Px.INK)
		ci.draw_rect(pr.grow(-4), Color("#2b1c11"))
		Px.text(ci, Px.won(int(_p["price"])), pr, 48, Px.WHITE)
		var warn := Rect2(0, 310, r.size.x, 120)
		ci.draw_rect(warn, Color(1, 0.75, 0.2, 0.12))
		ci.draw_rect(Rect2(warn.position, Vector2(6, warn.size.y)), Px.GOLD)
		Px.paragraph(ci, DB.t("purchase.mock"), warn.grow(-18), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 4), Vector2(720, 440))
	put(body, Rect2(60, 100, 720, 440))
	var no := PxButton.colored("blue", DB.t("common.cancel"), Vector2(330, 130), 40)
	no.pressed.connect(close)
	put(no, Rect2(70, 580, 330, 130))
	var yes := PxButton.colored("yellow", DB.t("purchase.pay"), Vector2(330, 130), 40)
	yes.pressed.connect(func() -> void:
		var rw := Game.profile.purchase(String(_p["id"]))
		var gained: Array = rw.get("_gained", [])
		Sfx.play("coin")
		close()
		if rw.is_empty():
			Game.app.toast(DB.t("shop.sold_out"))
		else:
			Game.app.popup("reward", {"title": DB.t("purchase.done"), "reward": rw, "items": gained}))
	put(yes, Rect2(440, 580, 330, 130))
