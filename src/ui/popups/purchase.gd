extends PxPopup
## 결제 확인 (개발용 가상 결제). 실제 스토어 결제 연동 전이라 돈은 나가지 않는다.
## Params: id, name, desc, price.
## 자리는 8차 시안(design/art/ui_src/구매확인8_완성화면.png)에서 잰 화면 px 그대로. 닫기 버튼은 없다 (취소 버튼).
## 시안에 없는 한 줄("개발용 가상 결제" 안내)을 버튼 아래에 더해 창이 60px 길다.

const FRAME := Rect2(148, 622, 728, 622)
const TITLE := Rect2(248, 584, 528, 98)
const PIC := Rect2(420, 696, 184, 172)
const LINE_A := Rect2(190, 878, 644, 79)
const LINE_B := Rect2(190, 963, 644, 77)
const BTN_NO := Rect2(194, 1054, 308, 108)
const BTN_YES := Rect2(522, 1054, 308, 108)
const NOTE := Rect2(190, 1170, 644, 56)

var _p: Dictionary


func setup(p: Dictionary) -> void:
	_p = p
	title = DB.t("purchase.title")
	title_size = 40
	show_close = false
	panel_rect = Rect2(92, 500, 840, 760)
	use_kit(FRAME, TITLE)


func build() -> void:
	var id := String(_p["id"])
	var icon := "icon_gold" if id == "monthly" or id.begins_with("g") else "tab_pack"
	var body := DrawLayer.make(func(ci: Control) -> void:
		var o := Vector2(LINE_A.position.x, PIC.position.y)
		var pr := Rect2(PIC.position - o, PIC.size)
		Px.nine(ci, "kit_box", pr)
		Px.fit(ci, Px.tex(icon), pr.grow(-34))
		var ra := Rect2(LINE_A.position - o, LINE_A.size)
		Px.nine(ci, "kit_box", ra)
		Px.text(ci, String(_p["name"]), Rect2(ra.position + Vector2(22, 0), Vector2(ra.size.x - 44, 44)), 30, Px.GOLD)
		Px.text(ci, String(_p["desc"]), Rect2(ra.position + Vector2(22, 42), Vector2(ra.size.x - 44, 30)), 18, Px.WHITE)
		var rb := Rect2(LINE_B.position - o, LINE_B.size)
		Px.nine(ci, "kit_box", rb)
		Px.text(ci, Px.won(int(_p["price"])), rb, 38, Px.WHITE)
		Px.paragraph(ci, DB.t("purchase.mock"), Rect2(NOTE.position - o, NOTE.size), 17, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 3))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_put(body, Rect2(LINE_A.position.x, PIC.position.y, LINE_A.size.x, NOTE.end.y - PIC.position.y))
	var no := PxButton.make("kit_box", true, BTN_NO.size)
	no.font_size = 34
	no.text = DB.t("common.cancel")
	no.pressed.connect(close)
	_put(no, BTN_NO)
	var yes := PxButton.make("kit_btn_red", true, BTN_YES.size)
	yes.font_size = 34
	yes.text = DB.t("purchase.pay")
	yes.pressed.connect(func() -> void:
		var rw := Game.profile.purchase(String(_p["id"]))
		var gained: Array = rw.get("_gained", [])
		Sfx.play("coin")
		close()
		if rw.is_empty():
			Game.app.toast(DB.t("shop.sold_out"))
		else:
			Game.app.popup("reward", {"title": DB.t("purchase.done"), "reward": rw, "items": gained}))
	_put(yes, BTN_YES)


func _put(c: Control, r: Rect2) -> void:
	if _art:
		_place(c, r)
	else:
		put(c, Rect2(r.position - panel_rect.position, r.size))
