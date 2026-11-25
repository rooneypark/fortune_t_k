extends PxPopup
## Yes / no question. Params: title, text, ok, cancel, cost_icon, cost.
## 구매 확인 창(8차 시안 구매확인8_완성화면.png)과 같은 틀 · 같은 버튼 두 개 (어두운 취소 · 빨간 확인). 닫기 버튼은 없다.

signal confirmed

const FRAME := Rect2(148, 690, 728, 490)
const TITLE := Rect2(248, 652, 528, 98)
const TEXT := Rect2(190, 770, 644, 270)
const BTN_NO := Rect2(194, 1054, 308, 108)
const BTN_YES := Rect2(522, 1054, 308, 108)

var _text := ""
var _ok := ""
var _cancel := ""


func setup(p: Dictionary) -> void:
	title = String(p.get("title", ""))
	title_size = 38
	show_close = false
	_text = String(p.get("text", ""))
	_ok = String(p.get("ok", DB.t("common.ok")))
	_cancel = String(p.get("cancel", DB.t("common.cancel")))
	panel_rect = Rect2(92, 560, 840, 620)
	use_kit(FRAME, TITLE)


func build() -> void:
	var body := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.paragraph(ci, _text, Rect2(24, 20, ci.size.x - 48, ci.size.y - 40), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(body, TEXT)
	var no := PxButton.make("kit_box", true, BTN_NO.size)
	no.font_size = 34
	no.text = _cancel
	no.pressed.connect(close)
	_place(no, BTN_NO)
	var yes := PxButton.make("kit_btn_red", true, BTN_YES.size)
	yes.font_size = 34
	yes.text = _ok
	yes.pressed.connect(func() -> void:
		confirmed.emit()
		close())
	_place(yes, BTN_YES)
