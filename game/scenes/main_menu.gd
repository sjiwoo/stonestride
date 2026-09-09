extends Control
## Title screen with the golem idling at the bottom.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art_path := "res://game/art/key_art_menu.jpg"
	if ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(art)
		# Slow ken-burns drift keeps the painted scene alive.
		art.pivot_offset = Vector2(360, 760)
		var tw := create_tween().set_loops()
		tw.tween_property(art, "scale", Vector2(1.05, 1.05), 14.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(art, "scale", Vector2.ONE, 14.0) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		var ground := ColorRect.new()
		ground.color = Color("2e2a3d")
		ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		ground.custom_minimum_size = Vector2(0, 240)
		ground.anchor_top = 1.0
		ground.offset_top = -240
		add_child(ground)
		var golem := BaseCharacter.create("golem")
		golem.position = Vector2(360, 1070)
		golem.scale = Vector2(0.9, 0.9)
		golem.walk_speed_visual = 0.35
		add_child(golem)
	var v: VBoxContainer = UiKit.vbox(18)
	v.set_anchors_preset(Control.PRESET_TOP_WIDE)
	v.offset_top = 130
	v.offset_left = 60
	v.offset_right = -60
	add_child(v)
	var title: Label = UiKit.label("Stonestride", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub: Label = UiKit.label("March. Mount. Survive.", 26, UiKit.TEXT_FAINT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var buttons: VBoxContainer = UiKit.vbox(14)
	buttons.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	buttons.anchor_top = 1.0
	buttons.offset_top = -330
	buttons.offset_bottom = -70
	buttons.offset_left = 60
	buttons.offset_right = -60
	add_child(buttons)
	var start := UiKit.primary_button("Start run")
	start.pressed.connect(func() -> void:
		Router.goto("res://game/scenes/select_menu.tscn"))
	buttons.add_child(start)
	var settings_btn := UiKit.ghost_button("Settings")
	settings_btn.pressed.connect(func() -> void:
		Router.goto("res://game/scenes/settings_menu.tscn"))
	buttons.add_child(settings_btn)
	var quit := UiKit.ghost_button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	buttons.add_child(quit)
