extends RefCounted
## Roguelike draft: deals 3 cards weighted by path theme + wave-scaled rarity.
## Deterministic for a given RNG seed.

var _rng: RandomNumberGenerator
var _pool: Array = []
var _themes: Dictionary = {}

func setup(rng: RandomNumberGenerator, cards_path: String, themes_path: String) -> void:
	_rng = rng
	_pool = _load_json(cards_path)["cards"]
	_themes = _load_json(themes_path)["themes"]

static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	assert(f != null, "missing %s" % path)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	assert(parsed is Dictionary)
	return parsed

func theme_info(theme: String) -> Dictionary:
	return _themes[theme]

func theme_weights(theme: String) -> Dictionary:
	return _themes[theme]["weights"]

func rarity_weights(wave: int) -> Dictionary:
	var epic := clampf(0.05 + wave * 0.02, 0.0, 0.35)
	var rare := clampf(0.20 + wave * 0.02, 0.0, 0.45)
	return {"common": 1.0 - epic - rare, "rare": rare, "epic": epic}

func _weighted_pick(weights: Dictionary) -> String:
	var total := 0.0
	for k: String in weights:
		total += float(weights[k])
	var roll := _rng.randf() * total
	for k: String in weights:
		roll -= float(weights[k])
		if roll <= 0.0:
			return k
	return weights.keys()[weights.size() - 1]

func draw(theme: String, wave: int, exclude_ids: Array = []) -> Array:
	var hand: Array = []
	var used: Array = exclude_ids.duplicate()
	for _i in range(3):
		var category := _weighted_pick(theme_weights(theme))
		var rarity := _weighted_pick(rarity_weights(wave))
		var card := _pick_card(category, rarity, used)
		used.append(card["id"])
		hand.append(card)
	return hand

func _pick_card(category: String, rarity: String, used: Array) -> Dictionary:
	var tiers := [rarity, "rare", "common"]
	for tier: String in tiers:
		var options: Array = []
		for c: Dictionary in _pool:
			if c["category"] == category and c["rarity"] == tier and not used.has(c["id"]):
				options.append(c)
		if not options.is_empty():
			return options[_rng.randi() % options.size()]
	for c: Dictionary in _pool:
		if not used.has(c["id"]):
			return c
	return _pool[_rng.randi() % _pool.size()]
