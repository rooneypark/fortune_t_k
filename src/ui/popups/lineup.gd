extends PxPopup
## 출정 편성 (병종-장수-재설계 §3.4): 스테이지에서 출정을 누르면 뜬다.
## 장수 최대 3명 + 병종 4개 = 슬롯 릴. 장수를 고르면 그 장수의 병종이 자동으로
## 들어가고 잠긴다 (장수는 자기 병종 줄에 껴야 합류하므로). 자동 편성 버튼,
## "한 번 돌릴 때 줄이 맞을 확률"을 바로 보여 준다.
## 영역: 장수 판 A(24,96 856×470) · 병종 판 B(24,580 856×420) · 정보 C(24,1014 856×60) · 버튼 줄 D(24,1090 856×120)

signal sortie

const CARD := Vector2(150, 176)
const COLS := 5

var chapter := 1
var stage := 1
var heroes: Array = []
var troops: Array = []
var _body: Control


func setup(p: Dictionary) -> void:
	title = DB.t("lineup.title")
	chapter = int(p.get("chapter", 1))
	stage = int(p.get("stage", 1))
	panel_rect = Rect2(60, 230, 904, 1230)
	heroes = Game.lineup()
	troops = Game.sortie_troops()
	_fix_troops()


func build() -> void:
	_body = Control.new()
	put(_body, Rect2(0, 0, panel_rect.size.x, panel_rect.size.y))
	_rebuild()


## Required troops first (locked), then the others, max troop_lineup.
func _fix_troops() -> void:
	var req := MetaRules.required_troops(heroes)
	var out: Array = req.duplicate()
	for t: Variant in troops:
		if out.size() >= int(DB.rules["troop_lineup"]):
			break
		if not out.has(t) and Game.profile.owns_troop(String(t)):
			out.append(t)
	troops = out


func _rebuild() -> void:
	for c in _body.get_children():
		c.queue_free()
	var w := panel_rect.size.x
	var hmax := int(DB.rules["hero_lineup_max"])
	var tmax := int(DB.rules["troop_lineup"])
	# --- 장수 판
	var owned_h: Array = (Game.profile.data["heroes"] as Dictionary).keys()
	owned_h.sort_custom(func(a: String, b: String) -> bool:
		return MetaRules.hero_power(Game.profile.data, a) > MetaRules.hero_power(Game.profile.data, b))
	_panel(Rect2(24, 96, w - 48, 470), DB.t("lineup.heroes", [heroes.size(), hmax]), DB.t("lineup.heroes_hint"))
	if owned_h.is_empty():
		_note(Rect2(48, 250, w - 96, 160), DB.t("lineup.no_heroes"))
	else:
		_grid(Rect2(40, 160, w - 80, 392), owned_h, true)
	# --- 병종 판
	var owned_t: Array = []
	for t: String in DB.soldier_ids():
		if Game.profile.owns_troop(t):
			owned_t.append(t)
	_panel(Rect2(24, 580, w - 48, 420), DB.t("lineup.troops", [troops.size(), tmax]), DB.t("lineup.troops_hint"))
	_grid(Rect2(40, 644, w - 80, 342), owned_t, false)
	# --- 확률
	var chance := MetaRules.line_chance(troops, heroes)
	var info := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_small", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, DB.t("lineup.chance", [int(round(chance * 100.0))]), Rect2(20, 0, ci.size.x - 40, ci.size.y), 28, Px.GOLD), Vector2(w - 48, 60))
	info.position = Vector2(24, 1014)
	_body.add_child(info)
	# --- 버튼
	var auto := PxButton.colored("blue", DB.t("lineup.auto"), Vector2(400, 110), 36)
	auto.position = Vector2(24, 1090)
	auto.pressed.connect(func() -> void:
		var a := MetaRules.auto_lineup(Game.profile.data)
		heroes = a["heroes"]
		troops = a["troops"]
		Sfx.play("click")
		_rebuild())
	_body.add_child(auto)
	var go := PxButton.colored("red", DB.t("lineup.go"), Vector2(400, 110), 40)
	go.position = Vector2(w - 424, 1090)
	go.disabled = troops.size() < mini(tmax, owned_t.size())
	go.pulse = not go.disabled
	go.pressed.connect(_go)
	_body.add_child(go)


func _panel(r: Rect2, head: String, hint: String) -> void:
	var d := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		Px.text(ci, head, Rect2(20, 8, 360, 48), 30, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, hint, Rect2(390, 8, ci.size.x - 410, 48), 20, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT), r.size)
	d.position = r.position
	_body.add_child(d)


func _note(r: Rect2, s: String) -> void:
	var d := DrawLayer.make(func(ci: Control) -> void:
		Px.paragraph(ci, s, Rect2(Vector2.ZERO, ci.size), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_CENTER), r.size)
	d.position = r.position
	_body.add_child(d)


## Scrollable card grid inside [param r]. Heroes or troops.
func _grid(r: Rect2, ids: Array, is_hero: bool) -> void:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	sc.position = r.position
	sc.size = r.size
	_body.add_child(sc)
	var content := Control.new()
	sc.add_child(content)
	var gap := (r.size.x - CARD.x * COLS) / (COLS - 1)
	var req := MetaRules.required_troops(heroes)
	for i in ids.size():
		var id := String(ids[i])
		var on := heroes.has(id) if is_hero else troops.has(id)
		var locked := not is_hero and req.has(id)
		var opts := {"big": false, "selected": on}
		if is_hero:
			opts["tag"] = DB.troop_name(DB.troop_of(id))
		else:
			opts["stars"] = int(Game.profile.troop(id).get("star", 1))
			opts["tag"] = DB.t("lineup.locked", [DB.troop_name(id)]) if locked else DB.troop_name(id)
		var c := W.hero_card(id, CARD, opts)
		if not on:
			c.modulate = Color(0.62, 0.62, 0.68)
		c.position = Vector2((i % COLS) * (CARD.x + gap), floorf(i / float(COLS)) * (CARD.y + 12))
		c.pressed.connect(func() -> void: _toggle(id, is_hero))
		content.add_child(c)
	content.custom_minimum_size = Vector2(r.size.x, ceilf(ids.size() / float(COLS)) * (CARD.y + 12))


func _toggle(id: String, is_hero: bool) -> void:
	var tmax := int(DB.rules["troop_lineup"])
	if is_hero:
		if heroes.has(id):
			heroes.erase(id)
		elif heroes.size() >= int(DB.rules["hero_lineup_max"]):
			Game.app.toast(DB.t("heroes.lineup_full", [int(DB.rules["hero_lineup_max"])]))
			Sfx.play("error")
			return
		else:
			var need := MetaRules.required_troops(heroes + [id])
			if need.size() > tmax:
				Game.app.toast(DB.t("lineup.too_many_troops"))
				Sfx.play("error")
				return
			heroes.append(id)
		_fix_troops()
	else:
		if MetaRules.required_troops(heroes).has(id):
			Game.app.toast(DB.t("lineup.locked_msg"))
			Sfx.play("error")
			return
		if troops.has(id):
			troops.erase(id)
		elif troops.size() >= tmax:
			# 가득 차면 잠기지 않은 병종 중 가장 앞의 것과 바꾼다
			var req := MetaRules.required_troops(heroes)
			for t: Variant in troops:
				if not req.has(t):
					troops.erase(t)
					break
			troops.append(id)
		else:
			troops.append(id)
	Sfx.play("click")
	_rebuild()


func _go() -> void:
	var adv := ""
	for h: String in heroes:
		if not DB.advisor_skill(h).is_empty():
			adv = h
			break
	Game.profile.set_lineup(heroes, adv)
	Game.profile.set_troop_lineup(troops)
	Game.next_stage = {"chapter": chapter, "stage": stage}
	sortie.emit()
	close()
	Game.app.goto("battle", {"chapter": chapter, "stage": stage})
