class_name Projectile
extends Node2D
## Mode-driven shot: shell (homing single), splash (homing AoE, may leave
## ash fields or split into bomblets), bolt (straight pierce, may chain).

var cfg := {}
var target: Enemy = null
var march: Node = null
var mode := "shell"
var speed := 620.0
var _dir := Vector2.RIGHT
var _hit: Array = []
var _pierce_left := 0
var _trail: Array = []

func setup(from: Vector2, target_ref: Enemy, config: Dictionary, march_ref: Node) -> void:
	global_position = from
	target = target_ref
	cfg = config
	march = march_ref
	mode = String(cfg.get("mode", "shell"))
	if mode == "bolt":
		speed = 880.0
		_pierce_left = int(cfg.get("pierce", 2))
		if is_instance_valid(target):
			_dir = (target.global_position + Vector2(0, -8) - from).normalized()
	elif mode == "bomblet":
		speed = 520.0

func _process(delta: float) -> void:
	if mode == "bolt":
		_process_bolt(delta)
	else:
		_process_homing(delta)
	queue_redraw()

func _process_homing(delta: float) -> void:
	if is_instance_valid(target):
		_dir = (target.global_position + Vector2(0, -8) - global_position).normalized()
	global_position += _dir * speed * delta
	if bool(cfg.get("magma", false)):
		_trail.append({"p": global_position, "t": 0.3})
	_age_trail(delta)
	if is_instance_valid(target) and global_position.distance_to(target.global_position + Vector2(0, -8)) < 15.0:
		_impact(global_position)
	elif not is_instance_valid(target):
		if global_position.x < -100 or global_position.x > 860 or global_position.y > 1400 or global_position.y < -100:
			queue_free()

func _impact(at: Vector2) -> void:
	if mode == "shell":
		if is_instance_valid(target):
			target.take_damage(float(cfg["damage"]))
			if is_instance_valid(target) and cfg.has("burn_dps"):
				target.apply_burn(float(cfg["burn_dps"]) * march.run.damage_mult, float(cfg["burn_time"]))
	else:
		march.damage_area(at, float(cfg.get("splash", 60)), float(cfg["damage"]))
		if cfg.has("field_dps"):
			march.spawn_ash_field(at, cfg)
		if mode == "splash" and cfg.has("cluster"):
			march.spawn_bomblets(at, cfg)
	queue_free()

func _process_bolt(delta: float) -> void:
	global_position += _dir * speed * delta
	for e_v in march.enemies:
		if not is_instance_valid(e_v) or _hit.has(e_v):
			continue
		var e: Enemy = e_v
		if global_position.distance_to(e.global_position + Vector2(0, -e.radius)) < e.radius + 12.0:
			_hit.append(e)
			var dmg := float(cfg["damage"])
			if e.blocked and cfg.has("blocked_bonus"):
				dmg += float(cfg["blocked_bonus"]) * march.run.damage_mult
			if cfg.has("chain"):
				_chain_from(e)
			e.take_damage(dmg)
			_pierce_left -= 1
			if _pierce_left <= 0:
				queue_free()
				return
	if global_position.x > 900 or global_position.x < -140:
		queue_free()

func _chain_from(source: Enemy) -> void:
	var origin := source.global_position + Vector2(0, -source.radius)
	var links: Array = []
	var struck := 0
	for e_v in march.enemies:
		if struck >= int(cfg["chain"]):
			break
		if not is_instance_valid(e_v) or e_v == source or _hit.has(e_v):
			continue
		var e: Enemy = e_v
		if origin.distance_to(e.global_position) < 150.0:
			links.append(e.global_position + Vector2(0, -e.radius))
			e.take_damage(float(cfg["chain_damage"]) * march.run.damage_mult)
			struck += 1
	if not links.is_empty():
		march.spawn_zap(origin, links)

func _age_trail(delta: float) -> void:
	for t: Dictionary in _trail:
		t["t"] -= delta
	_trail = _trail.filter(func(t: Dictionary) -> bool: return t["t"] > 0.0)

func _draw() -> void:
	match mode:
		"bolt":
			var back := -_dir * 22.0
			draw_line(back, Vector2.ZERO, Color("5b9bd5"), 4.0)
			draw_colored_polygon(PackedVector2Array([
				_dir * 8.0, (-_dir * 2.0) + _dir.orthogonal() * 5.0, (-_dir * 2.0) - _dir.orthogonal() * 5.0]), Color("85b7eb"))
		"splash", "bomblet":
			var r := 5.0 if mode == "splash" else 3.5
			draw_circle(Vector2.ZERO, r, Color("9ad17a"))
			draw_circle(Vector2.ZERO, r * 0.45, Color("eaf3de"))
		_:
			for t: Dictionary in _trail:
				var p: Vector2 = t["p"] - global_position
				draw_circle(p, 2.2 * (t["t"] / 0.3), Color("e05a4e", t["t"] * 2.5))
			if bool(cfg.get("tracer", false)):
				draw_line(-_dir * 14.0, Vector2.ZERO, Color("f0997b", 0.6), 3.0)
			draw_circle(Vector2.ZERO, 4.0, Color("ffd98a"))
			if bool(cfg.get("magma", false)):
				draw_circle(Vector2.ZERO, 2.0, Color("fff3d6"))
