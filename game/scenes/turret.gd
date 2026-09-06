class_name Turret
extends Node2D
## Mounted weapon. Cannon = single target, mortar = AoE splash.

const STATS := {
	"cannon": {"damage": 9.0, "cooldown": 0.8, "range": 460.0, "splash": 0.0, "color": "6e6a80"},
	"mortar": {"damage": 14.0, "cooldown": 1.9, "range": 420.0, "splash": 70.0, "color": "8f6b4a"},
}

var kind := "cannon"
var _cooldown := 0.0
var _barrel: Node2D
var march: Node = null

func setup(type_name: String, march_ref: Node) -> void:
	kind = type_name
	march = march_ref
	var body_color := Color(STATS[kind]["color"])
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-12, 0), Vector2(12, 0), Vector2(10, -16), Vector2(-10, -16)])
	base.color = body_color.darkened(0.25)
	add_child(base)
	_barrel = Node2D.new()
	_barrel.position = Vector2(0, -16)
	add_child(_barrel)
	var barrel_shape := Polygon2D.new()
	barrel_shape.polygon = PackedVector2Array([
		Vector2(0, -5), Vector2(22, -4), Vector2(22, 3), Vector2(0, 5)])
	barrel_shape.color = body_color
	_barrel.add_child(barrel_shape)

func _process(delta: float) -> void:
	if march == null or not march.has_method("nearest_enemy"):
		return
	_cooldown -= delta * march.run.fire_rate_mult
	var target: Enemy = march.nearest_enemy(global_position, STATS[kind]["range"])
	if target == null:
		return
	_barrel.rotation = (target.global_position - _barrel.global_position).angle()
	if _cooldown <= 0.0:
		_cooldown = STATS[kind]["cooldown"]
		march.spawn_projectile(
			_barrel.global_position, target,
			STATS[kind]["damage"] * march.run.damage_mult,
			STATS[kind]["splash"], kind)
