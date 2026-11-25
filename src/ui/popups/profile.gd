extends PxPopup
## 주공 정보: 대표 장수 얼굴, 이름 · 레벨 · 경험치, 전투력, 기록, 대표 장수 바꾸기. (시안: 주공정보8_완성화면.png)
## 자리는 8차 시안에서 잰 화면 px 그대로. 틀(안쪽 판이 있는 큰 창 kit_frame2) · 제목 띠 · 닫기 · 줄 · 버튼은 공용 부품.
const FRAME := Rect2(85, 363, 853, 1042)
const TITLE := Rect2(249, 362, 526, 98)
const CLOSE := Rect2(817, 379, 90, 87)
const FACE := Rect2(154, 476, 208, 208)
const NAME := Rect2(388, 500, 484, 90)
const EXP := Rect2(392, 634, 468, 34)
const POWER := Rect2(152, 702, 720, 124)
const REC := Rect2(152, 846, 720, 88)           # 첫 줄. 줄 간격 103
const BTN := Rect2(152, 1257, 720, 98)


func setup(_p: Dictionary) -> void:
	title = DB.t("profile.title")
	title_size = 40
	panel_rect = Rect2(60, 330, 904, 1100)
	use_kit(FRAME, TITLE, CLOSE, "kit_frame2")


func build() -> void:
	var d := Game.profile.data
	# 얼굴: 로비의 초상 틀 그림 그대로 (크게)
	var avatar := Art.avatar(String(Art.of_unit(String(d["avatar"]))["art"]))
	var face := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_texture_rect(Px.tex("lobby_portrait"), Rect2(Vector2.ZERO, ci.size), false)
		Px.fit(ci, avatar, Rect2(ci.size * 0.19, ci.size * 0.62)))
	_place(face, FACE)
	var st: Dictionary = d["stats"]
	var rows := [["profile.runs", int(st["runs"])], ["profile.victories", int(st["victories"])], ["profile.jackpots", int(st["jackpots"])],
		["profile.kills", int(st["kills"])], ["profile.heroes", (d["heroes"] as Dictionary).size()], ["profile.honor", int(d["honor"])]]
	var o := Vector2(POWER.position.x, NAME.position.y)
	var info := DrawLayer.make(func(ci: Control) -> void:
		var lv := int(d["lord_lv"])
		var nr := Rect2(NAME.position - o, NAME.size)
		Px.nine(ci, "kit_box", nr)
		Px.text(ci, String(d["name"]), Rect2(nr.position + Vector2(24, 0), Vector2(nr.size.x - 170, nr.size.y)), 34, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		Px.text(ci, DB.t("profile.lv", [lv]), Rect2(nr.position + Vector2(nr.size.x - 150, 0), Vector2(126, nr.size.y)), 26, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		var need := MetaRules.lord_exp_need(lv)
		var er := Rect2(EXP.position - o, EXP.size)
		Px.bar(ci, er, float(d["lord_exp"]) / maxi(1, need), Color("#9be27a"))
		Px.text(ci, "%s / %s" % [Px.num(int(d["lord_exp"])), Px.num(need)], er, 20)
		# 전투력 칸: 쌍칼 + 숫자
		var power := 0
		for id: String in Game.lineup():
			power += MetaRules.hero_power(d, id)
		var pr := Rect2(POWER.position - o, POWER.size)
		Px.nine(ci, "kit_box", pr)
		Px.fit(ci, Px.tex("icon_swords"), Rect2(pr.position + Vector2(22, 12), Vector2(100, 100)))
		Px.text(ci, DB.t("profile.power", [Px.num(power)]), Rect2(pr.position + Vector2(140, 0), Vector2(pr.size.x - 164, pr.size.y)), 36, Px.GOLD, HORIZONTAL_ALIGNMENT_LEFT, 6)
		# 기록 4줄: 한 줄에 두 개씩 (출정 · 승리 / 잭팟 · 처치 / 장수 · 명예), 넷째 줄은 대표 장수
		for i in 4:
			var r := Rect2(REC.position - o + Vector2(0, i * 103), REC.size)
			Px.nine(ci, "kit_box", r)
			if i < 3:
				for k in 2:
					var it: Array = rows[i * 2 + k]
					var c := Rect2(r.position + Vector2(24 + k * 348, 0), Vector2(324, r.size.y))
					Px.text(ci, DB.t(String(it[0])), Rect2(c.position, Vector2(180, c.size.y)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
					Px.text(ci, Px.num(int(it[1])), Rect2(c.position + Vector2(180, 0), Vector2(c.size.x - 180, c.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
			else:
				Px.text(ci, DB.t("profile.avatar"), Rect2(r.position + Vector2(24, 0), Vector2(300, r.size.y)), 24, Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT)
				Px.text(ci, DB.unit_name(String(d["avatar"])), Rect2(r.position + Vector2(324, 0), Vector2(r.size.x - 348, r.size.y)), 28, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT))
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(info, Rect2(o, Vector2(POWER.size.x, REC.position.y + 3 * 103 + REC.size.y - o.y)))
	# 대표 장수 바꾸기: 가진 장수를 전투력 순으로 하나씩 넘긴다
	var ids: Array = (d["heroes"] as Dictionary).keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return MetaRules.hero_power(d, a) > MetaRules.hero_power(d, b))
	var b := PxButton.make("kit_box", true, BTN.size)
	b.tooltip_text = DB.t("profile.avatar")
	b.disabled = ids.size() < 2
	b.overlay = func(btn: PxButton, off: Vector2) -> void:
		Px.fit(btn, Px.tex("act_retry"), Rect2(off + Vector2(26, 17), Vector2(84, 64)))
		Px.text(btn, DB.t("profile.avatar"), Rect2(off + Vector2(126, 0), Vector2(btn.size.x - 150, btn.size.y)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 6)
	b.pressed.connect(func() -> void:
		d["avatar"] = String(ids[(ids.find(String(d["avatar"])) + 1) % ids.size()])
		Game.profile.changed.emit()
		close()
		Game.app.popup("profile"))
	_place(b, BTN)
