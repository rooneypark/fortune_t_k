class_name DrawLayer
extends Control
## A transparent control whose _draw calls [member fn](self). Used to stack
## frames and labels over ArtRect pictures.

var fn: Callable


static func make(f: Callable, sz := Vector2.ZERO) -> DrawLayer:
	var d := DrawLayer.new()
	d.fn = f
	d.size = sz
	return d


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if fn.is_valid():
		fn.call(self)
