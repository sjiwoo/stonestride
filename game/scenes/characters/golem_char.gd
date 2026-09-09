class_name GolemChar
extends BaseCharacter
## Sprite-rigged hunched golem. Same neanderthal gait as the old vector rig:
## sine-phased arm/leg swings, body sway, knuckle-drag posture — but drawn
## with the Battle-Cats-style sprite parts plus a squash-and-stretch bounce.

const FAR_TINT := Color(0.72, 0.7, 0.78)

var body: Node2D
var body_spr: Sprite2D
var arm_near: Node2D
var arm_far: Node2D
var leg_near: Node2D
var leg_far: Node2D
var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y
	# Draw order: far limbs, body (with mounts), near limbs.
	leg_far = _joint(self, Vector2(-54, -95))
	_sprite(leg_far, "golem_leg.png", 0.19, Vector2.ZERO, Vector2(0.5, 0.06)).modulate = FAR_TINT
	body = _joint(self, Vector2(0, -85))
	arm_far = _joint(body, Vector2(12, -126))
	_sprite(arm_far, "golem_arm.png", 0.37, Vector2.ZERO, Vector2(0.5, 0.07)).modulate = FAR_TINT
	body_spr = _sprite(body, "golem_body.png", 0.44, Vector2(-4, -68))
	_make_mounts(body, [
		Vector2(-84, -58), Vector2(-52, -94), Vector2(-16, -126), Vector2(22, -152)])
	arm_near = _joint(body, Vector2(34, -118))
	_sprite(arm_near, "golem_arm.png", 0.37, Vector2.ZERO, Vector2(0.5, 0.07))
	leg_near = _joint(self, Vector2(-28, -95))
	_sprite(leg_near, "golem_leg.png", 0.19, Vector2.ZERO, Vector2(0.5, 0.06))

func _process(delta: float) -> void:
	_t += delta * 5.2 * walk_speed_visual
	var p := _t
	position.y = _base_y - absf(sin(p)) * 4.0
	body.rotation = sin(p * 2.0) * 0.03
	body_spr.scale.y = 0.44 * (1.0 + sin(p * 2.0) * 0.025)
	arm_near.rotation = sin(p) * 0.4
	arm_far.rotation = sin(p + PI) * 0.4
	leg_near.rotation = sin(p + PI) * 0.45
	leg_far.rotation = sin(p) * 0.45
