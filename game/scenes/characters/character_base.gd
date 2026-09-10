class_name BaseCharacter
extends Node2D
## Shared base for the three playable characters (golem, longship, tank).
## Subclasses build a sprite rig in _ready and animate Battle-Cats style in
## _process: bobbing, limb swings, squash-and-stretch. The march scene only
## touches walk_speed_visual and mount_points, so characters are swappable.

const IDS := ["golem", "ship", "tank"]
const NAMES := {"golem": "Golem", "ship": "Longship", "tank": "Ironclad"}
## Momentum ability per character: name + one-line hook for the select screen.
const ABILITIES := {
	"golem": {"name": "Stampede", "hook": "Charge through the horde"},
	"ship": {"name": "Broadside", "hook": "Every cat opens fire"},
	"tank": {"name": "Overdrive", "hook": "Nothing slows the treads"},
}
const SCRIPTS := {
	"golem": "res://game/scenes/characters/golem_char.gd",
	"ship": "res://game/scenes/characters/ship_char.gd",
	"tank": "res://game/scenes/characters/tank_char.gd",
}
const SPRITE_DIR := "res://game/art/sprites/"

var walk_speed_visual := 1.0
var mount_points: Array[Node2D] = []

static func create(id: String) -> BaseCharacter:
	return load(String(SCRIPTS.get(id, SCRIPTS["golem"]))).new()

## pivot_frac: which texture point (0..1 fractions) sits on the node origin.
func _sprite(parent: Node2D, tex_name: String, scale_f: float,
		pos := Vector2.ZERO, pivot_frac := Vector2(0.5, 0.5)) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(SPRITE_DIR + tex_name)
	s.scale = Vector2(scale_f, scale_f)
	s.position = pos
	s.offset = s.texture.get_size() * (Vector2(0.5, 0.5) - pivot_frac)
	parent.add_child(s)
	return s

func _joint(parent: Node2D, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	parent.add_child(n)
	return n

func _make_mounts(parent: Node2D, points: Array) -> void:
	for p: Vector2 in points:
		mount_points.append(_joint(parent, p))
