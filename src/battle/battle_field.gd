class_name BattleField
extends Control
## The battlefield above the wall (화면 설계서 §4.2): enemies walk down from
## y≈236, allies hold the zone under the engagement line (y 810..1160), the
## castle takes damage when an enemy reaches the wall. Simulates and draws
## every fighter, projectile and effect in this one control (y-sorted, pixel
## snapped). The run rules (RunState) stay outside; this only fights.

signal castle_hit(amount: float)
signal enemy_killed(f: Fighter)
signal ally_fell(f: Fighter)
signal ally_back(f: Fighter)
signal skill_cast(f: Fighter)
signal wave_done
signal boss_spawned(f: Fighter)

# 가로 전장 (2026-11-23): 왼쪽에 성벽, 오른쪽에서 적이 온다. 가운데 띠(공터)에서만 싸우고
# 띠의 위아래는 배경이다. 좌표는 이 노드 안의 px (1024 x 1328).
const BAND_TOP := 640.0
const BAND_BOTTOM := 1180.0
## 성벽 선: 적이 여기까지 오면 성을 친다.
const WALL_X := 104.0
## 아군 자리의 오른쪽 끝 (교전선).
const LINE_X := 500.0
## 적이 나오는 오른쪽 끝.
const SPAWN_X := 1030.0
const LEFT := WALL_X
const RIGHT := 1000.0

var run: RunState
var profile: Dictionary = {}
var stage_hue := 0.0
var allies: Array[Fighter] = []
var enemies: Array[Fighter] = []
var fighting := false
var speed := 1.0
var shake := 0.0
var shake_on := true
var _queue: Array = []
var _spawn_t := 0.0
var _projectiles: Array = []
var _fx: Array = []
var _texts: Array = []
var _warns: Array = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()
var _bg: Texture2D
var _hover_ghost: Dictionary = {}
var spawned_total := 0
var killed_total := 0
var _wave_mult := 1.0
var _boss: Fighter
var _off := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 12345
	_bg = Px.tex("battle_field")


func setup(r: RunState, prof: Dictionary) -> void:
	run = r
	profile = prof
	stage_hue = float(DB.stage_def(r.stage).get("hue", 0.0))
	set_process(true)


# ---------------------------------------------------------------- allies

## Brings fighters in line with run.field (new units pop in, removed vanish).
func sync() -> void:
	var keep: Array[Fighter] = []
	for f in allies:
		if run.field.has(f.unit):
			keep.append(f)
	allies = keep
	for u in run.field:
		var f := ally_of(u)
		if f == null:
			f = _make_ally(u)
			allies.append(f)
			_fx.append({"kind": "pop", "pos": f.pos, "t": 0.0, "life": 0.35, "color": Px.GOLD})
		else:
			_apply_stats(f)
	_apply_synergy()
	queue_redraw()


func ally_of(u: UnitState) -> Fighter:
	for f in allies:
		if f.unit == u:
			return f
	return null


func _make_ally(u: UnitState) -> Fighter:
	var f := Fighter.new()
	f.side = 0
	f.unit = u
	f.id = u.id
	var a := Art.of_unit(u.id)
	f.art = String(a["art"])
	f.hue = float(a["hue"])
	f.height = Art.target_h(f.art) * float(a["scale"])
	f.cls = u.cls()
	f.fac = DB.fac_of(u.id)
	if u.anchor == Vector2.ZERO:
		u.anchor = free_spot(f.cls)
	f.home = u.anchor
	f.pos = u.anchor
	f.pop = 0.25
	_apply_stats(f)
	f.hp = f.max_hp
	return f


## Stats and effects of an ally: 성급 · 군주 레벨 · 보물 (MetaRules.unit_stats) and the
## troop's own feature + the account's 속성 (MetaRules.unit_fx). Read again on every
## sync, so a 성급 or 속성 gained by absorbing shows at once.
func _apply_stats(f: Fighter) -> void:
	var u := f.unit
	var cdef: Dictionary = DB.units["classes"].get(f.cls, {})
	var d := DB.unit_def(u.id)
	var troop := DB.soldier(DB.troop_of(u.id))
	var st := MetaRules.unit_stats(profile, u.id)
	var fx := MetaRules.unit_fx(profile, u.id)
	f.skill = d.get("skill", {}) if u.is_hero() else {}
	f.ctr = DB.ctr_of(u.id)
	f.reach = float(d.get("range", cdef.get("range", 44))) + float(fx.get("range", 0.0))
	var old_ratio := f.ratio() if f.max_hp > 1.0 else 1.0
	f.atk = float(st["atk"])
	f.def = float(st["def"]) + float(fx.get("def_add", 0.0))
	f.max_hp = float(st["hp"]) * float(fx.get("hp", 1.0))
	f.crit = 0.05 + float(st.get("crit", 0.0)) + float(fx.get("crit", 0.0))
	f.crit_dmg = float(st.get("crit_dmg", 0.0)) + float(fx.get("crit_dmg", 0.0))
	f.aspd = float(cdef.get("aspd", 1.0)) * float(troop.get("aspd_k", 1.0)) * (1.0 + float(st.get("aspd", 0.0))) * float(fx.get("aspd", 1.0))
	f.spd = float(cdef.get("spd", 60)) * float(fx.get("spd", 1.0))
	f.energy_k = (1.0 + float(st.get("energy", 0.0))) * float(fx.get("energy", 1.0))
	f.flags = fx.duplicate()
	f.flags["dmg_taken"] = float(fx.get("dmg_taken", 1.0)) * (1.0 - float(st.get("guard", 0.0)))
	f.ranged = f.reach > 100.0
	if f.ranged:
		f.reach *= 1.3
	else:
		f.reach = maxf(f.reach, 52.0)
	f.hp = f.max_hp * old_ratio


## Class / faction synergies and hero bonds (콘텐츠 §4·5) for the allies on the field.
func _apply_synergy() -> void:
	var cls_n := {}
	var fac_n := {}
	var ids := {}
	for f in allies:
		cls_n[f.cls] = int(cls_n.get(f.cls, 0)) + 1
		if f.unit.is_hero() and f.fac != "":
			fac_n[f.fac] = int(fac_n.get(f.fac, 0)) + 1
			ids[f.id] = true
	for f in allies:
		var m := {"syn_atk": 1.0, "syn_dt": 1.0, "syn_aspd": 1.0, "syn_spd": 1.0, "syn_energy": 1.0, "syn_crit": 0.0, "syn_burn": 0.0, "burn_mult": 1.0}
		for s: Dictionary in active_synergies():
			var applies: bool = (s["kind"] == "class" and f.cls == s["key"]) or (s["kind"] == "faction" and f.fac == s["key"]) or s["kind"] == "bond" and (s["heroes"] as Array).has(f.id)
			if not applies:
				continue
			if s.has("atk"): m["syn_atk"] *= float(s["atk"])
			if s.has("dmg_taken"): m["syn_dt"] *= float(s["dmg_taken"])
			if s.has("aspd"): m["syn_aspd"] *= float(s["aspd"])
			if s.has("spd"): m["syn_spd"] *= float(s["spd"])
			if s.has("energy"): m["syn_energy"] *= float(s["energy"])
			if s.has("crit"): m["syn_crit"] += float(s["crit"])
			if s.has("burn_on_hit"): m["syn_burn"] = float(s["burn_on_hit"])
			if s.has("burn_mult"): m["burn_mult"] = float(s["burn_mult"])
		for k: String in m:
			f.flags[k] = m[k]


## Active synergies and bonds on the field: [{name, desc, kind, key, ...}].
func active_synergies() -> Array:
	var cls_n := {}
	var fac_n := {}
	var ids := {}
	for f in allies:
		cls_n[f.cls] = int(cls_n.get(f.cls, 0)) + 1
		if f.unit.is_hero() and f.fac != "":
			fac_n[f.fac] = int(fac_n.get(f.fac, 0)) + 1
			ids[f.id] = true
	var out: Array = []
	for s: Dictionary in DB.units["synergies"]:
		var n := int(cls_n.get(s["key"], 0)) if s["kind"] == "class" else int(fac_n.get(s["key"], 0))
		if n >= int(s["need"]):
			out.append(s)
	for b: Dictionary in DB.units["bonds"]:
		var n := 0
		for h: String in b["heroes"]:
			if ids.has(h):
				n += 1
		if n >= int(b["need"]):
			var d := b.duplicate()
			d["kind"] = "bond"
			out.append(d)
	return out


## A free standing spot in the ally zone: melee in front (right, near the line),
## ranged behind (left, near the wall). Rows fan out from the middle of the band.
func free_spot(cls: String) -> Vector2:
	var front := cls == "inf" or cls == "cav" or cls == "pike"
	var cols: Array = [430.0, 340.0, 250.0, 170.0] if front else [190.0, 270.0, 350.0, 430.0]
	var mid := (BAND_TOP + BAND_BOTTOM) * 0.5 + 20.0
	var rows := [mid, mid - 100.0, mid + 100.0, mid - 200.0, mid + 200.0]
	for x: float in cols:
		for y: float in rows:
			var p := Vector2(x, y)
			if _spot_free(p):
				return p
	return Vector2(_rng.randf_range(WALL_X + 60, LINE_X - 40), _rng.randf_range(BAND_TOP + 60, BAND_BOTTOM - 20))


func _spot_free(p: Vector2) -> bool:
	for u in run.field:
		if u.anchor != Vector2.ZERO and u.anchor.distance_to(p) < 80.0:
			return false
	return true


func clamp_zone(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, WALL_X + 50, LINE_X - 20), clampf(p.y, BAND_TOP + 50, BAND_BOTTOM - 10))


func in_zone(p: Vector2) -> bool:
	return p.x >= WALL_X - 20 and p.x <= LINE_X + 30 and p.y > BAND_TOP - 20 and p.y < BAND_BOTTOM + 40


func fighter_at(p: Vector2) -> Fighter:
	var best: Fighter = null
	var bd := 1e9
	for f in allies:
		if not f.alive():
			continue
		var r := Rect2(f.pos.x - 44, f.pos.y - f.height * 0.9, 88, f.height * 0.95)
		if r.has_point(p):
			var d := absf(p.y - f.pos.y)
			if d < bd:
				bd = d
				best = f
	return best


func move_home(f: Fighter, p: Vector2) -> void:
	f.unit.anchor = clamp_zone(p)
	f.home = f.unit.anchor
	if not fighting:
		f.pos = f.home


## Ghost shown while dragging (drawn by the field).
func set_ghost(g: Dictionary) -> void:
	_hover_ghost = g
	queue_redraw()


# ---------------------------------------------------------------- waves

func start_wave() -> void:
	var w := run.current_wave()
	_wave_mult = DB.stage_mult(run.stage, run.diff) * pow(float(DB.rules["wave_scale"]), run.wave)
	_queue.clear()
	var main: Array = []
	for pair: Array in w["list"]:
		for i in int(pair[1]):
			main.append(String(pair[0]))
	_shuffle(main)
	var tt := 0.6
	var gap := float(DB.rules["spawn_gap"])
	for id: String in main:
		_queue.append({"id": id, "t": tt, "flank": false})
		tt += gap
	var ft := tt * 0.45
	for pair: Array in w.get("flank", []):
		for i in int(pair[1]):
			_queue.append({"id": String(pair[0]), "t": ft, "flank": true})
			ft += gap * 0.6
	if String(w.get("boss", "")) != "":
		_queue.append({"id": String(w["boss"]), "t": tt + 0.8, "flank": false, "boss": true})
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	spawned_total = _queue.size()
	killed_total = 0
	_spawn_t = 0.0
	fighting = true
	for f in allies:
		f.energy = 0.0
		f.cd = _rng.randf_range(0.0, 0.4)
	_apply_synergy()


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t: Variant = a[i]
		a[i] = a[j]
		a[j] = t


func enemies_left() -> int:
	return _queue.size() + enemies.filter(func(e: Fighter) -> bool: return e.alive()).size()


func _spawn(q: Dictionary) -> void:
	var id := String(q["id"])
	var is_boss := DB.is_boss(id)
	var d := DB.enemy_def(id)
	var f := Fighter.new()
	f.side = 1
	f.id = id
	f.art = String(d.get("art", "enemy_mob"))
	f.hue = float(d.get("hue", 0.0)) + (stage_hue if not is_boss and f.art.begins_with("enemy_") and f.art != "enemy_zhangjiao" else 0.0)
	f.height = Art.target_h(f.art) * float(d.get("scale", 1.0))
	var m := _wave_mult
	f.max_hp = float(d["hp"]) * m
	f.hp = f.max_hp
	f.atk = float(d["atk"]) * m
	f.def = float(d.get("def", 0))
	f.spd = float(d.get("spd", 50)) * 0.9
	f.reach = float(d.get("range", 40))
	f.ranged = f.reach > 100.0
	if not f.ranged:
		f.reach = maxf(f.reach, 50.0)
	f.aspd = float(d.get("aspd", DB.units["enemy_aspd"]))
	f.cls = String(d.get("cls", ""))
	f.ctr = String(d.get("ctr", f.cls))
	f.flags = {"beh": String(d.get("beh", "")), "heal": float(d.get("heal", 0)), "ranged_resist": float(d.get("ranged_resist", 1.0)),
		"dmg_taken": 1.0, "backline": String(d.get("beh", "")) == "assassin"}
	f.boss = is_boss
	f.elite = bool(d.get("elite", false))
	f.mech = String(d.get("mech", ""))
	f.mech_t = 3.0
	if bool(q.get("flank", false)):
		# 기습: 띠의 위나 아래에서, 교전선 바로 오른쪽으로 들어온다
		var up := _rng.randf() < 0.5
		f.pos = Vector2(_rng.randf_range(LINE_X + 80, LINE_X + 260), BAND_TOP - 10 if up else BAND_BOTTOM + 10)
	else:
		f.pos = Vector2(SPAWN_X + _rng.randf_range(-10, 40), _rng.randf_range(BAND_TOP + 50, BAND_BOTTOM - 20))
		if is_boss:
			f.pos.y = (BAND_TOP + BAND_BOTTOM) * 0.5 + 30.0
	f.flip = true
	f.pop = 0.25
	f.cd = _rng.randf_range(0.2, 0.8)
	enemies.append(f)
	if is_boss:
		_boss = f
		boss_spawned.emit(f)


func boss() -> Fighter:
	return _boss if _boss != null and _boss.alive() else null


func clear_enemies() -> void:
	enemies.clear()
	_queue.clear()
	_projectiles.clear()
	_warns.clear()
	fighting = false
	_boss = null


# ---------------------------------------------------------------- simulation

func _process(delta: float) -> void:
	_t += delta
	var dt := delta * speed
	if shake > 0.0:
		shake = maxf(0.0, shake - delta * 2.5)
	if fighting:
		_step(dt)
	else:
		for f in allies:
			f.anim_t += dt
			_idle_ally(f, dt)
	_step_fx(dt)
	queue_redraw()


func _idle_ally(f: Fighter, dt: float) -> void:
	if f.dead:
		return
	f.pop = maxf(0.0, f.pop - dt)
	f.flash = maxf(0.0, f.flash - dt)
	var to := f.home - f.pos
	if to.length() > 4.0:
		f.pos += to.normalized() * minf(to.length(), f.spd * 2.0 * dt)
		f.set_action("walk")
		f.flip = to.x < 0
	else:
		f.set_action("idle")
		f.flip = false


func _step(dt: float) -> void:
	_spawn_t += dt
	while not _queue.is_empty() and float(_queue[0]["t"]) <= _spawn_t:
		_spawn(_queue.pop_front())
	for f in allies:
		f.anim_t += dt
		_tick_common(f, dt)
		if f.dead:
			f.respawn_t -= dt
			if f.respawn_t <= 0.0:
				f.dead = false
				f.hp = f.max_hp
				f.pos = f.home
				f.pop = 0.3
				f.fade = 1.0
				_fx.append({"kind": "pop", "pos": f.pos, "t": 0.0, "life": 0.35, "color": Px.WHITE})
				ally_back.emit(f)
			continue
		_unit_ai(f, enemies, dt)
	for e in enemies:
		e.anim_t += dt
		_tick_common(e, dt)
		if e.alive():
			_unit_ai(e, allies, dt)
	_separate(allies, dt)
	_separate(enemies, dt)
	_step_projectiles(dt)
	_step_warns(dt)
	var still: Array[Fighter] = []
	for e in enemies:
		if e.alive() or e.fade > 0.0:
			still.append(e)
	enemies = still
	if _queue.is_empty() and enemies.filter(func(e: Fighter) -> bool: return e.alive()).is_empty():
		fighting = false
		_projectiles.clear()
		_warns.clear()
		for f in allies:
			if f.dead:
				f.dead = false
				f.hp = f.max_hp
				f.pos = f.home
				ally_back.emit(f)
			f.buffs.clear()
			f.stun = 0.0
			f.slow_t = 0.0
			f.burn_t = 0.0
		wave_done.emit()


func _tick_common(f: Fighter, dt: float) -> void:
	f.pop = maxf(0.0, f.pop - dt)
	f.flash = maxf(0.0, f.flash - dt)
	if not f.alive():
		if f.side == 1:
			f.fade = maxf(0.0, f.fade - dt * 2.0)
		return
	f.cd -= dt
	f.stun = maxf(0.0, f.stun - dt)
	f.slow_t = maxf(0.0, f.slow_t - dt)
	for k: String in f.buffs.keys():
		f.buffs[k][0] = float(f.buffs[k][0]) - dt
		if float(f.buffs[k][0]) <= 0.0:
			f.buffs.erase(k)
	if f.burn_t > 0.0:
		f.burn_t -= dt
		_hurt(f, f.burn_dps * dt, null, false, true)


func _nearest(from: Fighter, list: Array, max_d: float, pred: Callable = Callable()) -> Fighter:
	var best: Fighter = null
	var bd := max_d
	for o: Fighter in list:
		if not o.alive():
			continue
		if pred.is_valid() and not pred.call(o):
			continue
		var d := from.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best


## Whom [param f] goes for: 후열 노림(backline) = the nearest ranged opponent first;
## an enemy near a 도발(taunt) ally goes for that ally; otherwise the nearest.
func _pick_target(f: Fighter, opponents: Array) -> Fighter:
	if bool(f.flags.get("backline", false)):
		var back := _nearest(f, opponents, 1e9, func(o: Fighter) -> bool: return o.ranged)
		if back != null:
			return back
	if f.side == 1:
		var taunter := _nearest(f, opponents, 260.0, func(o: Fighter) -> bool: return bool(o.flags.get("taunt", false)))
		if taunter != null:
			return taunter
	return _nearest(f, opponents, 1e9)


const ATTACK_ANIM_LOCK := 0.45


func _is_attacking(f: Fighter) -> bool:
	if not f.alive():
		return false
	if f.side == 1 and f.target == null and f.action == "attack":
		return true
	if f.target == null or not f.target.alive():
		return false
	return f.pos.distance_to(f.target.pos) <= f.reach or (f.action == "attack" and f.anim_t < ATTACK_ANIM_LOCK)


func _unit_ai(f: Fighter, opponents: Array, dt: float) -> void:
	if f.stun > 0.0:
		f.set_action("idle")
		return
	if f.side == 0:
		var ha := float(f.flags.get("heal_aura", 0.0))
		if ha > 0.0:
			f.heal_t -= dt
			if f.heal_t <= 0.0:
				f.heal_t = 6.0
				for o in allies:
					if o.alive() and o.pos.distance_to(f.pos) < 220.0:
						o.hp = minf(o.max_hp, o.hp + o.max_hp * ha)
						_text(o.pos + Vector2(0, -o.height), "+" + str(int(o.max_hp * ha)), Color("#7cff7c"), 24)
						_fx.append({"kind": "heal", "pos": o.pos + Vector2(0, -o.height * 0.6), "t": 0.0, "life": 0.5, "color": Color("#7cff7c")})
	else:
		if f.boss and f.mech != "":
			_boss_mech(f, dt)
		if float(f.flags.get("heal", 0.0)) > 0.0:
			f.heal_t -= dt
			if f.heal_t <= 0.0:
				f.heal_t = 3.0
				for o in enemies:
					if o.alive() and o != f and o.pos.distance_to(f.pos) < 200.0 and o.hp < o.max_hp:
						o.hp = minf(o.max_hp, o.hp + float(f.flags["heal"]) * _wave_mult)
						_fx.append({"kind": "ring", "pos": o.pos, "t": 0.0, "life": 0.4, "color": Color("#7cff7c"), "r": 40.0})

	# 대상이 없거나 죽었으면 즉시 다음 대상을 찾는다 (후열 노림 · 도발 포함)
	if f.target == null or not f.target.alive():
		f.target = _pick_target(f, opponents)

	if f.target != null:
		var tg := f.target
		var d := f.pos.distance_to(tg.pos)
		# 공격 사거리 안이거나 공격 모션 중에는 절대 이동하지 않는다
		if d <= f.reach or (f.action == "attack" and f.anim_t < ATTACK_ANIM_LOCK):
			f.flip = tg.pos.x < f.pos.x - 1.0
			if d <= f.reach:
				_attack(f, tg)
			return
		# 이동 중에는 더 가까운 적이 나타나면 그쪽으로 선회
		var closest := _pick_target(f, opponents)
		if closest != null and closest != tg and f.pos.distance_to(closest.pos) < d - 1.0:
			f.target = closest
			tg = closest
			d = f.pos.distance_to(tg.pos)
			if d <= f.reach:
				f.flip = tg.pos.x < f.pos.x - 1.0
				_attack(f, tg)
				return
		f.flip = tg.pos.x < f.pos.x - 1.0
		var step := minf(maxf(0.0, d - f.reach * 0.9), f.spd_now() * dt)
		if step > 0.0:
			f.pos += ((tg.pos - f.pos) / d) * step
			f.set_action("walk")
		return

	# 살아있는 적이 없을 때: 아군은 대기, 적은 성벽으로 전진
	if f.side == 0:
		var to := f.home - f.pos
		if to.length() > 6.0:
			f.pos += to.normalized() * minf(to.length(), f.spd_now() * dt)
			f.set_action("walk")
			f.flip = to.x < 0
		else:
			f.set_action("idle")
			f.flip = false
		return
	if f.pos.x > WALL_X + 30.0 + (f.reach if f.ranged else 0.0) * 0.6:
		f.pos.x -= f.spd_now() * dt
		f.pos.y = clampf(f.pos.y, BAND_TOP + 30, BAND_BOTTOM)
		f.set_action("walk")
		f.flip = true
	else:
		f.flip = true
		f.set_action("attack")
		f.castle_t -= dt
		if f.castle_t <= 0.0:
			f.castle_t = float(DB.rules["castle_attack_interval"]) / maxf(0.3, f.aspd)
			var dmg := f.atk_now() * (3.0 if f.boss else (2.0 if f.elite else 1.0))
			castle_hit.emit(dmg)
			if shake_on:
				shake = minf(1.0, shake + 0.25)
			_fx.append({"kind": "spark", "pos": Vector2(WALL_X - 10, f.pos.y - f.height * 0.4), "t": 0.0, "life": 0.25, "color": Color("#ff6a3a")})


func _attack(f: Fighter, tg: Fighter) -> void:
	if f.cd > 0.0:
		if f.action == "attack" and f.anim_t > 0.6:
			f.set_action("idle")
		return
	f.cd = 1.0 / maxf(0.2, f.aspd_now())
	f.action = "attack"
	f.anim_t = 0.0
	var mult := 1.0
	var opener := f.side == 0 and not f.first_hit
	if opener:
		f.first_hit = true
		if float(f.flags.get("first_hit", 0.0)) > 0.0:
			mult *= float(f.flags["first_hit"])
		# 짓밟기: the first attack stuns (bosses shrug it off)
		if float(f.flags.get("first_hit_stun", 0.0)) > 0.0 and not tg.boss:
			tg.stun = maxf(tg.stun, float(f.flags["first_hit_stun"]))
	# 밀집: stronger next to a comrade of the same troop
	if float(f.flags.get("phalanx", 1.0)) > 1.0 and f.unit != null:
		for o in allies:
			if o != f and o.alive() and o.unit != null and o.unit.troop() == f.unit.troop() and o.pos.distance_to(f.pos) < 120.0:
				mult *= float(f.flags["phalanx"])
				break
	_strike(f, tg, mult)
	# 연격: 20% for one more, weaker hit
	if float(f.flags.get("double", 0.0)) > 0.0 and _rng.randf() < 0.2:
		_strike(f, tg, mult * float(f.flags["double"]))
	# 유격: a burst of speed after attacking
	if float(f.flags.get("skirmish", 0.0)) > 0.0:
		f.add_buff("spd", 2.0, float(f.flags["skirmish"]))
	if f.side == 0 and not f.skill.is_empty():
		_gain_energy(f, float(DB.rules["energy_per_attack"]))


## One hit of [param f] on [param tg]: an arrow / orb for ranged fighters, else at once.
func _strike(f: Fighter, tg: Fighter, mult: float) -> void:
	if f.ranged:
		_projectiles.append({"from": f.pos + Vector2(0, -f.height * 0.55), "to": tg, "pos": f.pos + Vector2(0, -f.height * 0.55),
			"src": f, "mult": mult, "speed": 900.0, "kind": "orb" if f.cls == "str" or f.art == "enemy_mage" else "arrow",
			"pierce": float(f.flags.get("pierce", 0.0))})
	else:
		_deal(f, tg, f.atk_now() * mult, false)


func _gain_energy(f: Fighter, amount: float) -> void:
	if f.skill.is_empty():
		return
	f.energy += amount * f.energy_k * float(f.flags.get("syn_energy", 1.0))
	if f.energy >= float(DB.rules["energy_max"]):
		f.energy = 0.0
		_cast(f)


func _deal(src: Fighter, tg: Fighter, raw: float, ranged: bool) -> void:
	if not tg.alive():
		return
	var dmg := raw * 100.0 / (100.0 + tg.def_now() * 2.0)
	var crit := false
	if src != null:
		# 상성 (개편 §9.5) and the effects that depend on who is hit
		dmg *= DB.counter(src.ctr, tg.cls)
		if tg.cls == "cav":
			dmg *= float(src.flags.get("vs_cav", 1.0))
		if tg.ratio() >= 0.999:
			dmg *= float(src.flags.get("full_hp_dmg", 1.0))
		if tg.ranged:
			dmg *= float(src.flags.get("backline_dmg", 1.0))
		var cc := src.crit + float(src.flags.get("syn_crit", 0.0))
		if _rng.randf() < cc:
			crit = true
			dmg *= float(DB.rules["crit_mult"]) + src.crit_dmg
	if ranged:
		dmg *= float(tg.flags.get("ranged_resist", 1.0))
	_hurt(tg, dmg, src, crit, false)
	if src == null:
		return
	if tg.alive():
		# 파갑: the target's defence drops for 3 s
		var ab := float(src.flags.get("armor_break", 0.0))
		if ab > 0.0:
			tg.add_buff("def", 3.0, 1.0 - ab)
		# 감전: a short stun (not on bosses)
		var sc := float(src.flags.get("stun_chance", 0.0))
		if sc > 0.0 and not tg.boss and _rng.randf() < sc:
			tg.stun = maxf(tg.stun, 0.6)
		# 화상: troop feature / 속성 (2 s, a share of attack) or the 오 synergy (seconds)
		var burn_dps := 0.0
		var burn_time := 0.0
		var ratio := float(src.flags.get("burn", 0.0))
		if ratio > 0.0:
			burn_time = 2.0
			burn_dps = src.atk_now() * ratio / 2.0
		var syn := float(src.flags.get("syn_burn", 0.0))
		if syn > 0.0:
			burn_time = maxf(burn_time, syn)
			burn_dps = maxf(burn_dps, src.atk_now() * float(DB.rules["burn_ratio"]))
		if burn_time > 0.0:
			tg.burn_t = maxf(tg.burn_t, burn_time)
			tg.burn_dps = maxf(tg.burn_dps, burn_dps * float(src.flags.get("burn_mult", 1.0)) * float(tg.flags.get("burn_taken", 1.0)))
	if src.side == 0:
		var sp := float(src.flags.get("splash", 0.0))
		if sp > 0.0:
			for o in enemies:
				if o != tg and o.alive() and o.pos.distance_to(tg.pos) < 80.0:
					_hurt(o, dmg * sp, src, false, false)
			_fx.append({"kind": "ring", "pos": tg.pos, "t": 0.0, "life": 0.3, "color": Color("#ff8a3a"), "r": 80.0})


func _hurt(tg: Fighter, dmg: float, src: Fighter, crit: bool, quiet: bool) -> void:
	if not tg.alive():
		return
	dmg *= tg.taken_mult()
	tg.hp -= dmg
	if not quiet:
		tg.flash = 0.12
		var col := Color("#ffe14a") if crit else (Color("#ffffff") if tg.side == 1 else Color("#ff7a7a"))
		_text(tg.pos + Vector2(_rng.randf_range(-16, 16), -tg.height - 6), str(maxi(1, int(dmg))), col, 34 if crit else 24)
		_hit_fx(tg, src, crit, col)
	if src != null:
		src.dmg_dealt += dmg
		if src.unit != null:
			src.unit.damage += dmg
	if tg.side == 0 and not tg.skill.is_empty():
		_gain_energy(tg, float(DB.rules["energy_per_hit"]))
	if tg.hp <= 0.0:
		tg.hp = 0.0
		if tg.side == 1:
			tg.dead = true
			killed_total += 1
			if src != null:
				src.kills += 1
				if src.unit != null:
					src.unit.kills += 1
			_fx.append({"kind": "poof", "pos": tg.pos, "t": 0.0, "life": 0.4, "color": Color("#d8d0c0")})
			enemy_killed.emit(tg)
			if tg == _boss:
				if shake_on:
					shake = 1.0
				_fx.append({"kind": "ring", "pos": tg.pos, "t": 0.0, "life": 0.8, "color": Px.GOLD, "r": 260.0})
		else:
			tg.dead = true
			tg.respawn_max = run.respawn_time(tg.unit)
			tg.respawn_t = tg.respawn_max
			tg.target = null
			_fx.append({"kind": "poof", "pos": tg.pos, "t": 0.0, "life": 0.4, "color": Color("#a0a8b8")})
			ally_fell.emit(tg)
			for e in enemies:
				if e.target == tg:
					e.target = null


## 타격 이펙트 (도트 이펙트 기준, design/art/캐릭터-도트-컨셉.md §4): 공격한 쪽의 상성 줄마다
## 모양과 색이 정해져 있다. 창 = 찌르기, 보병 = 베기, 기병 = 충돌 + 먼지, 궁 = 꽂힘,
## 화공 = 불꽃, 뇌공 = 번개, 그 밖 = 십자 불꽃. 치명타는 금색 별이 하나 더 뜬다.
const HIT_FX := {
	"pike": ["thrust", "#f2e6b8"], "inf": ["cut", "#dfe6f0"], "cav": ["impact", "#ffb070"], "arc": ["pin", "#f0e0b0"],
	"fire": ["flame", "#ff8a3a"], "thunder": ["zap", "#ffe14a"], "medic": ["pin", "#7cff7c"],
}


func _hit_fx(tg: Fighter, src: Fighter, crit: bool, col: Color) -> void:
	var p := tg.pos + Vector2(0, -tg.height * 0.5)
	var dx := 1.0 if src == null or src.pos.x <= tg.pos.x else -1.0
	var kind := "spark"
	var c := col
	if src != null and HIT_FX.has(src.ctr):
		kind = String(HIT_FX[src.ctr][0])
		c = Color(String(HIT_FX[src.ctr][1]))
	_fx.append({"kind": kind, "pos": p, "t": 0.0, "life": 0.24, "color": c, "dx": dx, "feet": tg.pos})
	if crit:
		_fx.append({"kind": "star", "pos": p + Vector2(0, -24), "t": 0.0, "life": 0.32, "color": Px.GOLD})


func _separate(list: Array[Fighter], dt: float) -> void:
	for i in list.size():
		var a := list[i]
		if not a.alive():
			continue
		for j in range(i + 1, list.size()):
			var b := list[j]
			if not b.alive():
				continue
			var d := a.pos - b.pos
			var dist := d.length()
			var minimum := 46.0 if not (a.boss or b.boss) else 90.0
			if dist < minimum:
				var a_atk := _is_attacking(a)
				var b_atk := _is_attacking(b)
				if a_atk and b_atk:
					continue
				var push := (d.normalized() if dist > 0.1 else Vector2(1, 0)) * (minimum - dist) * 0.5 * minf(1.0, dt * 8.0)
				if a_atk:
					b.pos -= push * 2.0
				elif b_atk:
					a.pos += push * 2.0
				else:
					a.pos += push
					b.pos -= push


func _step_projectiles(dt: float) -> void:
	var keep: Array = []
	for p: Dictionary in _projectiles:
		var tg: Fighter = p["to"]
		var dest: Vector2 = tg.pos + Vector2(0, -tg.height * 0.5)
		var cur: Vector2 = p["pos"]
		var step := float(p["speed"]) * dt
		if cur.distance_to(dest) <= step or not tg.alive():
			var src: Fighter = p["src"]
			if tg.alive():
				_deal(src, tg, src.atk_now() * float(p["mult"]), true)
				if float(p["pierce"]) > 0.0:
					var behind := _nearest(tg, enemies if tg.side == 1 else allies, 120.0, func(o: Fighter) -> bool: return o != tg)
					if behind != null:
						_deal(src, behind, src.atk_now() * float(p["mult"]) * float(p["pierce"]), true)
			continue
		p["pos"] = cur + (dest - cur).normalized() * step
		keep.append(p)
	_projectiles = keep


# ---------------------------------------------------------------- skills

func _cast(f: Fighter) -> void:
	var s := f.skill
	var a := f.atk_now()
	var tg := f.target if f.target != null and f.target.alive() else _nearest(f, enemies, 900.0)
	f.set_action("skill")
	skill_cast.emit(f)
	Sfx.play("skill")
	_text(f.pos + Vector2(0, -f.height - 40), String(s.get("name", "")), Px.GOLD, 30)
	_fx.append({"kind": "pillar", "pos": f.pos, "t": 0.0, "life": 0.5, "color": DB.fac_color(f.fac)})
	match String(s.get("type", "")):
		"line":
			if tg == null:
				return
			var dir := (tg.pos - f.pos).normalized()
			var length := float(s.get("length", 200))
			var width := float(s.get("width", 100))
			for e in enemies:
				if not e.alive():
					continue
				var rel := e.pos - f.pos
				var along := rel.dot(dir)
				var across := absf(rel.dot(Vector2(-dir.y, dir.x)))
				if along > -20.0 and along < length and across < width * 0.5:
					_deal(f, e, a * float(s["mult"]), false)
			_fx.append({"kind": "slash", "pos": f.pos + Vector2(0, -f.height * 0.4), "dir": dir, "len": length, "w": width, "t": 0.0, "life": 0.35, "color": Color("#bff6ff")})
		"aoe_target":
			if tg == null:
				return
			var c := tg.pos
			for e in enemies:
				if e.alive() and e.pos.distance_to(c) < float(s["radius"]):
					_deal(f, e, a * float(s["mult"]), false)
					e.slow_t = float(s.get("slow", 0.0))
			_fx.append({"kind": "ring", "pos": c, "t": 0.0, "life": 0.6, "color": Color("#9ad7ff"), "r": float(s["radius"])})
		"stun_aoe":
			for e in enemies:
				if e.alive() and e.pos.distance_to(f.pos) < float(s["radius"]):
					_deal(f, e, a * float(s["mult"]), false)
					e.stun = float(s["stun"])
			_fx.append({"kind": "ring", "pos": f.pos, "t": 0.0, "life": 0.5, "color": Color("#ffe14a"), "r": float(s["radius"])})
		"random_strike":
			var alive := enemies.filter(func(e: Fighter) -> bool: return e.alive())
			for i in int(s.get("count", 3)):
				if alive.is_empty():
					break
				var e: Fighter = alive[_rng.randi_range(0, alive.size() - 1)]
				for o in enemies:
					if o.alive() and o.pos.distance_to(e.pos) < float(s.get("radius", 70)):
						_deal(f, o, a * float(s["mult"]), false)
				_fx.append({"kind": "rock", "pos": e.pos, "t": 0.0, "life": 0.45, "color": Color("#a08060")})
		"multi_shot":
			var alive2 := enemies.filter(func(e: Fighter) -> bool: return e.alive())
			alive2.sort_custom(func(x: Fighter, y: Fighter) -> bool: return x.pos.distance_to(f.pos) < y.pos.distance_to(f.pos))
			for i in int(s.get("count", 5)):
				if alive2.is_empty():
					break
				var e: Fighter = alive2[i % alive2.size()]
				_projectiles.append({"pos": f.pos + Vector2(0, -f.height * 0.55), "to": e, "src": f, "mult": float(s["mult"]), "speed": 1000.0 + i * 80.0, "kind": "arrow", "pierce": 0.0})
		"snipe":
			var strongest: Fighter = null
			for e in enemies:
				if e.alive() and (strongest == null or e.hp > strongest.hp):
					strongest = e
			if strongest != null:
				_deal(f, strongest, a * float(s["mult"]), true)
				_fx.append({"kind": "beam", "pos": f.pos + Vector2(0, -f.height * 0.55), "to": strongest.pos + Vector2(0, -strongest.height * 0.5), "t": 0.0, "life": 0.3, "color": Px.GOLD})
		"charm":
			if tg != null:
				tg.stun = float(s.get("time", 3.0))
				_deal(f, tg, a * float(s.get("mult", 1.0)), true)
				_fx.append({"kind": "ring", "pos": tg.pos, "t": 0.0, "life": 0.6, "color": Color("#ff8ad8"), "r": 50.0})
		"debuff_aoe":
			for e in enemies:
				if e.alive() and e.pos.distance_to(f.pos) < float(s["radius"]):
					e.add_buff("enemy_atk", float(s["time"]), float(s["enemy_atk"]))
			f.hp = minf(f.max_hp, f.hp + f.max_hp * float(s.get("heal", 0.0)))
			_fx.append({"kind": "ring", "pos": f.pos, "t": 0.0, "life": 0.5, "color": Color("#b070ff"), "r": float(s["radius"])})
		"ally_all":
			for o in allies:
				if o.alive():
					o.add_buff("atk", float(s["time"]), float(s["atk_mult"]))
					_fx.append({"kind": "pillar", "pos": o.pos, "t": 0.0, "life": 0.4, "color": Color("#ff6a3a")})
		"ally_class":
			for o in allies:
				if o.alive() and o.cls == String(s["cls"]):
					o.add_buff("atk", float(s["time"]), float(s["atk_mult"]))
					_fx.append({"kind": "pillar", "pos": o.pos, "t": 0.0, "life": 0.4, "color": Color("#ff6a3a")})
		"ally_aura":
			for o in allies:
				if o.alive() and o.pos.distance_to(f.pos) < float(s["radius"]):
					o.add_buff("dmg_taken", float(s["time"]), float(s["dmg_taken"]))
			_fx.append({"kind": "ring", "pos": f.pos, "t": 0.0, "life": 0.5, "color": Color("#5fc8ff"), "r": float(s["radius"])})
		"self_buff":
			f.add_buff("aspd", float(s["time"]), float(s.get("aspd_mult", 1.0)))
			f.add_buff("atk", float(s["time"]), float(s.get("atk_mult", 1.0)))
			f.hp = minf(f.max_hp, f.hp + f.max_hp * float(s.get("heal", 0.0)))
		"self_guard":
			f.add_buff("dmg_taken", float(s["time"]), float(s["dmg_taken"]))
			_fx.append({"kind": "ring", "pos": f.pos, "t": 0.0, "life": 0.5, "color": Color("#c0c8d8"), "r": 60.0})
		"heal_ally":
			var low: Fighter = null
			for o in allies:
				if o.alive() and (low == null or o.ratio() < low.ratio()):
					low = o
			if low != null:
				var h := low.max_hp * float(s["heal"])
				low.hp = minf(low.max_hp, low.hp + h)
				_text(low.pos + Vector2(0, -low.height - 10), "+" + str(int(h)), Color("#7cff7c"), 30)
				_fx.append({"kind": "pillar", "pos": low.pos, "t": 0.0, "life": 0.5, "color": Color("#7cff7c")})
		"ally_energy":
			for o in allies:
				if o.alive() and o != f and o.cls == String(s.get("cls", "str")):
					o.energy = minf(99.0, o.energy + float(s["amount"]))
			if tg != null:
				_deal(f, tg, a * float(s.get("mult", 1.0)), true)


func _boss_mech(e: Fighter, dt: float) -> void:
	var m: Dictionary = DB.units["boss_mech"].get(e.mech, {})
	if m.is_empty():
		return
	e.mech_t -= dt
	if e.mech_t > 0.0:
		return
	e.mech_t = float(m["every"])
	var c := e.pos
	if e.mech == "lightning":
		var alive := allies.filter(func(o: Fighter) -> bool: return o.alive())
		if alive.is_empty():
			return
		c = (alive[_rng.randi_range(0, alive.size() - 1)] as Fighter).pos
	_warns.append({"pos": c, "t": float(m["warn"]), "life": float(m["warn"]), "r": float(m["radius"]), "dmg": float(m["dmg"]) * _wave_mult, "stun": float(m["stun"]), "kind": e.mech, "src": e})


func _step_warns(dt: float) -> void:
	var keep: Array = []
	for w: Dictionary in _warns:
		w["t"] = float(w["t"]) - dt
		if float(w["t"]) <= 0.0:
			for o in allies:
				if o.alive() and o.pos.distance_to(w["pos"]) < float(w["r"]):
					_hurt(o, float(w["dmg"]), w["src"], false, false)
					o.stun = float(w["stun"])
			_fx.append({"kind": "bolt" if w["kind"] == "lightning" else "ring", "pos": w["pos"], "t": 0.0, "life": 0.4, "color": Color("#fff27a"), "r": float(w["r"])})
			Sfx.play("bolt" if w["kind"] == "lightning" else "castle")
			if shake_on:
				shake = minf(1.0, shake + 0.4)
			continue
		keep.append(w)
	_warns = keep


# ---------------------------------------------------------------- effects

func _text(p: Vector2, s: String, c: Color, size: int) -> void:
	if _texts.size() > 60:
		_texts.pop_front()
	_texts.append({"pos": p, "s": s, "c": c, "size": size, "t": 0.0, "life": 0.75})


func _step_fx(dt: float) -> void:
	for arr: Array in [_fx, _texts]:
		var i := 0
		while i < arr.size():
			var x: Dictionary = arr[i]
			x["t"] = float(x["t"]) + dt
			if float(x["t"]) >= float(x["life"]):
				arr.remove_at(i)
			else:
				i += 1


func burst(p: Vector2, color: Color) -> void:
	_fx.append({"kind": "pop", "pos": p, "t": 0.0, "life": 0.4, "color": color})


func show_summon(u: UnitState) -> void:
	var f := ally_of(u)
	if f == null:
		sync()
		f = ally_of(u)
	if f == null:
		return
	f.pop = 0.3
	var col := Px.GOLD if u.is_hero() else Color("#7fe0ff")
	_fx.append({"kind": "pillar", "pos": f.pos, "t": 0.0, "life": 0.65, "color": col})
	_fx.append({"kind": "ring", "pos": f.pos, "t": 0.0, "life": 0.55, "color": col, "r": 76.0})
	_fx.append({"kind": "pop", "pos": f.pos, "t": 0.0, "life": 0.45, "color": col})
	_text(f.pos + Vector2(0, -f.height - 28), u.display_name(), col, 26)
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var off := Vector2.ZERO
	if shake > 0.0:
		off = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)).round() * 10.0 * shake
	_off = off
	draw_set_transform(off)
	# 배경: 화면 맨 위부터 전장 아래까지 그림을 깔고 어둡게 한다. 싸우는 곳은 가운데 띠뿐이다.
	var top := -position.y
	Px.cover(self, _bg, Rect2(0, top, size.x, size.y - top))
	draw_rect(Rect2(0, top, size.x, BAND_TOP - top), Color(0.04, 0.06, 0.1, 0.55))
	draw_rect(Rect2(0, BAND_BOTTOM + 40, size.x, size.y - BAND_BOTTOM - 40), Color(0.04, 0.06, 0.1, 0.6))
	# 공터 (가로 띠): 흙바닥 + 위아래 턱
	var band := Rect2(0, BAND_TOP - 20, size.x, BAND_BOTTOM + 40 - (BAND_TOP - 20))
	draw_rect(band, Color("#6b5a3e"))
	for i in 9:
		var gy := band.position.y + 30 + i * (band.size.y - 40) / 9.0
		draw_rect(Rect2(0, gy, size.x, 3), Color(0, 0, 0, 0.06))
	draw_rect(Rect2(0, band.position.y, size.x, 8), Color("#3a2e1e"))
	draw_rect(Rect2(0, band.position.y + 8, size.x, 4), Color("#8a7654"))
	draw_rect(Rect2(0, band.end.y - 8, size.x, 8), Color("#3a2e1e"))
	# 교전선 (세로 점선) + 준비 시간의 아군 자리 표시
	var ly := BAND_TOP
	while ly < BAND_BOTTOM + 20:
		draw_rect(Rect2(LINE_X, ly, 4, 22), Color(1, 1, 1, 0.3))
		ly += 40
	if not fighting:
		draw_rect(Rect2(WALL_X, BAND_TOP - 10, LINE_X - WALL_X, BAND_BOTTOM + 30 - (BAND_TOP - 10)), Color(1, 1, 1, 0.05))
	# 성벽 (왼쪽): 돌벽 + 성가퀴
	var wall := Rect2(0, band.position.y - 60, WALL_X - 14, band.size.y + 60)
	draw_rect(wall, Px.INK)
	draw_rect(wall.grow_individual(-4, -4, -4, 0), Color("#7d7566"))
	var by := wall.position.y + 8
	var row := 0
	while by < wall.end.y - 10:
		draw_rect(Rect2(4, by + 38, wall.size.x - 8, 3), Color(0, 0, 0, 0.18))
		var bx := 4.0 + (22.0 if row % 2 == 1 else 0.0)
		while bx < wall.size.x - 6:
			draw_rect(Rect2(bx, by, 3, 38), Color(0, 0, 0, 0.14))
			bx += 44
		by += 41
		row += 1
	var cx := 0.0
	while cx < wall.size.x:
		draw_rect(Rect2(cx, wall.position.y - 22, 26, 26), Px.INK)
		draw_rect(Rect2(cx + 3, wall.position.y - 19, 20, 23), Color("#8a8272"))
		cx += 40
	draw_rect(Rect2(wall.end.x - 6, wall.position.y, 6, wall.size.y), Color(0, 0, 0, 0.3))
	for w: Dictionary in _warns:
		var k := 1.0 - float(w["t"]) / float(w["life"])
		var c: Vector2 = w["pos"]
		_ellipse(c, float(w["r"]), Color(1, 0.2, 0.15, 0.18 + 0.2 * k))
		_ellipse(c, float(w["r"]) * k, Color(1, 0.3, 0.2, 0.3))
	var all: Array = []
	for f in allies:
		if not f.dead:
			all.append(f)
	for e in enemies:
		all.append(e)
	all.sort_custom(func(a: Fighter, b: Fighter) -> bool: return a.pos.y < b.pos.y)
	for f: Fighter in all:
		_draw_fighter(f)
	for p: Dictionary in _projectiles:
		var tg: Fighter = p["to"]
		var cur: Vector2 = p["pos"]
		var dir: Vector2 = (tg.pos + Vector2(0, -tg.height * 0.5) - cur).normalized()
		if String(p["kind"]) == "arrow":
			# 화살: 흰 촉 1칸 + 나무 자루 3칸 + 깃 1칸 (비스듬해도 칸 단위로)
			_blk(cur, Px.INK, 1.6)
			_blk(cur, Color.WHITE)
			for i in range(1, 4):
				_blk(cur - dir * PXB * i, Color("#c8a060"))
			_blk(cur - dir * PXB * 4, Color("#e85a4a"))
		else:
			# 구슬: 2칸 색 + 1칸 흰 심 + 꼬리 2칸
			var oc := Color("#ff8a3a") if (p["src"] as Fighter).ctr == "fire" else (Color("#ffe14a") if (p["src"] as Fighter).ctr == "thunder" else Color("#7fd8ff"))
			_blk(cur - dir * PXB * 2, Color(oc, 0.5))
			_blk(cur - dir * PXB * 4, Color(oc, 0.3))
			_blk(cur, Px.INK, 2.6)
			_blk(cur, oc, 2.0)
			_blk(cur, Color.WHITE)
	for fx: Dictionary in _fx:
		_draw_fx(fx)
	for t: Dictionary in _texts:
		var k := float(t["t"]) / float(t["life"])
		var p: Vector2 = t["pos"] + Vector2(0, -40.0 * k)
		var c: Color = t["c"]
		c.a = 1.0 - maxf(0.0, k - 0.6) / 0.4
		Px.text(self, String(t["s"]), Rect2(p.x - 120, p.y - 20, 240, 40), int(t["size"]), c)
	if not _hover_ghost.is_empty():
		_draw_ghost()
	draw_set_transform(Vector2.ZERO)


func _ellipse(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.5))
	draw_colored_polygon(pts, col)


func _draw_fighter(f: Fighter) -> void:
	var frames := Art.hued_frames(f.art, f.action, f.hue)
	if frames.is_empty():
		return
	var fps := Art.fps(f.art, f.action)
	var idx := int(f.anim_t * fps)
	if f.action == "attack" or f.action == "skill":
		idx = mini(idx, frames.size() - 1)
	var t: Texture2D = frames[idx % frames.size()]
	var k := f.height / maxf(1.0, Art.frame_h(f.art))
	var sz := (t.get_size() * k).round()
	if f.pop > 0.0:
		var p := f.pop / 0.25
		sz = (sz * Vector2(1.0 - 0.25 * p, 1.0 + 0.35 * p)).round()
	var feet := f.pos.round()
	var a := f.fade if f.side == 1 else 1.0
	var shadow_w := f.height * (0.5 if not f.boss else 0.7)
	draw_rect(Rect2(feet.x - shadow_w * 0.5, feet.y - 5, shadow_w, 10), Color(0, 0, 0, 0.25 * a))
	var star := MetaRules.unit_star(profile, f.unit.id) if f.side == 0 and f.unit != null else 0
	if star >= 3:
		var rcol := Color("#3cc8e8") if star < 5 else Color("#ff9d2e")
		var rc := Color(rcol, 0.36 + 0.14 * sin(_t * 4.0))
		_ellipse(feet, 34.0 + (star - 1) * 3.0, rc)
	var rect := Rect2(Vector2(feet.x - sz.x * 0.5, feet.y - sz.y), sz)
	var mod := Color(1, 1, 1, a)
	if f.flash > 0.0:
		mod = Color(2.6, 2.6, 2.6, a)
	elif f.stun > 0.0:
		mod = Color(0.75, 0.75, 1.1, a)
	elif f.burn_t > 0.0:
		mod = Color(1.25, 0.85, 0.7, a)
	Px.tex_rect(self, t, rect, mod, f.flip, _off)
	if not f.alive():
		return
	# bars
	var bw := 64.0 if not f.boss else 0.0
	if f.boss:
		return  # boss uses the big HUD bar
	if f.elite:
		bw = 96.0
	var by := feet.y - f.height - 18.0
	var bar := Rect2(feet.x - bw * 0.5, by, bw, 12)
	draw_rect(bar, Px.INK)
	draw_rect(bar.grow(-2), Color("#2a1a1a"))
	var col := Px.HP_GREEN if f.side == 0 else Px.HP_RED
	draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2(floorf((bw - 4) * f.ratio()), 8)), col)
	if f.side == 0 and not f.skill.is_empty():
		var eb := Rect2(feet.x - bw * 0.5, by + 12, bw, 8)
		draw_rect(eb, Px.INK)
		draw_rect(Rect2(eb.position + Vector2(2, 2), Vector2(floorf((bw - 4) * f.energy / float(DB.rules["energy_max"])), 4)), Color("#4fc3ff"))
	if f.side == 0 and f.unit != null:
		var tc := Color("#d8cfb8") if star < 3 else (Color("#3cc8e8") if star < 5 else Color("#ffaa22"))
		var tag := "%d성" % star
		var tr := Rect2(feet.x - bw * 0.5 - 38, by - 4, 34, 20)
		draw_rect(tr, Px.INK)
		draw_rect(tr.grow(-2), tc.darkened(0.65))
		Px.text(self, tag, tr, 15, tc)
		if f.unit.is_hero():
			var fc := DB.fac_color(f.fac)
			draw_rect(Rect2(feet.x + bw * 0.5 + 4, by - 2, 14, 18), Px.INK)
			draw_rect(Rect2(feet.x + bw * 0.5 + 6, by, 10, 14), fc)


# ---------------------------------------------------------------- 이펙트 (도트 기준)
# 기준 (design/art/캐릭터-도트-컨셉.md §4):
# - 모든 이펙트는 PXB(8px = 도트 2칸 x 4배) 크기의 네모 칸으로만 그린다. 매끈한 선 · 원 없음.
# - 움직임은 부드럽게 흐르지 않고 4~5단계로 끊어진다 (_stp).
# - 색은 흰 심 + 주색 하나. 사라질 때는 서서히 투명해지지 않고 끝 30%에서 반투명 한 번.

const PXB := 8.0


func _snap(p: Vector2) -> Vector2:
	return (p / PXB).round() * PXB


## One effect block of [param n] cells, centred on the snapped point.
func _blk(p: Vector2, col: Color, n: float = 1.0) -> void:
	var s := PXB * n
	draw_rect(Rect2(_snap(p) - Vector2(s, s) * 0.5, Vector2(s, s)), col)


## Blocks along a line every [param gap] px.
func _blk_line(a: Vector2, b: Vector2, col: Color, n: float = 1.0, gap: float = PXB * 2.0) -> void:
	var d := a.distance_to(b)
	var steps := maxi(1, int(d / gap))
	for i in steps + 1:
		_blk(a.lerp(b, float(i) / steps), col, n)


static func _stp(k: float, steps: int = 4) -> float:
	return floorf(clampf(k, 0.0, 0.999) * steps) / float(steps)


func _draw_fx(fx: Dictionary) -> void:
	var k := clampf(float(fx["t"]) / float(fx["life"]), 0.0, 1.0)
	var ks := _stp(k)
	var p: Vector2 = fx["pos"]
	var c: Color = fx["color"]
	var al := 1.0 if k < 0.7 else 0.5
	var col := Color(c, al)
	var white := Color(1, 1, 1, al)
	var dx := float(fx.get("dx", 1.0))
	match String(fx["kind"]):
		# ---- 타격
		"spark":  # 십자 불꽃
			var arm := 1 + int(ks * 3.0)
			for i in range(1, arm + 1):
				for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					_blk(p + d * PXB * i, col)
			_blk(p, white, 1.4)
		"thrust":  # 창: 가로로 찌르는 줄 + 흰 끝
			var reach := 2 + int(ks * 4.0)
			for i in reach:
				_blk(p + Vector2(dx * PXB * (i - 3), 0), col)
			_blk(p + Vector2(dx * PXB * (reach - 3), 0), white, 1.6)
			_blk(p + Vector2(dx * PXB * (reach - 3), -PXB), white)
			_blk(p + Vector2(dx * PXB * (reach - 3), PXB), white)
		"cut":  # 보병: 비스듬한 베기
			var n := 2 + int(ks * 4.0)
			for i in n:
				var q := p + Vector2(dx * PXB * (i - 2.5) * 1.6, PXB * (i - 2.5) * 1.6)
				_blk(q, col, 1.6)
				_blk(q + Vector2(dx * PXB, -PXB), white)
		"impact":  # 기병: 여덟 방향 충돌 + 발밑 먼지
			var r := PXB * (1.5 + ks * 3.0)
			for i in 8:
				var a := TAU * i / 8.0
				_blk(p + Vector2(cos(a), sin(a)) * r, col, 1.4)
			_blk(p, white, 2.0)
			var feet: Vector2 = fx.get("feet", p)
			for i in 3:
				_blk(feet + Vector2(-dx * PXB * (2 + i * 2 + ks * 4.0), -PXB * (i % 2 + ks * 2.0)), Color("#c8b48a", al), 1.4)
		"pin":  # 화살이 꽂힘: 작은 십자
			for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				_blk(p + d * PXB * (1.0 + ks), col)
			_blk(p, white)
		"flame":  # 화공: 위로 솟는 불꽃 세 줄기
			for i in 3:
				var h := PXB * (1.0 + ks * 4.0 + i)
				_blk(p + Vector2((i - 1) * PXB * 2.0, 0), Color("#ffe14a", al), 1.6)
				_blk(p + Vector2((i - 1) * PXB * 2.0, -h * 0.5), col, 1.6)
				_blk(p + Vector2((i - 1) * PXB * 2.0, -h), Color("#d83a2a", al))
		"zap":  # 뇌공: 위에서 꺾여 내려오는 번개
			var pts := [Vector2(-12, -60), Vector2(6, -42), Vector2(-6, -24), Vector2(12, -12), Vector2(0, 0)]
			var upto := 2 + int(ks * 3.0)
			for i in mini(upto, pts.size() - 1):
				_blk_line(p + pts[i], p + pts[i + 1], col, 1.4, PXB)
			_blk(p, white, 2.0)
		"star":  # 치명타: 금색 네 꼭지 별
			var arm := 2 + int(ks * 2.0)
			for i in range(1, arm + 1):
				for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
					_blk(p + d * PXB * i, col, 1.4 if i == 1 else 1.0)
			for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				_blk(p + d * PXB, col)
			_blk(p, white, 1.6)
		"heal":  # 회복: 떠오르는 초록 십자
			var q := p + Vector2(0, -PXB * ks * 5.0)
			for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				_blk(q + d * PXB, col, 1.4)
			_blk(q, white, 1.4)
		# ---- 등장 · 쓰러짐
		"pop":
			for i in 8:
				var a := TAU * i / 8.0
				_blk(p + Vector2(cos(a), sin(a) * 0.6) * (20.0 + 70.0 * ks) + Vector2(0, -40), col, 1.6)
		"poof":
			for i in 6:
				var a := TAU * i / 6.0 + 0.4
				_blk(p + Vector2(cos(a), sin(a) * 0.5) * (10.0 + 40.0 * ks) + Vector2(0, -20 - 30 * ks), col, 2.6 - ks * 1.2)
		# ---- 기술
		"ring":  # 범위: 칸으로 찍은 타원 테두리
			var r := float(fx.get("r", 80.0)) * (0.4 + 0.6 * ks)
			var n := clampi(int(r / 7.0), 12, 40)
			for i in n:
				var a := TAU * i / n
				_blk(p + Vector2(cos(a) * r, sin(a) * r * 0.5), col, 1.4)
		"pillar":  # 시전: 발밑에서 솟는 기둥 (세력색) + 흰 심
			var h := 40.0 + 180.0 * ks
			var y := 0.0
			while y < h:
				_blk(p + Vector2(-PXB * 3.0, -y), Color(c, 0.45 * al), 2.0)
				_blk(p + Vector2(PXB * 3.0, -y), Color(c, 0.45 * al), 2.0)
				_blk(p + Vector2(0, -y), Color(1, 1, 1, 0.55 * al), 2.0)
				y += PXB * 2.0
		"slash":  # 일직선 기술: 방향을 따라 뻗는 굵은 줄 + 흰 심
			var dir: Vector2 = fx["dir"]
			var l := float(fx["len"]) * minf(1.0, ks * 2.5 + 0.25)
			var thick := clampf(float(fx["w"]) / 30.0, 2.0, 5.0)
			_blk_line(p, p + dir * l, col, thick, PXB * 2.0)
			_blk_line(p, p + dir * l, white, 1.0, PXB * 2.0)
		"rock":  # 낙석: 뚝뚝 끊어지며 떨어지고 먼지 고리
			var fall := minf(1.0, _stp(k * 2.0, 4) + 0.25)
			if k < 0.5:
				_blk(p + Vector2(0, -300.0 * (1.0 - fall) - 18), Px.INK, 6.6)
				_blk(p + Vector2(0, -300.0 * (1.0 - fall) - 18), col, 6.0)
			else:
				var r := 70.0 * (0.5 + _stp((k - 0.5) * 2.0, 3) * 0.5)
				for i in 14:
					var a := TAU * i / 14.0
					_blk(p + Vector2(cos(a) * r, sin(a) * r * 0.5), Color("#c8b48a", al), 1.6)
		"beam":  # 저격: 두 점을 잇는 줄
			var to: Vector2 = fx["to"]
			_blk_line(p, to, col, 2.0, PXB * 2.0)
			_blk_line(p, to, white, 1.0, PXB * 2.0)
			_blk(to, white, 3.0)
		"bolt":  # 낙뢰 (보스): 화면 위에서 꺾여 내려온다, 모양은 고정
			var zig := [0.0, 24.0, -18.0, 30.0, -24.0, 18.0, -30.0, 12.0, 0.0]
			var top := p.y - 700.0
			for i in zig.size() - 1:
				var a := Vector2(p.x + float(zig[i]), lerpf(top, p.y, float(i) / (zig.size() - 1)))
				var b := Vector2(p.x + float(zig[i + 1]), lerpf(top, p.y, float(i + 1) / (zig.size() - 1)))
				_blk_line(a, b, col, 2.4, PXB * 2.0)
				_blk_line(a, b, white, 1.0, PXB * 2.0)
			var r := float(fx.get("r", 90.0))
			for i in 16:
				var a := TAU * i / 16.0
				_blk(p + Vector2(cos(a) * r, sin(a) * r * 0.5), Color(1, 1, 0.6, al), 1.6)


func _draw_ghost() -> void:
	var p: Vector2 = _hover_ghost["pos"]
	var id := String(_hover_ghost["id"])
	var a := Art.of_unit(id)
	var frames := Art.hued_frames(String(a["art"]), "idle", float(a["hue"]))
	if frames.is_empty():
		return
	var t: Texture2D = frames[0]
	var h := Art.target_h(String(a["art"]))
	var k := h / maxf(1.0, Art.frame_h(String(a["art"])))
	var sz := (t.get_size() * k).round()
	var ok: bool = _hover_ghost.get("ok", true)
	var col := Color(1, 1, 1, 0.6) if ok else Color(1, 0.4, 0.4, 0.6)
	_ellipse(p, 40, Color(Px.GOLD, 0.35) if ok else Color(1, 0.2, 0.2, 0.3))
	draw_texture_rect(t, Rect2((p - Vector2(sz.x * 0.5, sz.y)).round(), sz), false, col)
	var label := String(_hover_ghost.get("label", ""))
	if label != "":
		Px.text(self, label, Rect2(p.x - 160, p.y - sz.y - 50, 320, 40), 28, Px.GOLD if ok else Color("#ff8a80"))
