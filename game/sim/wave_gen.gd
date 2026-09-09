extends RefCounted
## Endless procedural wave configs. Pure math, no nodes, fully testable.
## Replaces the fixed waves.json: goals stretch then cap, spawns speed up to a
## floor, enemy hp compounds forever, mix shifts toward runners/tanks, and a
## boss guards every BOSS_EVERY-th checkpoint.

const BOSS_EVERY := 10

static func cfg(wave: int) -> Dictionary:
	var n := maxi(wave, 1)
	var runner_w := minf(20.0 + float(n) * 1.5, 40.0)
	var tank_w := minf(float(n) * 2.0, 30.0)
	return {
		"goal_m": minf(55.0 + 10.0 * float(n - 1), 220.0),
		"spawn_interval": maxf(1.45 * pow(0.94, float(n - 1)), 0.4),
		"hp_mult": pow(1.15, float(n - 1)),
		"boss": n % BOSS_EVERY == 0,
		"types": {
			"grunt": maxf(100.0 - runner_w - tank_w, 25.0),
			"runner": runner_w,
			"tank": tank_w,
		},
	}
