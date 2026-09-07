class_name AshField
extends Node2D
## Burning ground patch left by the mortar's ash branch.

var radius := 84.0
var dps := 7.0
var time_left := 3.0
var march: Node = null
var _t := 0.0

func setup(cfg: Dictionary, march_ref: Node) -> void:
	radius = float(cfg["field_radius"])
	dps = float(cfg["field_dps"]) * march_ref.run.damage_mult
	time_left = float(cfg["field_time"])
	march = march_ref

func _process(delta: float) -> void:
	_t += delta
	time_left -= delta
	if time_left <= 0.0:
		queue_free()
		return
	for e_v in march.enemies:
		if not is_instance_valid(e_v):
			continue
		var e: Enemy = e_v
		if global_position.distance_to(e.global_position) <= radius:
			e.take_damage(dps * delta)
	queue_redraw()

func _draw() -> void:
	var fade := clampf(time_left / 0.6, 0.0, 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, radius, Color("e05a4e", 0.16 * fade))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in range(6):
		var fx := -radius * 0.8 + i * radius * 0.32
		var h := (8.0 + 6.0 * sin(_t * (6.0 + i) + i * 2.1)) * fade
		var col := Color("ffb347") if i % 2 == 0 else Color("e05a4e")
		draw_colored_polygon(PackedVector2Array([
			Vector2(fx - 4, 0), Vector2(fx, -h), Vector2(fx + 4, 0)]), Color(col, 0.85 * fade))
