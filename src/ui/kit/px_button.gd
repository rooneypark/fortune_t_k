class_name PxButton
extends BaseButton
## Button (or static panel) made of a cut part: whole picture or 9-slice, with
## optional icon and text. Pressed = sinks 4px and darkens; disabled = grey.
## Plays the click sound and a small squash on release.

@export var part := ""
@export var nine := false
@export var icon: Texture2D
## Icon box in local px; empty = centred, 60 % of the height.
var icon_rect := Rect2()
var text := "":
	set(v):
		text = v
		queue_redraw()
## Small second line under the text (e.g. a cost).
var sub := "":
	set(v):
		sub = v
		queue_redraw()
var sub_icon: Texture2D
var text_rect := Rect2()
var font_size := 40
var sub_size := 30
var text_color := Px.WHITE
var text_align := HORIZONTAL_ALIGNMENT_CENTER
var press_depth := 3.0
var static_panel := false
var sound := "click"
## Gold frame (selected tab / highlighted choice).
var highlight := false:
	set(v):
		highlight = v
		queue_redraw()
## Red notification dot (우편·임무 알림).
var badge := false:
	set(v):
		badge = v
		queue_redraw()
## Breathing glow to draw the eye (튜토리얼, 꽝일 때 밀기).
var pulse := false:
	set(v):
		pulse = v
		set_process(pulse)
		queue_redraw()
## Extra draw on top: Callable(button: PxButton, offset: Vector2).
var overlay: Callable
var _t := 0.0

## Line mode (임시 UI): whole-picture parts become a framed box with a text label
## (strings_ko "btn.<part>"). Sizes the old pictures had, for make(part) without a size.
const LINE_SIZE := {
	"btn_settings": Vector2(108, 102), "btn_mail": Vector2(120, 129), "btn_mission": Vector2(120, 129),
	"btn_bag": Vector2(120, 129), "btn_recruit": Vector2(120, 129), "sign_battle": Vector2(150, 147),
	"btn_arena": Vector2(150, 147), "sign_arena": Vector2(150, 147), "btn_pause": Vector2(87, 81),
	"btn_plus": Vector2(60, 60), "btn_battle": Vector2(255, 105), "btn_nudge": Vector2(123, 114),
	"btn_advisor": Vector2(123, 114), "btn_speed": Vector2(123, 114), "btn_bench": Vector2(123, 114),
	"lever": Vector2(114, 216), "btn_small": Vector2(96, 87), "frame_portrait": Vector2(147, 186),
	"tile": Vector2(147, 132),
}


static func make(part_name: String, nine_slice := false, sz := Vector2.ZERO) -> PxButton:
	var b := PxButton.new()
	b.part = part_name
	b.nine = nine_slice
	if sz != Vector2.ZERO:
		b.size = sz
	return b


## Coloured chunky button (tab_red / tab_green / tab_blue / tab_yellow / tab_purple 9-slice).
## Shared button (UI kit): kinds wood (보조) · wood_on (선택) · yellow (주요) ·
## red (전투/위험) · purple (다이아). One font rule for every screen:
## the label size follows the button height. [param fsize] is kept for
## callers but capped by that rule.
const KINDS := {"blue": "wood", "green": "yellow"}


static func colored(color: String, label: String, sz: Vector2, fsize := 40) -> PxButton:
	var kind := String(KINDS.get(color, color))
	var b := make("tab_" + kind, true, sz)
	b.text = label
	b.font_size = mini(fsize, font_for(sz.y))
	return b


static func font_for(h: float) -> int:
	return clampi(int(round(h * 0.34)), 22, 40)


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE if static_panel else Control.MOUSE_FILTER_STOP
	button_down.connect(_on_down)
	button_up.connect(queue_redraw)
	pressed.connect(_on_pressed)
	if size == Vector2.ZERO and not nine:
		if Px.LINE_UI and LINE_SIZE.has(part):
			size = LINE_SIZE[part]
		else:
			var t := Px.tex(part)
			if t != null:
				size = t.get_size()
	set_process(pulse)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_down() -> void:
	queue_redraw()
	if Game and Game.settings().get("vibrate", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(10)


func _on_pressed() -> void:
	if sound != "" and not static_panel:
		Sfx.play(sound)


func sunk() -> bool:
	if static_panel or disabled:
		return false
	var m := get_draw_mode()
	return m == DRAW_PRESSED or m == DRAW_HOVER_PRESSED


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var is_sunk := sunk()
	var has_pressed := is_sunk and ResourceLoader.exists(Px.UI + part + "_pressed.png")
	var off := Vector2(0, press_depth if is_sunk else 0.0)
	var mod := Color(0.55, 0.52, 0.5) if disabled else (Color.WHITE if has_pressed else (Color(0.82, 0.78, 0.74) if is_sunk else Color.WHITE))
	var r := Rect2(off, size)
	if not static_panel:
		Px.rec(self, "button", r, text if text != "" else part)
	if pulse and not disabled:
		var a := 0.35 + 0.35 * sin(_t * 6.0)
		draw_rect(r.grow(6), Color(Px.GOLD, a), false, 6.0)
	if part != "" and Px.LINE_UI:
		var lmod := mod if not is_sunk else Color(1.25, 1.25, 1.25)
		Px.draw_skin(self, part, r, lmod)
		if part == "lever":
			_draw_line_lever(r, mod)
		if not nine and icon == null and text == "":
			var key := "btn." + part
			var label := DB.t(key)
			if label != key:
				# 숫자 overlay가 있는 버튼은 글자를 위쪽에 둔다
				var lr := Rect2(r.position + Vector2(4, 0), Vector2(size.x - 8, size.y * (0.62 if overlay.is_valid() else 1.0)))
				if part == "lever":
					lr = Rect2(r.position + Vector2(0, size.y - 40), Vector2(size.x, 36))
				elif part in ["sign_battle", "btn_arena", "sign_arena"]:
					lr = Rect2(r.position + Vector2(0, size.y - 50), Vector2(size.x, 44))
				Px.text(self, label, lr, clampi(int(minf(size.y * 0.3, size.x / maxf(1.0, label.length()) * 0.95)), 18, 40), Px.WHITE * mod)
	elif part != "":
		var use_part := part + "_pressed" if has_pressed else part
		if nine:
			var sb := Px.skin(use_part)
			sb.modulate_color = mod
			draw_style_box(sb, r)
			sb.modulate_color = Color.WHITE
		else:
			var t := Px.tex(part)
			if t != null:
				draw_texture_rect(t, r, false, mod)
	if icon != null:
		var ir := icon_rect
		if ir.size == Vector2.ZERO:
			var h := size.y * 0.6
			ir = Rect2((size - Vector2(h, h)) * 0.5, Vector2(h, h))
		Px.fit(self, icon, Rect2(ir.position + off, ir.size), mod)
	if text != "":
		var tr := text_rect if text_rect.size != Vector2.ZERO else Rect2(Vector2(8, 0), size - Vector2(16, 0))
		if sub != "" and text_rect.size == Vector2.ZERO:
			tr = Rect2(Vector2(8, size.y * 0.08), Vector2(size.x - 16, size.y * 0.5))
		Px.text(self, text, Rect2(tr.position + off, tr.size), font_size, text_color * mod, text_align)
	if sub != "":
		var sr := Rect2(Vector2(8, size.y * 0.55), Vector2(size.x - 16, size.y * 0.36))
		if sub_icon != null:
			var w := Px.text_width(sub, sub_size) + sub_size * 1.2
			var x := (size.x - w) * 0.5
			Px.fit(self, sub_icon, Rect2(Vector2(x, sr.position.y + sr.size.y * 0.5 - sub_size * 0.55) + off, Vector2(sub_size * 1.1, sub_size * 1.1)), mod)
			Px.text(self, sub, Rect2(Vector2(x + sub_size * 1.2, sr.position.y) + off, Vector2(w - sub_size * 1.2, sr.size.y)), sub_size, Px.WHITE * mod, HORIZONTAL_ALIGNMENT_LEFT)
		else:
			Px.text(self, sub, Rect2(sr.position + off, sr.size), sub_size, Px.WHITE * mod)
	if highlight:
		# 선택: 버튼 바깥 금테 (잉크 1칸 + 금 1칸, 아트 픽셀 3px 기준)
		var hr := Rect2(off, size)
		draw_rect(hr.grow(4.5), Px.INK, false, 3.0)
		draw_rect(hr.grow(1.5), Px.GOLD, false, 3.0)
	if overlay.is_valid():
		overlay.call(self, off)
	if badge:
		var c := Vector2(size.x - 14, 14) + off
		draw_circle(c, 15, Px.INK)
		draw_circle(c, 11, Color("#ff3b30"))
		draw_circle(c + Vector2(-3, -3), 4, Color("#ff8a80"))


## Line-mode lever: a slot, a stick and a knob (pulled down while pressed).
func _draw_line_lever(r: Rect2, mod: Color) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var top := r.position.y + r.size.y * 0.18
	var bot := r.position.y + r.size.y * 0.82
	draw_rect(Rect2(cx - 10, top, 20, bot - top), Color("#4f5a6a") * mod, false, 2.0)
	var ky := bot - 20.0 if sunk() else top + 10.0
	draw_line(Vector2(cx, bot), Vector2(cx, ky), Px.WHITE * mod, 4.0)
	draw_circle(Vector2(cx, ky), minf(r.size.x, r.size.y) * 0.12, Color("#ff6b5b") * mod)
