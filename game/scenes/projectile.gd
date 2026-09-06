class_name Projectile
extends Node2D
## Homing shot fired by turrets.

var target: Enemy = null
var damage := 5.0
var splash := 0.0
var speed := 620.0
var march: Node = null
var _color := Color("ffd98a")
var _last_dir := Vector2.RIGHT

func setup(from: Vector2, target_ref: Enemy, dmg: float, splash_r: float, kind: String, march_ref: Node) -> void:
	global_position = from
	target = target_ref
	damage = dmg
	splash = splash_r
	march = march_ref
	_color = Color("ffd98a") if kind == "cannon" else Color("9ad17a")

func _process(delta: float) -> void:
	if is_instance_valid(target):
		_last_dir = (target.global_position + Vector2(0, -8) - global_position).normalized()
	global_position += _last_dir * speed * delta
	if is_instance_valid(target) and global_position.distance_to(target.global_position + Vector2(0, -8)) < 14.0:
		_impact()
	elif not is_instance_valid(target) and (global_position.x < -100 or global_position.x > 820 or global_position.y > 1400):
		queue_free()
	queue_redraw()

func _impact() -> void:
	if splash > 0.0 and march != null:
		march.damage_area(global_position, splash, damage)
	elif is_instance_valid(target):
		target.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, _color)
