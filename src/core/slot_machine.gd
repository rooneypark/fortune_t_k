class_name SlotMachine
extends RefCounted
## 천명 슬롯 (스테이지-흡수-합성-개편 §9.9, 2026-11-23): three independent reels.
## Each reel stops on a unit ("당첨", slot_win_chance = 1/3) or on a blank ("꽝").
## Every winning reel recruits its unit; three wins are a 잭팟. A winning reel shows
## a hero with slot_hero_chance, otherwise a soldier. Which hero / troop: by grade
## and tier odds (Gacha.slot_hero / slot_soldier) out of the lists given to setup —
## in the game that is every hero and troop, owned or not (개편 §13: 캐릭터는
## 전투 중 슬롯에서만 얻는다).
## The cells just above and below each result cell are real cells and stay visible:
## after a spin with a blank, one blank reel may be shifted once so that its upper
## or lower neighbour slides into the result row (재배치, 위아래 둘 다).
## Pure rules: no nodes; every random number comes from the injected rng.

const REELS := 3

## Hero / soldier ids that can appear.
var heroes: Array = []
var soldiers: Array = []
## Reel strips for the view: 3 Arrays of unit ids or "" (blank). Only the cell
## at the stop index counts; the rest are decoys that scroll past.
var strips: Array = []
## Index of the result cell on each strip.
var stops: Array = [0, 0, 0]
## True while one blank reel may still be shifted (재배치).
var can_nudge := false
## Pending scripted result (tutorial / tests): {cells: [id or ""] x3,
## above: [id or ""] x3, below: [id or ""] x3} — above / below are optional.
var forced: Dictionary = {}

var _length := 12


func setup(hero_ids: Array, soldier_ids: Array, length: int, rng: RandomNumberGenerator) -> void:
	heroes = hero_ids.duplicate()
	soldiers = soldier_ids.duplicate()
	_length = maxi(4, length)
	strips.clear()
	for _r in REELS:
		strips.append(_decoys(rng))
	stops = [0, 0, 0]
	for r in REELS:
		strips[r][0] = ""
	can_nudge = false


## Result of [param reel]: a unit id, or "" for a blank.
func cell(reel: int) -> String:
	return String(strips[reel][int(stops[reel])])


func cells() -> Array:
	return [cell(0), cell(1), cell(2)]


static func win_chance() -> float:
	return float(DB.rules["slot_win_chance"])


static func hero_chance() -> float:
	return float(DB.rules["slot_hero_chance"])


## One winning unit: a hero with [param hero_p] (when the list has any), else a soldier.
func _unit(rng: RandomNumberGenerator, hero_p: float) -> String:
	if not heroes.is_empty() and (soldiers.is_empty() or rng.randf() < hero_p):
		return Gacha.slot_hero(rng, heroes)
	if soldiers.is_empty():
		return ""
	return Gacha.slot_soldier(rng, soldiers)


func _roll(rng: RandomNumberGenerator, win_p: float, hero_p: float) -> String:
	return _unit(rng, hero_p) if rng.randf() < win_p else ""


## The rest of a strip. Its cells are rolled at the real odds, because the two
## next to the result can be shifted into the row (재배치).
func _decoys(rng: RandomNumberGenerator) -> Array:
	var strip: Array = []
	for _i in _length:
		strip.append(_roll(rng, win_chance(), hero_chance()))
	return strip


## The cell [param off] steps from the result of [param reel] (-1 = above, +1 = below).
func peek(reel: int, off: int) -> String:
	var strip: Array = strips[reel]
	return String(strip[posmod(int(stops[reel]) + off, strip.size())])


func _put(reel: int, off: int, id: String) -> void:
	var strip: Array = strips[reel]
	strip[posmod(int(stops[reel]) + off, strip.size())] = id


func _set_reel(reel: int, id: String, rng: RandomNumberGenerator) -> void:
	strips[reel] = _decoys(rng)
	stops[reel] = rng.randi_range(0, _length - 1)
	strips[reel][int(stops[reel])] = id


## Spins all reels. [param lucky]: win chance slot_lucky_chance for this spin.
## [param hero_boost]: winning reels show a hero with slot_boost_hero_chance.
## [param min_wins]: at least this many reels win (RunState asks for 1 while the
## field is empty, so a run can never stall with no unit and no 군량).
func spin(rng: RandomNumberGenerator, hero_boost := false, lucky := false, min_wins := 0) -> Dictionary:
	var win_p := float(DB.rules["slot_lucky_chance"]) if lucky else win_chance()
	var hero_p := float(DB.rules["slot_boost_hero_chance"]) if hero_boost else hero_chance()
	for r in REELS:
		_set_reel(r, _roll(rng, win_p, hero_p), rng)
	var have := 0
	for r in REELS:
		if cell(r) != "":
			have += 1
	for r in REELS:
		if have >= min_wins:
			break
		if cell(r) == "":
			strips[r][int(stops[r])] = _unit(rng, hero_p)
			have += 1
	if not forced.is_empty():
		for r in REELS:
			_put(r, 0, String(forced["cells"][r]))
			if forced.has("above"):
				_put(r, -1, String(forced["above"][r]))
			if forced.has("below"):
				_put(r, 1, String(forced["below"][r]))
		forced = {}
	var res := evaluate(cells(), [0, 1, 2])
	can_nudge = (res["wins"] as Array).size() < REELS
	return res


## 재배치: shifts one blank reel by one cell. [param dir] +1 = down (the cell above
## slides into the row), -1 = up (the cell below slides in). Allowed once after a
## spin with a blank. Returns the new result (recruits = that reel only), or {}
## when not allowed.
func nudge(reel: int, dir: int) -> Dictionary:
	if not can_nudge or reel < 0 or reel >= REELS or absi(dir) != 1 or cell(reel) != "":
		return {}
	can_nudge = false
	stops[reel] = posmod(int(stops[reel]) - dir, (strips[reel] as Array).size())
	return evaluate(cells(), [reel])


## Shifts that would bring a unit into the row now: [[reel, dir]].
func nudge_wins() -> Array:
	var out: Array = []
	if not can_nudge:
		return out
	for r in REELS:
		if cell(r) != "":
			continue
		if peek(r, -1) != "":
			out.append([r, 1])
		if peek(r, 1) != "":
			out.append([r, -1])
	return out


## Spins one blank reel again (책사 "한 칸 다시"). Ends the 재배치 chance.
## Returns {} when the reel is not a blank.
func respin_reel(reel: int, rng: RandomNumberGenerator) -> Dictionary:
	if reel < 0 or reel >= REELS or cell(reel) != "":
		return {}
	can_nudge = false
	_set_reel(reel, _roll(rng, win_chance(), hero_chance()), rng)
	return evaluate(cells(), [reel])


## First blank reel, or -1.
func first_blank() -> int:
	for r in REELS:
		if cell(r) == "":
			return r
	return -1


## Evaluates three cells. [param fresh] = reels that were just spun: only those
## recruit. Returns:
##   cells:    [id or ""] x3
##   wins:     reel indices showing a unit
##   recruits: [{id, reel}] for the fresh winning reels
##   jackpot:  all three reels show a unit and this spin added at least one
static func evaluate(c: Array, fresh: Array) -> Dictionary:
	var wins: Array = []
	var recruits: Array = []
	for r in c.size():
		var id := String(c[r])
		if id == "":
			continue
		wins.append(r)
		if fresh.has(r):
			recruits.append({"id": id, "reel": r})
	return {"cells": c.duplicate(), "wins": wins, "recruits": recruits,
		"jackpot": wins.size() == REELS and not recruits.is_empty()}


## Chance of exactly [param n] winning reels on a normal spin (for the odds text).
static func chance_of(n: int) -> float:
	var p := win_chance()
	var comb: int = [1, 3, 3, 1][clampi(n, 0, 3)]
	return comb * pow(p, n) * pow(1.0 - p, REELS - n)
