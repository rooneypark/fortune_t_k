class_name Px
extends RefCounted
## Pixel UI look (화면 설계서 §1-2): cut parts from res://assets/ui (9-slice
## margins in cuts.json), the Galmuri pixel font, white text with a navy outline,
## and the palette. Coordinates are the 1024 x 1792 logical canvas.

const UI := "res://assets/ui/"
const CANVAS := Vector2(1024, 1792)
const INK := Color("#14181f")
const WHITE := Color("#ffffff")
const GOLD := Color("#ffd447")
const GOLD_DARK := Color("#c8901c")
const PANEL := Color("#5a3a22")
const PANEL_DARK := Color("#3e2817")
const PANEL_DEEP := Color("#24170d")
const EDGE := Color("#c99a5e")
const RED := Color("#d73734")
const GREEN := Color("#2cb178")
const BLUE := Color("#8a5a2e")
const YELLOW := Color("#ebb22d")
const WOOD := Color("#69442a")
const HP_RED := Color("#d83a34")
const HP_GREEN := Color("#5fbf3a")
const BAR_BG := Color("#22170f")
const MUTED := Color("#cdb994")
const SHADER := preload("res://src/ui/kit/unit.gdshader")

## 선 UI (2026-11-22): 나무·철 질감 부품 대신 어두운 판 + 선 테두리만 코드로 그린다.
## Codex 부품이 오면 false로 돌리고 cuts.json 부품을 쓴다 (design/ux/UI-테마-기획서.md).
const LINE_UI := true
## part name -> [fill, line, line width]. 부품 이름 그대로 두고 그리는 법만 바꾼다.
const LINE_STYLE := {
	"tab_yellow": ["#3b3113", "#ffd447", 3], "tab_red": ["#4a1717", "#ff6b5b", 3],
	"tab_purple": ["#2c1d45", "#c79bff", 3], "tab_wood": ["#1b222c", "#8e9bab", 3],
	"tab_wood_on": ["#1b222c", "#ffd447", 3], "tab_blue": ["#152536", "#6fb6ff", 3],
	"panel_slot": ["#0d1117", "#4f5a6a", 2], "panel_small": ["#171e27", "#a7b2c0", 2],
	"panel_chip": ["#171e27", "#a7b2c0", 2], "btn_small": ["#171e27", "#a7b2c0", 2],
	"panel_ctrl": ["#121820", "#d5dce5", 3], "panel_wide": ["#121820", "#d5dce5", 3],
	"plate_title": ["#1b222c", "#ffd447", 3], "plate_lever": ["#1b222c", "#ffd447", 3],
	"tile": ["#0d111799", "#3a4452", 2], "frame_portrait": ["#0d1117", "#d5dce5", 3],
}
const LINE_DEFAULT := ["#141a22", "#cfd6df", 3]

## 배치 지도(점검): true인 동안 그려지는 글자·그림·버튼·판 자리를 화면 좌표로 모은다.
## tools/layout_dump.gd 가 켜고 끈다 (design/ux/규격/).
static var recording := false
static var records: Array = []

static var _tex: Dictionary = {}
static var _skins: Dictionary = {}
## 9-slice 그림 부품 (assets/ui/nine.json: 이름 -> 가장자리 여백 px) — tools/import_dialog_ui.py
static var _nine_margin: Dictionary = {}
static var _nines: Dictionary = {}
static var _meta: Dictionary = {}
static var _font: FontFile
static var _font_thin: FontFile
## Global text scale from settings (글자 크기 작게/보통/크게).
static var text_scale := 1.0


## Records one drawn slot in canvas coordinates (layout map). [param kind]:
## text / image / button / panel.
static func rec(ci: CanvasItem, kind: String, r: Rect2, label: String, extra: Dictionary = {}) -> void:
	if not recording or ci == null or not ci.is_visible_in_tree():
		return
	var xf := ci.get_global_transform()
	var a := xf * r.position
	var b := xf * r.end
	var box := Rect2(a, b - a).abs()
	if box.size.x < 2.0 or box.size.y < 2.0:
		return
	records.append({"kind": kind, "x": roundi(box.position.x), "y": roundi(box.position.y),
		"w": roundi(box.size.x), "h": roundi(box.size.y), "label": label, "node": String(ci.get_path()),
		"sx": xf.get_scale().x, "extra": extra})


static func _tex_label(t: Texture2D) -> String:
	if t == null:
		return ""
	var p := t.resource_path
	return p.get_file().get_basename() if p != "" else "(그림)"


static func tex(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var t: Texture2D = null
	var paths: Array = [UI + name + ".png", UI + name + ".webp", UI + "icons/" + name + ".png",
		"res://assets/bg/" + name + ".png", "res://assets/bg/" + name + ".webp", name]
	for p: String in paths:
		if ResourceLoader.exists(p):
			t = load(p)
			break
	if t == null:
		# 가져오기(import) 캐시가 낡아 새 png가 아직 리소스로 없을 때도 화면에서 빠지지 않게
		# 원본 png를 직접 읽는다 (예: 로비 오른쪽 가방 · 모집 버튼).
		for p: String in [UI + name + ".png", UI + "icons/" + name + ".png", "res://assets/bg/" + name + ".png"]:
			if FileAccess.file_exists(p):
				var img := Image.load_from_file(ProjectSettings.globalize_path(p))
				if img != null and not img.is_empty():
					t = ImageTexture.create_from_image(img)
					break
	if t == null:
		push_warning("Px: missing texture " + name)
	_tex[name] = t
	return t


## 통째 그림 부품(버튼 · 성문 · 성벽)의 그림 파일이 있는가. 선 UI 중에도 그림이 있으면 그림을 쓴다
## (임시 그림 tools/draw_ui_placeholders.py, 정식 그림은 같은 이름으로 덮어쓴다).
static func has_art(name: String) -> bool:
	return name != "" and (ResourceLoader.exists(UI + name + ".png") or FileAccess.file_exists(UI + name + ".png"))


## 9-slice로 쓰는 그림 부품인가 (nine.json에 여백이 있고 그림이 있다).
static func has_nine(name: String) -> bool:
	if _nine_margin.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(UI + "nine.json")) if FileAccess.file_exists(UI + "nine.json") else null
		_nine_margin = parsed if parsed is Dictionary else {"_": 0}
	return _nine_margin.has(name) and has_art(name)


## 그림 부품을 9-slice로 그린다: 가장자리(여백)는 그대로, 가운데만 늘어난다. 선 UI 설정과 상관없이 그림으로.
static func nine(ci: CanvasItem, name: String, r: Rect2, mod: Color = Color.WHITE) -> void:
	if not has_nine(name):
		draw_skin(ci, name, r, mod)
		return
	if not _nines.has(name):
		var sb := StyleBoxTexture.new()
		sb.texture = tex(name)
		# 여백: 숫자 하나(네 방향 같게) 또는 [왼, 위, 오른, 아래]
		var m: Variant = _nine_margin[name]
		if m is Array:
			sb.texture_margin_left = float(m[0])
			sb.texture_margin_top = float(m[1])
			sb.texture_margin_right = float(m[2])
			sb.texture_margin_bottom = float(m[3])
		else:
			sb.set_texture_margin_all(float(m))
		_nines[name] = sb
	var st := _nines[name] as StyleBoxTexture
	rec(ci, "panel", r, name)
	st.modulate_color = mod
	ci.draw_style_box(st, r)
	st.modulate_color = Color.WHITE


## 글자 버튼 → 아이콘 버튼 (design/ux/UI-그림-규격.md §5). 문구 열쇠 -> 아이콘 파일.
## 버튼 글자가 이 문구와 같으면 글자 대신 아이콘을 그린다 (글자는 툴팁으로 남는다).
const ICON_FOR := {
	"common.ok": "act_ok", "common.cancel": "act_cancel", "common.buy": "act_buy",
	"absorb.do": "act_absorb", "wave.next_btn": "act_play",
	"pause.retreat": "act_retreat", "pause.retreat_ok": "act_retreat",
	"treasure.enhance": "act_enhance", "treasure.dismantle": "act_break", "purchase.pay": "act_buy",
	"mail.get": "act_claim", "mail.get_all": "act_claim_all", "mail.delete": "act_trash", "mail.claimed": "act_done",
	"missions.go": "act_go", "hero.auto_equip": "act_auto", "hero.unequip": "act_unequip",
	"arena.shop": "act_shop", "arena.fight": "icon_swords", "arena.buy": "act_ticket",
	"synth.open": "act_synth", "result.continue": "act_revive", "result.lobby": "act_home",
	"result.next": "act_next", "result.again": "act_retry", "stage.odds": "act_odds", "quit.ok": "act_exit",
	"heroes.all": "flt_all", "heroes.mine": "flt_mine",
	"heroes.tab_heroes": "tab_hero", "heroes.tab_troops": "tab_soldier",
	"hero.tab_up": "tab_growth", "hero.tab_star": "tab_trait", "hero.tab_treasure": "tab_gear",
	"missions.daily": "tab_daily", "missions.weekly": "tab_weekly", "missions.achieve": "tab_trophy",
	"shop.t_rec": "tab_pick", "shop.t_dia": "icon_gold", "shop.t_gold": "icon_rice", "shop.t_pack": "tab_pack",
}
static var _icon_by_text: Dictionary = {}


## Icon file for a button label, or "" (the label stays text).
static func icon_for(label_text: String) -> String:
	if label_text == "":
		return ""
	if _icon_by_text.is_empty():
		for k: String in ICON_FOR:
			_icon_by_text[DB.t(k)] = ICON_FOR[k]
	return String(_icon_by_text.get(label_text, ""))


static func _cut_meta() -> Dictionary:
	if _meta.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(UI + "cuts.json"))
		_meta = parsed if parsed is Dictionary else {}
	return _meta


## [fill, line, width] of a part in line mode.
static func line_style(name: String) -> Array:
	var st: Array = LINE_STYLE.get(name.trim_suffix("_pressed"), LINE_DEFAULT)
	return [Color(String(st[0])), Color(String(st[1])), float(st[2])]


## Draws part [param name] as a frame. Line mode: fill + pixel border; else 9-slice art.
static func draw_skin(ci: CanvasItem, name: String, r: Rect2, mod: Color = Color.WHITE) -> void:
	rec(ci, "panel", r, name)
	if LINE_UI:
		var st := line_style(name)
		var w: float = st[2]
		ci.draw_rect(r, (st[0] as Color) * mod)
		ci.draw_rect(r.grow(-w * 0.5), (st[1] as Color) * mod, false, w)
		return
	var sb := skin(name) as StyleBoxTexture
	sb.modulate_color = mod
	ci.draw_style_box(sb, r)
	sb.modulate_color = Color.WHITE


## 9-slice style box of a framed part (margin from cuts.json). Line mode: flat box.
static func skin(name: String, margin: float = -1.0) -> StyleBox:
	var key := "%s:%d" % [name, int(margin)]
	if _skins.has(key):
		return _skins[key]
	if LINE_UI:
		var st := line_style(name)
		var fb := StyleBoxFlat.new()
		fb.bg_color = st[0]
		fb.border_color = st[1]
		fb.set_border_width_all(int(st[2]))
		fb.anti_aliasing = false
		_skins[key] = fb
		return fb
	var sb := StyleBoxTexture.new()
	sb.texture = tex(name)
	var m := margin if margin >= 0.0 else float(_cut_meta().get(name, {}).get("margin", 14))
	sb.set_texture_margin_all(m)
	_skins[key] = sb
	return sb


static func font() -> FontFile:
	if _font == null:
		_font = load("res://assets/fonts/Galmuri11-Bold.ttf")
		_setup_font(_font)
	return _font


static func _setup_font(f: FontFile) -> void:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false


static func fs(size: int) -> int:
	return int(round(size * text_scale))


static func text_width(s: String, size: int) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs(size)).x


## White text with a dark outline (size / 6, min 4px), aligned in [param r].
## Shrinks to fit the width when needed.
static func text(ci: CanvasItem, s: String, r: Rect2, size: int, color: Color = WHITE,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER, outline: int = -1, f: Font = null) -> void:
	if s == "" or size < 4:
		return
	var fnt: Font = f if f != null else font()
	var sz := fs(size)
	var w := fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	while w > r.size.x and sz > 12:
		sz -= 2
		w = fnt.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	if recording:
		var gh := fnt.get_ascent(sz) + fnt.get_descent(sz)
		rec(ci, "text", r, s, {"req": fs(size), "fs": sz, "tw": w, "th": gh, "align": align})
	var x := r.position.x + (r.size.x - w) * 0.5
	if align == HORIZONTAL_ALIGNMENT_LEFT:
		x = r.position.x
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x = r.end.x - w
	var y := r.position.y + (r.size.y + fnt.get_ascent(sz) - fnt.get_descent(sz)) * 0.5
	var ow := outline if outline >= 0 else maxi(4, sz / 6)
	var p := Vector2(x, y).round()
	if ow > 0:
		ci.draw_string_outline(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, ow, INK)
	ci.draw_string(fnt, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, color)


## Multi-line text (wraps at the width), top aligned.
static func paragraph(ci: CanvasItem, s: String, r: Rect2, size: int, color: Color = WHITE,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 0) -> void:
	var fnt := font()
	var sz := fs(size)
	var lines := _wrap(s, r.size.x, sz)
	var lh := sz * 1.35
	rec(ci, "text", r, s, {"para": true, "req": sz, "fs": sz, "need_h": lines.size() * lh, "lines": lines.size()})
	var was := recording
	recording = false
	var y := r.position.y
	for line: String in lines:
		text(ci, line, Rect2(r.position.x, y, r.size.x, lh), size, color, align, outline)
		y += lh
	recording = was


static func _wrap(s: String, width: float, sz: int) -> Array:
	var out: Array = []
	for para in s.split("\n"):
		var cur := ""
		for ch in para:
			var probe := cur + ch
			if font().get_string_size(probe, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x > width and cur != "":
				out.append(cur)
				cur = ch
			else:
				cur = probe
		out.append(cur)
	return out


## Draws [param t] fitted and centred in [param r].
static func fit(ci: CanvasItem, t: Texture2D, r: Rect2, modulate: Color = Color.WHITE) -> void:
	if t == null:
		return
	rec(ci, "image", r, _tex_label(t))
	var ts := t.get_size()
	var k := minf(r.size.x / ts.x, r.size.y / ts.y)
	var sz := (ts * k).round()
	ci.draw_texture_rect(t, Rect2((r.get_center() - sz * 0.5).round(), sz), false, modulate)


## Draws [param t] covering [param r] (cropped), like a background.
static func cover(ci: CanvasItem, t: Texture2D, r: Rect2, modulate: Color = Color.WHITE) -> void:
	if t == null:
		return
	rec(ci, "image", r, _tex_label(t))
	var ts := t.get_size()
	var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src_size := r.size / k
	var src := Rect2((ts - src_size) * 0.5, src_size)
	ci.draw_texture_rect_region(t, r, src, modulate)


## Pixel panel drawn without textures (outer ink, inner light edge) — for
## panels that need colours the cut parts do not have.
static func box(ci: CanvasItem, r: Rect2, fill: Color, _edge: Color = EDGE, _ink: Color = INK, _thick: float = 4.0) -> void:
	# UI 키트로 통일: 밝은 바탕 = 나무 팻말판, 어두운 바탕 = 철테 + 어두운 안판.
	draw_skin(ci, "plate_title" if fill.get_luminance() > 0.5 else "panel_slot", r, Color(1, 1, 1, fill.a))


## Gold-trimmed red ribbon title with notched tails.
static func ribbon(ci: CanvasItem, r: Rect2, s: String, size: int = 48, _base: Color = Color("#c8352e")) -> void:
	# 제목판: 로비 팻말과 같은 나무판 (UI 키트 plate_title) — 빨간 리본 대신 같은 재질로 통일.
	var h := minf(r.size.y, 104.0)
	var body := Rect2(r.position.x, r.position.y + (r.size.y - h) * 0.5, r.size.x, h)
	ci.draw_style_box(skin("plate_title"), body)
	text(ci, s, body.grow(-16), mini(size, 46), WHITE)


## Wooden plate (팻말) with text.
static func plate(ci: CanvasItem, r: Rect2, s: String, size: int = 36, color: Color = WHITE) -> void:
	ci.draw_style_box(skin("plate_lever"), r)
	text(ci, s, r.grow(-10), size, color)


## Horizontal bar with frame. [param ratio] 0..1.
static func bar(ci: CanvasItem, r: Rect2, ratio: float, fill: Color, bg: Color = BAR_BG) -> void:
	ci.draw_rect(r, INK)
	ci.draw_rect(r.grow(-3), bg)
	var inner := r.grow(-5)
	var w := floorf(inner.size.x * clampf(ratio, 0.0, 1.0))
	if w > 0:
		ci.draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill)
		ci.draw_rect(Rect2(inner.position, Vector2(w, maxf(2.0, floorf(inner.size.y * 0.3)))), fill.lightened(0.3))


## Row of stars (성급). [param filled] of [param total].
static func stars(ci: CanvasItem, center: Vector2, filled: int, total: int, size: float = 28.0) -> void:
	var on := tex("ic_star")
	var off := tex("ic_star_off")
	var gap := size * 0.92
	var x0 := center.x - gap * total * 0.5
	rec(ci, "image", Rect2(x0, center.y - size * 0.5, gap * total, size), "ic_star")
	for i in total:
		var t := on if i < filled else off
		if t != null:
			ci.draw_texture_rect(t, Rect2(Vector2(x0 + i * gap, center.y - size * 0.5).round(), Vector2(size, size)), false)


## "12500" -> "12,500".
static func num(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


## Short form for big counters: 15,750 / 1.2만 / 3.4억.
static func short(n: int) -> String:
	if n >= 100000000:
		return "%.1f억" % (n / 100000000.0)
	if n >= 1000000:
		return "%d만" % (n / 10000)
	return num(n)


static func won(n: int) -> String:
	return "₩" + num(n)


static func unit_material(hue: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("hue", hue)
	return m


static func label(s: String, size: int, color: Color = WHITE, outline: int = -1) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", fs(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline if outline >= 0 else maxi(4, size / 6) * 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Draws [param t] in [param r], mirrored left-right when [param flip].
## [param base] = the canvas item's current draw offset (restored afterwards).
static func tex_rect(ci: CanvasItem, t: Texture2D, r: Rect2, modulate: Color = Color.WHITE, flip := false, base := Vector2.ZERO, src := Rect2()) -> void:
	rec(ci, "image", r, _tex_label(t))
	if flip:
		ci.draw_set_transform(base + Vector2(r.position.x * 2.0 + r.size.x, 0), 0.0, Vector2(-1, 1))
	if src.size == Vector2.ZERO:
		ci.draw_texture_rect(t, r, false, modulate)
	else:
		ci.draw_texture_rect_region(t, r, src, modulate)
	if flip:
		ci.draw_set_transform(base)
