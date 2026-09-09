class_name PathPicker
extends CanvasLayer
## Seamless checkpoint route choice: a compact bottom sheet with one glowing
## waystone glyph per route — no full-screen map, no 3D flame SubViewports
## (whose shader compiles caused a visible hitch on the old map screen).
## Public API matches the old overlay: set `choices`, listen to `chosen`.

signal chosen(index: int)

const THEME_NAMES := {
	"fire": "Fiery path", "forest": "Forest path", "water": "Water path",
	"boss": "Boss gate", "neutral": "Wastes",
}
const THEME_COLORS := {
	"fire": Color("e05a4e"), "forest": Color("5aa06b"),
	"water": Color("5b9bd5"), "boss": Color("c79bf0"), "neutral": Color("9a93b8"),
}

var choices: Array = []
var drafts: RefCounted = null

var _root: Control
var _picked := false

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_root.add_child(UiKit.fullscreen_dim(0.45))
	var sheet := PanelContainer.new()
	sheet.add_theme_stylebox_override("panel", UiKit.flat_style(Color("221e36"), 22))
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.anchor_top = 1.0
	sheet.offset_top = -400.0
	sheet.offset_bottom = -36.0
	sheet.offset_left = 28.0
	sheet.offset_right = -28.0
	_root.add_child(sheet)
	var clip := Control.new()
	clip.clip_contents = true
	sheet.add_child(clip)
	var strip_path := "res://game/art/map_backdrop.jpg"
	if ResourceLoader.exists(strip_path):
		var strip := TextureRect.new()
		strip.texture = load(strip_path)
		strip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		strip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		strip.set_anchors_preset(Control.PRESET_FULL_RECT)
		strip.modulate = Color(1.15, 1.15, 1.2, 0.5)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(strip)
	var v: VBoxContainer = UiKit.vbox(6)
	sheet.add_child(v)
	var title: Label = UiKit.label("The road forks", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub: Label = UiKit.label("Your route shapes the next draft", 18, UiKit.TEXT_FAINT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var row: HBoxContainer = UiKit.hbox(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(row)
	for i in range(choices.size()):
		row.add_child(_route_card(i, choices[i]))
	_root.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.18)

func _route_card(i: int, choice: Dictionary) -> Control:
	var node: RefCounted = choice["node"]
	var theme_id: String = node.theme
	var col: Color = THEME_COLORS.get(theme_id, UiKit.TEXT_DIM)
	var card := Button.new()
	card.flat = true
	card.custom_minimum_size = Vector2(184, 250)
	card.focus_mode = Control.FOCUS_NONE
	var glyph := Control.new()
	glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.draw.connect(_draw_card.bind(glyph, theme_id, col, bool(node.get("elite"))))
	card.add_child(glyph)
	glyph.set_meta("phase", randf() * TAU)
	var name_l: Label = UiKit.label(String(THEME_NAMES.get(theme_id, theme_id)), 21, col.lightened(0.2))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	name_l.anchor_top = 1.0
	name_l.offset_top = -68.0
	card.add_child(name_l)
	if drafts != null and drafts.has_method("theme_weights") and theme_id in ["fire", "forest", "water"]:
		var w: Dictionary = drafts.theme_weights(theme_id)
		var best := "attack"
		for k: String in w:
			if float(w[k]) > float(w[best]):
				best = k
		var hint: Label = UiKit.label("%d%% %s" % [int(w[best]), best],
			17, UiKit.CATEGORY_COLORS.get(best, UiKit.TEXT_FAINT))
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		hint.anchor_top = 1.0
		hint.offset_top = -36.0
		card.add_child(hint)
	card.pressed.connect(func() -> void: _pick(i))
	return card

func _process(_delta: float) -> void:
	if _root == null:
		return
	for card in _find_glyphs():
		card.queue_redraw()

func _find_glyphs() -> Array:
	var out: Array = []
	for c in _root.find_children("*", "Control", true, false):
		if c.has_meta("phase"):
			out.append(c)
	return out

func _draw_card(glyph: Control, theme_id: String, col: Color, elite: bool) -> void:
	var p := Vector2(glyph.size.x * 0.5, 88.0)
	var radius := 44.0
	var t := float(Time.get_ticks_msec()) / 1000.0 + float(glyph.get_meta("phase"))
	var pulse := 0.5 + 0.5 * sin(t * 3.4)
	glyph.draw_circle(p, radius + 16.0 + pulse * 4.0, Color(col, 0.05 + 0.06 * pulse))
	glyph.draw_arc(p, radius + 8.0 + pulse * 3.0, 0.0, TAU, 40, Color(col, 0.25 + 0.3 * pulse), 2.5, true)
	glyph.draw_circle(p, radius, col.darkened(0.72))
	glyph.draw_arc(p, radius, 0.0, TAU, 44, col, 3.0, true)
	if elite:
		for s in range(8):
			var a := TAU * float(s) / 8.0 + 0.3
			var d := Vector2(cos(a), sin(a))
			glyph.draw_line(p + d * (radius + 2.0), p + d * (radius + 10.0), col, 3.0)
	_draw_glyph(glyph, theme_id, p, radius, col.lightened(0.35))

func _draw_glyph(g: Control, theme_id: String, p: Vector2, radius: float, col: Color) -> void:
	var s := radius / 26.0
	match theme_id:
		"fire":
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -14) * s, p + Vector2(7.5, 1) * s, p + Vector2(-7.5, 1) * s]), col)
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(-8.5, -6) * s, p + Vector2(-2, 0) * s, p + Vector2(-8, 3) * s]), col)
			g.draw_circle(p + Vector2(0, 5) * s, 8.0 * s, col)
			var dark := Color(col.r * 0.25, col.g * 0.1, col.b * 0.08, col.a)
			g.draw_circle(p + Vector2(0, 7) * s, 4.0 * s, dark)
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -4) * s, p + Vector2(3.4, 5) * s, p + Vector2(-3.4, 5) * s]), dark)
		"forest":
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -6) * s, p + Vector2(11, 8) * s, p + Vector2(-11, 8) * s]), col)
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -13) * s, p + Vector2(9, 1) * s, p + Vector2(-9, 1) * s]), col)
			g.draw_rect(Rect2(p + Vector2(-2, 8) * s, Vector2(4, 5) * s), col)
		"water":
			g.draw_circle(p + Vector2(0, 4) * s, 8.0 * s, col)
			g.draw_colored_polygon(PackedVector2Array([
				p + Vector2(0, -13) * s, p + Vector2(6.4, -0.8) * s, p + Vector2(-6.4, -0.8) * s]), col)
			g.draw_circle(p + Vector2(-2.8, 4.5) * s, 1.8 * s, Color(1, 1, 1, col.a * 0.55))
		"boss":
			g.draw_circle(p + Vector2(0, -3) * s, 11.0 * s, col)
			g.draw_rect(Rect2(p + Vector2(-8, 2) * s, Vector2(16, 8) * s), col)
			var dark := Color(0.1, 0.05, 0.05, col.a)
			g.draw_circle(p + Vector2(-4.5, -4) * s, 3.0 * s, dark)
			g.draw_circle(p + Vector2(4.5, -4) * s, 3.0 * s, dark)
			for t in range(3):
				g.draw_rect(Rect2(p + Vector2(-4.5 + float(t) * 3.6, 4) * s, Vector2(1.8, 5) * s), dark)
		_:
			g.draw_circle(p + Vector2(-4, 5) * s, 4.5 * s, col)
			g.draw_circle(p + Vector2(5, 5) * s, 4.0 * s, col)
			g.draw_circle(p + Vector2(0, -3) * s, 5.5 * s, col)

func _pick(i: int) -> void:
	if _picked:
		return
	_picked = true
	Settings.vibrate(12)
	chosen.emit(int(choices[i]["index"]))
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.16)
	tw.tween_callback(queue_free)
