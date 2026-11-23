extends Node
## Global state (autoload "Game"): the account Profile, saving, settings and a
## handle to the App that owns the screens. Saves to user://save.json shortly
## after every change.

signal settings_changed

const SAVE_PATH := "user://save.json"

var profile := Profile.new()
var app: App
## Chosen stage and difficulty for the next run.
var next_stage := {"stage": 1, "diff": 1}
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


## 대표 장수 3명 (전투력 순): 로비 · 프로필 · 군웅대전에 보여 준다. 출정 편성은 없다.
func lineup() -> Array:
	var ids: Array = (profile.data["heroes"] as Dictionary).keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return MetaRules.hero_power(profile.data, a) > MetaRules.hero_power(profile.data, b))
	return ids.slice(0, 3)


## Heroes on the reels: every hero, owned or not (개편 §13: 캐릭터는 전투 중 슬롯에서만
## 얻는다 — 처음 나온 장수는 그 자리에서 합류한다).
func sortie_heroes() -> Array:
	return DB.hero_ids()


## Troops on the reels: every troop, owned or not.
func sortie_troops() -> Array:
	return DB.soldier_ids()


func tutorial_done() -> bool:
	return bool(profile.data["tutorial"]["done"])
