class_name Art
extends RefCounted
## Temporary character art (assets/units — tools/draw_art.py 임시 그림, 출시 전 교체).
## Heroes without their own art borrow a sprite of the same class with a hue
## shift (units.json "art" + "hue").

const MAP := "res://assets/units/art.json"

static var _map: Dictionary = {}
static var _tex: Dictionary = {}
static var _frames: Dictionary = {}


static func ensure() -> void:
	if _map.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP))
		_map = parsed if parsed is Dictionary else {}


static func entry(art: String) -> Dictionary:
	ensure()
	return _map.get(art, {})


## {art, hue, scale} for a recruitable unit or an enemy id.
static func of_unit(id: String) -> Dictionary:
	var d := DB.unit_def(id)
	if d.is_empty():
		d = DB.enemy_def(id)
	return {"art": String(d.get("art", "spear")), "hue": float(d.get("hue", 0.0)), "scale": float(d.get("scale", 1.0))}


static func _load(path: String) -> Texture2D:
	if path == "":
		return null
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[path] = t
	return t


static func resolve(art: String, logical: String) -> String:
	var e := entry(art)
	return String(e.get("alias", {}).get(logical, logical))


static func frames(art: String, logical: String) -> Array:
	var act := resolve(art, logical)
	var key := art + ":" + act
	if _frames.has(key):
		return _frames[key]
	var e := entry(art)
	var arr: Array = []
	var info: Dictionary = e.get("actions", {}).get(act, {})
	for i in int(info.get("frames", 0)):
		var t := _load("%s/%s/%03d.png" % [e.get("dir", ""), act, i])
		if t:
			arr.append(t)
	if arr.is_empty() and act != "idle":
		arr = frames(art, "idle")
	_frames[key] = arr
	return arr


static func fps(art: String, logical: String) -> float:
	var act := resolve(art, logical)
	return float(entry(art).get("actions", {}).get(act, {}).get("fps", 10.0))


static func frame_h(art: String) -> float:
	return float(entry(art).get("frame_h", 64.0))


## Height in battle px the idle frame should have.
static func target_h(art: String) -> float:
	return float(entry(art).get("target_h", 36.0)) * float(DB.rules.get("visual_boost", 2.4))


## Square-ish face icon (portrait), else head, else idle frame.
static func portrait(art: String) -> Texture2D:
	var e := entry(art)
	for k in ["portrait", "head", "illustration"]:
		var t := _load(String(e.get(k, "")))
		if t:
			return t
	var f := frames(art, "idle")
	return f[0] if not f.is_empty() else null


## Avatar bust for portrait frames: generated clean bust if present
## (assets/portraits/avatar_<art>.png), else the head / portrait cut.
static func avatar(art: String) -> Texture2D:
	var t := _load("res://assets/portraits/avatar_%s.png" % art)
	if t:
		return t
	var h := _load(String(entry(art).get("head", "")))
	return h if h else portrait(art)


## Big illustration (lihui) for cards and detail screens, else portrait.
static func illustration(art: String) -> Texture2D:
	var t := _load(String(entry(art).get("illustration", "")))
	return t if t else portrait(art)


static var _hued: Dictionary = {}


## Frames with a hue shift baked in (saturated pixels only, like unit.gdshader).
## Used by the battlefield, which draws every fighter in one canvas item.
static func hued_frames(art: String, logical: String, hue: float) -> Array:
	if absf(hue) < 0.001:
		return frames(art, logical)
	var key := "%s:%s:%.3f" % [art, resolve(art, logical), hue]
	if _hued.has(key):
		return _hued[key]
	var out: Array = []
	for t: Texture2D in frames(art, logical):
		var img := t.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.05 and c.s > 0.25:
					c.h = fposmod(c.h + hue, 1.0)
					img.set_pixel(x, y, c)
		out.append(ImageTexture.create_from_image(img))
	_hued[key] = out
	return out


static func _hue_image(t: Texture2D, hue: float) -> Texture2D:
	var img := t.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.05 and c.s > 0.25:
				c.h = fposmod(c.h + hue, 1.0)
				img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


## Portrait with the unit's hue shift baked in (cached).
static func hued_portrait(art: String, hue: float) -> Texture2D:
	var t := portrait(art)
	if t == null or absf(hue) < 0.001:
		return t
	var key := "p:%s:%.3f" % [art, hue]
	if not _hued.has(key):
		_hued[key] = [_hue_image(t, hue)]
	return _hued[key][0]
