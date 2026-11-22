class_name Fighter
extends RefCounted
## One body on the battlefield (ally or enemy). Plain data: BattleField runs
## the behaviour and draws every fighter itself (one canvas item, y-sorted).

var side := 0  # 0 = ally, 1 = enemy
var id := ""
var unit: UnitState
var art := ""
var hue := 0.0
var height := 86.0
var pos := Vector2.ZERO
var home := Vector2.ZERO
var hp := 1.0
var max_hp := 1.0
var atk := 1.0
var def := 0.0
var reach := 44.0
var spd := 60.0
var aspd := 1.0
var crit := 0.05
var crit_dmg := 0.0
var cls := ""
var fac := ""
var skill: Dictionary = {}
var energy := 0.0
var energy_k := 1.0
var cd := 0.5
var action := "idle"
var anim_t := 0.0
var flip := false
var target: Fighter
var dead := false
var respawn_t := 0.0
var respawn_max := 1.0
var stun := 0.0
var slow_t := 0.0
var burn_t := 0.0
var burn_dps := 0.0
var flash := 0.0
var pop := 0.0
## name -> [seconds left, value]
var buffs: Dictionary = {}
var flags: Dictionary = {}
var boss := false
var elite := false
var mech := ""
var mech_t := 0.0
var castle_t := 0.0
var heal_t := 0.0
var first_hit := false
var ranged := false
var dmg_dealt := 0.0
var kills := 0
var fade := 1.0


func alive() -> bool:
	return not dead and hp > 0.0


func set_action(a: String) -> void:
	if action != a:
		action = a
		anim_t = 0.0


func buff(name: String, default: float = 1.0) -> float:
	if buffs.has(name):
		return float(buffs[name][1])
	return default


func add_buff(name: String, time: float, value: float) -> void:
	buffs[name] = [time, value]


func atk_now() -> float:
	return atk * buff("atk") * buff("enemy_atk") * float(flags.get("syn_atk", 1.0))


func aspd_now() -> float:
	return aspd * buff("aspd") * float(flags.get("syn_aspd", 1.0)) * (0.55 if slow_t > 0.0 else 1.0)


func spd_now() -> float:
	return spd * float(flags.get("syn_spd", 1.0)) * (1.0 - float(DB.rules["slow_ratio"]) if slow_t > 0.0 else 1.0)


func taken_mult() -> float:
	return float(flags.get("dmg_taken", 1.0)) * float(flags.get("syn_dt", 1.0)) * buff("dmg_taken")


func ratio() -> float:
	return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
