extends RefCounted
## All mutable state for one run. Pure data + math, no nodes, fully testable.

const PX_PER_M := 10.0

var run_seed := 0
var wave := 1
var hp := 100.0
var max_hp := 100.0
var gold := 0
var kills := 0
var total_distance_m := 0.0
var slam_charge := 0.0
var rerolls_per_draft := 1

var base_speed := 70.0
var speed_mult := 1.0
var damage_mult := 1.0
var fire_rate_mult := 1.0
var gold_per_meter := 1.0
var gold_per_kill := 2
var slam_radius := 150.0
var slam_damage := 60.0
var latch_resist := 0.0
var coin_magnet := false
var tap_damage := 15.0
var turrets: Array[String] = ["cannon"]

const STAT_KEYS := [
	"max_hp", "base_speed", "speed_mult", "damage_mult", "fire_rate_mult",
	"gold_per_meter", "gold_per_kill", "slam_radius", "slam_damage",
	"latch_resist", "tap_damage", "rerolls_per_draft",
]

func apply_effect(effect: Dictionary) -> void:
	var op: String = effect.get("op", "add")
	match op:
		"mount":
			turrets.append(String(effect["value"]))
		"flag":
			set(String(effect["stat"]), bool(effect["value"]))
		"add":
			var stat_a := String(effect["stat"])
			assert(stat_a in STAT_KEYS)
			set(stat_a, get(stat_a) + effect["value"])
			if stat_a == "max_hp":
				hp += float(effect["value"])
		"mul":
			var stat_m := String(effect["stat"])
			assert(stat_m in STAT_KEYS)
			set(stat_m, get(stat_m) * effect["value"])
		_:
			assert(false, "unknown op %s" % op)
	latch_resist = clampf(latch_resist, 0.0, 0.85)

func apply_card(card: Dictionary) -> void:
	for e: Dictionary in card["effects"]:
		apply_effect(e)

func march_speed_px(latched_count: int) -> float:
	var slow := 1.0 - float(latched_count) * 0.08 * (1.0 - latch_resist)
	return base_speed * speed_mult * clampf(slow, 0.2, 1.0)

func add_kill() -> void:
	kills += 1
	gold += gold_per_kill
	slam_charge = minf(slam_charge + 7.0, 100.0)

func travel(px: float) -> float:
	var meters := px / PX_PER_M
	total_distance_m += meters
	gold += int(meters * gold_per_meter)
	return meters
