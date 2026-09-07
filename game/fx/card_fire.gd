class_name FlameFrame
extends Control
## Wraps a single content control with a 3D flame aura: GPUParticles3D rendered
## in a transparent SubViewport with an orthographic camera and glow, emitting
## stylized fire billboards (flame_billboard.gdshader, adapted from GDQuest's
## MIT-licensed stylized fire) along the card's border ring.
## Plain Control so children keep manual layout; works inside VBox/HBox containers.
## Usage: var f := FlameFrame.wrap(card_panel, Color("e05a4e"), 0.25)

const FLAME_SHADER := preload("res://game/fx/flame_billboard.gdshader")

static var _noise_tex: NoiseTexture2D
static var _mask_tex: GradientTexture2D
static var _scale_curve: CurveTexture

var pad := 16.0
var corner := 16.0
var _content: Control
var _svc: SubViewportContainer
var _vp: SubViewport
var _cam: Camera3D
var _particles: GPUParticles3D
var _proc: ParticleProcessMaterial
var _draw_mat: ShaderMaterial
var _intensity := 0.25
var _last_size := Vector2.ZERO

static func wrap(content: Control, tint: Color, intensity: float, pad_px: float = 16.0, corner_px: float = 16.0) -> FlameFrame:
	var f := FlameFrame.new()
	f.pad = pad_px
	f.corner = corner_px
	f._intensity = intensity
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f._build_viewport(tint)
	f._content = content
	f.add_child(content)
	f.resized.connect(f._layout)
	content.minimum_size_changed.connect(f.update_minimum_size)
	return f

static func _shared_noise() -> NoiseTexture2D:
	if _noise_tex == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = 4
		n.frequency = 0.045
		_noise_tex = NoiseTexture2D.new()
		_noise_tex.noise = n
		_noise_tex.seamless = true
		_noise_tex.width = 128
		_noise_tex.height = 128
	return _noise_tex

static func _shared_mask() -> GradientTexture2D:
	if _mask_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color.WHITE, Color(0.85, 0.85, 0.85), Color.BLACK])
		_mask_tex = GradientTexture2D.new()
		_mask_tex.gradient = g
		_mask_tex.fill = GradientTexture2D.FILL_RADIAL
		_mask_tex.fill_from = Vector2(0.5, 0.5)
		_mask_tex.fill_to = Vector2(0.5, 0.0)
		_mask_tex.width = 64
		_mask_tex.height = 64
	return _mask_tex

static func _shared_scale_curve() -> CurveTexture:
	if _scale_curve == null:
		var c := Curve.new()
		c.add_point(Vector2(0.0, 0.6))
		c.add_point(Vector2(0.35, 1.0))
		c.add_point(Vector2(1.0, 0.45))
		_scale_curve = CurveTexture.new()
		_scale_curve.curve = c
	return _scale_curve

func _color_ramp(tint: Color) -> GradientTexture1D:
	var hot := Color(1.0, 0.8, 0.35, 0.9)
	var mid := Color(1.0, 0.45, 0.1, 1.0).lerp(tint, 0.45)
	mid.a = 0.85
	var deep := Color(0.75, 0.15, 0.03, 1.0).lerp(tint, 0.55)
	deep.a = 0.5
	var tail := deep
	tail.a = 0.0
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 0.75, 1.0])
	g.colors = PackedColorArray([hot, mid, deep, tail])
	var t := GradientTexture1D.new()
	t.gradient = g
	t.width = 128
	return t

func _build_viewport(tint: Color) -> void:
	_svc = SubViewportContainer.new()
	_svc.stretch = true
	_svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_svc)
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.disable_3d = false
	_vp.positional_shadow_atlas_size = 0
	_svc.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.position = Vector3(0, 0, 80)
	_cam.near = 0.05
	_cam.far = 200.0
	_cam.current = true
	_vp.add_child(_cam)
	_proc = ParticleProcessMaterial.new()
	_proc.direction = Vector3(0, 1, 0)
	_proc.spread = 8.0
	_proc.initial_velocity_min = 8.0
	_proc.initial_velocity_max = 16.0
	_proc.gravity = Vector3.ZERO
	_proc.linear_accel_min = 6.0
	_proc.linear_accel_max = 14.0
	_proc.angle_min = -25.0
	_proc.angle_max = 25.0
	_proc.scale_min = 24.0
	_proc.scale_max = 40.0
	_proc.scale_curve = _shared_scale_curve()
	_proc.color_ramp = _color_ramp(tint)
	_proc.lifetime_randomness = 0.75
	_proc.turbulence_enabled = true
	_proc.turbulence_noise_strength = 1.2
	_proc.turbulence_noise_scale = 2.5
	_proc.turbulence_influence_min = 0.05
	_proc.turbulence_influence_max = 0.2
	_draw_mat = ShaderMaterial.new()
	_draw_mat.shader = FLAME_SHADER
	_draw_mat.set_shader_parameter("noise_texture", _shared_noise())
	_draw_mat.set_shader_parameter("texture_mask", _shared_mask())
	_draw_mat.set_shader_parameter("texture_scale", Vector2(0.012, 0.012))
	_draw_mat.set_shader_parameter("time_scale", 2.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.55)
	quad.material = _draw_mat
	_particles = GPUParticles3D.new()
	_particles.process_material = _proc
	_particles.draw_pass_1 = quad
	_particles.local_coords = true
	_particles.lifetime = 0.8
	_particles.randomness = 0.7
	_particles.draw_order = GPUParticles3D.DRAW_ORDER_LIFETIME
	_particles.amount = 48
	_particles.preprocess = 0.7
	_vp.add_child(_particles)
	_apply_intensity(_intensity)

func _ready() -> void:
	# Containers resize us after tree entry, but manually laid-out frames
	# (e.g. the map's boss ring) may have their size set before entering the
	# tree, in which case resized never fires — lay out once on entry.
	_layout()

func set_flame(tint: Color, intensity: float) -> void:
	_proc.color_ramp = _color_ramp(tint)
	_apply_intensity(intensity)

func tween_intensity(to_value: float, dur := 0.3) -> void:
	var tw := create_tween()
	tw.tween_method(_apply_intensity, _intensity, to_value, dur)

func _apply_intensity(i: float) -> void:
	_intensity = i
	_particles.amount_ratio = clampf(0.2 + 0.8 * i, 0.0, 1.0)
	_draw_mat.set_shader_parameter("emission_intensity", 0.5 + 0.9 * i)

func _perimeter_points(w: float, h: float, r: float, n: int) -> PackedVector3Array:
	# Points along a rounded rectangle centered at the origin, y up.
	var pts := PackedVector3Array()
	var hw := w * 0.5
	var hh := h * 0.5
	var straight_w := w - 2.0 * r
	var straight_h := h - 2.0 * r
	var arc := 0.5 * PI * r
	var total := 2.0 * straight_w + 2.0 * straight_h + 4.0 * arc
	for k in range(n):
		var d := total * float(k) / float(n)
		var p := Vector2.ZERO
		if d < straight_w:
			p = Vector2(-hw + r + d, hh)
		elif d < straight_w + arc:
			var a := (d - straight_w) / r
			p = Vector2(hw - r, hh - r) + Vector2(sin(a), cos(a)) * r
		elif d < straight_w + arc + straight_h:
			p = Vector2(hw, hh - r - (d - straight_w - arc))
		elif d < straight_w + 2.0 * arc + straight_h:
			var a2 := (d - straight_w - arc - straight_h) / r
			p = Vector2(hw - r, -hh + r) + Vector2(cos(a2), -sin(a2)) * r
		elif d < 2.0 * straight_w + 2.0 * arc + straight_h:
			p = Vector2(hw - r - (d - straight_w - 2.0 * arc - straight_h), -hh)
		elif d < 2.0 * straight_w + 3.0 * arc + straight_h:
			var a3 := (d - 2.0 * straight_w - 2.0 * arc - straight_h) / r
			p = Vector2(-hw + r, -hh + r) + Vector2(-sin(a3), -cos(a3)) * r
		elif d < 2.0 * straight_w + 3.0 * arc + 2.0 * straight_h:
			p = Vector2(-hw, -hh + r + (d - 2.0 * straight_w - 3.0 * arc - straight_h))
		else:
			var a4 := (d - 2.0 * straight_w - 3.0 * arc - 2.0 * straight_h) / r
			p = Vector2(-hw + r, hh - r) + Vector2(-cos(a4), sin(a4)) * r
		pts.append(Vector3(p.x, p.y, 0.0))
	return pts

func _refresh_emission(frame_size: Vector2) -> void:
	var card := frame_size - Vector2(pad, pad) * 2.0
	if card.x < 8.0 or card.y < 8.0:
		return
	var n := clampi(int((card.x + card.y) * 2.0 / 11.0), 56, 170)
	var pts := _perimeter_points(card.x, card.y, corner, n)
	var img := Image.create_empty(n, 1, false, Image.FORMAT_RGBF)
	for k in range(n):
		img.set_pixel(k, 0, Color(pts[k].x, pts[k].y, 0.0))
	_proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINTS
	_proc.emission_point_texture = ImageTexture.create_from_image(img)
	_proc.emission_point_count = n
	_particles.amount = clampi(n, 56, 140)
	_particles.restart()

func _get_minimum_size() -> Vector2:
	if _content == null:
		return Vector2.ZERO
	return _content.get_combined_minimum_size() + Vector2(pad, pad) * 2.0

func _layout() -> void:
	if _content == null:
		return
	_svc.position = Vector2.ZERO
	_svc.size = size
	_content.position = Vector2(pad, pad)
	_content.size = size - Vector2(pad, pad) * 2.0
	if size.distance_to(_last_size) > 1.0:
		_last_size = size
		_cam.size = maxf(size.y, 1.0)
		_refresh_emission(size)
