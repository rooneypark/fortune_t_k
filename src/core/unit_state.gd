class_name UnitState
extends RefCounted
## One body recruited during a run. Its 성급 and 속성 are not stored here: they
## belong to the account (per hero / per troop, 개편 §9.1) and are read through
## RunState / MetaRules, so every soldier of a troop shares them.

static var _next_uid := 1

var uid := 0
var id := ""
## Field anchor in battle px (where the unit stands); Vector2.ZERO = auto.
var anchor := Vector2.ZERO
## 체력 비율 (0~1): 부대에 남아 다음 전투로 이어진다 (2026-11-23).
var hp_ratio := 1.0
## Run stats for the MVP card.
var kills := 0
var damage := 0.0


static func create(unit_id: String, _unused: int = 0) -> UnitState:
	var u := UnitState.new()
	u.uid = _next_uid
	_next_uid += 1
	u.id = unit_id
	return u


func is_hero() -> bool:
	return DB.is_hero(id)


func cls() -> String:
	return DB.cls_of(id)


## 병종 of this unit (a hero counts as its troop).
func troop() -> String:
	return DB.troop_of(id)


func display_name() -> String:
	return DB.unit_name(id)
