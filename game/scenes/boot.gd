extends Node
## Boot: routes to the menu, or hands off to the screenshot verification flow
## when STONESTRIDE_SHOTS=<dir> is set (runner lives on the root so it
## survives scene transitions).

func _ready() -> void:
	await get_tree().process_frame
	var shots_dir := OS.get_environment("STONESTRIDE_SHOTS")
	if shots_dir.is_empty():
		Router.goto("res://game/scenes/main_menu.tscn", true)
		return
	var runner := ShotRunner.new()
	runner.dir = shots_dir
	get_tree().root.add_child.call_deferred(runner)
