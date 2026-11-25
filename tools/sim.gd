extends Node
## 창 없는 밸런스 모의 전투: 정해진 방식으로 플레이하는 가상의 플레이어가 스테이지를
## 여러 판 돌고, 승률 · 도달 웨이브 · 남은 성 체력 · 성장(성급, 군주 레벨)을 표로 찍는다.
## 화면이 없고 저장 파일도 쓰지 않는다 (계정은 메모리 안에만 있다).
##
##   godot --headless --path . res://tools/sim.tscn -- --no-save --save=<임시 json>
##
## 가상 플레이어의 규칙 (사람보다 서툴다고 보면 된다):
## - 군량은 가득 찬 채로 시작한다고 본다. 한 전투 10번을 준비 시간에 되는 대로 돌리고,
##   꽝 줄의 위아래에 유닛이 보이면 재배치로 끌어온다.
## - 전장이 가득 차면 같은 병종끼리 흡수(성급)해서 자리를 만든다. 없으면 가장 약한
##   병사를 가장 강한 유닛에게 먹여 속성 첫 장을 받는다.
## - 금이 넉넉하면 전장 칸을 산다. 장비 · 합성은 쓰지 않는다. 배치는 자동 자리 그대로.

const DT := 0.05
## 한 판에 쓰는 군량 (2026-11-23): 군량 30분에 1 · 하루 2번 접속 가정 → 한 번에 24 (돌리기 12번).
const RICE_PER_RUN := 24
const RUNS_PER_DAY := 2
const MAX_STEPS := 4000  # 한 웨이브 200초


func _ready() -> void:
	DB.ensure()
	if OS.get_cmdline_user_args().has("--quick"):
		print("== 새 계정 하나로 40판 (하루 %d판 · 한 판 군량 %d 가정): 깬 곳 다음 스테이지 보통 (부대 · 성장 누적) ==" % [RUNS_PER_DAY, RICE_PER_RUN])
		_campaign(40, [])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--army"):
		_army_check(6, [0, 4, 10, 18])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--army-long"):
		_army_check(5, [18, 30])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--tune"):
		_tune()
		get_tree().quit(0)
		return
	print("== 새 계정 (장수 0, 병종 4, 군주 Lv.%d) 스테이지 1 보통 20판, 판마다 새 계정 ==" % int(Profile.new().data["lord_lv"]))
	_report(_many(20, 1, 2, false, []))
	print("== 같은 계정으로 이어서 40판: 깬 곳 다음 스테이지 보통으로 올라간다 (성장 누적) ==")
	_campaign(40, [])
	print("== 장수 3명(관우 · 장비 · 황충)을 가진 계정으로 이어서 40판 ==")
	_campaign(40, ["guanyu", "zhangfei", "huangzhong"])
	print("== 새 계정 스테이지 1 쉬움 / 어려움 각 10판 ==")
	_report(_many(10, 1, 1, false, []))
	_report(_many(10, 1, 3, false, []))
	get_tree().quit(0)


func _account(heroes: Array, seed: int) -> Profile:
	var p := Profile.new()
	p.rng.seed = seed
	for h: String in heroes:
		p.add_hero_card(h)
	return p


func _many(n: int, stage: int, diff: int, keep: bool, heroes: Array) -> Array:
	var out: Array = []
	var acc := _account(heroes, 1)
	for i in n:
		if not keep:
			acc = _account(heroes, 100 + i)
		out.append(_one(acc, stage, diff, 1000 + i))
	return out


## One account climbs: plays the highest unlocked stage on 보통 each run.
func _campaign(n: int, heroes: Array) -> void:
	var acc := _account(heroes, 7)
	var rows: Array = []
	var gold0 := int(acc.data["gold"])
	for i in n:
		var stage := 1
		for s in range(1, DB.stage_count() + 1):
			if acc.is_unlocked(s, 1):
				stage = s
		var r := _one(acc, stage, 2, 2000 + i)
		rows.append(r)
		if i % 5 == 4:
			var wins := 0
			for k in range(i - 4, i + 1):
				wins += int(rows[k]["win"])
			var stars: Array = []
			for id: String in acc.data["troops"]:
				stars.append("%s%d" % [DB.troop_name(id).substr(0, 2), int(acc.data["troops"][id]["star"])])
			var atk := int(MetaRules.soldier_stats(acc.data, "spear")["atk"])
			print("  판 %2d~%2d (%d일째): 스테이지 %d, 5판 중 %d승, 부대 %d명, 군주 Lv.%d, 장수 %d명, 창병 %d성 공격 %d, 재료 %d, 번 금 %d" % [
				i - 3, i + 1, (i + RUNS_PER_DAY) / RUNS_PER_DAY, stage, wins, acc.army().size(), int(acc.data["lord_lv"]), (acc.data["heroes"] as Dictionary).size(),
				int(acc.data["troops"]["spear"]["star"]), atk, _mats(acc), int(acc.data["gold"]) - gold0])
	var top := 0
	for s in range(1, DB.stage_count() + 1):
		if acc.is_unlocked(s + 1) or (s == DB.stage_count() and (acc.stars_of(DB.stage_key(s, 1)) > 0 or acc.stars_of(DB.stage_key(s, 2)) > 0 or acc.stars_of(DB.stage_key(s, 3)) > 0)):
			top = s
	print("  결과: %d판 뒤 보통 클리어 %d스테이지까지" % [n, top])


func _mats(acc: Profile) -> int:
	var n := 0
	for slot: String in acc.data["materials"]:
		for r: String in acc.data["materials"][slot]:
			n += int(acc.data["materials"][slot][r])
	return n


func _report(rows: Array) -> void:
	var wins := 0
	var waves := 0.0
	var castle := 0.0
	var units := 0.0
	var spins := 0.0
	for r: Dictionary in rows:
		wins += int(r["win"])
		waves += float(r["wave"])
		castle += float(r["castle"])
		units += float(r["units"])
		spins += float(r["spins"])
	var n := float(maxi(1, rows.size()))
	var whys := {}
	for r: Dictionary in rows:
		if String(r["why"]) != "":
			whys[r["why"]] = int(whys.get(r["why"], 0)) + 1
	if not whys.is_empty():
		print("    진 이유: ", whys)
	print("  스테이지 %d %s: %d판 중 %d승 (%.0f%%), 평균 도달 웨이브 %.1f, 승리 시 성 체력 평균 %.0f%%, 마지막 전장 유닛 %.1f명, 돌린 횟수 %.1f" % [
		int(rows[0]["stage"]), String(DB.difficulty(int(rows[0]["diff"]))["name"]), rows.size(), wins, 100.0 * wins / n, waves / n,
		100.0 * castle / maxf(1.0, float(wins)), units / n, spins / n])


## Plays one run. Returns {win, wave (waves cleared), castle (ratio, wins only), units, spins}.
func _one(acc: Profile, stage: int, diff: int, seed: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	acc.data["rice"]["n"] = RICE_PER_RUN
	var run := RunState.new(rng, DB.hero_ids(), DB.soldier_ids(), stage, diff, acc)
	run.load_units(acc.army())        # 내 부대 (이겨도 져도 남는다, 기획서 §18)
	var bf := BattleField.new()
	bf.setup(run, acc.data)
	bf.castle_hit.connect(func(dmg: float) -> void: run.damage_castle(dmg))
	var cleared := 0
	var won := false
	while true:
		_prep(run)
		bf.sync()
		if run.field.is_empty():
			break
		bf.start_wave()
		var steps := 0
		while bf.fighting and not run.castle_fallen() and steps < MAX_STEPS:
			bf._step(DT)
			steps += 1
		if run.castle_fallen() or bf.fighting:
			break
		var last := run.is_last_wave()
		run.finish_wave()
		cleared += 1
		if last:
			won = true
			break
	var why := "" if won else ("성 함락" if run.castle_fallen() else ("전장에 아무도 없음" if run.field.is_empty() else "웨이브가 200초 안에 안 끝남"))
	var res := {"stage": stage, "diff": diff, "win": won, "why": why, "wave": cleared, "castle": run.castle_ratio() if won else 0.0,
		"units": run.field.size(), "spins": int(run.stats["spins"])}
	bf.store_hp()
	acc.set_army(run.field)
	acc.finish_run(stage, diff, cleared, won, run.stars_earned(won), run.stats)
	bf.free()
	return res


## --army: 병력 기준 난이도 점검 (2026-11-25). 한 계정을 보통으로 키워 가며, 정해 둔 판 수마다 그때의 병력 그대로
## 쉬움 · 보통 · 어려움을 k판씩 해 본다 (그 결과는 버리고 계정은 보통으로 계속 큰다).
## 볼 것: 병력이 작든 크든 쉬움 > 보통 > 어려움 순으로 승률이 벌어지고, 그 차이가 비슷하게 유지되는가.
func _army_check(k: int, marks: Array) -> void:
	var acc := _account([], 7)
	var played := 0
	for mark: int in marks:
		while played < mark:
			_one(acc, acc.current_stage(), 2, 3000 + played)
			played += 1
		var sc := MetaRules.army_scale(acc.data, acc.army())
		print("== %d판 뒤: 스테이지 %d, 부대 %d명, 레벨 %.2f, 적 수 x%.2f, 적 세기 몫 x%.2f, 장수 %d명, 군주 Lv.%d ==" % [
			played, acc.current_stage(), int(sc["n"]), float(sc["level"]), float(sc["count"]), float(sc["mult"]),
			(acc.data["heroes"] as Dictionary).size(), int(acc.data["lord_lv"])])
		var snap: Dictionary = acc.data.duplicate(true)
		for d in [1, 2, 3]:
			var rows: Array = []
			for i in k:
				var c := _account([], 500 + i)
				c.data = snap.duplicate(true)
				rows.append(_one(c, c.current_stage(), d, 4000 + d * 100 + i))
			_report(rows)


## The simulated player's preparation: spin while possible, absorb to make room.
func _prep(run: RunState) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		# 장수 자리가 가득 차면 금이 넉넉할 때 자리를 사고, 아니면 흡수로 자리를 만든다.
		if run.heroes_full():
			var cost := run.field_cap_cost()
			if cost >= 0 and int(run.account.data["gold"]) >= cost + 5000:
				run.buy_field_cap()
			elif not _make_room(run):
				break
		if run.spin_block_reason() != "":
			break
		run.spin()
		# 재배치: 끌어올 유닛이 보이는 동안 계속 (군량이 있는 동안)
		while run.can_nudge():
			var wins := run.slot.nudge_wins()
			if wins.is_empty() or run.nudge(int(wins[0][0]), int(wins[0][1])).is_empty():
				break


## Frees one field slot by absorbing. Returns false when nothing can be absorbed.
func _make_room(run: RunState) -> bool:
	for a: UnitState in run.field:
		for b: UnitState in run.field:
			if a != b and not b.is_hero() and a.troop() == b.troop() and not run.absorb_star(b, a).is_empty():
				return true
	var best: UnitState = null
	var weak: UnitState = null
	for u: UnitState in run.field:
		var p := MetaRules.power_of(MetaRules.unit_stats(run.account.data, u.id))
		if best == null or p > MetaRules.power_of(MetaRules.unit_stats(run.account.data, best.id)):
			best = u
		if not u.is_hero() and (weak == null or p < MetaRules.power_of(MetaRules.unit_stats(run.account.data, weak.id))):
			weak = u
	if best == null or weak == null or best == weak:
		return false
	for o: Dictionary in run.trait_options(weak, best):
		if not bool(o["maxed"]):
			var slots_full := run.traits_of(best).size() >= run.trait_slots(best)
			var has := int(o["lv"]) > 0
			if run.absorb_trait(weak, best, String(o["id"]), 0 if slots_full and not has else -1):
				return true
	return false


## 수치 실험 (--tune): 새 계정 스테이지 1 보통을 값만 바꿔서 여러 판 돌린다.
## 데이터 파일은 고치지 않는다 (메모리 안의 값만 바꾼다).
func _tune() -> void:
	var d0: Dictionary = DB.stages["difficulties"][0]
	var base_mult := float(d0["mult"])
	var base_cap := int(DB.rules["field_cap_base"])
	for cfg: Array in [[0.35, 8], [0.25, 8], [0.2, 8], [0.35, 10], [0.35, 12]]:
		d0["mult"] = cfg[0]
		DB.rules["field_cap_base"] = cfg[1]
		print("적 배율 %.2f · 전장 %d칸" % cfg)
		_report(_many(12, 1, 1, false, []))
	d0["mult"] = base_mult
	DB.rules["field_cap_base"] = base_cap
