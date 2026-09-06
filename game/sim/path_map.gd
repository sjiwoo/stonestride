extends RefCounted
## Slay-the-Spire style branching map. Row 0 = start, last row = boss.
## Every node is guaranteed on a start-to-boss path by construction.

class MapNode:
	var theme: String
	var elite := false
	var edges: Array[int] = []

	func _init(theme_name: String) -> void:
		theme = theme_name

var rows: Array = []

const THEMES := ["fire", "forest", "water"]

func generate(rng: RandomNumberGenerator, waves: int) -> void:
	rows = []
	var start := MapNode.new("neutral")
	rows.append([start])
	for r in range(1, waves - 1):
		var row: Array = []
		for _i in range(3):
			var node := MapNode.new(THEMES[rng.randi() % THEMES.size()])
			node.elite = r >= 4 and rng.randf() < 0.18
			row.append(node)
		rows.append(row)
	rows.append([MapNode.new("boss")])
	for r in range(rows.size() - 1):
		_connect_rows(rng, r)

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
	var result: Array = []
	if row + 1 >= rows.size():
		return result
	for j: int in (rows[row][index] as MapNode).edges:
		result.append({"index": j, "node": rows[row + 1][j]})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["index"] < b["index"])
	return result
