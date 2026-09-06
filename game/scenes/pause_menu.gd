class_name PauseMenu
extends CanvasLayer
## In-run pause: resume, inline settings, or abandon back to the main menu.

signal resumed
signal abandoned

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.fullscreen_dim(0.7))
	var wrap: Dictionary = UiKit.center_panel(540)
	add_child(wrap["center"])
	var v: VBoxContainer = UiKit.vbox(18)
	wrap["panel"].add_child(v)
	v.add_child(UiKit.label("Paused", 40))
	v.add_child(UiKit.label("Music volume", 20, UiKit.TEXT_DIM))
	v.add_child(UiKit.slider(Settings.music_volume, func(val: float) -> void:
		Settings.music_volume = val
		Settings.save_settings()))
	v.add_child(UiKit.label("Sound effects", 20, UiKit.TEXT_DIM))
	v.add_child(UiKit.slider(Settings.sfx_volume, func(val: float) -> void:
		Settings.sfx_volume = val
		Settings.save_settings()))
	var hapt := CheckButton.new()
	hapt.text = "Haptics"
	hapt.button_pressed = Settings.haptics
	hapt.add_theme_font_size_override("font_size", 22)
	hapt.toggled.connect(func(on: bool) -> void:
		Settings.haptics = on
		Settings.save_settings())
	v.add_child(hapt)
	v.add_child(UiKit.spacer(4))
	var resume := UiKit.primary_button("Resume")
	resume.pressed.connect(func() -> void:
		resumed.emit()
		queue_free())
	v.add_child(resume)
	var abandon := UiKit.ghost_button("Abandon run")
	abandon.pressed.connect(func() -> void:
		abandoned.emit()
		queue_free())
	v.add_child(abandon)
