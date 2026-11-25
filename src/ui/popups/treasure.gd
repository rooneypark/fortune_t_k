extends PxPopup
## 장비 상세 (메타 §3.8): 아이콘 · 이름 · 희귀도 · +n/+최대, 주 능력치 변화, 부 능력치(잠김 표시), 장착 장수,
## 강화(금) / 장착 / 분해.
## 자리는 8차 시안(design/art/ui_src/장비상세8_완성화면.png)에서 잰 화면 px 그대로. 틀 · 칸 · 버튼은 공용 부품.

const FRAME := Rect2(124, 470, 775, 853)
const TITLE := Rect2(249, 433, 526, 97)
const CLOSE := Rect2(818, 450, 88, 86)
const ITEM := Rect2(173, 547, 188, 183)
const LINE_A := Rect2(382, 555, 472, 86)
const LINE_B := Rect2(382, 645, 472, 82)
const ROW := Rect2(166, 747, 692, 78)         # 첫 줄. 줄 간격 81
const WORN := Rect2(166, 1084, 692, 78)
const BTNS := [Rect2(156, 1179, 235, 124), Rect2(395, 1179, 233, 124), Rect2(638, 1179, 231, 124)]

var uid := 0
var hero := ""


func setup(p: Dictionary) -> void:
	uid = int(p["uid"])
	hero = String(p.get("hero", ""))
	title = DB.t("treasure.title")
	title_size = 40
	panel_rect = Rect2(72, 330, 880, 1150)
	use_kit(FRAME, TITLE, CLOSE)


func build() -> void:
	for c in panel.get_children():
		if c.has_meta("body"):
			c.queue_free()
	var it := MetaRules.find_treasure(Game.profile.data, uid)
	if it.is_empty():
		close()
		return
	var d := DB.treasure_def(String(it["tid"]))
	var rar := String(d["rarity"])
	var rc := DB.rarity_color(rar)
	var owner := MetaRules.treasure_owner(Game.profile.data, uid)
	var maxlv := int(DB.meta["treasure"]["max_level"])
	var cell := W.treasure_cell(it, ITEM.size)
	cell.static_panel = true
	_body(cell, ITEM)
	var o := LINE_A.position
	var info := DrawLayer.make(func(ci: Control) -> void:
		# 첫 띠: 이름 + 희귀도, 둘째 띠: +n / +최대 막대 + 종류
		var ra := Rect2(Vector2.ZERO, LINE_A.size)
		Px.nine(ci, "kit_box", ra)
		Px.text(ci, String(d["name"]), Rect2(22, 0, ra.size.x - 170, ra.size.y), 34, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("rarity_t." + rar), Rect2(ra.size.x - 150, 0, 130, ra.size.y), 24, rc.lightened(0.3), HORIZONTAL_ALIGNMENT_RIGHT)
		var rb := Rect2(LINE_B.position - o, LINE_B.size)
		Px.nine(ci, "kit_box", rb)
		Px.text(ci, "+%d / +%d" % [int(it["lv"]), maxlv], Rect2(rb.position + Vector2(22, 0), Vector2(150, rb.size.y)), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(rb.position + Vector2(176, 28), Vector2(170, 26)), float(it["lv"]) / maxlv, Px.GOLD)
		var kind := DB.t("slot." + String(d["slot"]))
		if String(d.get("exclusive", "")) != "":
			kind = DB.t("treasure.exclusive", [DB.unit_name(String(d["exclusive"]))])
		Px.text(ci, kind, Rect2(rb.position + Vector2(356, 0), Vector2(rb.size.x - 376, rb.size.y)), 20, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT))
	_body(info, Rect2(o, Vector2(LINE_A.size.x, LINE_B.end.y - o.y)))
	var ro := ROW.position
	var stats := DrawLayer.make(func(ci: Control) -> void:
		var ms := MetaRules.treasure_main_stat(it)
		var cur := MetaRules.treasure_main(it)
		var nx := it.duplicate()
		nx["lv"] = mini(maxlv, int(it["lv"]) + 1)
		# 1줄: 주 능력치 (지금 → 다음)
		var r0 := Rect2(Vector2.ZERO, ROW.size)
		Px.nine(ci, "kit_box", r0)
		Px.text(ci, DB.t("stat." + ms), Rect2(24, 0, 200, r0.size.y), 30, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "+" + Px.num(int(cur)), Rect2(230, 0, 180, r0.size.y), 32, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		if int(it["lv"]) < maxlv:
			Px.text(ci, "▶  +" + Px.num(int(MetaRules.treasure_main(nx))), Rect2(420, 0, r0.size.x - 444, r0.size.y), 28, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_RIGHT)
		# 2~4줄: 부 능력치 (잠긴 것은 자물쇠 + 열리는 강화 단계)
		var open := MetaRules.treasure_open_subs(it)
		var subs: Array = it["subs"]
		var unlock: Array = DB.meta["treasure"]["sub_unlock"]
		for i in 3:
			var r := Rect2(0, (i + 1) * 81, ROW.size.x, ROW.size.y)
			Px.nine(ci, "kit_box", r, Color.WHITE if i < subs.size() else Color(0.7, 0.7, 0.7))
			if i >= subs.size():
				continue
			var sb: Dictionary = subs[i]
			var on := i < open
			Px.fit(ci, Px.tex("ic_star" if on else "ic_lock"), Rect2(r.position + Vector2(24, 22), Vector2(34, 34)))
			Px.text(ci, DB.t("stat." + String(sb["kind"])), Rect2(r.position + Vector2(72, 0), Vector2(280, r.size.y)), 26, Px.WHITE if on else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "+%d%%" % int(round(float(sb["v"]) * 100.0)) if on else DB.t("treasure.unlock_at", [int(unlock[i - 1])]),
				Rect2(r.position + Vector2(360, 0), Vector2(r.size.x - 384, r.size.y)), 24, Px.HP_GREEN if on else Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		# 아래 줄: 특수 능력 (보물만) · 장착한 장수
		var rw := Rect2(WORN.position - ro, WORN.size)
		Px.nine(ci, "kit_box", rw)
		var fx := String(d.get("fx_desc", ""))
		Px.text(ci, DB.t("gear.special", [fx]) if fx != "" else DB.t("gear.normal"), Rect2(rw.position + Vector2(24, 0), Vector2(rw.size.x - 300, rw.size.y)), 20, Color("#e0b0ff") if fx != "" else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		if owner != "":
			Px.text(ci, DB.t("treasure.worn", [DB.unit_name(owner)]), Rect2(rw.position + Vector2(rw.size.x - 270, 0), Vector2(246, rw.size.y)), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	_body(stats, Rect2(ro, Vector2(ROW.size.x, WORN.end.y - ro.y)))
	# 버튼 3개: 강화(빨강 · 망치 · 금 값) / 장착(칼 든 손) / 분해(부러진 칼 · 돌려받는 금)
	var cost := MetaRules.treasure_level_cost(it)
	var up := _action("kit_btn_red", "act_enhance", DB.t("treasure.enhance"), Px.short(cost), BTNS[0])
	up.disabled = int(it["lv"]) >= maxlv
	up.pressed.connect(func() -> void:
		var why := Game.profile.enhance_treasure(uid)
		if why != "":
			Game.app.toast(why)
			Sfx.play("error")
		else:
			Sfx.play("rankup")
			build())
	var eq_label := DB.t("treasure.equip_to", [DB.unit_name(hero)]) if hero != "" else DB.t("treasure.equipped") if owner != "" else DB.t("treasure.equip_hint")
	var eqb := _action("kit_box", "act_equip", eq_label, "", BTNS[1])
	eqb.disabled = hero == "" or owner == hero
	eqb.pressed.connect(func() -> void:
		Game.profile.equip(hero, uid)
		Sfx.play("pop")
		close())
	var dis := _action("kit_box", "act_break", DB.t("treasure.dismantle"), "+" + Px.short(MetaRules.dismantle_gold(it)), BTNS[2])
	dis.pressed.connect(func() -> void:
		var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("treasure.dismantle"), "text": DB.t("treasure.dismantle_text", [String(d["name"]), MetaRules.dismantle_gold(it)]), "ok": DB.t("treasure.dismantle")})
		c.confirmed.connect(func() -> void:
			Game.profile.dismantle(uid)
			Sfx.play("coin")
			close()))


## 아래 버튼 하나: 왼쪽 아이콘 + 이름, 그 아래 금 값(있으면).
func _action(part: String, icon_name: String, label: String, gold: String, r: Rect2) -> PxButton:
	var b := PxButton.make(part, true, r.size)
	b.tooltip_text = label
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		Px.fit(btn, Px.tex(icon_name), Rect2(off + Vector2(14, (btn.size.y - 66) * 0.5), Vector2(66, 66)), Color(0.6, 0.6, 0.6) if btn.disabled else Color.WHITE)
		var tx := 86.0
		if gold == "":
			Px.paragraph(btn, label, Rect2(off + Vector2(tx, 10), Vector2(btn.size.x - tx - 12, btn.size.y - 20)), 22, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 4)
		else:
			Px.text(btn, label, Rect2(off + Vector2(tx, 18), Vector2(btn.size.x - tx - 12, 40)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 5)
			Px.fit(btn, Px.tex("icon_gold"), Rect2(off + Vector2(tx + 4, 66), Vector2(34, 34)))
			Px.text(btn, gold, Rect2(off + Vector2(tx + 42, 62), Vector2(btn.size.x - tx - 54, 42)), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	_body(b, r)
	return b


func _body(c: Control, r: Rect2) -> void:
	c.set_meta("body", true)
	if _art:
		_place(c, r)
	else:
		put(c, r)
