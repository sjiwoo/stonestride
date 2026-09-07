class_name Turret
extends Node2D
## Mounted weapon. Visuals evolve with level/branch; stats come from the
## armory (weapons.json) with run multipliers applied at fire time.

var stats := {}
var march: Node = null
var _cooldown := 0.0
var _barrel: Node2D
var _flip := false
var _t := 0.0

func setup(weapon_stats: Dictionary, march_ref: Node) -> void:
	stats = weapon_stats
	march = march_ref
	_barrel = Node2D.new()
	_barrel.position = Vector2(0, -14)
	_barrel.draw.connect(_draw_barrel)
	add_child(_barrel)
	queue_redraw()

func _accent() -> Color:
	return Color(String(stats.get("color", "e05a4e")))

func _draw() -> void:
	var body := _accent().darkened(0.45)
	draw_rect(Rect2(-12, -14, 24, 14), body)
	draw_rect(Rect2(-12, -14, 24, 3), body.lightened(0.2))
	if int(stats.get("level", 1)) >= 2:
		draw_circle(Vector2(0, -14), 5.0, body.lightened(0.3))

func _draw_barrel() -> void:
	var c := _accent()
	var lvl := int(stats.get("level", 1))
	var branch := String(stats.get("branch", ""))
	var length := 20.0 + lvl * 5.0
	match String(stats["weapon"]):
		"cannon":
			if branch == "twin":
				_barrel.draw_rect(Rect2(0, -8, length, 5), c)
				_barrel.draw_rect(Rect2(0, 1, length, 5), c)
			else:
				_barrel.draw_rect(Rect2(0, -4, length, 7), c)
				if lvl >= 2:
					_barrel.draw_rect(Rect2(length - 6, -5, 3, 9), c.lightened(0.3))
				if branch == "magma":
					_barrel.draw_circle(Vector2(length + 2, 0), 5.0, Color("ffb347"))
					_barrel.draw_circle(Vector2(length + 2, 0), 2.5, Color("fff3d6"))
		"mortar":
			_barrel.draw_rect(Rect2(-2, -6, length - 2, 11), c)
			if lvl >= 2:
				_barrel.draw_arc(Vector2(length - 4, 0), 7.0, 0, TAU, 14, c.lightened(0.35), 2.0)
			if branch == "ash":
				_barrel.draw_circle(Vector2(length + 1, -4), 2.6, Color("ffb347"))
				_barrel.draw_circle(Vector2(length + 2, 3), 2.2, Color("e05a4e"))
			elif branch == "cluster":
				for i in range(3):
					_barrel.draw_circle(Vector2(length - 2 - i * 6, -8), 2.4, c.lightened(0.35))
		"javelin":
			_barrel.draw_rect(Rect2(0, -2, length + 8, 4), c)
			_barrel.draw_colored_polygon(PackedVector2Array([
				Vector2(length + 14, 0), Vector2(length + 5, -5), Vector2(length + 5, 5)]), c.lightened(0.3))
			if branch == "storm":
				_barrel.draw_polyline(PackedVector2Array([
					Vector2(6, -6), Vector2(11, -9), Vector2(9, -5), Vector2(15, -9)]), Color("c79bf0"), 1.6)

func _process(delta: float) -> void:
	if march == null or not march.has_method("nearest_enemy"):
		return
	_t += delta
	_cooldown -= delta * march.run.fire_rate_mult
	var target: Enemy = march.nearest_enemy(global_position, float(stats["range"]))
	if target == null:
		return
	_barrel.rotation = (target.global_position + Vector2(0, -8) - _barrel.global_position).angle()
	if _cooldown <= 0.0:
		_cooldown = float(stats["cooldown"])
		_fire(target)

func _fire(target: Enemy) -> void:
	var cfg := stats.duplicate()
	cfg["damage"] = float(stats["damage"]) * march.run.damage_mult
	var from := _barrel.global_position
	if bool(stats.get("twin", false)):
		from += Vector2(0, -5 if _flip else 5).rotated(_barrel.rotation)
		_flip = not _flip
	march.spawn_projectile(from, target, cfg)
