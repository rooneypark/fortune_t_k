extends PxPopup
## "획득!" pop-up listing rewards. Params: reward (dict), items (array of gained
## hero / treasure infos), title.
## 자리는 8차 시안(design/art/ui_src/보상8_완성화면.png)에서 잰 화면 px 그대로: 금색 제목 띠 위에 보물 상자,
## 보상 칸 한 줄(4칸 기준, 많으면 좁힌다), 그 아래 이름 줄, 빨간 확인 버튼. 닫기 버튼은 없다.

const FRAME := Rect2(148, 648, 728, 536)
const TITLE := Rect2(250, 610, 524, 96)
const CHEST := Rect2(432, 474, 160, 150)
const SLOTS := Rect2(178, 761, 668, 157)        # 칸 한 줄 (칸 161, 간격 169)
const LINE := Rect2(178, 939, 668, 100)
const OK := Rect2(310, 1057, 404, 108)

var _reward: Dictionary = {}
var _items: Array = []


func setup(p: Dictionary) -> void:
	title = String(p.get("title", DB.t("reward.title")))
	title_size = 40
	show_close = false
	_reward = p.get("reward", {})
	_items = p.get("items", [])
	panel_rect = Rect2(112, 520, 800, 700)
	use_kit(FRAME, TITLE, Rect2(), "kit_frame", "kit_title_gold")
	Sfx.play("coin")


func build() -> void:
	var entries: Array = []
	for k: String in _reward:
		# 재료(mats)는 아래 items에 낱개로 들어온다
		if k.begins_with("_") or k == "mats" or k == "boxes" or k == "skin":
			continue
		entries.append({k: _reward[k]})
	for it: Dictionary in _items:
		if String(it.get("type", "")) == "treasure":
			entries.append({"treasure": String(it["tid"])})
		elif String(it.get("type", "")) == "material":
			entries.append({"material": it})
		elif String(it.get("type", "")) == "hero":
			entries.append({"hero": String(it["id"])})
	var chest := DrawLayer.make(func(ci: Control) -> void: Px.fit(ci, Px.tex("icon_chest"), Rect2(Vector2.ZERO, ci.size)))
	chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(chest, CHEST)
	var n := maxi(1, entries.size())
	var step := minf(169.0, SLOTS.size.x / n)
	var cw := minf(161.0, step - 8.0)
	var x0 := SLOTS.position.x + (SLOTS.size.x - (step * (n - 1) + cw)) * 0.5
	var labels: Array = []
	for i in entries.size():
		var e: Dictionary = entries[i]
		var k := String(e.keys()[0])
		var r := Rect2(x0 + i * step, SLOTS.position.y, cw, SLOTS.size.y)
		var lab := DB.unit_name(String(e[k])) if k == "hero" else W.reward_text(e)
		labels.append(lab)
		var ic := "icon_chest" if k == "treasure" else ("" if k == "hero" else W.reward_icon(e))
		var c := DrawLayer.make(func(ci: Control) -> void:
			Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
			if ic != "":
				var s := minf(ci.size.x, ci.size.y) * 0.5
				Px.fit(ci, Px.tex(ic), Rect2((ci.size.x - s) * 0.5, 20, s, s))
			Px.paragraph(ci, lab, Rect2(8, ci.size.y - 54, ci.size.x - 16, 44), 18 if n > 4 else 20, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4))
		_place(c, r)
		if k == "hero":
			var pr := Rect2(r.position + Vector2((cw - 84) * 0.5, 16), Vector2(84, 84))
			_place(W.portrait(String(e[k]), pr.size), pr)
	var line := DrawLayer.make(func(ci: Control) -> void:
		Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
		Px.paragraph(ci, " · ".join(labels) if not labels.is_empty() else "-", Rect2(20, 10, ci.size.x - 40, ci.size.y - 20), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_CENTER, 4))
	_place(line, LINE)
	var ok := PxButton.make("kit_btn_red", true, OK.size)
	ok.font_size = 36
	ok.text = DB.t("common.ok")
	ok.pressed.connect(close)
	_place(ok, OK)
