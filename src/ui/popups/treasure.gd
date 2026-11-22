extends PxPopup
## 보물 상세 (메타 §3.8): 아이콘·이름·희귀도·칸·+n/+15, 주 능력치 변화, 부 능력치
## (잠김 표시), 장착 장수, 강화(골드) / 장착 / 분해.

var uid := 0
var hero := ""


func setup(p: Dictionary) -> void:
	uid = int(p["uid"])
	hero = String(p.get("hero", ""))
	title = DB.t("treasure.title")
	panel_rect = Rect2(72, 330, 880, 1150)


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
	var owner := MetaRules.treasure_owner(Game.profile.data, uid)
	var maxlv := int(DB.meta["treasure"]["max_level"])
	var cell := W.treasure_cell(it, Vector2(220, 220))
	cell.static_panel = true
	_body(cell, Rect2(50, 100, 220, 220))
	var info := DrawLayer.make(func(ci: Control) -> void:
		var rr := Rect2(0, 0, 160, 46)
		ci.draw_rect(rr, Px.INK)
		ci.draw_rect(rr.grow(-3), DB.rarity_color(rar))
		Px.text(ci, DB.t("rarity_t." + rar), rr, 26)
		Px.text(ci, DB.t("slot." + String(d["slot"])), Rect2(176, 0, 200, 46), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, String(d["name"]), Rect2(0, 54, 540, 70), 52, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "+%d / +%d" % [int(it["lv"]), maxlv], Rect2(0, 128, 300, 44), 32, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		Px.bar(ci, Rect2(0, 178, 520, 26), float(it["lv"]) / maxlv, Px.GOLD)
		if String(d.get("exclusive", "")) != "":
			Px.text(ci, DB.t("treasure.exclusive", [DB.unit_name(String(d["exclusive"]))]), Rect2(300, 128, 240, 44), 24, Color("#e0b0ff"), HORIZONTAL_ALIGNMENT_RIGHT))
	_body(info, Rect2(300, 100, 540, 220))
	var stats := DrawLayer.make(func(ci: Control) -> void:
		Px.draw_skin(ci, "panel_slot", Rect2(Vector2.ZERO, ci.size))
		var ms := MetaRules.treasure_main_stat(it)
		var cur := MetaRules.treasure_main(it)
		var nx := it.duplicate()
		nx["lv"] = mini(maxlv, int(it["lv"]) + 1)
		Px.text(ci, DB.t("treasure.main"), Rect2(30, 16, 300, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("stat." + ms), Rect2(30, 60, 200, 56), 38, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, "+" + Px.num(int(cur)), Rect2(240, 60, 180, 56), 40, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		if int(it["lv"]) < maxlv:
			Px.text(ci, "▶  +" + Px.num(int(MetaRules.treasure_main(nx))), Rect2(430, 60, 300, 56), 36, Px.HP_GREEN, HORIZONTAL_ALIGNMENT_LEFT)
		Px.text(ci, DB.t("treasure.subs"), Rect2(30, 130, 300, 40), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		var open := MetaRules.treasure_open_subs(it)
		var subs: Array = it["subs"]
		var unlock: Array = DB.meta["treasure"]["sub_unlock"]
		for i in subs.size():
			var sb: Dictionary = subs[i]
			var y := 176 + i * 52
			var on := i < open
			var name := DB.t("stat." + String(sb["kind"]))
			Px.fit(ci, Px.tex("ic_star" if on else "ic_lock"), Rect2(30, y + 8, 32, 32))
			Px.text(ci, name, Rect2(74, y, 300, 48), 30, Px.WHITE if on else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
			Px.text(ci, "+%d%%" % int(round(float(sb["v"]) * 100.0)) if on else DB.t("treasure.unlock_at", [int(unlock[i - 1])]), Rect2(380, y, 380, 48), 28, Px.HP_GREEN if on else Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		if owner != "":
			Px.text(ci, DB.t("treasure.worn", [DB.unit_name(owner)]), Rect2(30, ci.size.y - 54, ci.size.x - 60, 44), 26, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT), Vector2(780, 480))
	_body(stats, Rect2(50, 340, 780, 480))
	var cost := MetaRules.treasure_level_cost(it)
	var up := PxButton.colored("yellow", DB.t("treasure.enhance"), Vector2(250, 130), 36)
	up.sub = Px.short(cost)
	up.sub_icon = Px.tex("icon_gold")
	up.disabled = int(it["lv"]) >= maxlv
	up.pressed.connect(func() -> void:
		var why := Game.profile.enhance_treasure(uid)
		if why != "":
			Game.app.toast(why)
			Sfx.play("error")
		else:
			Sfx.play("rankup")
			build())
	_body(up, Rect2(50, 860, 250, 130))
	var eq_label := DB.t("treasure.equip_to", [DB.unit_name(hero)]) if hero != "" else DB.t("treasure.equipped") if owner != "" else DB.t("treasure.equip_hint")
	var eqb := PxButton.colored("wood", eq_label, Vector2(250, 130), 30)
	eqb.disabled = hero == "" or owner == hero
	eqb.pressed.connect(func() -> void:
		Game.profile.equip(hero, uid)
		Sfx.play("pop")
		close())
	_body(eqb, Rect2(316, 860, 250, 130))
	var dis := PxButton.colored("red", DB.t("treasure.dismantle"), Vector2(250, 130), 36)
	dis.sub = "+" + Px.short(MetaRules.dismantle_gold(it))
	dis.sub_icon = Px.tex("icon_gold")
	dis.pressed.connect(func() -> void:
		var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("treasure.dismantle"), "text": DB.t("treasure.dismantle_text", [String(d["name"]), MetaRules.dismantle_gold(it)]), "ok": DB.t("treasure.dismantle")})
		c.confirmed.connect(func() -> void:
			Game.profile.dismantle(uid)
			Sfx.play("coin")
			close()))
	_body(dis, Rect2(582, 860, 250, 130))


func _body(c: Control, r: Rect2) -> void:
	c.set_meta("body", true)
	put(c, r)
