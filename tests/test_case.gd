class_name TestCase
extends RefCounted
## Minimal test base (no plugin needed). Methods named test_* run in order.

var failures: Array[String] = []
var checks := 0
var _current := ""


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append("%s: %s" % [_current, msg])


func eq(a: Variant, b: Variant, msg: String) -> void:
	check(a == b, "%s (got %s, want %s)" % [msg, str(a), str(b)])


func near(a: float, b: float, tol: float, msg: String) -> void:
	check(absf(a - b) <= tol, "%s (got %.4f, want %.4f ±%.4f)" % [msg, a, b, tol])


func run_all() -> void:
	for m: Dictionary in get_method_list():
		var n := String(m["name"])
		if n.begins_with("test_"):
			_current = n
			call(n)


## Fixed grid helper: rows given top->bottom as [[r0c0, r0c1, r0c2], ...] -> grid[reel][row].
static func grid_rows(rows: Array) -> Array:
	var g: Array = [[], [], []]
	for row: Array in rows:
		for r in 3:
			g[r].append(row[r])
	return g
