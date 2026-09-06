extends Control
## Title screen with the golem idling at the bottom.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var ground := ColorRect.new()
	ground.color = Color("2e2a3d")
	ground.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	ground.custom_minimum_size = Vector2(0, 240)
	ground.anchor_top = 1.0
	ground.offset_top = -240
	add_child(ground)
	var golem := Golem.new()
	golem.position = Vector2(360, 1070)
	golem.scale = Vector2(0.9, 0.9)
	golem.walk_speed_visual = 0.35
	add_child(golem)
	var v: VBoxContainer = UiKit.vbox(18)
	v.set_anchors_preset(Control.PRESET_TOP_WIDE)
	v.offset_top = 170
	v.offset_left = 60
	v.offset_right = -60
	add_child(v)
	var title: Label = UiKit.label("Stonestride", 72)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub: Label = UiKit.label("March. Mount. Survive.", 26, UiKit.TEXT_FAINT)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UiKit.spacer(30))
	var start := UiKit.primary_button("Start run")
	start.pressed.connect(func() -> void:
		Game.start_run()
		Router.goto("res://game/scenes/march.tscn"))
	v.add_child(start)
	var settings_btn := UiKit.ghost_button("Settings")
	settings_btn.pressed.connect(func() -> void:
		Router.goto("res://game/scenes/settings_menu.tscn"))
	v.add_child(settings_btn)
	var quit := UiKit.ghost_button("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	v.add_child(quit)
