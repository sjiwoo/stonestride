class_name PathOverlay
extends CanvasLayer
## Post-draft path choice: themed routes bias the next draft's category odds.

signal chosen(index: int)

var choices: Array = []
var drafts: RefCounted

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.fullscreen_dim())
	var wrap: Dictionary = UiKit.center_panel(620)
	add_child(wrap["center"])
	var v: VBoxContainer = UiKit.vbox(14)
	wrap["panel"].add_child(v)
	v.add_child(UiKit.label("Choose your path", 40))
	v.add_child(UiKit.label("The route shapes your next upgrade draft", 20, UiKit.TEXT_FAINT))
	for choice: Dictionary in choices:
		v.add_child(_make_choice(choice))

func _make_choice(choice: Dictionary) -> Button:
	var node: RefCounted = choice["node"]
	var info: Dictionary = drafts.theme_info(node.theme)
	var col := Color(String(info["color"]))
	var title := String(info["name"])
	if node.theme == "boss":
		title = "Boss gate — the horde's champion"
	elif node.get("elite"):
		title += "  ·  elite"
	var odds := ""
	if node.theme != "boss":
		var w: Dictionary = info["weights"]
		odds = "%d%% attack · %d%% speed · %d%% econ" % [w["attack"], w["speed"], w["econ"]]
	else:
		odds = "Survive the champion to win the run"
	var b := UiKit.button(title + "\n" + odds, col.darkened(0.68), col, 24)
	b.custom_minimum_size = Vector2(0, 110)
	b.pressed.connect(func() -> void:
		chosen.emit(choice["index"])
		queue_free())
	return b
