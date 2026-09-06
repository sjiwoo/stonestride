extends Node
## Run orchestration: owns the active RunState, path map, and draft system.

const RunState := preload("res://game/sim/run_state.gd")
const PathMap := preload("res://game/sim/path_map.gd")
const DraftSystem := preload("res://game/sim/draft_system.gd")

const TOTAL_WAVES := 10

var run: RunState
var map: PathMap
var drafts: DraftSystem
var current_row := 0
var current_index := 0
var last_summary := {}

func start_run(seed_value: int = -1) -> void:
	if seed_value < 0:
		seed_value = randi()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	run = RunState.new()
	run.run_seed = seed_value
	map = PathMap.new()
	map.generate(rng, TOTAL_WAVES)
	drafts = DraftSystem.new()
	drafts.setup(rng, "res://game/data/cards.json", "res://game/data/themes.json")
	current_row = 0
	current_index = 0

func current_theme() -> String:
	return map.node_at(current_row, current_index).theme

func choices_for_next_wave() -> Array:
	return map.reachable(current_row, current_index)

func advance_to(next_index: int) -> void:
	current_row += 1
	current_index = next_index
	run.wave += 1

func end_run(victory: bool) -> void:
	last_summary = {
		"victory": victory,
		"wave": run.wave,
		"distance": run.total_distance_m,
		"kills": run.kills,
		"gold": run.gold,
	}
	run = null
