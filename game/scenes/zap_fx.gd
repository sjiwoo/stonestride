class_name ZapFx
extends Node2D
## Brief lightning arcs for the javelin's storm branch.

var links: Array = []
var life := 0.16

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var a := clampf(life / 0.16, 0.0, 1.0)
	for l: Vector2 in links:
		var to := l - global_position
		var mid1 := to * 0.35 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var mid2 := to * 0.7 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		draw_polyline(PackedVector2Array([Vector2.ZERO, mid1, mid2, to]), Color("c79bf0", a), 2.4)
