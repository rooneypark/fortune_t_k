extends SceneTree
## Headless test runner: godot --headless --path . -s res://tests/run_tests.gd
## Exits 0 when every check passes, 1 otherwise.

const SUITES := [
	"res://tests/unit/test_slot.gd",
	"res://tests/unit/test_run.gd",
	"res://tests/unit/test_battle.gd",
	"res://tests/unit/test_meta.gd",
	"res://tests/unit/test_gacha.gd",
	"res://tests/unit/test_profile.gd",
	"res://tests/unit/test_data.gd",
]


func _initialize() -> void:
	DB.ensure()
	var total := 0
	var failed: Array[String] = []
	for path: String in SUITES:
		var script: GDScript = load(path)
		var t: TestCase = script.new()
		t.run_all()
		total += t.checks
		print("%-40s %4d checks  %s" % [path.get_file(), t.checks, "OK" if t.failures.is_empty() else "FAIL %d" % t.failures.size()])
		for f in t.failures:
			failed.append(path.get_file() + " > " + f)
	print("----")
	for f in failed:
		print("  ✗ ", f)
	print("TOTAL %d checks, %d failed" % [total, failed.size()])
	quit(0 if failed.is_empty() else 1)
