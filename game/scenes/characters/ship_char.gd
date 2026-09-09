class_name ShipChar
extends BaseCharacter
## Cartoony viking longship. Sails over the ground with a wave-swell bob,
## hull rock and sail sway; turret cats crew the deck.

var hull: Node2D
var sail: Sprite2D
var _t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y
	hull = _joint(self, Vector2.ZERO)
	sail = _sprite(hull, "ship_sail.png", 0.42, Vector2(-42, -82), Vector2(0.5, 0.95))
	_sprite(hull, "ship_hull.png", 0.55, Vector2(0, -4), Vector2(0.5, 0.97))
	_make_mounts(hull, [
		Vector2(-112, -104), Vector2(-62, -112), Vector2(-8, -112), Vector2(46, -104)])

func _process(delta: float) -> void:
	_t += delta * (1.6 + 2.6 * walk_speed_visual)
	position.y = _base_y - 3.0 - sin(_t * 0.9) * 4.0 - absf(sin(_t * 1.7)) * 2.0
	hull.rotation = sin(_t * 0.8) * 0.045
	sail.rotation = sin(_t * 0.8 + 0.7) * 0.05
	sail.scale.x = 0.42 * (1.0 + sin(_t * 1.1) * 0.03)
