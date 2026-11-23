extends TestCase
## Battle targeting & movement rules:
## - Immediately run toward nearest opponent as soon as enemies appear
## - Never move while attacking (in attack range / attack animation)
## - Retarget to nearest living opponent when current target dies
## - Consistent for both allies and enemies + headless wave run


func _mk_field() -> BattleField:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var r := RunState.new(rng, ["guanyu", "zhangfei"], [], 1, 1)
	var bf := BattleField.new()
	bf.setup(r, {})
	bf.fighting = true
	return bf


func _mk_fighter(side: int, id: String, pos: Vector2, reach := 54.0, spd := 80.0, hp := 500.0) -> Fighter:
	var f := Fighter.new()
	f.side = side
	f.id = id
	f.pos = pos
	f.home = pos
	f.reach = reach
	f.ranged = reach > 100.0
	f.spd = spd
	f.aspd = 1.0
	f.atk = 25.0
	f.max_hp = hp
	f.hp = hp
	f.cd = 0.0
	return f


func test_allies_and_enemies_immediately_target_and_run_to_nearest() -> void:
	var bf := _mk_field()
	var ally := _mk_fighter(0, "spear", Vector2(200, 950), 54.0, 100.0)
	var far_enemy := _mk_fighter(1, "mob_far", Vector2(200, 240), 50.0, 50.0)
	var near_enemy := _mk_fighter(1, "mob_near", Vector2(300, 380), 50.0, 50.0)
	bf.allies.append(ally)
	bf.enemies.append(far_enemy)
	bf.enemies.append(near_enemy)

	var d0_near := ally.pos.distance_to(near_enemy.pos)
	var d0_far := ally.pos.distance_to(far_enemy.pos)
	bf._step(0.1)

	eq(ally.target, near_enemy, "ally immediately picks nearest enemy even at top of field")
	check(ally.pos.distance_to(near_enemy.pos) < d0_near, "ally immediately runs toward nearest enemy")
	eq(ally.action, "walk", "ally is walking toward enemy")

	# Enemy also targets nearest ally (add a closer second ally)
	var close_ally := _mk_fighter(0, "shield", Vector2(260, 420), 54.0, 0.0)
	bf.allies.append(close_ally)
	far_enemy.target = null
	bf._step(0.1)
	eq(far_enemy.target, close_ally, "enemy immediately picks nearest ally")
	check(far_enemy.pos.distance_to(close_ally.pos) < d0_far, "enemy runs toward nearest ally")

	bf.free()


func test_no_move_while_attacking_even_with_separation() -> void:
	var bf := _mk_field()
	# Two melee allies stacked close together (< separation min 46px) both in reach of enemy
	var a1 := _mk_fighter(0, "spear", Vector2(500, 500), 60.0, 100.0, 1000.0)
	var a2 := _mk_fighter(0, "shield", Vector2(510, 500), 60.0, 100.0, 1000.0)
	var e1 := _mk_fighter(1, "mob", Vector2(540, 500), 60.0, 60.0, 1000.0)
	bf.allies.append(a1)
	bf.allies.append(a2)
	bf.enemies.append(e1)

	var p_a1 := a1.pos
	var p_a2 := a2.pos
	var p_e1 := e1.pos
	for _i in 20:
		bf._step(0.05)

	eq(a1.pos, p_a1, "ally 1 does not move while attacking")
	eq(a2.pos, p_a2, "ally 2 does not move while attacking")
	eq(e1.pos, p_e1, "enemy does not move while attacking")
	check(e1.hp < 1000.0, "allies actually deal damage while stationary")
	check(a1.hp < 1000.0 or a2.hp < 1000.0, "enemy actually deals damage while stationary")

	bf.free()


func test_retargets_nearest_when_target_dies() -> void:
	var bf := _mk_field()
	var ally := _mk_fighter(0, "spear", Vector2(500, 600), 54.0, 100.0, 1000.0)
	ally.atk = 200.0
	var e1 := _mk_fighter(1, "mob1", Vector2(530, 600), 50.0, 0.0, 50.0)
	var e2 := _mk_fighter(1, "mob2", Vector2(500, 300), 50.0, 0.0, 500.0)
	var e3 := _mk_fighter(1, "mob3", Vector2(500, 460), 50.0, 0.0, 500.0)
	bf.allies.append(ally)
	bf.enemies.append(e1)
	bf.enemies.append(e2)
	bf.enemies.append(e3)

	# First step kills e1 (hp 50 vs atk 200)
	bf._step(0.1)
	check(not e1.alive(), "first target dies")
	# Wait out attack anim lock (~0.5s) then step; ally must retarget nearest living enemy (e3 at y=460, not e2 at y=300)
	for _i in 8:
		bf._step(0.1)
	eq(ally.target, e3, "retargets nearest living enemy after target dies")
	check(ally.pos.y < 600.0, "runs toward new nearest target")

	bf.free()


func test_headless_wave_simulation() -> void:
	var bf := _mk_field()
	bf.run.recruit("guanyu")
	bf.run.recruit("spear")
	bf.run.recruit("archer")
	bf.sync()
	bf.start_wave()
	for _i in 300:
		bf._step(0.05)
		if not bf.fighting:
			break
	check(bf.killed_total > 0, "headless wave kills enemies")
	bf.free()
