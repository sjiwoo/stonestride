extends Node
## Seamless scene transitions: radial wipe overlay that covers, swaps, reveals.
## Usage: Router.goto("res://game/scenes/march.tscn")

signal transition_finished

const WIPE_TIME := 0.35

var _overlay: ColorRect
var _busy := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://game/fx/transition.gdshader")
	mat.set_shader_parameter("progress", 0.0)
	_overlay.material = mat
	layer.add_child(_overlay)

func goto(path: String, instant := false) -> void:
	if _busy:
		return
	_busy = true
	if not instant:
		await _wipe(0.0, 1.0)
	get_tree().paused = false
	var err := get_tree().change_scene_to_file(path)
	assert(err == OK)
	await get_tree().process_frame
	await get_tree().process_frame
	if not instant:
		await _wipe(1.0, 0.0)
	_busy = false
	transition_finished.emit()

func _wipe(from_p: float, to_p: float) -> void:
	var mat: ShaderMaterial = _overlay.material
	var tw := create_tween()
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("progress", v),
		from_p, to_p, WIPE_TIME
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
