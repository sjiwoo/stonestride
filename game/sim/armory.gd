extends RefCounted
## Weapon tree logic: level gating, branch exclusivity, gold costs.
## Pure data + validation; UI and turrets read through this.

const WEAPON_ORDER := ["cannon", "mortar", "javelin"]

var _defs: Dictionary = {}

func setup(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "missing %s" % path)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	for w: Dictionary in parsed["weapons"]:
		_defs[w["id"]] = w

func weapon_def(id: String) -> Dictionary:
	return _defs[id]

func level_of(run: RefCounted, id: String) -> int:
	return int(run.weapons.get(id, {}).get("level", 0))

func branch_of(run: RefCounted, id: String) -> String:
	return String(run.weapons.get(id, {}).get("branch", ""))

## Nodes purchasable right now for a weapon: [] when maxed.
func purchasable(run: RefCounted, id: String) -> Array:
	var lvl := level_of(run, id)
	var d := weapon_def(id)
	if lvl < 2:
		return [{"kind": "level", "index": lvl, "node": d["levels"][lvl]}]
	if lvl == 2:
		var out: Array = []
		for b: Dictionary in d["branches"]:
			out.append({"kind": "branch", "id": b["id"], "node": b})
		return out
	return []

func can_forge(run: RefCounted, id: String, branch_id: String = "") -> Dictionary:
	var lvl := level_of(run, id)
	var d := weapon_def(id)
	if lvl >= 3:
		return {"ok": false, "reason": "maxed", "cost": 0}
	var node: Dictionary
	if lvl < 2:
		if branch_id != "":
			return {"ok": false, "reason": "requires %s" % d["levels"][1]["name"], "cost": 0}
		node = d["levels"][lvl]
	else:
		node = _branch_node(d, branch_id)
		if node.is_empty():
			return {"ok": false, "reason": "unknown branch", "cost": 0}
	var cost := int(node["cost"])
	if run.gold < cost:
		return {"ok": false, "reason": "not enough gold", "cost": cost}
	return {"ok": true, "reason": "", "cost": cost}

func forge(run: RefCounted, id: String, branch_id: String = "") -> bool:
	var check := can_forge(run, id, branch_id)
	if not check["ok"]:
		return false
	run.gold -= int(check["cost"])
	var lvl := level_of(run, id)
	if lvl < 2:
		run.weapons[id] = {"level": lvl + 1, "branch": ""}
	else:
		run.weapons[id] = {"level": 3, "branch": branch_id}
	return true

## Merged stat dictionary for the weapon's current level/branch.
func turret_stats(run: RefCounted, id: String) -> Dictionary:
	var lvl := level_of(run, id)
	assert(lvl > 0, "turret_stats on unowned weapon")
	var d := weapon_def(id)
	var node: Dictionary
	if lvl <= 2:
		node = d["levels"][lvl - 1]
	else:
		node = _branch_node(d, branch_of(run, id))
	var out := node.duplicate()
	out["weapon"] = id
	out["level"] = lvl
	out["branch"] = branch_of(run, id)
	out["color"] = d["color"]
	return out

func _branch_node(d: Dictionary, branch_id: String) -> Dictionary:
	for b: Dictionary in d["branches"]:
		if String(b["id"]) == branch_id:
			return b
	return {}
