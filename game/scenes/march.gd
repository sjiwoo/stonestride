extends Node2D
## The march: golem auto-walks right, enemies mob its front and slow it, turrets fire,
## reaching the wave's distance goal opens the draft, then the path choice.

const GROUND_Y := 1000.0
const GOLEM_X := 250.0
const FRONT_OFFSET := 80.0
const VIEW_W := 720.0

var run: RefCounted
var wave_cfgs: Array = []
var themes: Dictionary = {}
var wave_cfg: Dictionary = {}
var wave_distance := 0.0
var boss: Enemy = null
var spawn_timer := 0.0
var enemies: Array = []
var coins: Array = []
var _shake := 0.0
var _paused_for_overlay := false

var golem: Golem
var bg: Node2D
var rocks: Array = []
var clouds: Array = []
var theme_colors := {}

var hud: CanvasLayer
var dist_fill: ColorRect
var dist_track: ColorRect
var hp_fill: ColorRect
var wave_label: Label
var gold_label: Label
var slam_btn: Button

func _ready() -> void:
	run = Game.run
	assert(run != null, "march loaded without an active run")
	wave_cfgs = _load_json("res://game/data/waves.json")["waves"]
	themes = _load_json("res://game/data/themes.json")["themes"]
	_build_world()
	_build_hud()
	_mount_turrets()
	_start_wave()

static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(f.get_as_text())

func _build_world() -> void:
	bg = Node2D.new()
	bg.z_index = -10
	bg.draw.connect(_draw_bg.bind(bg))
	add_child(bg)
	for i in range(10):
		rocks.append({"x": randf() * 900.0 - 60.0, "y": GROUND_Y + 20 + randf() * 200.0, "r": 8.0 + randf() * 16.0})
	for i in range(4):
		clouds.append({"x": randf() * 800.0, "y": 90.0 + randf() * 160.0, "r": 30.0 + randf() * 30.0})
	golem = Golem.new()
	golem.position = Vector2(GOLEM_X, GROUND_Y)
	golem.scale = Vector2(1.35, 1.35)
	add_child(golem)

func _draw_bg(canvas: Node2D) -> void:
	var top := Color(String(theme_colors.get("sky_top", "1b2440")))
	var bottom := Color(String(theme_colors.get("sky_bottom", "3d3154")))
	var ground := Color(String(theme_colors.get("ground", "2e2a3d")))
	canvas.draw_rect(Rect2(0, 0, VIEW_W, GROUND_Y * 0.5), top)
	canvas.draw_rect(Rect2(0, GROUND_Y * 0.5, VIEW_W, GROUND_Y * 0.5), bottom)
	canvas.draw_circle(Vector2(600, 250), 44, Color("f5e6b8", 0.9))
	for c: Dictionary in clouds:
		canvas.draw_set_transform(Vector2(c["x"], c["y"]), 0.0, Vector2(1.0, 0.28))
		canvas.draw_circle(Vector2.ZERO, c["r"], top.lightened(0.14))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	canvas.draw_rect(Rect2(0, GROUND_Y, VIEW_W, 1280 - GROUND_Y), ground)
	canvas.draw_rect(Rect2(0, GROUND_Y, VIEW_W, 8), ground.lightened(0.25))
	for r: Dictionary in rocks:
		canvas.draw_set_transform(Vector2(r["x"], r["y"]), 0.0, Vector2(1.0, 0.3))
		canvas.draw_circle(Vector2.ZERO, r["r"], ground.darkened(0.35))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 56)
	hud.add_child(margin)
	var v: VBoxContainer = UiKit.vbox(10)
	margin.add_child(v)
	var top: HBoxContainer = UiKit.hbox()
	wave_label = UiKit.label("Wave 1", 26)
	wave_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(wave_label)
	gold_label = UiKit.label("0 g", 26, UiKit.GOLD)
	top.add_child(gold_label)
	var pause_btn := UiKit.ghost_button("II")
	pause_btn.custom_minimum_size = Vector2(84, 68)
	pause_btn.pressed.connect(_on_pause)
	top.add_child(pause_btn)
	v.add_child(top)
	dist_track = ColorRect.new()
	dist_track.color = Color("2a2540")
	dist_track.custom_minimum_size = Vector2(0, 14)
	v.add_child(dist_track)
	dist_fill = ColorRect.new()
	dist_fill.color = UiKit.GOLD
	dist_fill.size = Vector2(0, 14)
	dist_track.add_child(dist_fill)
	var hp_track := ColorRect.new()
	hp_track.color = Color("2a2540")
	hp_track.custom_minimum_size = Vector2(0, 10)
	v.add_child(hp_track)
	hp_fill = ColorRect.new()
	hp_fill.color = UiKit.GOOD
	hp_fill.size = Vector2(0, 10)
	hp_track.add_child(hp_fill)
	slam_btn = UiKit.button("Slam 0%", Color("3a2430"), Color("e05a4e"), 28)
	slam_btn.custom_minimum_size = Vector2(220, 110)
	slam_btn.pressed.connect(_on_slam)
	hud.add_child(slam_btn)
	slam_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	slam_btn.offset_left = -244
	slam_btn.offset_right = -24
	slam_btn.offset_top = -150
	slam_btn.offset_bottom = -40

func _mount_turrets() -> void:
	for m in golem.mount_points:
		for child in m.get_children():
			child.queue_free()
	for i in range(run.turrets.size()):
		if i >= golem.mount_points.size():
			break
		var t := Turret.new()
		golem.mount_points[i].add_child(t)
		t.setup(run.turrets[i], self)

func _start_wave() -> void:
	wave_cfg = wave_cfgs[run.wave - 1]
	wave_distance = 0.0
	spawn_timer = 0.6
	theme_colors = themes[Game.current_theme()]
	bg.queue_redraw()
	wave_label.text = "Wave %d · %s" % [run.wave, String(theme_colors["name"])]
	if wave_cfg.get("boss", false):
		boss = _spawn_enemy("boss", 820.0)

func _process(delta: float) -> void:
	if _paused_for_overlay:
		return
	enemies = enemies.filter(func(e: Variant) -> bool: return is_instance_valid(e))
	coins = coins.filter(func(c: Variant) -> bool: return is_instance_valid(c))
	var blocked_count := 0
	for e: Enemy in enemies:
		if e.blocked:
			blocked_count += 1
	var speed_px: float = run.march_speed_px(blocked_count)
	var boss_blocking := is_instance_valid(boss)
	if boss_blocking and boss.blocked:
		speed_px = 0.0
	golem.walk_speed_visual = clampf(speed_px / run.base_speed, 0.15, 2.0)
	var goal := float(wave_cfg["goal_m"])
	var meters: float = run.travel(speed_px * delta)
	wave_distance += meters
	if boss_blocking:
		wave_distance = minf(wave_distance, goal * 0.97)
	_scroll_world(speed_px * delta)
	_update_spawning(delta)
	_update_enemies(delta, speed_px)
	_update_hud(goal)
	if _shake > 0.0:
		_shake -= delta * 3.0
		golem.position.x = GOLEM_X + randf_range(-1.0, 1.0) * _shake * 14.0
	if run.hp <= 0.0:
		_finish_run(false)
	elif wave_distance >= goal:
		_complete_wave()

func _scroll_world(px: float) -> void:
	for r: Dictionary in rocks:
		r["x"] -= px
		if r["x"] < -60.0:
			r["x"] += 900.0
			r["y"] = GROUND_Y + 20 + randf() * 200.0
	for c: Dictionary in clouds:
		c["x"] -= px * 0.15
		if c["x"] < -80.0:
			c["x"] += 880.0
	bg.queue_redraw()

func _update_spawning(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = float(wave_cfg["spawn_interval"])
		var kind := _pick_enemy_kind()
		_spawn_enemy(kind, 800.0)

func _pick_enemy_kind() -> String:
	var weights: Dictionary = wave_cfg["types"]
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var roll := randf() * total
	for k: String in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return "grunt"

func _spawn_enemy(kind: String, x: float) -> Enemy:
	var e := Enemy.new()
	e.setup(kind, float(wave_cfg["hp_mult"]))
	e.position = Vector2(x, GROUND_Y + randf_range(-4.0, 60.0))
	e.died.connect(_on_enemy_died)
	add_child(e)
	enemies.append(e)
	return e

func _update_enemies(delta: float, scroll_px: float) -> void:
	var front_x := golem.position.x + FRONT_OFFSET
	for e: Enemy in enemies:
		var min_x := front_x + e.radius + e.press_offset
		e.position.x -= (scroll_px + e.speed) * delta
		if e.position.x <= min_x:
			e.position.x = min_x
			e.blocked = true
			run.hp -= e.dps * delta
		else:
			e.blocked = false

func _on_enemy_died(e: Enemy) -> void:
	enemies.erase(e)
	run.add_kill()
	if e == boss:
		boss = null
	if randf() < 0.4:
		var coin := Coin.new()
		coin.position = e.position
		if run.coin_magnet:
			coin.magnet_target = golem
		coin.collected.connect(func(v: int) -> void:
			run.gold += v
			coins.erase(coin))
		add_child(coin)
		coins.append(coin)

func nearest_enemy(from: Vector2, max_range: float) -> Enemy:
	var best: Enemy = null
	var best_d := max_range
	for e_v in enemies:
		if not is_instance_valid(e_v):
			continue
		var e: Enemy = e_v
		var d := from.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func spawn_projectile(from: Vector2, target: Enemy, dmg: float, splash: float, kind: String) -> void:
	var p := Projectile.new()
	add_child(p)
	p.setup(from, target, dmg, splash, kind, self)

func damage_area(center: Vector2, radius: float, dmg: float) -> void:
	for e_v in enemies.duplicate():
		if not is_instance_valid(e_v):
			continue
		var e: Enemy = e_v
		if center.distance_to(e.global_position) <= radius + e.radius:
			e.take_damage(dmg)

func _on_slam() -> void:
	if run.slam_charge < 100.0:
		return
	run.slam_charge = 0.0
	Settings.vibrate(40)
	_shake = 1.0
	for e_v in enemies.duplicate():
		if not is_instance_valid(e_v):
			continue
		var e: Enemy = e_v
		if golem.position.distance_to(e.global_position) <= run.slam_radius + e.radius:
			e.blocked = false
			e.position.x = golem.position.x + FRONT_OFFSET + run.slam_radius + randf_range(30.0, 90.0)
			e.position.y = clampf(e.position.y, GROUND_Y - 10.0, GROUND_Y + 60.0)
			e.take_damage(run.slam_damage * run.damage_mult)

func _unhandled_input(event: InputEvent) -> void:
	var tap_pos := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
		pressed = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = event.position
		pressed = true
	if not pressed:
		return
	var world_pos := get_canvas_transform().affine_inverse() * tap_pos
	for c_v in coins.duplicate():
		if is_instance_valid(c_v) and (c_v as Coin).try_tap(world_pos):
			return
	var best: Enemy = null
	var best_d := 60.0
	for e_v in enemies:
		if not is_instance_valid(e_v):
			continue
		var e: Enemy = e_v
		var d := world_pos.distance_to(e.global_position + Vector2(0, -e.radius))
		if d < best_d + e.radius:
			best_d = d
			best = e
	if best != null:
		best.take_damage(run.tap_damage)
		Settings.vibrate(10)

func _update_hud(goal: float) -> void:
	dist_fill.size.x = dist_track.size.x * clampf(wave_distance / goal, 0.0, 1.0)
	hp_fill.size.x = hp_fill.get_parent().size.x * clampf(run.hp / run.max_hp, 0.0, 1.0)
	hp_fill.color = UiKit.GOOD if run.hp > run.max_hp * 0.35 else UiKit.BAD
	gold_label.text = "%d g" % run.gold
	if run.slam_charge >= 100.0:
		slam_btn.text = "SLAM"
		slam_btn.modulate = Color(1.15, 1.15, 1.15)
	else:
		slam_btn.text = "Slam %d%%" % int(run.slam_charge)
		slam_btn.modulate = Color(1, 1, 1, 0.8)

func _complete_wave() -> void:
	if Game.current_row >= Game.map.rows.size() - 1:
		_finish_run(true)
		return
	_paused_for_overlay = true
	get_tree().paused = true
	_clear_field()
	var overlay := DraftOverlay.new()
	overlay.theme_name = Game.current_theme()
	overlay.wave = run.wave
	overlay.drafts = Game.drafts
	overlay.run = run
	overlay.finished.connect(_on_card_chosen)
	add_child(overlay)

func _clear_field() -> void:
	for e_v in enemies.duplicate():
		if is_instance_valid(e_v):
			(e_v as Enemy).queue_free()
	enemies.clear()
	for c_v in coins.duplicate():
		if is_instance_valid(c_v):
			(c_v as Coin).collect()
	coins.clear()

func _on_card_chosen(card: Dictionary) -> void:
	run.apply_card(card)
	_mount_turrets()
	var overlay := PathOverlay.new()
	overlay.choices = Game.choices_for_next_wave()
	overlay.drafts = Game.drafts
	overlay.chosen.connect(_on_path_chosen)
	add_child(overlay)

func _on_path_chosen(index: int) -> void:
	Game.advance_to(index)
	get_tree().paused = false
	_paused_for_overlay = false
	_start_wave()

func _on_pause() -> void:
	if _paused_for_overlay:
		return
	get_tree().paused = true
	var menu := PauseMenu.new()
	menu.resumed.connect(func() -> void: get_tree().paused = false)
	menu.abandoned.connect(func() -> void:
		Game.end_run(false)
		Router.goto("res://game/scenes/main_menu.tscn"))
	add_child(menu)

func _finish_run(victory: bool) -> void:
	if _paused_for_overlay:
		return
	_paused_for_overlay = true
	Game.end_run(victory)
	Router.goto("res://game/scenes/end_screen.tscn")
