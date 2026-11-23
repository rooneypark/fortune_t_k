extends PxPopup
## 난이도 창: 로비의 출정 성문을 누르면 지금 스테이지로 바로 뜬다. 맨 아래는 스테이지 되돌리기(금).
## 예전 설명: 스테이지를 누르면 뜬다. 보통 · 어려움 · 지옥 버튼 셋뿐이고,
## 누르면 편성 없이 바로 전투에 들어간다. 잠긴 난이도는 자물쇠.

var stage := 1


func setup(p: Dictionary) -> void:
	stage = int(p.get("stage", 1))
	title = "%s · %s" % [DB.t("stage.n", [stage]), DB.stage_name(stage)]
	panel_rect = Rect2(112, 500, 800, 772)


func build() -> void:
	var diffs := DB.difficulties()
	# 슬롯 확률 보기 (예전 스테이지 목록 화면에 있던 버튼)
	var odds := PxButton.colored("blue", DB.t("stage.odds"), Vector2(120, 64), 26)
	odds.pressed.connect(func() -> void: Game.app.popup("odds", {}))
	put(odds, Rect2(60, 28, 120, 64))
	for i in diffs.size():
		var d := i + 1
		var def: Dictionary = diffs[i]
		var unlocked := Game.profile.is_unlocked(stage, d)
		var st := Game.profile.stars_of(DB.stage_key(stage, d))
		var b := PxButton.colored("yellow" if unlocked else "blue", "", Vector2(680, 140), 44)
		b.sound = "whoosh"
		b.pulse = unlocked and st == 0
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, String(def["name"]), Rect2(off + Vector2(40, 0), Vector2(300, btn.size.y)), 48, Px.WHITE if unlocked else Px.MUTED, HORIZONTAL_ALIGNMENT_LEFT, 6)
			if unlocked:
				Px.stars(btn, off + Vector2(btn.size.x - 150, btn.size.y * 0.5), st, 3, 44.0)
			else:
				Px.fit(btn, Px.tex("ic_lock"), Rect2(off + Vector2(btn.size.x - 110, btn.size.y * 0.5 - 30), Vector2(60, 60)))
		b.pressed.connect(func() -> void:
			if not unlocked:
				Game.app.toast(DB.t("stage.locked_diff"))
				return
			Game.next_stage = {"stage": stage, "diff": d}
			Game.app.goto("battle", {"stage": stage, "diff": d}))
		put(b, Rect2(60, 110 + i * 164, 680, 140))
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
		put(back, Rect2(60, 110 + diffs.size() * 164, 680, 104))
