class_name DraftOverlay
extends CanvasLayer
## Roguelike card draft popup. Pauses gameplay; select a card, confirm, done.

signal finished(card: Dictionary)

var theme_name := "neutral"
var wave := 1
var drafts: RefCounted
var run: RefCounted

var _hand: Array = []
var _selected := -1
var _rerolls_left := 1
var _card_panels: Array = []
var _reroll_btn: Button
var _confirm_btn: Button
var _error_label: Label

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
	var v: VBoxContainer = UiKit.vbox(14)
	wrap["panel"].add_child(v)
	var info: Dictionary = drafts.theme_info(theme_name)
	v.add_child(UiKit.label("Wave %d cleared — %s" % [wave, String(info["name"]).to_lower()], 22, UiKit.TEXT_FAINT))
	v.add_child(UiKit.label("Choose an upgrade", 40))
	_card_panels = []
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

func _make_card(i: int) -> PanelContainer:
	var card: Dictionary = _hand[i]
	var cat_color: Color = UiKit.CATEGORY_COLORS[card["category"]]
	var p := PanelContainer.new()
	_style_card(p, cat_color, i == _selected)
	var v: VBoxContainer = UiKit.vbox(4)
	p.add_child(v)
	var top: HBoxContainer = UiKit.hbox()
	var cat: Label = UiKit.label(String(card["category"]).capitalize(), 20, cat_color)
	cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(cat)
	top.add_child(UiKit.label(String(card["rarity"]).capitalize(), 20, _rarity_color(card["rarity"])))
	v.add_child(top)
	v.add_child(UiKit.label(card["name"], 28))
	var desc: Label = UiKit.label(card["desc"], 20, UiKit.TEXT_DIM)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)
	v.add_child(UiKit.label(card["stat"], 21, cat_color))
	p.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			_select(i))
	_card_panels.append(p)
	return p

func _style_card(p: PanelContainer, cat_color: Color, selected: bool) -> void:
	var bg := cat_color.darkened(0.72)
	bg.a = 1.0
	var border := cat_color if selected else UiKit.PANEL_LIGHT
	p.add_theme_stylebox_override("panel", UiKit.flat_style(bg, 12, border, 3))

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic":
			return Color("c79bf0")
		"rare":
			return Color("7fb3f0")
	return UiKit.TEXT_FAINT

func _select(i: int) -> void:
	_selected = i
	_error_label.visible = false
	for j in range(_card_panels.size()):
		_style_card(_card_panels[j], UiKit.CATEGORY_COLORS[_hand[j]["category"]], j == i)

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
