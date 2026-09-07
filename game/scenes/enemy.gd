class_name Enemy
extends Node2D
## Tiny monster: runs at the golem, presses against its front, chews HP, slows the march.

signal died(enemy: Enemy)

const TYPES := {
	"grunt": {"hp": 20.0, "speed": 110.0, "dps": 1.5, "radius": 10.0, "fill": "c94f4f", "line": "7e2e2e"},
	"runner": {"hp": 12.0, "speed": 190.0, "dps": 1.2, "radius": 8.0, "fill": "b57edc", "line": "6b3f8a"},
	"tank": {"hp": 55.0, "speed": 70.0, "dps": 3.5, "radius": 13.0, "fill": "5aa06b", "line": "2e5e3c"},
	"boss": {"hp": 900.0, "speed": 55.0, "dps": 9.0, "radius": 34.0, "fill": "c79bf0", "line": "6b3f8a"},
}

var kind := "grunt"
var hp := 20.0
var max_hp := 20.0
var speed := 110.0
var dps := 3.0
var radius := 10.0
var blocked := false
var press_offset := 0.0
var _hop := 0.0
var _fill: Color
var _line: Color

func setup(type_name: String, hp_mult: float) -> void:
	kind = type_name
	var cfg: Dictionary = TYPES[type_name]
	max_hp = cfg["hp"] * hp_mult
	hp = max_hp
	speed = cfg["speed"]
	dps = cfg["dps"]
	radius = cfg["radius"]
	_fill = Color(cfg["fill"])
	_line = Color(cfg["line"])
	_hop = randf() * TAU
	press_offset = randf_range(0.0, 26.0)

func take_damage(amount: float) -> bool:
	hp -= amount
	queue_redraw()
	if hp <= 0.0:
		died.emit(self)
		queue_free()
		return true
	return false

func _process(delta: float) -> void:
	_hop += delta * (10.0 if kind == "runner" else 7.0)
	queue_redraw()

func _draw() -> void:
	var bounce := -absf(sin(_hop)) * radius * 0.55
	var c := Vector2(0, bounce - radius)
	draw_ellipse_shadow()
	draw_circle(c, radius, _fill)
	draw_arc(c, radius, 0, TAU, 20, _line, 2.0)
	draw_circle(c + Vector2(radius * 0.3, -radius * 0.2), radius * 0.22, Color("ffffff", 0.85))
	if hp < max_hp:
		var w := radius * 2.0
		draw_rect(Rect2(-w * 0.5, -radius * 2.6, w, 3.0), Color("221f2e"))
		draw_rect(Rect2(-w * 0.5, -radius * 2.6, w * clampf(hp / max_hp, 0.0, 1.0), 3.0), Color("9fe1cb"))

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, radius * 0.9, Color("191624", 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
