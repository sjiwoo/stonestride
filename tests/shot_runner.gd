class_name ShotRunner
extends Node
## Lives on the root (survives scene swaps) and drives the visual verification
## flow: menu, march, draft, path choice, capturing a PNG at each step.

var dir := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await _run()

func _run() -> void:
	Router.goto("res://game/scenes/main_menu.tscn", true)
	await _settle(0.8)
	await _capture("01_main_menu.png")
	Game.start_run(42)
	Router.goto("res://game/scenes/march.tscn", true)
	await _settle(0.2)
	var march := get_tree().current_scene
	march.wave_cfg["goal_m"] = 100000.0
	await _settle(9.0)
	await _capture("02_march.png")
	march.wave_cfg["goal_m"] = 60.0
	march.wave_distance = 35.0
	await _settle(1.6)
	await _capture("03_waystone.png")
	march.wave_distance = 999999.0
	await _settle(0.55)
	await _capture("04_rout.png")
	await _settle(1.8)
	await _capture("05_draft.png")
	var overlay: Node = null
	for child in march.get_children():
		if child is DraftOverlay:
			overlay = child
	if overlay != null:
		overlay._select(0)
		overlay._on_confirm()
	await _settle(0.5)
	await _capture("06_path.png")
	print("SCREENSHOTS_DONE")
	get_tree().quit()

func _settle(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += 1.0 / 60.0

func _capture(file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir.path_join(file_name))
	print("shot: ", file_name)
