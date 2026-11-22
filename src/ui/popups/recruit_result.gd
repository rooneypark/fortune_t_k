extends PxPopup
## 모집 결과: 카드가 한 장씩 뒤집힌다 (등급 테두리 B 회색·A 파랑·S 보라·
## SS 금, NEW, 카드 +1). 확인 / 10회 더. 누르면 연출 건너뜀.

var cards: Array = []
var count := 1
## "hero" (장수 모집, 다이아) or "soldier" (병사 모집, 골드).
var kind := "hero"
var _t := 0.0
var _shown := 0
var _views: Array = []


func setup(p: Dictionary) -> void:
	cards = p["cards"]
	count = int(p["count"])
	kind = String(p.get("kind", "hero"))
	title = DB.t("recruit.result")
	var rows := ceili(cards.size() / 5.0) if cards.size() > 1 else 1
	var hgt := 120.0 + (rows * 266.0 if cards.size() > 1 else 576.0) + 30.0 + 120.0 + 50.0
	panel_rect = Rect2(32, 896 - hgt * 0.5, 960, hgt)
	dim_closes = false


func build() -> void:
	var n := cards.size()
	var cols := 5 if n > 1 else 1
	var cw := 172.0 if n > 1 else 400.0
	var chh := 250.0 if n > 1 else 560.0
	var rows := ceili(n / float(cols))
	var x0 := (960 - cols * cw - (cols - 1) * 12) * 0.5
	var y0 := 120.0 if n > 1 else 140.0
	for i in n:
		var c: Dictionary = cards[i]
		var id := String(c["id"])
		var holder := Control.new()
		holder.size = Vector2(cw, chh)
		holder.pivot_offset = holder.size * 0.5
		var opts := {"new": bool(c.get("new", false)), "rank": bool(c.get("new", false))}
		if DB.is_soldier(id):
			opts["stars"] = int(Game.profile.troop(id).get("star", 1))
			opts["tag"] = DB.troop_name(id)
		var card := W.hero_card(id, Vector2(cw, chh), opts)
		card.static_panel = true
		holder.add_child(card)
		var back := DrawLayer.make(func(ci: Control) -> void:
			var r := Rect2(Vector2.ZERO, ci.size)
			ci.draw_rect(r, Px.INK)
			ci.draw_rect(r.grow(-4), Px.GOLD_DARK)
			ci.draw_rect(r.grow(-10), Color("#2a1a3a"))
			Px.fit(ci, Px.tex("ic_seal"), Rect2(r.size * 0.25, r.size * 0.5)), Vector2(cw, chh))
		holder.add_child(back)
		var tag := DrawLayer.make(func(ci: Control) -> void:
			if not bool(c.get("new", false)):
				var r := Rect2(0, ci.size.y - 40, ci.size.x, 36)
				ci.draw_rect(r, Color(0, 0, 0, 0.7))
				var txt := DB.t("recruit.card_plus")
				if bool(c.get("honor", false)):
					txt = DB.t("recruit.honor", [int(c.get("honor_amount", 0))])
				elif c.has("gold"):
					txt = DB.t("recruit.gold_plus", [int(c["gold"])])
				Px.text(ci, txt, r, 22, Color("#e0b0ff")), Vector2(cw, chh))
		tag.visible = false
		holder.add_child(tag)
		put(holder, Rect2(x0 + (i % cols) * (cw + 12), y0 + (i / cols) * (chh + 16), cw, chh))
		holder.scale = Vector2(0.0, 0.0)
		_views.append([holder, card, back, tag, String(c.get("rarity", DB.rarity_of(id)))])
	var by := y0 + rows * (chh + 16) + 30
	var ok := PxButton.colored("yellow", DB.t("common.ok"), Vector2(360, 120), 40)
	ok.pressed.connect(close)
	put(ok, Rect2(100 if count >= 10 else 300, by, 360, 120))
	if count >= 10:
		var again := PxButton.colored("purple", DB.t("recruit.ten_again"), Vector2(360, 120), 36)
		var soldier := kind == "soldier"
		again.sub = Px.num(int(DB.meta["soldier_recruit" if soldier else "recruit"]["cost_ten"]))
		again.sub_icon = Px.tex("icon_gold" if soldier else "icon_diamond")
		again.pressed.connect(func() -> void:
			var res := Game.profile.recruit_soldiers(10) if soldier else Game.profile.recruit(10)
			if String(res["error"]) != "":
				Game.app.toast(String(res["error"]))
				return
			close()
			Game.app.popup("recruit_result", {"cards": res["cards"], "count": 10, "kind": kind}))
		put(again, Rect2(500, by, 360, 120))
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	var step := 0.16
	while _shown < _views.size() and _t > 0.15 + _shown * step:
		_reveal(_shown)
		_shown += 1


func _reveal(i: int) -> void:
	var v: Array = _views[i]
	var holder: Control = v[0]
	var back: Control = v[2]
	var tag: Control = v[3]
	var rar := String(v[4])
	var tw := holder.create_tween()
	holder.scale = Vector2(0.2, 1.0)
	tw.tween_property(holder, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		back.visible = false
		tag.visible = true)
	if rar == "ss":
		Sfx.play("jackpot")
		var glow := DrawLayer.make(func(ci: Control) -> void:
			var a := 0.4 + 0.3 * sin(_t * 8.0)
			ci.draw_rect(Rect2(Vector2(-8, -8), ci.size + Vector2(16, 16)), Color(Px.GOLD, a), false, 8.0), holder.size)
		holder.add_child(glow)
		glow.set_process(true)
		var tw2 := glow.create_tween().set_loops(40)
		tw2.tween_callback(glow.queue_redraw).set_delay(0.05)
	elif rar == "s":
		Sfx.play("win")
	else:
		Sfx.play("pop")


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		while _shown < _views.size():
			_reveal(_shown)
			_shown += 1
