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
const MAX_STEPS := 4000  # 한 웨이브 200초


func _ready() -> void:
	DB.ensure()
	if OS.get_cmdline_user_args().has("--quick"):
		print("== 새 계정 하나로 20판: 깬 곳 다음 스테이지 보통으로 올라간다 (성장 누적) ==")
		_campaign(20, [])
		get_tree().quit(0)
		return
	if OS.get_cmdline_user_args().has("--tune"):
		_tune()
		get_tree().quit(0)
		return
	print("== 새 계정 (장수 0, 병종 4, 군주 Lv.%d) 스테이지 1 보통 20판, 판마다 새 계정 ==" % int(Profile.new().data["lord_lv"]))
	_report(_many(20, 1, 1, false, []))
	print("== 같은 계정으로 이어서 40판: 깬 곳 다음 스테이지 보통으로 올라간다 (성장 누적) ==")
	_campaign(40, [])
	print("== 장수 3명(관우 · 장비 · 황충)을 가진 계정으로 이어서 40판 ==")
	_campaign(40, ["guanyu", "zhangfei", "huangzhong"])
	print("== 새 계정 스테이지 1 어려움 / 지옥 각 10판 ==")
	_report(_many(10, 1, 2, false, []))
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
		var r := _one(acc, stage, 1, 2000 + i)
		rows.append(r)
		if i % 5 == 4:
			var wins := 0
			for k in range(i - 4, i + 1):
				wins += int(rows[k]["win"])
			var stars: Array = []
			for id: String in acc.data["troops"]:
				stars.append("%s%d" % [DB.troop_name(id).substr(0, 2), int(acc.data["troops"][id]["star"])])
			var atk := int(MetaRules.soldier_stats(acc.data, "spear")["atk"])
			print("  판 %2d~%2d: 스테이지 %d, 5판 중 %d승, 군주 Lv.%d, 장수 %d명, 병종 %d종, 창병 %d성 공격 %d, 재료 %d, 번 금 %d" % [
				i - 3, i + 1, stage, wins, int(acc.data["lord_lv"]), (acc.data["heroes"] as Dictionary).size(), (acc.data["troops"] as Dictionary).size(),
				int(acc.data["troops"]["spear"]["star"]), atk, _mats(acc), int(acc.data["gold"]) - gold0])
	var top := 0
	for s in range(1, DB.stage_count() + 1):
		if acc.stars_of(DB.stage_key(s, 1)) > 0:
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
	acc.data["rice"]["n"] = int(DB.rules["rice_max"])
	var run := RunState.new(rng, DB.hero_ids(), DB.soldier_ids(), stage, diff, acc)
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
	acc.finish_run(stage, diff, cleared, won, run.stars_earned(won), run.stats)
	bf.free()
	return res


## The simulated player's preparation: spin while possible, absorb to make room.
func _prep(run: RunState) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		# 전장이 가득 차면 금이 넉넉할 때 칸을 사고, 아니면 흡수로 자리를 만든다.
		if run.field_full():
			var cost := run.field_cap_cost()
			if cost >= 0 and int(run.account.data["gold"]) >= cost + 5000:
				run.buy_field_cap()
			elif not _make_room(run):
				break
		if run.spin_block_reason() != "":
			break
		run.spin()
		if run.can_nudge():
			var wins := run.slot.nudge_wins()
			if not wins.is_empty():
				run.nudge(int(wins[0][0]), int(wins[0][1]))


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
	var base_spins := int(DB.rules["spins_per_battle"])
	for cfg: Array in [[0.35, 8, 10], [0.25, 8, 10], [0.2, 8, 10], [0.35, 8, 15], [0.35, 8, 20]]:
		d0["mult"] = cfg[0]
		DB.rules["field_cap_base"] = cfg[1]
		DB.rules["spins_per_battle"] = cfg[2]
		print("적 배율 %.2f · 전장 %d칸 · 전투당 돌리기 %d" % cfg)
		_report(_many(12, 1, 1, false, []))
	d0["mult"] = base_mult
	DB.rules["field_cap_base"] = base_cap
	DB.rules["spins_per_battle"] = base_spins
