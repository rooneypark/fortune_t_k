extends PxPopup
## 임무: 일일 · 주간 · 업적 탭. 진행 바, 받기 / 바로가기. (시안: 임무8_완성화면.png)
## 자리는 8차 시안에서 잰 화면 px 그대로. 틀(안쪽 판이 있는 큰 창 kit_frame2) · 제목 띠 · 닫기 · 줄 · 버튼은 공용 부품.
const FRAME := Rect2(85, 363, 853, 1042)
const TITLE := Rect2(249, 362, 526, 98)
const CLOSE := Rect2(817, 379, 90, 87)
const TABS := Rect2(153, 485, 717, 101)          # 탭 3개 (해 · 달력 · 메달), 탭 하나 239
const LIST := Rect2(154, 606, 717, 756)         # 임무 줄이 구르는 칸
const ROW := Vector2(717, 130)                  # 줄 간격 146

var tab := 0


func setup(p: Dictionary) -> void:
	title = DB.t("missions.title")
	title_size = 40
	tab = int(p.get("tab", 0))
	panel_rect = Rect2(60, 260, 904, 1280)
	Game.profile.refresh_periods()
	use_kit(FRAME, TITLE, CLOSE, "kit_frame2")


func build() -> void:
	var scopes := ["daily", "weekly", "achievements"]
	var scope: String = scopes[tab]
	_place(W.icon_tabs(["tab_daily", "tab_weekly", "tab_trophy"], tab, 239, func(i: int) -> void:
		close()
		Game.app.popup("missions", {"tab": i}), [DB.t("missions.daily"), DB.t("missions.weekly"), DB.t("missions.achieve")]), TABS)
	var list: Array = (DB.missions[scope] as Array).duplicate()
	var order := {"ready": 0, "progress": 1, "claimed": 2}
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(order[Game.profile.mission_state(a, scope)]) < int(order[Game.profile.mission_state(b, scope)]))
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var content := Control.new()
	sc.add_child(content)
	for i in list.size():
		var mi: Dictionary = list[i]
		var st := Game.profile.mission_state(mi, scope)
		var prog := mini(Game.profile.mission_progress(mi, scope), int(mi["need"]))
		var rw: Dictionary = mi["reward"]
		# 줄: 왼쪽 보상 틀, 가운데 이름 + 진행 막대, 오른쪽 버튼
		var row := DrawLayer.make(func(ci: Control) -> void:
			Px.nine(ci, "kit_box", Rect2(Vector2.ZERO, ci.size))
			var ic := Rect2(16, 16, 96, 98)
			Px.nine(ci, "kit_box", ic)
			Px.fit(ci, Px.tex(W.reward_icon(rw)), Rect2(ic.position + Vector2(22, 10), Vector2(52, 52)))
			Px.text(ci, W.reward_text(rw), Rect2(ic.position + Vector2(4, 62), Vector2(88, 28)), 18, Px.WHITE)
			Px.text(ci, String(mi["name"]), Rect2(131, 12, 410, 50), 26, Px.MUTED if st == "claimed" else Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
			var br := Rect2(131, 76, 410, 34)
			Px.bar(ci, br, float(prog) / maxi(1, int(mi["need"])), Color("#9be27a"))
			Px.text(ci, "%d / %d" % [prog, int(mi["need"])], br, 20), ROW)
		row.position = Vector2(0, i * 146)
		var btn: PxButton
		match st:
			"ready":
				btn = PxButton.make("kit_btn_yellow", true, Vector2(132, 80))
				btn.text_color = Color("#3a2a10")
				btn.text = DB.t("mail.get")
				btn.pulse = true
				btn.pressed.connect(func() -> void:
					var g := Game.profile.claim_mission(mi, scope)
					close()
					var p := Game.app.popup("reward", {"reward": rw, "items": g})
					p.closed.connect(func() -> void: Game.app.popup("missions", {"tab": tab})))
			"claimed":
				btn = PxButton.make("kit_box", true, Vector2(132, 80))
				btn.text_color = Px.MUTED
				btn.text = DB.t("mail.claimed")
				btn.disabled = true
			_:
				btn = PxButton.make("kit_box", true, Vector2(132, 80))
				btn.text = DB.t("missions.go")
				var route := String(mi.get("go", ""))
				btn.disabled = route == ""
				btn.pressed.connect(func() -> void:
					close()
					# 스테이지 목록 화면은 없다: 지금 스테이지의 난이도 창을 바로 띄운다.
					if route == "stage":
						Game.app.popup("difficulty", {"stage": Game.profile.current_stage()})
					else:
						Game.app.goto(route))
		btn.font_size = 24
		btn.position = Vector2(566, 25)
		row.add_child(btn)
		content.add_child(row)
	content.custom_minimum_size = Vector2(ROW.x, list.size() * 146)
	_place(sc, LIST)
