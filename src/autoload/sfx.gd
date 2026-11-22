extends Node
## Sound (autoload "Sfx"): synthesised chiptune effects and two BGM loops from
## assets/sfx (tools/make_sfx.py). Volumes follow the settings sliders.

const DIR := "res://assets/sfx/"
var _players: Array[AudioStreamPlayer] = []
var _bgm: AudioStreamPlayer
var _cache: Dictionary = {}
var _bgm_name := ""
var _sfx_db := 0.0
var muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_bgm = AudioStreamPlayer.new()
	add_child(_bgm)
	if DisplayServer.get_name() == "headless":
		muted = true


func _stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path := DIR + name + ".wav"
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = s
	return s


func play(name: String, pitch: float = 1.0) -> void:
	if muted:
		return
	var s := _stream(name)
	if s == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch
			p.volume_db = _sfx_db
			p.play()
			return


func play_bgm(name: String) -> void:
	if muted or name == _bgm_name:
		return
	_bgm_name = name
	var s := _stream(name)
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * w.mix_rate)
	_bgm.stream = s
	_bgm.play()


func stop_bgm() -> void:
	_bgm_name = ""
	_bgm.stop()


func set_volumes(bgm: float, sfx: float) -> void:
	if _bgm == null:
		return
	_bgm.volume_db = linear_to_db(maxf(0.001, bgm)) - 4.0
	_sfx_db = linear_to_db(maxf(0.001, sfx)) - 2.0
