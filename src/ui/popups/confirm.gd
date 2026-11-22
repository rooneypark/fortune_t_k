extends PxPopup
## Yes / no question. Params: title, text, ok, cancel, cost_icon, cost.

signal confirmed

var _text := ""
var _ok := ""
var _cancel := ""


func setup(p: Dictionary) -> void:
	title = String(p.get("title", ""))
	_text = String(p.get("text", ""))
	_ok = String(p.get("ok", DB.t("common.ok")))
	_cancel = String(p.get("cancel", DB.t("common.cancel")))
	panel_rect = Rect2(92, 560, 840, 620)


func build() -> void:
	var body := DrawLayer.make(func(ci: Control) -> void: Px.paragraph(ci, _text, Rect2(0, 0, ci.size.x, ci.size.y), 36, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6))
	put(body, Rect2(60, 110, 720, 260))
	var no := PxButton.colored("blue", _cancel, Vector2(330, 130), 40)
	no.pressed.connect(close)
	put(no, Rect2(70, 430, 330, 130))
	var yes := PxButton.colored("yellow", _ok, Vector2(330, 130), 40)
	yes.pressed.connect(func() -> void:
		confirmed.emit()
		close())
	put(yes, Rect2(440, 430, 330, 130))
