class_name UnitState
extends RefCounted
## One unit owned during a run (GDD v5 §3.4): what it is, its in-run rank
## (1-3, gold bands) built from absorb experience, and the traits it took.
## Ranks and traits vanish when the run ends.

static var _next_uid := 1

var uid := 0
var id := ""
## Absorb experience (same unit 2, same class 1). Rank thresholds come from rules.
var xp := 0
var rank := 1
## Trait ids (GDD §3.4b). Slots = rank.
var traits: Array[String] = []
## Field anchor in battle px (where the unit stands); Vector2.ZERO = auto.
var anchor := Vector2.ZERO
## Run stats for the MVP card.
var kills := 0
var damage := 0.0


static func create(unit_id: String, start_xp: int = 0) -> UnitState:
	var u := UnitState.new()
	u.uid = _next_uid
	_next_uid += 1
	u.id = unit_id
	u.add_xp(start_xp)
	return u


func is_hero() -> bool:
	return DB.is_hero(id)


func cls() -> String:
	return DB.cls_of(id)


func display_name() -> String:
	return DB.unit_name(id)


static func rank_for(total_xp: int) -> int:
	var thresholds: Array = DB.rules["rank_absorbs"]
	var r := 1
	for i in thresholds.size():
		if total_xp >= int(thresholds[i]):
			r = i + 1
	return mini(r, int(DB.rules["rank_max"]))


func is_max_rank() -> bool:
	return rank >= int(DB.rules["rank_max"])


## Adds experience; returns ranks gained. Excess past max rank is kept but has no effect.
func add_xp(amount: int) -> int:
	var before := rank
	xp += amount
	rank = rank_for(xp)
	return rank - before


## Experience needed for the next rank, or -1 at max.
func next_threshold() -> int:
	if is_max_rank():
		return -1
	return int(DB.rules["rank_absorbs"][rank])


func rank_mult() -> float:
	return float(DB.rules["rank_mult"][rank - 1])


func trait_slots() -> int:
	return rank


func has_trait(trait_id: String) -> bool:
	return traits.has(trait_id)
