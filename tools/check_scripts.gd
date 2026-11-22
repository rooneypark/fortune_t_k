extends Node
## Loads every script under res://src and res://tests so parse errors show up
## in headless runs: godot --headless --path . -s res://tools/check_scripts.gd

func _ready() -> void:
	var bad := 0
	for dir in ["res://src", "res://tests"]:
		bad += _walk(dir)
	print("check_scripts: %d failed" % bad)
	get_tree().quit(1 if bad > 0 else 0)


func _walk(dir: String) -> int:
	var bad := 0
	var d := DirAccess.open(dir)
	if d == null:
		return 0
	for f in d.get_files():
		if f.ends_with(".gd"):
			var s: Script = load(dir + "/" + f)
			if s == null or not s.can_instantiate():
				print("FAILED: ", dir + "/" + f)
				bad += 1
	for sub in d.get_directories():
		bad += _walk(dir + "/" + sub)
	return bad
