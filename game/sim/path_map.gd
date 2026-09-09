extends RefCounted
## Endless Slay-the-Spire style branching map, generated lazily row by row
## from the run seed (deterministic append order). Rows repeat in acts of
## ACT_LEN: row 0 is the neutral start, every row where r % ACT_LEN ==
## ACT_LEN - 1 is a single boss gate, everything else is a triple. Every
## node is guaranteed on a forward path by construction (no dead ends).

class MapNode:
	var theme: String
	var elite := false
	var edges: Array[int] = []

	func _init(theme_name: String) -> void:
		theme = theme_name

var rows: Array = []

const THEMES := ["fire", "forest", "water"]
const ACT_LEN := 10

var _rng: RandomNumberGenerator

func setup(seed_value: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	rows = [[MapNode.new("neutral")]]

func ensure_rows(upto_row: int) -> void:
	while rows.size() <= upto_row:
		_append_row()

func _append_row() -> void:
	var r := rows.size()
	var row: Array = []
	if r % ACT_LEN == ACT_LEN - 1:
		row.append(MapNode.new("boss"))
	else:
		for _i in range(3):
			var node := MapNode.new(THEMES[_rng.randi() % THEMES.size()])
			node.elite = (r % ACT_LEN) >= 4 and _rng.randf() < 0.18
			row.append(node)
	rows.append(row)
	_connect_rows(_rng, rows.size() - 2)

func _connect_rows(rng: RandomNumberGenerator, r: int) -> void:
	var cur: Array = rows[r]
	var nxt: Array = rows[r + 1]
	for i in range(cur.size()):
		var node: MapNode = cur[i]
		var lo := clampi(int(round(float(i) * float(nxt.size() - 1) / maxf(1.0, float(cur.size() - 1)))), 0, nxt.size() - 1)
		node.edges.append(lo)
		if nxt.size() > 1 and rng.randf() < 0.6:
			var extra := clampi(lo + (1 if rng.randf() < 0.5 else -1), 0, nxt.size() - 1)
			if extra != lo:
				node.edges.append(extra)
	for j in range(nxt.size()):
		var has_incoming := false
		for i in range(cur.size()):
			if (rows[r][i] as MapNode).edges.has(j):
				has_incoming = true
				break
		if not has_incoming:
			var donor: MapNode = cur[rng.randi() % cur.size()]
			donor.edges.append(j)

func node_at(row: int, index: int) -> MapNode:
	return rows[row][index]

func reachable(row: int, index: int) -> Array:
	ensure_rows(row + 1)
	var result: Array = []
	for j: int in (rows[row][index] as MapNode).edges:
		result.append({"index": j, "node": rows[row + 1][j]})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["index"] < b["index"])
	return result
