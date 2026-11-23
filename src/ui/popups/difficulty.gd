extends PxPopup
## 난이도 창: 로비의 출정 성문을 누르면 지금 스테이지로 바로 뜬다. 맨 아래는 스테이지 되돌리기(금).
## 예전 설명: 스테이지를 누르면 뜬다. 보통 · 어려움 · 지옥 버튼 셋뿐이고,
## 누르면 편성 없이 바로 전투에 들어간다. 스테이지가 열려 있으면 세 난이도 모두 열려 있다.
## 별(클리어 등급)은 보여 주지 않는다 (2026-11-23).

var stage := 1
## 적 분류 → 아이콘 (병종 무기 아이콘으로 구분)
const FOE_ICON := {"pike": "wp_spear", "inf": "wp_sword", "arc": "wp_archer", "cav": "wp_rider", "str": "wp_fire"}


func setup(p: Dictionary) -> void:
	stage = int(p.get("stage", 1))
	title = "%s · %s" % [DB.t("stage.n", [stage]), DB.stage_name(stage)]
	panel_rect = Rect2(112, 460, 800, 860)


func build() -> void:
	var diffs := DB.difficulties()
	# 슬롯 확률 보기 (예전 스테이지 목록 화면에 있던 버튼)
	var odds := PxButton.colored("blue", DB.t("stage.odds"), Vector2(120, 64), 26)
	odds.pressed.connect(func() -> void: Game.app.popup("odds", {}))
	put(odds, Rect2(60, 28, 120, 64))
	# 이 스테이지의 적 분류 (기획서 §9.5): 분류 아이콘만, 이름은 툴팁. 상성을 보고 병종을 고르게.
	var seen: Array = []
	for w: Dictionary in DB.stage_waves(stage, 1):
		for pair: Array in w.get("list", []) + w.get("flank", []):
			var c := String(DB.enemy_def(String(pair[0])).get("cls", ""))
			if c != "" and not seen.has(c):
				seen.append(c)
	var order := ["pike", "inf", "arc", "cav", "str"]
	seen.sort_custom(func(a: String, b: String) -> bool: return order.find(a) < order.find(b))
	var foes := DrawLayer.make(func(ci: Control) -> void:
		Px.text(ci, DB.t("stage.foes"), Rect2(0, 0, 90, ci.size.y), 26, Px.MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
		for i in seen.size():
			Px.fit(ci, Px.tex(String(FOE_ICON.get(String(seen[i]), "class_inf"))), Rect2(104 + i * 76, 0, 64, 64)))
	foes.tooltip_text = " · ".join(seen.map(func(c: String) -> String: return DB.cls_name(c)))
	put(foes, Rect2(60, 104, 680, 64))
	for i in diffs.size():
		var d := i + 1
		var def: Dictionary = diffs[i]
		var unlocked := Game.profile.is_unlocked(stage, d)
		var b := PxButton.colored("yellow" if unlocked else "blue", "", Vector2(680, 140), 44)
		b.sound = "whoosh"
		b.tooltip_text = String(def["name"])
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			# 글자 대신 해골 1 · 2 · 3개 (diff_1 ~ diff_3, 규격 §5.4). 이름은 툴팁으로.
			Px.fit(btn, Px.tex("diff_%d" % d), Rect2(off + Vector2((btn.size.x - 112) * 0.5, (btn.size.y - 112) * 0.5), Vector2(112, 112)), Color.WHITE if unlocked else Color(0.5, 0.5, 0.5))
			if not unlocked:
				Px.fit(btn, Px.tex("ic_lock"), Rect2(off + Vector2(btn.size.x - 110, btn.size.y * 0.5 - 30), Vector2(60, 60)))
		b.pressed.connect(func() -> void:
			if not unlocked:
				Game.app.toast(DB.t("stage.locked_diff"))
				return
			Game.next_stage = {"stage": stage, "diff": d}
			# 로비에서 열었으면 성문이 열리고 부대가 출정한 뒤 전투로 (2026-11-23)
			var go := func() -> void: Game.app.goto("battle", {"stage": stage, "diff": d})
			var cur: Node = Game.app.current
			close()
			if cur != null and cur.has_method("march_out"):
				cur.call("march_out", go)
			else:
				go.call())
		put(b, Rect2(60, 190 + i * 164, 680, 140))
	# 스테이지 되돌리기: 지금 스테이지에서만, 금이 든다. 다시 깨면서 더 키우고 싶을 때 쓴다.
	var prof := Game.profile
	if stage > 1 and stage == prof.current_stage():
		var cost := prof.stage_back_cost()
		var back := PxButton.colored("blue", "", Vector2(680, 104), 36)
		back.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, "◀ " + DB.t("stage.back"), Rect2(off + Vector2(40, 0), Vector2(400, btn.size.y)), 36, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 5)
			Px.fit(btn, Px.tex("icon_gold"), Rect2(off + Vector2(btn.size.x - 220, btn.size.y * 0.5 - 24), Vector2(48, 48)))
			Px.text(btn, Px.num(cost), Rect2(off + Vector2(btn.size.x - 164, 0), Vector2(130, btn.size.y)), 36, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 5)
		back.pressed.connect(func() -> void:
			var c: PxPopup = Game.app.popup("confirm", {"title": DB.t("stage.back"),
				"text": DB.t("stage.back_ask", [Px.num(cost), stage - 1, DB.stage_name(stage - 1)]), "ok": DB.t("common.ok")})
			c.connect("confirmed", func() -> void:
				var why := prof.stage_back()
				if why != "":
					Game.app.toast(why)
					Sfx.play("error")
					return
				Sfx.play("coin")
				Game.app.toast(DB.t("stage.back_done", [stage - 1]))
				close()
				Game.app.popup("difficulty", {"stage": stage - 1})))
		put(back, Rect2(60, 190 + diffs.size() * 164, 680, 104))
