class_name DraftOverlay
extends CanvasLayer
## Roguelike card draft popup. Pauses gameplay; select a card, confirm, done.
## Cards carry a subtle animated flame aura (FlameFrame) that flares on selection.

signal finished(card: Dictionary)

const CARD_CORNER := 16
const AURA_PAD := 24.0
const FLAME_IDLE := 0.16
const FLAME_SELECTED := 0.85

var theme_name := "neutral"
var wave := 1
var drafts: RefCounted
var run: RefCounted

var _hand: Array = []
var _selected := -1
var _rerolls_left := 1
var _card_panels: Array = []
var _card_frames: Array = []
var _reroll_btn: Button
var _confirm_btn: Button
var _error_label: Label

class RarityPips extends Control:
	var count := 1
	var color := Color.WHITE
	func _init(n: int, c: Color) -> void:
		count = n
		color = c
		custom_minimum_size = Vector2(count * 16 + 4, 14)
	func _draw() -> void:
		var r := 5.0
		for i in range(count):
			var cx := size.x - 6.0 - float(i) * 16.0
			var cy := size.y * 0.5
			var pts := PackedVector2Array([
				Vector2(cx, cy - r), Vector2(cx + r, cy),
				Vector2(cx, cy + r), Vector2(cx - r, cy)])
			draw_colored_polygon(pts, color)

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rerolls_left = run.rerolls_per_draft
	_hand = drafts.draw(theme_name, wave)
	_build()

func _build() -> void:
	add_child(UiKit.fullscreen_dim())
	var wrap: Dictionary = UiKit.center_panel(620)
	add_child(wrap["center"])
	var v: VBoxContainer = UiKit.vbox(10)
	wrap["panel"].add_child(v)
	var info: Dictionary = drafts.theme_info(theme_name)
	v.add_child(UiKit.label("Wave %d cleared — %s" % [wave, String(info["name"]).to_lower()], 22, UiKit.TEXT_FAINT))
	v.add_child(UiKit.label("Choose an upgrade", 40))
	_card_panels = []
	_card_frames = []
	for i in range(_hand.size()):
		v.add_child(_make_card(i))
	var row: HBoxContainer = UiKit.hbox()
	_reroll_btn = UiKit.ghost_button("Reroll (%d)" % _rerolls_left)
	_reroll_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reroll_btn.pressed.connect(_on_reroll)
	row.add_child(_reroll_btn)
	_confirm_btn = UiKit.primary_button("Confirm")
	_confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_confirm_btn.size_flags_stretch_ratio = 1.4
	_confirm_btn.pressed.connect(_on_confirm)
	row.add_child(_confirm_btn)
	v.add_child(row)
	_error_label = UiKit.label("Pick a card first", 20, UiKit.BAD)
	_error_label.visible = false
	v.add_child(_error_label)

func _flame_tint(cat_color: Color) -> Color:
	return cat_color.lerp(Color("ff7a2f"), 0.5)

func _make_card(i: int) -> FlameFrame:
	var card: Dictionary = _hand[i]
	var cat_color: Color = UiKit.CATEGORY_COLORS[card["category"]]
	var p := PanelContainer.new()
	_style_card(p, cat_color, i == _selected)
	var body: VBoxContainer = UiKit.vbox(0)
	p.add_child(body)
	var content := MarginContainer.new()
	content.add_theme_constant_override("margin_left", 18)
	content.add_theme_constant_override("margin_right", 18)
	content.add_theme_constant_override("margin_top", 12)
	content.add_theme_constant_override("margin_bottom", 10)
	body.add_child(content)
	var h: HBoxContainer = UiKit.hbox(14)
	content.add_child(h)
	var emblem := _category_emblem(card["category"])
	if emblem != null:
		h.add_child(emblem)
	var v: VBoxContainer = UiKit.vbox(4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top: HBoxContainer = UiKit.hbox()
	top.add_child(_category_pill(card["category"], cat_color))
	var fill := Control.new()
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(fill)
	var rarity := String(card["rarity"])
	var r_col := _rarity_color(rarity)
	top.add_child(UiKit.label(rarity.capitalize(), 18, r_col))
	var pips := RarityPips.new(_rarity_pips(rarity), r_col)
	pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(pips)
	v.add_child(top)
	v.add_child(UiKit.label(card["name"], 28))
	var desc: Label = UiKit.label(card["desc"], 20, UiKit.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	body.add_child(_stat_strip(card["stat"], cat_color))
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_select(i))
	_card_panels.append(p)
	var frame := FlameFrame.wrap(p, _flame_tint(cat_color), FLAME_IDLE, AURA_PAD, float(CARD_CORNER))
	_card_frames.append(frame)
	return frame

func _category_emblem(category: String) -> Control:
	var path := "res://game/art/emblem_%s.png" % category
	if not ResourceLoader.exists(path):
		return null
	var plaque := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("12101c")
	sb.set_corner_radius_all(14)
	plaque.add_theme_stylebox_override("panel", sb)
	plaque.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tex := TextureRect.new()
	tex.texture = load(path)
	tex.custom_minimum_size = Vector2(92, 92)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plaque.add_child(tex)
	return plaque

func _category_pill(category: String, cat_color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cat_color
	sb.set_corner_radius_all(11)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", sb)
	pill.add_child(UiKit.label(category.capitalize(), 18, cat_color.darkened(0.82)))
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return pill

func _stat_strip(stat: String, cat_color: Color) -> PanelContainer:
	var strip := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = cat_color.darkened(0.62)
	sb.corner_radius_bottom_left = CARD_CORNER
	sb.corner_radius_bottom_right = CARD_CORNER
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	strip.add_theme_stylebox_override("panel", sb)
	strip.add_child(UiKit.label(stat, 21, cat_color.lightened(0.25)))
	return strip

func _style_card(p: PanelContainer, cat_color: Color, selected: bool) -> void:
	var bg := cat_color.darkened(0.78)
	bg.a = 1.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(CARD_CORNER)
	sb.border_color = cat_color if selected else UiKit.PANEL_LIGHT
	sb.set_border_width_all(3 if selected else 2)
	p.add_theme_stylebox_override("panel", sb)

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic":
			return Color("c79bf0")
		"rare":
			return Color("7fb3f0")
	return UiKit.TEXT_FAINT

func _rarity_pips(rarity: String) -> int:
	match rarity:
		"epic":
			return 3
		"rare":
			return 2
	return 1

func _select(i: int) -> void:
	_selected = i
	_error_label.visible = false
	for j in range(_card_panels.size()):
		var cat_color: Color = UiKit.CATEGORY_COLORS[_hand[j]["category"]]
		_style_card(_card_panels[j], cat_color, j == i)
		_card_frames[j].tween_intensity(FLAME_SELECTED if j == i else FLAME_IDLE)

func _on_reroll() -> void:
	if _rerolls_left <= 0:
		return
	_rerolls_left -= 1
	var exclude: Array = []
	for c: Dictionary in _hand:
		exclude.append(c["id"])
	_hand = drafts.draw(theme_name, wave, exclude)
	_selected = -1
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame
	_build()
	_reroll_btn.text = "Reroll (%d)" % _rerolls_left
	if _rerolls_left <= 0:
		_reroll_btn.modulate = Color(1, 1, 1, 0.45)

func _on_confirm() -> void:
	if _selected < 0:
		_error_label.visible = true
		return
	finished.emit(_hand[_selected])
	queue_free()
