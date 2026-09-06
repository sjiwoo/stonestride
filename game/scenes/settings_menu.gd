extends Control
## Standalone settings screen reachable from the title.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v: VBoxContainer = UiKit.vbox(20)
	v.set_anchors_preset(Control.PRESET_TOP_WIDE)
	v.offset_top = 170
	v.offset_left = 60
	v.offset_right = -60
	add_child(v)
	v.add_child(UiKit.label("Settings", 56))
	v.add_child(UiKit.spacer(10))
	v.add_child(UiKit.label("Music volume", 24, UiKit.TEXT_DIM))
	v.add_child(UiKit.slider(Settings.music_volume, func(val: float) -> void:
		Settings.music_volume = val))
	v.add_child(UiKit.label("Sound effects", 24, UiKit.TEXT_DIM))
	v.add_child(UiKit.slider(Settings.sfx_volume, func(val: float) -> void:
		Settings.sfx_volume = val))
	var hapt := CheckButton.new()
	hapt.text = "Haptics"
	hapt.button_pressed = Settings.haptics
	hapt.add_theme_font_size_override("font_size", 26)
	hapt.toggled.connect(func(on: bool) -> void: Settings.haptics = on)
	v.add_child(hapt)
	v.add_child(UiKit.spacer(30))
	var back := UiKit.primary_button("Back")
	back.pressed.connect(func() -> void:
		Settings.save_settings()
		Router.goto("res://game/scenes/main_menu.tscn"))
	v.add_child(back)
