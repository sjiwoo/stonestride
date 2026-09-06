class_name Golem
extends Node2D
## The walking base. Procedurally animated hunched gait: jointed shoulders,
## elbows, hips, and knees driven by sine phases, mirroring the concept art.

const STONE := Color("8a8599")
const STONE_DARK := Color("77728a")
const STONE_FAR := Color("5f5a73")
const OUTLINE := Color("454157")
const OUTLINE_FAR := Color("39344c")
const MOSS := Color("5e8a5a")
const CORE := Color("ffb347")
const CORE_HOT := Color("fff3d6")

var walk_speed_visual := 1.0
var _t := 0.0
var _core_pulse := 0.0
var _base_y := 0.0

var arm_far: Node2D
var elbow_far: Node2D
var leg_far: Node2D
var knee_far: Node2D
var body: Node2D
var arm_near: Node2D
var elbow_near: Node2D
var leg_near: Node2D
var knee_near: Node2D
var core_shape: Polygon2D
var mount_points: Array[Node2D] = []

func _ready() -> void:
	_base_y = position.y
	arm_far = _joint(self, Vector2(16, -108))
	elbow_far = _build_arm(arm_far, STONE_FAR, OUTLINE_FAR)
	leg_far = _joint(self, Vector2(-42, -50))
	knee_far = _build_leg(leg_far, STONE_FAR, OUTLINE_FAR)
	body = _joint(self, Vector2.ZERO)
	_build_body(body)
	arm_near = _joint(self, Vector2(22, -110))
	elbow_near = _build_arm(arm_near, STONE_DARK, OUTLINE)
	leg_near = _joint(self, Vector2(-36, -50))
	knee_near = _build_leg(leg_near, STONE_DARK, OUTLINE)

func _joint(parent: Node2D, pos: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	parent.add_child(n)
	return n

func _shape(parent: Node2D, points: PackedVector2Array, fill: Color, line: Color, pos := Vector2.ZERO) -> Node2D:
	var holder := Node2D.new()
	holder.position = pos
	var p := Polygon2D.new()
	p.polygon = points
	p.color = fill
	holder.add_child(p)
	var outline := Line2D.new()
	var closed := points.duplicate()
	closed.append(points[0])
	outline.points = closed
	outline.width = 3.0
	outline.default_color = line
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	holder.add_child(outline)
	parent.add_child(holder)
	return holder

func _circle(r: float, n: int = 14) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(n):
		var a := TAU * i / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

func _build_arm(shoulder: Node2D, fill: Color, line: Color) -> Node2D:
	_shape(shoulder, _circle(15.0), fill, line)
	_shape(shoulder, PackedVector2Array([
		Vector2(-13, -4), Vector2(13, 0), Vector2(9, 56), Vector2(-11, 54)]), fill, line)
	var elbow := _joint(shoulder, Vector2(0, 54))
	_shape(elbow, _circle(11.0), fill, line)
	_shape(elbow, PackedVector2Array([
		Vector2(-11, -2), Vector2(11, -4), Vector2(13, 44), Vector2(-9, 46)]), fill, line)
	_shape(elbow, _circle(14.0, 12), fill, line, Vector2(3, 56))
	return elbow

func _build_leg(hip: Node2D, fill: Color, line: Color) -> Node2D:
	_shape(hip, PackedVector2Array([
		Vector2(-12, -6), Vector2(12, -6), Vector2(9, 32), Vector2(-9, 32)]), fill, line)
	var knee := _joint(hip, Vector2(0, 32))
	_shape(knee, _circle(8.0), fill, line)
	_shape(knee, PackedVector2Array([
		Vector2(-8, -2), Vector2(8, -2), Vector2(7, 28), Vector2(-7, 28)]), fill, line)
	_shape(knee, PackedVector2Array([
		Vector2(-8, 28), Vector2(14, 28), Vector2(14, 36), Vector2(-10, 36)]), fill, line)
	return knee

func _build_body(b: Node2D) -> void:
	_shape(b, PackedVector2Array([
		Vector2(-60, -40), Vector2(-52, -78), Vector2(-24, -110), Vector2(14, -128),
		Vector2(48, -126), Vector2(54, -104), Vector2(38, -84), Vector2(6, -72),
		Vector2(-24, -58), Vector2(-46, -34)]), STONE, OUTLINE)
	_shape(b, PackedVector2Array([
		Vector2(-8, 0), Vector2(-16, -14), Vector2(-4, -24), Vector2(6, -16),
		Vector2(2, -4)]), MOSS, MOSS.darkened(0.3), Vector2(-26, -96))
	var head := _joint(b, Vector2(44, -114))
	_shape(head, PackedVector2Array([
		Vector2(-14, 8), Vector2(-12, -12), Vector2(2, -20), Vector2(16, -14),
		Vector2(18, 2), Vector2(4, 10)]), STONE, OUTLINE)
	var eye := ColorRect.new()
	eye.size = Vector2(11, 6)
	eye.position = Vector2(4, -10)
	eye.color = Color("ffd98a")
	head.add_child(eye)
	_shape(b, _circle(18.0), Color("3a3350"), OUTLINE, Vector2(14, -80))
	var core_holder := _shape(b, _circle(11.0, 12), CORE, CORE, Vector2(14, -80))
	core_shape = core_holder.get_child(0)
	for i in range(4):
		var m := _joint(b, Vector2(-46 + i * 27, -70 - i * 15))
		mount_points.append(m)

func _process(delta: float) -> void:
	_t += delta * 5.2 * walk_speed_visual
	_core_pulse += delta * 3.0
	var p := _t
	position.y = _base_y - absf(sin(p)) * 4.0
	body.rotation = sin(p * 2.0) * 0.03
	arm_near.rotation = sin(p) * 0.42
	elbow_near.rotation = maxf(0.0, -sin(p)) * 0.5 + 0.1
	arm_far.rotation = sin(p + PI) * 0.42
	elbow_far.rotation = maxf(0.0, -sin(p + PI)) * 0.5 + 0.1
	leg_near.rotation = sin(p + PI) * 0.5
	knee_near.rotation = maxf(0.0, sin(p + PI)) * 0.55 + 0.12
	leg_far.rotation = sin(p) * 0.5
	knee_far.rotation = maxf(0.0, sin(p)) * 0.55 + 0.12
	core_shape.scale = Vector2.ONE * (1.0 + sin(_core_pulse) * 0.18)
	core_shape.color = CORE.lerp(CORE_HOT, (sin(_core_pulse) + 1.0) * 0.35)
