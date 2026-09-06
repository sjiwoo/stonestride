extends SceneTree
## Headless property test suite. Run:
##   godot --headless --path . --script tests/run_tests.gd
## Exits nonzero on any failure.

const RunState := preload("res://game/sim/run_state.gd")
const DraftSystem := preload("res://game/sim/draft_system.gd")
const PathMap := preload("res://game/sim/path_map.gd")

var failures := 0
var checks := 0

func _init() -> void:
	test_draft_determinism()
	test_theme_weight_distribution()
	test_draft_no_duplicates()
	test_path_map_structure()
	test_path_map_connectivity()
	test_run_state_effects()
	test_march_speed_bounds()
	test_data_integrity()
	print("---")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)

func _make_drafts(seed_value: int) -> DraftSystem:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var d := DraftSystem.new()
	d.setup(rng, "res://game/data/cards.json", "res://game/data/themes.json")
	return d

func test_draft_determinism() -> void:
	var a := _make_drafts(1234)
	var b := _make_drafts(1234)
	for wave in range(1, 51):
		var ha: Array = a.draw("fire", wave % 10 + 1)
		var hb: Array = b.draw("fire", wave % 10 + 1)
		for i in range(3):
			check(ha[i]["id"] == hb[i]["id"],
				"determinism: draw %d card %d differs (%s vs %s)" % [wave, i, ha[i]["id"], hb[i]["id"]])

func test_theme_weight_distribution() -> void:
	for theme in ["fire", "forest", "water"]:
		var d := _make_drafts(777)
		var counts := {"attack": 0, "speed": 0, "econ": 0}
		var n := 2000
		for i in range(n):
			for card: Dictionary in d.draw(theme, 3):
				counts[card["category"]] += 1
		var total := float(n * 3)
		var weights: Dictionary = d.theme_weights(theme)
		for cat: String in counts:
			var expected := float(weights[cat]) / 100.0
			var actual: float = counts[cat] / total
			check(absf(actual - expected) < 0.05,
				"%s/%s: expected %.2f got %.3f" % [theme, cat, expected, actual])

func test_draft_no_duplicates() -> void:
	var d := _make_drafts(9)
	for i in range(200):
		var hand: Array = d.draw("neutral", 5)
		var ids := {}
		for card: Dictionary in hand:
			ids[card["id"]] = true
		check(ids.size() == 3, "duplicate card in hand at draw %d" % i)

func test_path_map_structure() -> void:
	for s in range(30):
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var m := PathMap.new()
		m.generate(rng, 10)
		check(m.rows.size() == 10, "seed %d: expected 10 rows got %d" % [s, m.rows.size()])
		check(m.rows[0].size() == 1, "seed %d: start row not single" % s)
		check(m.rows[9].size() == 1, "seed %d: boss row not single" % s)
		check((m.node_at(9, 0)).theme == "boss", "seed %d: last node not boss" % s)

func test_path_map_connectivity() -> void:
	for s in range(50):
		var rng := RandomNumberGenerator.new()
		rng.seed = 1000 + s
		var m := PathMap.new()
		m.generate(rng, 10)
		var reachable := {}
		reachable[Vector2i(0, 0)] = true
		for r in range(m.rows.size() - 1):
			for i in range(m.rows[r].size()):
				if not reachable.has(Vector2i(r, i)):
					continue
				for j: int in (m.node_at(r, i)).edges:
					check(j >= 0 and j < m.rows[r + 1].size(),
						"seed %d: edge out of range row %d" % [s, r])
					reachable[Vector2i(r + 1, j)] = true
		for r in range(m.rows.size()):
			for i in range(m.rows[r].size()):
				check(reachable.has(Vector2i(r, i)),
					"seed %d: node r%d i%d unreachable from start" % [s, r, i])
		check(reachable.has(Vector2i(9, 0)), "seed %d: boss unreachable" % s)
		for r in range(m.rows.size() - 1):
			for i in range(m.rows[r].size()):
				check(not (m.node_at(r, i)).edges.is_empty(),
					"seed %d: dead end at r%d i%d" % [s, r, i])

func test_run_state_effects() -> void:
	var run := RunState.new()
	run.apply_effect({"stat": "damage_mult", "op": "mul", "value": 1.5})
	check(absf(run.damage_mult - 1.5) < 0.0001, "mul effect wrong")
	run.apply_effect({"stat": "gold_per_meter", "op": "add", "value": 2})
	check(absf(run.gold_per_meter - 3.0) < 0.0001, "add effect wrong")
	run.apply_effect({"op": "mount", "value": "mortar"})
	check(run.turrets.size() == 2 and run.turrets[1] == "mortar", "mount effect wrong")
	run.apply_effect({"stat": "coin_magnet", "op": "flag", "value": true})
	check(run.coin_magnet, "flag effect wrong")
	run.apply_effect({"stat": "max_hp", "op": "add", "value": 25})
	check(absf(run.hp - 125.0) < 0.0001, "max_hp add should heal by the same amount")
	run.apply_effect({"stat": "latch_resist", "op": "add", "value": 5.0})
	check(run.latch_resist <= 0.85, "latch_resist must clamp")

func test_march_speed_bounds() -> void:
	var run := RunState.new()
	check(absf(run.march_speed_px(0) - 70.0) < 0.0001, "base speed wrong")
	check(run.march_speed_px(50) >= 70.0 * 0.2 - 0.0001, "speed floor violated")
	var slowed := run.march_speed_px(3)
	run.latch_resist = 0.5
	check(run.march_speed_px(3) > slowed, "latch resist should reduce slowdown")
	for latched in range(0, 20):
		check(run.march_speed_px(latched + 1) <= run.march_speed_px(latched) + 0.0001,
			"speed must be monotone non-increasing in latched count")

func test_data_integrity() -> void:
	var cards: Array = DraftSystem._load_json("res://game/data/cards.json")["cards"]
	var themes: Dictionary = DraftSystem._load_json("res://game/data/themes.json")["themes"]
	var waves: Array = DraftSystem._load_json("res://game/data/waves.json")["waves"]
	var probe := RunState.new()
	for card: Dictionary in cards:
		check(card["category"] in ["attack", "speed", "econ"], "%s: bad category" % card["id"])
		check(card["rarity"] in ["common", "rare", "epic"], "%s: bad rarity" % card["id"])
		for e: Dictionary in card["effects"]:
			var op := String(e.get("op", "add"))
			check(op in ["add", "mul", "mount", "flag"], "%s: bad op" % card["id"])
			if op in ["add", "mul"]:
				check(String(e["stat"]) in RunState.STAT_KEYS, "%s: unknown stat %s" % [card["id"], e["stat"]])
		probe.apply_card(card)
	for cat in ["attack", "speed", "econ"]:
		var has_common := false
		for card: Dictionary in cards:
			if card["category"] == cat and card["rarity"] == "common":
				has_common = true
		check(has_common, "category %s needs at least one common card" % cat)
	for t: String in ["neutral", "fire", "forest", "water", "boss"]:
		check(themes.has(t), "missing theme %s" % t)
		var w: Dictionary = themes[t]["weights"]
		var total: float = w["attack"] + w["speed"] + w["econ"]
		check(absf(total - 100.0) < 0.001, "theme %s weights must sum to 100" % t)
	var prev_goal := 0.0
	for i in range(waves.size()):
		check(int(waves[i]["wave"]) == i + 1, "wave numbering broken at %d" % i)
		check(float(waves[i]["goal_m"]) > prev_goal, "wave goals must increase")
		prev_goal = float(waves[i]["goal_m"])
	check(bool(waves[waves.size() - 1].get("boss", false)), "final wave must be a boss")
