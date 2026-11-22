extends Node
## Global state (autoload "Game"): the account Profile, saving, settings and a
## handle to the App that owns the screens. Saves to user://save.json shortly
## after every change.

signal settings_changed

const SAVE_PATH := "user://save.json"

var profile := Profile.new()
var app: App
## Chosen stage for the next run: {chapter, stage}.
var next_stage := {"chapter": 1, "stage": 1}
var save_path := SAVE_PATH
var autosave := true
var _dirty := false
var _save_t := 0.0


func _ready() -> void:
	DB.ensure()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--save="):
			save_path = a.substr(7)
		elif a == "--no-save":
			autosave = false
	if not profile.load_from(save_path):
		profile.reset()
	profile.seed_welcome_mail()
	profile.refresh_periods()
	profile.changed.connect(_on_changed)
	apply_settings()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_changed() -> void:
	_dirty = true
	_save_t = 0.6


func _process(delta: float) -> void:
	if _dirty:
		_save_t -= delta
		if _save_t <= 0.0:
			save_now()


func save_now() -> void:
	_dirty = false
	if autosave:
		profile.save_to(save_path)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_now()


func settings() -> Dictionary:
	return profile.data["settings"]


func set_setting(key: String, value: Variant) -> void:
	profile.data["settings"][key] = value
	apply_settings()
	_on_changed()
	settings_changed.emit()


func apply_settings() -> void:
	var s := settings()
	Px.text_scale = [0.9, 1.0, 1.1][clampi(int(s.get("font", 1)), 0, 2)]
	Sfx.set_volumes(float(s.get("bgm", 0.6)), float(s.get("sfx", 0.8)))


## Slot reel timing multiplier (설정: 빠르게 / 보통 / 끄기).
func slot_speed() -> float:
	return [0.55, 1.0, 0.0][clampi(int(settings().get("slot_speed", 1)), 0, 2)]


func lord_lv() -> int:
	return int(profile.data["lord_lv"])


## 편성 장수 (최대 3명, 보유 장수만). 2026-11-22: 장수 없이 시작할 수 있다.
func lineup() -> Array:
	var out: Array = []
	for id: Variant in profile.data["lineup"]:
		if profile.owns(String(id)) and out.size() < int(DB.rules["hero_lineup_max"]):
			out.append(String(id))
	return out


## Heroes put on the reels for a sortie: exactly the lineup.
func sortie_heroes() -> Array:
	return lineup()


## 병종 4개 for the reels: the troop lineup, topped up with other owned troops.
func sortie_troops() -> Array:
	var n := int(DB.rules["troop_lineup"])
	var out: Array = []
	for id: Variant in profile.data["troop_lineup"]:
		if profile.owns_troop(String(id)) and out.size() < n:
			out.append(String(id))
	for id: String in DB.soldier_ids():
		if out.size() >= n:
			break
		if profile.owns_troop(id) and not out.has(id):
			out.append(id)
	return out


## 책사 slot skill owner, or "" (none).
func advisor() -> String:
	var a := String(profile.data["advisor"])
	return a if profile.owns(a) and not DB.advisor_skill(a).is_empty() else ""


func tutorial_done() -> bool:
	return bool(profile.data["tutorial"]["done"])
