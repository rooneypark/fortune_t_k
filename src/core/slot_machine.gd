class_name SlotMachine
extends RefCounted
## 천명 슬롯 (GDD v5 §3.2, 2026-11-22 재설계): 3 reels x 3 visible rows, 5
## paylines (3 rows + 2 diagonals). A line matches when its three cells are the
## same 병종 (a hero counts as its troop: 창병·창병·관우). A matching line with a
## hero recruits only the hero; without one, one soldier. A miss gives nothing
## but allows one nudge.
## Pure rules: no nodes; every random number comes from the injected rng.

const REELS := 3
const ROWS := 3
## Paylines as [reel, row]: rows 0-2, then the two diagonals.
const LINES := [
	[[0, 0], [1, 0], [2, 0]],
	[[0, 1], [1, 1], [2, 1]],
	[[0, 2], [1, 2], [2, 2]],
	[[0, 0], [1, 1], [2, 2]],
	[[0, 2], [1, 1], [2, 0]],
]

## Reel strips: 3 Arrays of unit ids.
var strips: Array = []
## Top visible index of each reel.
var stops: Array = [0, 0, 0]
## True while the current result may still be nudged (a miss, not nudged yet).
var can_nudge := false
## Pending scripted result (tutorial): {cols: [[ids top->bottom]x3], above: [id or ""]x3}.
var forced: Dictionary = {}


## Builds three strips from the lineup heroes and the basic soldiers.
func setup(heroes: Array, soldiers: Array, length: int, w_soldier: int, w_hero: int,
		rng: RandomNumberGenerator) -> void:
	var pool: Array = []
	for s in soldiers:
		for _i in w_soldier:
			pool.append(String(s))
	for h in heroes:
		for _i in w_hero:
			pool.append(String(h))
	strips.clear()
	for _r in REELS:
		var strip: Array = []
		for _i in length:
			strip.append(pool[rng.randi_range(0, pool.size() - 1)])
		strips.append(strip)
	stops = [0, 0, 0]
	can_nudge = false


## Unit id at [param reel], [param row] (0 = top); row may be -1 or 3 (just outside).
func cell(reel: int, row: int) -> String:
	var strip: Array = strips[reel]
	return strip[posmod(int(stops[reel]) + row, strip.size())]


## Visible grid as grid[reel][row].
func grid() -> Array:
	var g: Array = []
	for r in REELS:
		g.append([cell(r, 0), cell(r, 1), cell(r, 2)])
	return g


func _hero_cells(reel: int, stop: int) -> int:
	var strip: Array = strips[reel]
	var n := 0
	for row in ROWS:
		if DB.is_hero(String(strip[posmod(stop + row, strip.size())])):
			n += 1
	return n


## Spins all reels. [param hero_boost]: each reel rolls twice and keeps the stop
## showing more heroes (책사 "인재 등용"). Returns the evaluated result.
func spin(rng: RandomNumberGenerator, hero_boost := false) -> Dictionary:
	for r in REELS:
		var size := (strips[r] as Array).size()
		var s := rng.randi_range(0, size - 1)
		if hero_boost:
			var s2 := rng.randi_range(0, size - 1)
			if _hero_cells(r, s2) > _hero_cells(r, s):
				s = s2
		stops[r] = s
	if not forced.is_empty():
		_apply_forced()
	var res := evaluate(grid())
	can_nudge = (res["lines"] as Array).is_empty()
	return res


func _apply_forced() -> void:
	var cols: Array = forced["cols"]
	var above: Array = forced.get("above", ["", "", ""])
	for r in REELS:
		var strip: Array = strips[r]
		var top := int(stops[r])
		var col: Array = cols[r]
		for row in col.size():
			strip[posmod(top + row, strip.size())] = col[row]
		if String(above[r]) != "":
			strip[posmod(top - 1, strip.size())] = above[r]
	forced = {}


## Moves one reel by one tile (dir -1 = up, +1 = down: the tile above slides in).
## Allowed once after a miss. Returns the new result, or {} when not allowed.
func nudge(reel: int, dir: int) -> Dictionary:
	if not can_nudge or reel < 0 or reel >= REELS or absi(dir) != 1:
		return {}
	can_nudge = false
	stops[reel] = posmod(int(stops[reel]) - dir, (strips[reel] as Array).size())
	return evaluate(grid())


## Spins one reel again (책사 "한 줄 다시"). Ends the nudge chance.
func respin_reel(reel: int, rng: RandomNumberGenerator) -> Dictionary:
	stops[reel] = rng.randi_range(0, (strips[reel] as Array).size() - 1)
	var res := evaluate(grid())
	can_nudge = false
	return res


## Match kind of three unit ids: "unit" (same id), "troop" (same 병종 — a hero
## counts as its own troop, e.g. spear, spear, guanyu) or "".
static func line_kind(a: String, b: String, c: String) -> String:
	if a == b and b == c:
		return "unit"
	var ta := DB.troop_of(a)
	if ta != "" and ta == DB.troop_of(b) and ta == DB.troop_of(c):
		return "troop"
	return ""


## Evaluates a grid (grid[reel][row]). Returns:
##   lines:    [{index, kind, cells, ids, troop, heroes}] for every matching payline
##             heroes = hero ids on that line (a hero line recruits only the heroes)
##   recruits: kept for callers/tests: one entry per line — the heroes on it, or
##             one soldier of the troop when there is no hero.
##   factions: always empty (세력 줄은 2026-11-22에 없앴다)
static func evaluate(g: Array) -> Dictionary:
	var lines: Array = []
	var recruits: Array = []
	for i in LINES.size():
		var cells: Array = LINES[i]
		var ids: Array = []
		for c: Array in cells:
			ids.append(String(g[c[0]][c[1]]))
		var kind := line_kind(ids[0], ids[1], ids[2])
		if kind == "":
			continue
		var heroes: Array = []
		for id: String in ids:
			if DB.is_hero(id) and not heroes.has(id):
				heroes.append(id)
		var troop := DB.troop_of(String(ids[0]))
		lines.append({"index": i, "kind": kind, "cells": cells, "ids": ids, "troop": troop, "heroes": heroes})
		if heroes.is_empty():
			recruits.append({"id": troop, "xp": 0, "kind": kind})
		else:
			for h: String in heroes:
				recruits.append({"id": h, "xp": 0, "kind": kind})
	return {"lines": lines, "recruits": recruits, "factions": []}
