class_name Coin
extends Node2D
## Dropped gold. Expires unless tapped; coin_magnet upgrade auto-collects.

signal collected(value: int)

var value := 3
var lifetime := 4.0
var magnet_target: Node2D = null

func _process(delta: float) -> void:
	lifetime -= delta
	if magnet_target != null and is_instance_valid(magnet_target):
		var to_target := magnet_target.global_position + Vector2(0, -90) - global_position
		global_position += to_target.normalized() * 500.0 * delta
		if to_target.length() < 30.0:
			collect()
			return
	if lifetime <= 0.0:
		queue_free()
	queue_redraw()

func collect() -> void:
	collected.emit(value)
	queue_free()

func try_tap(tap_pos: Vector2) -> bool:
	if global_position.distance_to(tap_pos) < 46.0:
		collect()
		return true
	return false

static var _tex: Texture2D = null
static var _tex_checked := false

func _draw() -> void:
	var blink := lifetime < 1.2 and fmod(lifetime, 0.3) < 0.15
	if blink:
		return
	if not _tex_checked:
		_tex_checked = true
		var p := "res://game/art/sprites/coin.png"
		if ResourceLoader.exists(p):
			_tex = load(p)
	if _tex != null:
		draw_texture_rect(_tex, Rect2(-12, -12, 24, 24), false)
	else:
		draw_circle(Vector2.ZERO, 9.0, Color("ffd98a"))
		draw_arc(Vector2.ZERO, 9.0, 0, TAU, 16, Color("b8862e"), 2.0)
		draw_circle(Vector2.ZERO, 3.5, Color("fff3d6"))
