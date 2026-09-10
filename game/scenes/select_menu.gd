extends Control
## Character select: the three champions idle side by side on the key art;
## tap one to pick it, then march. Remembers the last choice.

var _selected := "golem"
var _rings := {}
var _chars := {}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var art_path := "res://game/art/key_art_menu.jpg"
	if ResourceLoader.exists(art_path):
		var art := TextureRect.new()
		art.texture = load(art_path)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.modulate = Color(0.45, 0.45, 0.55)
		add_child(art)
	_selected = String(Settings.last_character)
	if not _selected in BaseCharacter.IDS:
		_selected = "golem"
	var title: Label = UiKit.label("Choose your champion", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 120
	add_child(title)
	var slots := {"golem": 150.0, "ship": 360.0, "tank": 570.0}
	for id: String in BaseCharacter.IDS:
		var cx: float = slots[id]
		var ring := Control.new()
		ring.position = Vector2(cx, 640)
		ring.draw.connect(_draw_ring.bind(ring, id))
		add_child(ring)
		_rings[id] = ring
		var ch := BaseCharacter.create(id)
		ch.position = Vector2(cx, 700)
		ch.scale = Vector2(0.52, 0.52)
		ch.walk_speed_visual = 0.45
		add_child(ch)
		_chars[id] = ch
		var name_l: Label = UiKit.label(String(BaseCharacter.NAMES[id]), 24)
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.position = Vector2(cx - 90, 740)
		name_l.size = Vector2(180, 30)
		add_child(name_l)
		var ab: Dictionary = BaseCharacter.ABILITIES[id]
		var ab_l: Label = UiKit.label(String(ab["name"]), 18, UiKit.GOLD)
		ab_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ab_l.position = Vector2(cx - 90, 772)
		ab_l.size = Vector2(180, 24)
		add_child(ab_l)
		var hit := Button.new()
		hit.flat = true
		hit.position = Vector2(cx - 95, 470)
		hit.size = Vector2(190, 320)
		hit.pressed.connect(func() -> void: _pick(id))
		add_child(hit)
	var start := UiKit.primary_button("March")
	start.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	start.anchor_top = 1.0
	start.offset_top = -190
	start.offset_bottom = -100
	start.offset_left = 60
	start.offset_right = -60
	start.pressed.connect(func() -> void:
		Game.character = _selected
		Settings.last_character = _selected
		Settings.save_settings()
		Game.start_run()
		Router.goto("res://game/scenes/march.tscn"))
	add_child(start)
	var back := UiKit.ghost_button("Back")
	back.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	back.anchor_top = 1.0
	back.offset_top = -84
	back.offset_bottom = -30
	back.offset_left = 60
	back.offset_right = -60
	back.pressed.connect(func() -> void:
		Router.goto("res://game/scenes/main_menu.tscn"))
	add_child(back)

func _pick(id: String) -> void:
	_selected = id
	Settings.vibrate(8)
	for k: String in _rings:
		(_rings[k] as Control).queue_redraw()

func _process(_delta: float) -> void:
	for k: String in _chars:
		(_chars[k] as BaseCharacter).walk_speed_visual = 1.0 if k == _selected else 0.35

func _draw_ring(ring: Control, id: String) -> void:
	if id == _selected:
		ring.draw_arc(Vector2(0, 40), 118.0, 0.0, TAU, 48, Color(UiKit.GOLD, 0.9), 4.0, true)
		ring.draw_circle(Vector2(0, 40), 118.0, Color(UiKit.GOLD, 0.07))
