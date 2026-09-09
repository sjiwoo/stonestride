class_name Turret
extends Node2D
## Mounted weapon crewed by a Battle-Cats-style cat sprite. Stats come from
## the armory (weapons.json) with run multipliers applied at fire time; the
## cat leans toward its target and recoils with squash on every shot.

const CAT_TEXTURES := {
	"cannon": "res://game/art/sprites/cat_cannon.png",
	"mortar": "res://game/art/sprites/cat_mortar.png",
	"javelin": "res://game/art/sprites/cat_javelin.png",
}
## Muzzle point as texture fractions (x right, y down from top-left).
const MUZZLES := {
	"cannon": Vector2(0.95, 0.45),
	"mortar": Vector2(0.82, 0.1),
	"javelin": Vector2(0.98, 0.35),
}
const CAT_SCALE := 0.34

var stats := {}
var march: Node = null
var _cooldown := 0.0
var _cat: Sprite2D
var _cat_scale := CAT_SCALE
var _muzzle: Vector2
var _flip := false
var _recoil_tw: Tween = null

func setup(weapon_stats: Dictionary, march_ref: Node) -> void:
	stats = weapon_stats
	march = march_ref
	var weapon := String(stats["weapon"])
	_cat_scale = CAT_SCALE * (1.12 if int(stats.get("level", 1)) >= 2 else 1.0)
	_cat = Sprite2D.new()
	_cat.texture = load(String(CAT_TEXTURES[weapon]))
	var ts: Vector2 = _cat.texture.get_size()
	_cat.offset = Vector2(0, -ts.y * 0.5)  # pivot at the cat's feet
	_cat.scale = Vector2(_cat_scale, _cat_scale)
	add_child(_cat)
	var frac: Vector2 = MUZZLES[weapon]
	_muzzle = Vector2((frac.x - 0.5) * ts.x, (frac.y - 1.0) * ts.y) * _cat_scale
	queue_redraw()

func _accent() -> Color:
	return Color(String(stats.get("color", "e05a4e")))

func _draw() -> void:
	# Branch weapons get an accent glow disc behind the cat.
	if String(stats.get("branch", "")) != "":
		draw_circle(Vector2(0, -20), 26.0, Color(_accent(), 0.18))
		draw_arc(Vector2(0, -20), 26.0, 0.0, TAU, 24, Color(_accent(), 0.5), 2.0, true)

func _process(delta: float) -> void:
	if march == null or not march.has_method("nearest_enemy"):
		return
	_cooldown -= delta * march.run.fire_rate_mult
	var target: Enemy = march.nearest_enemy(global_position, float(stats["range"]))
	if target == null:
		return
	var aim := (target.global_position + Vector2(0, -8) - global_position).angle()
	_cat.rotation = lerp_angle(_cat.rotation, clampf(aim * 0.35, -0.35, 0.5), delta * 8.0)
	if _cooldown <= 0.0:
		_cooldown = float(stats["cooldown"])
		_fire(target)

func _fire(target: Enemy) -> void:
	var cfg := stats.duplicate()
	cfg["damage"] = float(stats["damage"]) * march.run.damage_mult
	var from := global_position + _muzzle.rotated(_cat.rotation)
	if bool(stats.get("twin", false)):
		from += Vector2(0, -5 if _flip else 5).rotated(_cat.rotation)
		_flip = not _flip
	march.spawn_projectile(from, target, cfg)
	if _recoil_tw != null and _recoil_tw.is_running():
		_recoil_tw.kill()
	_cat.scale = Vector2(_cat_scale * 0.86, _cat_scale * 1.1)
	_cat.position.x = -5.0
	_recoil_tw = create_tween()
	_recoil_tw.set_parallel(true)
	_recoil_tw.tween_property(_cat, "scale", Vector2(_cat_scale, _cat_scale), 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_recoil_tw.tween_property(_cat, "position:x", 0.0, 0.22)
