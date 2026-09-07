class_name PathOverlay
extends CanvasLayer
## Full-screen visual path map (Slay-the-Spire style, journey bottom-to-top).
## Selection is purely visual: tap a pulsing waystone — no text anywhere.
## Procedurally laid out per run: node jitter and trail bends are seeded from
## the run seed, so the same run always shows the same map.
## Public API unchanged: set `choices` + `drafts`, listen to `chosen(index)`.

signal chosen(index: int)

const ROW_GAP := 168.0
const MARGIN_V := 170.0
const NODE_R := 26.0
const BOSS_R := 40.0
const TRAVEL_TIME := 0.85

var choices: Array = []
var drafts: RefCounted

## Normally read from the Game autoload; injectable for tests.
var map: RefCounted
var current_row := -1
var current_index := 0
var run_seed := 0
var path_history: Array = []

var _view: MapView
var _root: Control
var _terrain_mat: ShaderMaterial
var _picked := false

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	var game := get_node_or_null("/root/Game")
	if map == null and game != null:
		map = game.map
		current_row = game.current_row
		current_index = game.current_index
		path_history = game.path_history.duplicate()
		if game.run != null:
			run_seed = game.run.run_seed
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.clip_contents = true
	add_child(_root)
	_terrain_mat = ShaderMaterial.new()
	_terrain_mat.shader = preload("res://game/fx/map_terrain.gdshader")
	var terrain := ColorRect.new()
	terrain.material = _terrain_mat
	terrain.set_anchors_preset(Control.PRESET_FULL_RECT)
	terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(terrain)
	_view = MapView.new()
	_view.setup(self)
	_root.add_child(_view)
	_root.gui_input.connect(_on_input)
	_root.resized.connect(_relayout)
	_relayout.call_deferred()
	_root.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 1.0, 0.3)

func _relayout() -> void:
	if map == null or _root.size.y < 2.0:
		return
	_view.layout(_root.size)
	_view.position.y = _view.scroll_for_focus(_root.size.y)

# --- input: drag to scroll, tap to pick a glowing waystone ---

var _drag_start := Vector2.ZERO
var _drag_view_y := 0.0
var _drag_dist := 0.0
var _pressing := false

func _on_input(ev: InputEvent) -> void:
	if _picked:
		return
	if ev is InputEventScreenTouch or ev is InputEventMouseButton:
		if ev.pressed:
			_pressing = true
			_drag_start = ev.position
			_drag_view_y = _view.position.y
			_drag_dist = 0.0
		elif _pressing:
			_pressing = false
			if _drag_dist < 14.0:
				var idx := _view.hit_choice(ev.position - _view.position)
				if idx >= 0:
					_pick(idx)
	elif (ev is InputEventScreenDrag or ev is InputEventMouseMotion) and _pressing:
		_drag_dist = maxf(_drag_dist, _drag_start.distance_to(ev.position))
		var y: float = _drag_view_y + (ev.position.y - _drag_start.y)
		_view.position.y = clampf(y, _root.size.y - _view.content_h, 0.0)

func _pick(idx: int) -> void:
	_picked = true
	_view.begin_travel(idx)
	await _view.travel_done
	chosen.emit(idx)
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.28)
	tw.tween_callback(queue_free)

# ============================================================================
class MapView extends Control:
	## Draws terrain, trails and waystones; owns markers, embers and travel.
	signal travel_done

	var overlay: PathOverlay
	var content_h := 1400.0
	var _pos := {}          # "r:i" -> Vector2 node center
	var _rng_salt := 0
	var _phase := 0.0
	var _golem: GolemMarker
	var _travel_curve: PackedVector2Array = []
	var _travel_t := -1.0
	var _burst: Array = []  # [{center, t, color}]
	var _boss_flame: Control

	func setup(o: PathOverlay) -> void:
		overlay = o
		_rng_salt = o.run_seed
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _jit(r: int, i: int, k: int, spread: float) -> float:
		var h := hash(Vector3i(_rng_salt, r * 31 + i, k))
		return (float(h % 10007) / 10007.0 * 2.0 - 1.0) * spread

	func layout(screen: Vector2) -> void:
		var rows: Array = overlay.map.rows
		content_h = MARGIN_V * 2.0 + ROW_GAP * float(rows.size() - 1)
		size = Vector2(screen.x, content_h)
		_pos.clear()
		for r in range(rows.size()):
			var row: Array = rows[r]
			for i in range(row.size()):
				var fx := 0.5
				if row.size() > 1:
					fx = lerpf(0.2, 0.8, float(i) / float(row.size() - 1))
				var p := Vector2(
					screen.x * fx + _jit(r, i, 1, 30.0),
					content_h - MARGIN_V - ROW_GAP * float(r) + _jit(r, i, 2, 20.0))
				_pos["%d:%d" % [r, i]] = p
		_build_children(screen)

	func _build_children(screen: Vector2) -> void:
		for c in get_children():
			c.queue_free()
		_add_embers()
		# 3D flame ring around the boss waystone, reusing FlameFrame.
		var boss_r: int = overlay.map.rows.size() - 1
		var bp: Vector2 = _pos["%d:0" % boss_r]
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(BOSS_R, BOSS_R) * 2.0
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_boss_flame = FlameFrame.wrap(holder, Color("e2372f"), 0.45, 26.0, BOSS_R)
		_boss_flame.position = bp - Vector2(BOSS_R + 26.0, BOSS_R + 26.0)
		_boss_flame.size = Vector2(BOSS_R + 26.0, BOSS_R + 26.0) * 2.0
		add_child(_boss_flame)
		_golem = GolemMarker.new()
		_golem.size = Vector2(44, 44)
		_golem.position = _node_pos(maxi(overlay.current_row, 0), overlay.current_index) - _golem.size * 0.5
		add_child(_golem)

	func _add_embers() -> void:
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = Vector3(size.x * 0.5, size.y * 0.5, 1.0)
		pm.direction = Vector3(0, -1, 0)
		pm.spread = 20.0
		pm.gravity = Vector3.ZERO
		pm.initial_velocity_min = 8.0
		pm.initial_velocity_max = 26.0
		pm.scale_min = 0.4
		pm.scale_max = 1.0
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 0.6
		pm.turbulence_noise_scale = 1.4
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 0.8, 1.0])
		g.colors = PackedColorArray([
			Color(1.0, 0.7, 0.3, 0.0), Color(1.0, 0.7, 0.3, 0.75),
			Color(0.95, 0.45, 0.2, 0.4), Color(0.9, 0.35, 0.15, 0.0)])
		var ramp := GradientTexture1D.new()
		ramp.gradient = g
		pm.color_ramp = ramp
		var dotg := Gradient.new()
		dotg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
		dotg.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.0)])
		var dot := GradientTexture2D.new()
		dot.gradient = dotg
		dot.fill = GradientTexture2D.FILL_RADIAL
		dot.fill_from = Vector2(0.5, 0.5)
		dot.fill_to = Vector2(0.5, 0.0)
		dot.width = 8
		dot.height = 8
		var p := GPUParticles2D.new()
		p.process_material = pm
		p.texture = dot
		p.amount = 46
		p.lifetime = 7.0
		p.preprocess = 7.0
		p.position = size * 0.5
		add_child(p)

	func _node_pos(r: int, i: int) -> Vector2:
		return _pos.get("%d:%d" % [r, i], size * 0.5)

	func scroll_for_focus(screen_h: float) -> float:
		var cur := _node_pos(maxi(overlay.current_row, 0), overlay.current_index)
		return clampf(screen_h * 0.68 - cur.y, screen_h - content_h, 0.0)

	func hit_choice(p: Vector2) -> int:
		for c in overlay.choices:
			var np := _node_pos(overlay.current_row + 1, c["index"])
			if p.distance_to(np) <= NODE_R + 16.0:
				return int(c["index"])
		return -1

	func _on_history(r: int, i: int) -> bool:
		var h: Array = overlay.path_history
		if h.is_empty():
			return r <= overlay.current_row and (r < overlay.current_row or i == overlay.current_index)
		return r < h.size() and int(h[r]) == i

	func _choice_indices() -> Array:
		var out: Array = []
		for c in overlay.choices:
			out.append(int(c["index"]))
		return out

	func begin_travel(idx: int) -> void:
		var a := _node_pos(overlay.current_row, overlay.current_index)
		var b := _node_pos(overlay.current_row + 1, idx)
		_travel_curve = _curve_points(a, b, overlay.current_row, overlay.current_index, idx)
		_burst.append({"center": b, "t": 0.0, "color": _theme_color_at(overlay.current_row + 1, idx)})
		var tw := create_tween()
		tw.tween_method(_set_travel_t, 0.0, 1.0, TRAVEL_TIME).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void: travel_done.emit())

	func _set_travel_t(t: float) -> void:
		_travel_t = t
		var n := _travel_curve.size()
		if n < 2:
			return
		var f := t * float(n - 1)
		var i0 := clampi(int(f), 0, n - 2)
		var p := _travel_curve[i0].lerp(_travel_curve[i0 + 1], f - float(i0))
		_golem.position = p - _golem.size * 0.5
		_golem.hop_phase = t * 9.0

	func _theme_color_at(r: int, i: int) -> Color:
		var node: RefCounted = overlay.map.rows[r][i]
		return Color(String(overlay.drafts.theme_info(node.theme)["color"]))

	func _process(dt: float) -> void:
		_phase += dt
		if overlay._terrain_mat != null:
			overlay._terrain_mat.set_shader_parameter("scroll", -position.y)
		for b: Dictionary in _burst:
			b["t"] += dt * 1.6
		_burst = _burst.filter(func(b: Dictionary) -> bool: return b["t"] < 1.0)
		queue_redraw()

	func _curve_points(a: Vector2, b: Vector2, r: int, i: int, j: int) -> PackedVector2Array:
		var bow := _jit(r, i * 7 + j, 3, 34.0)
		var c1 := a.lerp(b, 0.33) + Vector2(bow, 0)
		var c2 := a.lerp(b, 0.66) + Vector2(bow * 0.6, 0)
		var pts := PackedVector2Array()
		for k in range(25):
			var t := float(k) / 24.0
			pts.append(a.bezier_interpolate(c1, c2, b, t))
		return pts

	func _draw_trail(pts: PackedVector2Array, color: Color, width: float, dashed: bool, anim: bool) -> void:
		if not dashed:
			draw_polyline(pts, color, width, true)
			return
		var offset := fmod(_phase * 30.0, 15.0) if anim else 0.0
		var carried := offset
		for k in range(pts.size() - 1):
			var a := pts[k]
			var b := pts[k + 1]
			var seg := a.distance_to(b)
			var d := carried
			while d < seg:
				var e := minf(d + 6.0, seg)
				draw_line(a.lerp(b, d / seg), a.lerp(b, e / seg), color, width)
				d += 15.0
			carried = d - seg

	func _draw() -> void:
		if overlay == null or overlay.map == null:
			return
		var rows: Array = overlay.map.rows
		var cur_r := overlay.current_row
		var cur_i := overlay.current_index
		var picks := _choice_indices()
		# Edges.
		for r in range(rows.size() - 1):
			for i in range(rows[r].size()):
				var node: RefCounted = rows[r][i]
				for j: int in node.edges:
					var pts := _curve_points(_node_pos(r, i), _node_pos(r + 1, j), r, i, j)
					if _on_history(r, i) and _on_history(r + 1, j):
						_draw_trail(pts, Color(1.0, 0.7, 0.28, 0.6), 4.5, false, false)
					elif r == cur_r and i == cur_i and picks.has(j) and _travel_t < 0.0:
						_draw_trail(pts, Color(1.0, 0.85, 0.55, 0.9), 4.0, true, true)
					elif r < cur_r:
						_draw_trail(pts, Color(0.56, 0.53, 0.72, 0.12), 3.0, true, false)
					else:
						_draw_trail(pts, Color(0.56, 0.53, 0.72, 0.3), 3.0, true, false)
		# Traversed segment being walked right now.
		if _travel_t >= 0.0 and _travel_curve.size() > 1:
			var upto := clampi(int(_travel_t * float(_travel_curve.size() - 1)) + 1, 2, _travel_curve.size())
			_draw_trail(_travel_curve.slice(0, upto), Color(1.0, 0.7, 0.28, 0.9), 4.5, false, false)
		# Waystones.
		for r in range(rows.size()):
			for i in range(rows[r].size()):
				_draw_waystone(r, i, cur_r, cur_i, picks)
		# Selection bursts: expanding rings.
		for b: Dictionary in _burst:
			var t: float = b["t"]
			var col: Color = b["color"]
			col.a = (1.0 - t) * 0.9
			draw_arc(b["center"], NODE_R + 6.0 + t * 46.0, 0.0, TAU, 40, col, 3.0 * (1.0 - t) + 1.0, true)

	func _draw_waystone(r: int, i: int, cur_r: int, cur_i: int, picks: Array) -> void:
		var node: RefCounted = overlay.map.rows[r][i]
		var p := _node_pos(r, i)
		var col := _theme_color_at(r, i)
		var is_boss: bool = node.theme == "boss"
		var radius := BOSS_R if is_boss else NODE_R
		var selectable: bool = r == cur_r + 1 and picks.has(i) and _travel_t < 0.0
		var visited: bool = _on_history(r, i) and r <= cur_r
		var future_dim: float = 0.45 if (not selectable and not visited) else 1.0
		if selectable:
			var pulse := 0.5 + 0.5 * sin(_phase * 4.2)
			draw_arc(p, radius + 9.0 + pulse * 5.0, 0.0, TAU, 40, Color(col, 0.25 + 0.3 * pulse), 2.5, true)
			draw_arc(p, radius + 4.0, 0.0, TAU, 40, Color(col, 0.85), 3.0, true)
			draw_circle(p, radius + 18.0 + pulse * 4.0, Color(col, 0.05 + 0.05 * pulse))
		var bg := col.darkened(0.65 if visited else 0.78)
		if not visited and not selectable:
			bg = bg.lerp(Color("232a44"), 0.42)
		draw_circle(p, radius, Color(bg, future_dim))
		var ring := col if (selectable or visited or is_boss) else col.darkened(0.3)
		draw_arc(p, radius, 0.0, TAU, 44, Color(ring, future_dim), 3.0 if is_boss else 2.5, true)
		if node.get("elite"):
			for s in range(8):
				var a := TAU * float(s) / 8.0 + 0.3
				var d := Vector2(cos(a), sin(a))
				draw_line(p + d * (radius + 2.0), p + d * (radius + 9.0), Color(col, future_dim), 3.0)
		_draw_glyph(node.theme, p, radius, Color(col.lightened(0.35), future_dim), is_boss)
		if r == cur_r and i == cur_i:
			draw_arc(p, radius + 5.0, 0.0, TAU, 40, Color(1.0, 0.7, 0.28, 0.9), 3.0, true)

	func _draw_glyph(theme: String, p: Vector2, radius: float, col: Color, is_boss: bool) -> void:
		var s := radius / 26.0
		match theme:
			"fire":
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0, -14) * s, p + Vector2(7.5, 1) * s, p + Vector2(-7.5, 1) * s]), col)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(-8.5, -6) * s, p + Vector2(-2, 0) * s, p + Vector2(-8, 3) * s]), col)
				draw_circle(p + Vector2(0, 5) * s, 8.0 * s, col)
				var dark := Color(col.r * 0.25, col.g * 0.1, col.b * 0.08, col.a)
				draw_circle(p + Vector2(0, 7) * s, 4.0 * s, dark)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0, -4) * s, p + Vector2(3.4, 5) * s, p + Vector2(-3.4, 5) * s]), dark)
			"forest":
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0, -6) * s, p + Vector2(11, 8) * s, p + Vector2(-11, 8) * s]), col)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0, -13) * s, p + Vector2(9, 1) * s, p + Vector2(-9, 1) * s]), col)
				draw_rect(Rect2(p + Vector2(-2, 8) * s, Vector2(4, 5) * s), col)
			"water":
				draw_circle(p + Vector2(0, 4) * s, 8.0 * s, col)
				draw_colored_polygon(PackedVector2Array([
					p + Vector2(0, -13) * s, p + Vector2(6.4, -0.8) * s, p + Vector2(-6.4, -0.8) * s]), col)
				var glint := Color(1, 1, 1, col.a * 0.55)
				draw_circle(p + Vector2(-2.8, 4.5) * s, 1.8 * s, glint)
			"boss":
				draw_circle(p + Vector2(0, -3) * s, 11.0 * s, col)
				draw_rect(Rect2(p + Vector2(-8, 2) * s, Vector2(16, 8) * s), col)
				var dark := Color(0.1, 0.05, 0.05, col.a)
				draw_circle(p + Vector2(-4.5, -4) * s, 3.0 * s, dark)
				draw_circle(p + Vector2(4.5, -4) * s, 3.0 * s, dark)
				for t in range(3):
					draw_rect(Rect2(p + Vector2(-4.5 + float(t) * 3.6, 4) * s, Vector2(1.8, 5) * s), dark)
			_:
				draw_circle(p + Vector2(-4, 5) * s, 4.5 * s, col)
				draw_circle(p + Vector2(5, 5) * s, 4.0 * s, col)
				draw_circle(p + Vector2(0, -3) * s, 5.5 * s, col)

# ============================================================================
class GolemMarker extends Control:
	## Tiny hunched golem silhouette; bobs while walking the trail.
	var hop_phase := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0.0, -NODE_R - 10.0 + absf(sin(hop_phase * PI)) * -6.0)
		var col := Color(0.93, 0.9, 0.98, 1.0)
		var edge := Color(1.0, 0.7, 0.28, 1.0)
		draw_circle(c + Vector2(0, -2), 7.0, col)
		draw_circle(c + Vector2(4, -8), 4.0, col)
		draw_line(c + Vector2(-5, 0), c + Vector2(-9, 9), col, 3.5)
		draw_line(c + Vector2(5, 1), c + Vector2(9, 10), col, 3.5)
		draw_line(c + Vector2(-2, 5), c + Vector2(-3, 12), col, 3.0)
		draw_line(c + Vector2(2, 5), c + Vector2(3, 12), col, 3.0)
		draw_arc(c + Vector2(0, -2), 9.5, 0.0, TAU, 24, edge, 1.5, true)
