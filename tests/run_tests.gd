extends SceneTree
## Headless property test suite. Run:
##   godot --headless --path . --script tests/run_tests.gd
## Exits nonzero on any failure.

const RunState := preload("res://game/sim/run_state.gd")
const DraftSystem := preload("res://game/sim/draft_system.gd")
const PathMap := preload("res://game/sim/path_map.gd")
const Armory := preload("res://game/sim/armory.gd")
const WaveGen := preload("res://game/sim/wave_gen.gd")

var failures := 0
var checks := 0

func _init() -> void:
	test_draft_determinism()
	test_theme_weight_distribution()
	test_draft_no_duplicates()
	test_path_map_structure()
	test_path_map_connectivity()
	test_path_map_determinism()
	test_wave_gen()
	test_run_state_effects()
	test_march_speed_bounds()
	test_armory_gating()
	test_armory_branch_exclusivity()
	test_armory_stats()
	test_data_integrity()
	test_weapons_data()
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
		var m := PathMap.new()
		m.setup(s)
		m.ensure_rows(35)
		check(m.rows.size() >= 36, "seed %d: ensure_rows(35) left %d rows" % [s, m.rows.size()])
		check(m.rows[0].size() == 1, "seed %d: start row not single" % s)
		check((m.node_at(0, 0)).theme == "neutral", "seed %d: start not neutral" % s)
		for r in range(1, 36):
			if r % PathMap.ACT_LEN == PathMap.ACT_LEN - 1:
				check(m.rows[r].size() == 1, "seed %d: boss row %d not single" % [s, r])
				check((m.node_at(r, 0)).theme == "boss", "seed %d: row %d not boss" % [s, r])
			else:
				check(m.rows[r].size() == 3, "seed %d: row %d not triple" % [s, r])
				for i in range(m.rows[r].size()):
					check((m.node_at(r, i)).theme in PathMap.THEMES,
						"seed %d: row %d bad theme" % [s, r])

func test_path_map_connectivity() -> void:
	for s in range(50):
		var m := PathMap.new()
		m.setup(1000 + s)
		m.ensure_rows(25)
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
		for r in range(m.rows.size() - 1):
			for i in range(m.rows[r].size()):
				check(not (m.node_at(r, i)).edges.is_empty(),
					"seed %d: dead end at r%d i%d" % [s, r, i])

func test_path_map_determinism() -> void:
	for s in range(10):
		var a := PathMap.new()
		a.setup(555 + s)
		var b := PathMap.new()
		b.setup(555 + s)
		# Different ensure_rows call patterns must yield the same map.
		a.ensure_rows(22)
		for step in [5, 11, 22]:
			b.ensure_rows(step)
		for r in range(23):
			check(a.rows[r].size() == b.rows[r].size(), "seed %d: row %d size differs" % [s, r])
			for i in range(a.rows[r].size()):
				check((a.node_at(r, i)).theme == (b.node_at(r, i)).theme,
					"seed %d: r%d i%d theme differs" % [s, r, i])
				check((a.node_at(r, i)).edges == (b.node_at(r, i)).edges,
					"seed %d: r%d i%d edges differ" % [s, r, i])

func test_wave_gen() -> void:
	var prev := WaveGen.cfg(1)
	check(not bool(prev["boss"]), "wave 1 must not be a boss")
	for n in range(2, 121):
		var c: Dictionary = WaveGen.cfg(n)
		check(float(c["goal_m"]) >= float(prev["goal_m"]) - 0.0001,
			"wave %d: goal must be non-decreasing" % n)
		check(float(c["goal_m"]) <= 320.0001, "wave %d: goal capped at 320" % n)
		check(float(c["spawn_interval"]) <= float(prev["spawn_interval"]) + 0.0001,
			"wave %d: spawn interval must not grow" % n)
		check(float(c["spawn_interval"]) >= 0.4 - 0.0001, "wave %d: interval floor" % n)
		check(float(c["hp_mult"]) > float(prev["hp_mult"]),
			"wave %d: hp must keep compounding" % n)
		check(bool(c["boss"]) == (n % WaveGen.BOSS_EVERY == 0),
			"wave %d: boss cadence wrong" % n)
		var types: Dictionary = c["types"]
		var total := 0.0
		for k: String in types:
			check(float(types[k]) >= 0.0, "wave %d: negative weight" % n)
			total += float(types[k])
		check(total > 0.0, "wave %d: no spawnable types" % n)
		prev = c

func test_run_state_effects() -> void:
	var run := RunState.new()
	run.apply_effect({"stat": "damage_mult", "op": "mul", "value": 1.5})
	check(absf(run.damage_mult - 1.5) < 0.0001, "mul effect wrong")
	run.apply_effect({"stat": "gold_per_meter", "op": "add", "value": 2})
	check(absf(run.gold_per_meter - 3.0) < 0.0001, "add effect wrong")
	run.apply_effect({"stat": "coin_magnet", "op": "flag", "value": true})
	check(run.coin_magnet, "flag effect wrong")
	run.apply_effect({"stat": "max_hp", "op": "add", "value": 25})
	check(absf(run.hp - 125.0) < 0.0001, "max_hp add should heal by the same amount")
	run.apply_effect({"stat": "latch_resist", "op": "add", "value": 5.0})
	check(run.latch_resist <= 0.85, "latch_resist must clamp")

func test_march_speed_bounds() -> void:
	var run := RunState.new()
	check(absf(run.march_speed_px(0) - 90.0) < 0.0001, "base speed wrong")
	check(run.march_speed_px(50) >= 90.0 * 0.2 - 0.0001, "speed floor violated")
	var slowed := run.march_speed_px(3)
	run.latch_resist = 0.5
	check(run.march_speed_px(3) > slowed, "latch resist should reduce slowdown")
	for latched in range(0, 20):
		check(run.march_speed_px(latched + 1) <= run.march_speed_px(latched) + 0.0001,
			"speed must be monotone non-increasing in latched count")

func test_data_integrity() -> void:
	var cards: Array = DraftSystem._load_json("res://game/data/cards.json")["cards"]
	var themes: Dictionary = DraftSystem._load_json("res://game/data/themes.json")["themes"]
	var probe := RunState.new()
	for card: Dictionary in cards:
		check(card["category"] in ["attack", "speed", "econ"], "%s: bad category" % card["id"])
		check(card["rarity"] in ["common", "rare", "epic"], "%s: bad rarity" % card["id"])
		for e: Dictionary in card["effects"]:
			var op := String(e.get("op", "add"))
			check(op in ["add", "mul", "flag"], "%s: bad op" % card["id"])
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

func _make_armory() -> Armory:
	var a := Armory.new()
	a.setup("res://game/data/weapons.json")
	return a

func test_armory_gating() -> void:
	var a := _make_armory()
	var run := RunState.new()
	run.gold = 10000
	check(a.level_of(run, "cannon") == 1, "cannon should start at level 1")
	check(a.level_of(run, "javelin") == 0, "javelin should start unowned")
	check(not a.can_forge(run, "javelin", "storm")["ok"], "branch must not be forgeable before level 2")
	check(a.forge(run, "javelin"), "forge javelin L1")
	check(a.level_of(run, "javelin") == 1, "javelin level 1 after forge")
	check(a.forge(run, "javelin"), "forge javelin L2")
	check(a.forge(run, "javelin", "storm"), "forge javelin branch")
	check(a.level_of(run, "javelin") == 3 and a.branch_of(run, "javelin") == "storm", "branch recorded")
	check(not a.forge(run, "javelin", "impaler"), "maxed weapon rejects further forging")
	var poor := RunState.new()
	poor.gold = 5
	check(not a.forge(poor, "mortar"), "insufficient gold must fail")
	check(poor.gold == 5, "failed forge must not spend gold")

func test_armory_branch_exclusivity() -> void:
	var a := _make_armory()
	for id: String in ["cannon", "mortar", "javelin"]:
		var run := RunState.new()
		run.gold = 10000
		var before: int = run.gold
		while a.level_of(run, id) < 2:
			check(a.forge(run, id), "level up %s" % id)
		check(a.forge(run, id, "nonsense") == false, "%s: unknown branch rejected" % id)
		var branches: Array = a.weapon_def(id)["branches"]
		check(a.forge(run, id, String(branches[0]["id"])), "%s: first branch forges" % id)
		check(not a.can_forge(run, id, String(branches[1]["id"]))["ok"], "%s: second branch sealed" % id)
		check(run.gold < before, "%s: forging spends gold" % id)

func test_armory_stats() -> void:
	var a := _make_armory()
	var run := RunState.new()
	run.gold = 10000
	var s1: Dictionary = a.turret_stats(run, "cannon")
	check(String(s1["mode"]) == "shell" and int(s1["level"]) == 1, "cannon L1 stats")
	a.forge(run, "cannon")
	var s2: Dictionary = a.turret_stats(run, "cannon")
	check(float(s2["damage"]) > float(s1["damage"]), "L2 must hit harder than L1")
	a.forge(run, "cannon", "magma")
	var s3: Dictionary = a.turret_stats(run, "cannon")
	check(s3.has("burn_dps") and String(s3["branch"]) == "magma", "magma branch stats carry burn")

func test_weapons_data() -> void:
	var a := _make_armory()
	check(a.WEAPON_ORDER.size() == 3, "three weapon lines")
	for id: String in a.WEAPON_ORDER:
		var d: Dictionary = a.weapon_def(id)
		check(d["levels"].size() == 2, "%s: two levels" % id)
		check(d["branches"].size() == 2, "%s: two branches" % id)
		var prev_cost := -1
		for node: Dictionary in d["levels"]:
			check(int(node["cost"]) > prev_cost, "%s: level costs must increase" % id)
			prev_cost = int(node["cost"])
			for key in ["name", "desc", "mode", "damage", "cooldown", "range"]:
				check(node.has(key), "%s: level missing %s" % [id, key])
		for b: Dictionary in d["branches"]:
			check(int(b["cost"]) > prev_cost, "%s: branch cost above levels" % id)
			check(b.has("id") and b.has("name") and b.has("desc"), "%s: branch fields" % id)
		var probe := RunState.new()
		probe.gold = 100000
		while a.level_of(probe, id) < 2:
			check(a.forge(probe, id), "%s: probe level" % id)
		check(a.forge(probe, id, String(d["branches"][1]["id"])), "%s: probe branch" % id)
		var st: Dictionary = a.turret_stats(probe, id)
		check(String(st["mode"]) in ["shell", "splash", "bolt"], "%s: valid mode" % id)
