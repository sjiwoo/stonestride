class_name ArmoryOverlay
extends CanvasLayer
## Between-waves weapon tree: forge levels and branches with gold.

signal closed

var run: RefCounted
var armory: RefCounted

var _gold_label: Label
var _detail_title: Label
var _detail_desc: Label
var _forge_btn: Button
var _note: Label
var _rows_box: VBoxContainer
var _selected := {}
var _node_buttons: Array = []

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.fullscreen_dim())
	var wrap: Dictionary = UiKit.center_panel(640)
	add_child(wrap["center"])
	var v: VBoxContainer = UiKit.vbox(10)
	wrap["panel"].add_child(v)
	var top: HBoxContainer = UiKit.hbox()
	var title: Label = UiKit.label("Golem armory", 38)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_gold_label = UiKit.label("%d g" % run.gold, 26, UiKit.GOLD)
	top.add_child(_gold_label)
	v.add_child(top)
	v.add_child(UiKit.label("Forge weapons between waves", 19, UiKit.TEXT_FAINT))
	_rows_box = UiKit.vbox(12)
	v.add_child(_rows_box)
	_build_rows()
	var detail: PanelContainer = UiKit.panel(Color("221e36"), 10)
	var dv: VBoxContainer = UiKit.vbox(4)
	detail.add_child(dv)
	_detail_title = UiKit.label("Tap a node to inspect it", 22, UiKit.TEXT_DIM)
	dv.add_child(_detail_title)
	_detail_desc = UiKit.label("", 19, UiKit.TEXT_FAINT)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.visible = false
	dv.add_child(_detail_desc)
	_note = UiKit.label("", 18, UiKit.BAD)
	_note.visible = false
	dv.add_child(_note)
	v.add_child(detail)
	var row: HBoxContainer = UiKit.hbox()
	_forge_btn = UiKit.button("Forge", UiKit.GOLD, UiKit.GOLD_DARK, 24)
	_forge_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_forge_btn.visible = false
	_forge_btn.pressed.connect(_on_forge)
	row.add_child(_forge_btn)
	var done := UiKit.primary_button("March on")
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.pressed.connect(func() -> void:
		closed.emit()
		queue_free())
	row.add_child(done)
	v.add_child(row)

func _build_rows() -> void:
	for child in _rows_box.get_children():
		child.queue_free()
	_node_buttons = []
	for id: String in armory.WEAPON_ORDER:
		_rows_box.add_child(_weapon_row(id))

func _weapon_row(id: String) -> VBoxContainer:
	var d: Dictionary = armory.weapon_def(id)
	var col := Color(String(d["color"]))
	var box: VBoxContainer = UiKit.vbox(6)
	var head: HBoxContainer = UiKit.hbox(8)
	var emblem_path := "res://game/art/emblem_%s.png" % id
	if ResourceLoader.exists(emblem_path):
		var tex := TextureRect.new()
		tex.texture = load(emblem_path)
		tex.custom_minimum_size = Vector2(48, 48)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(tex)
	head.add_child(UiKit.label(d["name"], 24, col))
	head.add_child(UiKit.label(d["role"], 18, UiKit.TEXT_FAINT))
	box.add_child(head)
	var row: HBoxContainer = UiKit.hbox(6)
	var lvl: int = armory.level_of(run, id)
	for i in range(2):
		row.add_child(_node_button(id, "level", i, d["levels"][i], col, lvl))
		row.add_child(UiKit.label(">", 22, Color("3d3658")))
	var branch_box: VBoxContainer = UiKit.vbox(2)
	branch_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for b: Dictionary in d["branches"]:
		branch_box.add_child(_node_button(id, "branch", -1, b, col, lvl, true))
	box.add_child(row)
	row.add_child(branch_box)
	return box

func _node_button(id: String, kind: String, index: int, node: Dictionary, col: Color, lvl: int, small := false) -> Button:
	var branch_id := String(node.get("id", ""))
	var owned := false
	var available := false
	var chosen_branch: String = armory.branch_of(run, id)
	if kind == "level":
		owned = lvl > index
		available = lvl == index
	else:
		owned = lvl == 3 and chosen_branch == branch_id
		available = lvl == 2
	var state_text: String
	var ring: Color
	if owned:
		state_text = "forged"
		ring = col
	elif lvl == 3 and kind == "branch":
		state_text = "sealed"
		ring = Color("3d3658")
	elif available:
		state_text = "%d g" % int(node["cost"])
		ring = UiKit.GOLD
	else:
		state_text = "locked"
		ring = Color("3d3658")
	var b := UiKit.button("%s\n%s" % [node["name"], state_text], Color("221e36"), col if owned or available else UiKit.TEXT_FAINT, 18 if small else 20)
	b.custom_minimum_size = Vector2(0, 62 if small else 92)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_stylebox_override("normal", UiKit.flat_style(Color("221e36"), 10, ring, 2))
	b.add_theme_stylebox_override("hover", UiKit.flat_style(Color("2a2540"), 10, ring, 2))
	b.add_theme_stylebox_override("pressed", UiKit.flat_style(Color("1b1830"), 10, ring, 2))
	if not (owned or available):
		b.modulate = Color(1, 1, 1, 0.55)
	b.pressed.connect(func() -> void: _select(id, kind, branch_id, node, owned, available, col))
	_node_buttons.append(b)
	return b

func _select(id: String, kind: String, branch_id: String, node: Dictionary, owned: bool, available: bool, col: Color) -> void:
	_selected = {"id": id, "branch": branch_id}
	_note.visible = false
	_detail_title.text = node["name"]
	_detail_title.add_theme_color_override("font_color", col)
	_detail_desc.visible = true
	var desc := String(node["desc"])
	if kind == "branch":
		desc += " — choosing this seals the other path"
	_detail_desc.text = desc
	if owned:
		_forge_btn.visible = false
		_detail_desc.text = String(node["desc"]) + " — forged onto the golem"
	elif available:
		_forge_btn.visible = true
		_forge_btn.text = "Forge — %d g" % int(node["cost"])
	else:
		_forge_btn.visible = false
		var check: Dictionary = armory.can_forge(run, id, branch_id)
		_note.visible = true
		_note.text = String(check["reason"]) if check["reason"] != "" else "locked"

func _on_forge() -> void:
	if _selected.is_empty():
		return
	if armory.forge(run, _selected["id"], _selected["branch"]):
		Settings.vibrate(15)
		_gold_label.text = "%d g" % run.gold
		_forge_btn.visible = false
		_build_rows()
		_detail_desc.text += " — forged onto the golem"
	else:
		var check: Dictionary = armory.can_forge(run, _selected["id"], _selected["branch"])
		_note.visible = true
		_note.text = String(check["reason"])
