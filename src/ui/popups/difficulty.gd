extends PxPopup
## 난이도 창: 로비의 출정 성문을 누르면 지금 스테이지로 바로 뜬다. 맨 아래는 스테이지 되돌리기(금).
## 난이도 버튼 셋(쉬움 · 보통 · 어려움, 해골 1 · 2 · 3개): 누르면 편성 없이 바로 전투에 들어간다.
## 난이도는 스테이지가 아니라 지금 내 병력(인원수 · 레벨) 기준이다 (2026-11-25, MetaRules.army_scale). 어느 난이도로 깨도 다음 스테이지가 열린다.
## 별(클리어 등급)은 보여 주지 않는다 (2026-11-23).

var stage := 1
## 그림 창 (2026-11-24): 창 틀 · 제목 띠 · 버튼이 제미나이 완성 화면에서 떼어 낸 그림이다
## (tools/import_popups8_ui.py → assets/ui/difficulty_*.png, 자리 difficulty_layout.json).
## 해골 · 주사위 · 화살표 · 금괴는 그림에 들어 있고, 게임은 제목 · 적 아이콘 · 금 값만 쓴다. 그림이 없으면 선 UI로 그린다.
## 적 분류 → 아이콘 (병종 무기 아이콘으로 구분)
const FOE_ICON := {"pike": "wp_spear", "inf": "wp_sword", "arc": "wp_archer", "cav": "wp_rider", "str": "wp_fire"}


func setup(p: Dictionary) -> void:
	stage = int(p.get("stage", 1))
	title = "%s · %s" % [DB.t("stage.n", [stage]), DB.stage_name(stage)]
	panel_rect = Rect2(112, 460, 800, 860)
	_art = use_art("difficulty")
	title_size = 44


func _btn_pic(name: String) -> PxButton:
	return PxButton.make(name, false, _r(name).size)


func build() -> void:
	if _art:
		_build_art()
		return
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
			# 이 창은 곧 닫힌다: 출정 연출이 끝난 뒤 부를 일은 창이 아니라 Game.app 에 묶는다
			# (창에 묶인 람다는 창이 사라지면 조용히 불리지 않아 전투로 못 넘어갔다, 2026-11-24)
			var go := Game.app.goto.bind("battle", {"stage": stage, "diff": d}, true)
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


## 이 스테이지에 나오는 적의 분류 (병종 분류 순서대로).
func _foe_classes() -> Array:
	var seen: Array = []
	for w: Dictionary in DB.stage_waves(stage, 1):
		for pair: Array in w.get("list", []) + w.get("flank", []):
			var c := String(DB.enemy_def(String(pair[0])).get("cls", ""))
			if c != "" and not seen.has(c):
				seen.append(c)
	var order := ["pike", "inf", "arc", "cav", "str"]
	seen.sort_custom(func(a: String, b: String) -> bool: return order.find(a) < order.find(b))
	return seen


## 그림 창의 내용: 적 정보 칸 · 확률 · 난이도 버튼 3개 · 스테이지 되돌리기.
func _build_art() -> void:
	# 적 정보 칸: 어두운 칸 그림 안에 적 분류 아이콘 (이름은 툴팁)
	var seen := _foe_classes()
	var army := MetaRules.army_scale(Game.profile.data, Game.profile.army())
	var foes := DrawLayer.make(func(ci: Control) -> void:
		ci.draw_texture_rect(Px.tex("difficulty_slot_foes"), Rect2(Vector2.ZERO, ci.size), false)
		var s := ci.size.y - 44.0
		for i in seen.size():
			Px.fit(ci, Px.tex(String(FOE_ICON.get(String(seen[i]), "class_inf"))), Rect2(28 + i * (s + 14), 22, s, s))
		# 난이도의 기준: 지금 내 병력 (인원수 · 레벨). 쉬움 · 보통 · 어려움은 이 병력에 맞춘 적이 얼마나 세게 나오는가다.
		Px.text(ci, DB.t("diff.army", [int(army["n"]), "%.1f" % float(army["level"])]), Rect2(ci.size.x - 292, 0, 270, ci.size.y), 22, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 5))
	foes.tooltip_text = "%s
%s" % [" · ".join(seen.map(func(c: String) -> String: return DB.cls_name(c))), DB.t("diff.rule")]
	_place(foes, "difficulty_slot_foes")
	var odds := _btn_pic("difficulty_btn_odds")
	odds.tooltip_text = DB.t("stage.odds")
	odds.pressed.connect(func() -> void: Game.app.popup("odds", {}))
	_place(odds, "difficulty_btn_odds")
	var diffs := DB.difficulties()
	for i in mini(3, diffs.size()):
		var d := i + 1
		var unlocked := Game.profile.is_unlocked(stage, d)
		var b := _btn_pic("difficulty_btn_%d" % d)
		b.sound = "whoosh"
		var dname := String((diffs[i] as Dictionary)["name"])
		var exp_mult: float = float((DB.meta["lord"]["diff_exp"] as Array)[i])
		b.tooltip_text = dname
		b.overlay = func(btn: PxButton, off: Vector2) -> void:
			# 해골은 그림에 있다: 왼쪽에 난이도 이름, 오른쪽에 군주 경험 배율
			Px.text(btn, dname, Rect2(off + Vector2(28, 0), Vector2(170, btn.size.y)), 32, Px.WHITE, HORIZONTAL_ALIGNMENT_LEFT, 6)
			Px.text(btn, DB.t("diff.exp", ["%.1f" % exp_mult]), Rect2(off + Vector2(btn.size.x - 198, 0), Vector2(170, btn.size.y)), 24, Px.GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 5)
			if not unlocked:
				btn.draw_rect(Rect2(off, btn.size), Color(0, 0, 0, 0.5))
				Px.fit(btn, Px.tex("ic_lock"), Rect2(off + Vector2(btn.size.x - 110, btn.size.y * 0.5 - 30), Vector2(60, 60)))
		b.pressed.connect(func() -> void:
			if not unlocked:
				Game.app.toast(DB.t("stage.locked_diff"))
				return
			Game.next_stage = {"stage": stage, "diff": d}
			# 로비에서 열었으면 성문이 열리고 부대가 출정한 뒤 전투로
			# 이 창은 곧 닫힌다: 출정 연출이 끝난 뒤 부를 일은 창이 아니라 Game.app 에 묶는다
			# (창에 묶인 람다는 창이 사라지면 조용히 불리지 않아 전투로 못 넘어갔다, 2026-11-24)
			var go := Game.app.goto.bind("battle", {"stage": stage, "diff": d}, true)
			var cur: Node = Game.app.current
			close()
			if cur != null and cur.has_method("march_out"):
				cur.call("march_out", go)
			else:
				go.call())
		_place(b, "difficulty_btn_%d" % d)
	# 스테이지 되돌리기: 지금 스테이지에서만. 화살표 · 금괴는 그림에 있고 오른쪽 어두운 칸에 금 값을 쓴다.
	var prof := Game.profile
	if stage > 1 and stage == prof.current_stage():
		var cost := prof.stage_back_cost()
		var back := _btn_pic("difficulty_btn_back")
		back.tooltip_text = DB.t("stage.back")
		back.overlay = func(btn: PxButton, off: Vector2) -> void:
			Px.text(btn, Px.num(cost), Rect2(off + Vector2(btn.size.x * 0.62, btn.size.y * 0.3), Vector2(btn.size.x * 0.27, btn.size.y * 0.42)), 28, Px.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 5)
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
		_place(back, "difficulty_btn_back")
