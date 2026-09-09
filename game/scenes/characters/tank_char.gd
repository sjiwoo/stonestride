class_name TankChar
extends BaseCharacter
## Stubby cartoon tank. Rumbles along with a fast tread-bounce, a hint of
## pitch, and squash-and-stretch; weapons mount on the flat top deck.

var hull: Node2D
var hull_spr: Sprite2D
var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y
	hull = _joint(self, Vector2.ZERO)
	hull_spr = _sprite(hull, "tank_hull.png", 0.5, Vector2(0, -2), Vector2(0.5, 0.98))
	_make_mounts(hull, [
		Vector2(-76, -110), Vector2(-32, -118), Vector2(12, -118), Vector2(54, -110)])

func _process(delta: float) -> void:
	_t += delta * (2.0 + 9.0 * walk_speed_visual)
	position.y = _base_y - absf(sin(_t)) * 2.2
	hull.rotation = sin(_t * 1.13) * 0.012
	hull_spr.scale.y = 0.5 * (1.0 + sin(_t * 2.0) * 0.018)
