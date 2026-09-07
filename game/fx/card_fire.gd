class_name FlameFrame
extends Control
## Wraps a single content control with an animated flame aura (card_fire.gdshader).
## Plain Control so children keep manual layout; works inside VBox/HBox containers.
## Usage: var f := FlameFrame.wrap(card_panel, Color("e05a4e"), 0.25)

const SHADER := preload("res://game/fx/card_fire.gdshader")

var pad := 16.0
var _content: Control
var _aura: ColorRect
var _mat: ShaderMaterial

static func wrap(content: Control, tint: Color, intensity: float, pad_px: float = 16.0, corner_px: float = 16.0) -> FlameFrame:
	var f := FlameFrame.new()
	f.pad = pad_px
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f._mat = ShaderMaterial.new()
	f._mat.shader = SHADER
	f._mat.set_shader_parameter("tint", tint)
	f._mat.set_shader_parameter("intensity", intensity)
	f._mat.set_shader_parameter("pad", pad_px)
	f._mat.set_shader_parameter("corner", corner_px)
	f._aura = ColorRect.new()
	f._aura.color = Color.WHITE
	f._aura.material = f._mat
	f._aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(f._aura)
	f._content = content
	f.add_child(content)
	f.resized.connect(f._layout)
	content.minimum_size_changed.connect(f.update_minimum_size)
	return f

func set_flame(tint: Color, intensity: float) -> void:
	_mat.set_shader_parameter("tint", tint)
	_mat.set_shader_parameter("intensity", intensity)

func tween_intensity(to_value: float, dur := 0.25) -> void:
	var tw := create_tween()
	tw.tween_property(_mat, "shader_parameter/intensity", to_value, dur)

func _get_minimum_size() -> Vector2:
	if _content == null:
		return Vector2.ZERO
	return _content.get_combined_minimum_size() + Vector2(pad, pad) * 2.0

func _layout() -> void:
	if _content == null:
		return
	_aura.position = Vector2.ZERO
	_aura.size = size
	_mat.set_shader_parameter("rect_size", size)
	_content.position = Vector2(pad, pad)
	_content.size = size - Vector2(pad, pad) * 2.0
