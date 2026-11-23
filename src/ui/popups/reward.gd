extends PxPopup
## "획득!" pop-up listing rewards. Params: reward (dict), items (array of gained
## hero / treasure infos), title.

var _reward: Dictionary = {}
var _items: Array = []


func setup(p: Dictionary) -> void:
	title = String(p.get("title", DB.t("reward.title")))
	_reward = p.get("reward", {})
	_items = p.get("items", [])
	panel_rect = Rect2(112, 520, 800, 700)
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
	var n := maxi(1, entries.size())
	var cell := minf(200.0, 700.0 / n)
	var x0 := (800 - cell * n) * 0.5
	for i in entries.size():
		var e: Dictionary = entries[i]
		var k := String(e.keys()[0])
		var c: Control
		if k == "hero":
			c = W.portrait(String(e[k]), Vector2(cell - 20, cell - 20))
		else:
			var lab := W.reward_text(e)
			var ic := "icon_chest" if k == "treasure" else W.reward_icon(e)
			c = DrawLayer.make(func(ci: Control) -> void:
				Px.box(ci, Rect2(Vector2.ZERO, Vector2(ci.size.x, ci.size.x)), Px.PANEL_DEEP)
				Px.fit(ci, Px.tex(ic), Rect2(ci.size.x * 0.2, ci.size.x * 0.12, ci.size.x * 0.6, ci.size.x * 0.6))
				Px.paragraph(ci, lab, Rect2(0, ci.size.x + 6, ci.size.x, ci.size.y - ci.size.x - 6), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4))
			c.size = Vector2(cell - 20, cell + 100)
		put(c, Rect2(x0 + i * cell + 10, 150, c.size.x, c.size.y))
	var ok := PxButton.colored("yellow", DB.t("common.ok"), Vector2(360, 130), 44)
	ok.pressed.connect(close)
	put(ok, Rect2(220, 520, 360, 130))
