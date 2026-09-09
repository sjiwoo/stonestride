extends Node
## Persistent player settings (user://settings.cfg). Applied at boot.

const PATH := "user://settings.cfg"

var music_volume := 0.8
var sfx_volume := 1.0
var haptics := true

func _ready() -> void:
	load_settings()
	if "--background" in OS.get_cmdline_user_args():
		# QA/autoshot runs: keep rendering but never take focus or appear on
		# screen. Launch with CLI `--position 10000,80` too so the window is
		# off-screen during boot. Never minimize instead — a minimized window
		# throttles the swapchain and screenshot runs hang or slow ~10x.
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		var edge := 0
		for i in DisplayServer.get_screen_count():
			edge = maxi(edge, DisplayServer.screen_get_position(i).x
				+ DisplayServer.screen_get_size(i).x)
		DisplayServer.window_set_position(Vector2i(edge + 60, 80))

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		music_volume = cfg.get_value("audio", "music", 0.8)
		sfx_volume = cfg.get_value("audio", "sfx", 1.0)
		haptics = cfg.get_value("feel", "haptics", true)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("feel", "haptics", haptics)
	cfg.save(PATH)

func vibrate(ms: int) -> void:
	if haptics and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)
