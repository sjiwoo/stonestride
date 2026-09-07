class_name PathOverlay
extends CanvasLayer
## Post-draft path choice: themed routes bias the next draft's category odds.
## Each gate carries a faint flame aura tinted by its route theme; boss gates burn hotter.

signal chosen(index: int)

const GATE_CORNER := 14
const AURA_PAD := 20.0

var choices: Array = []
var drafts: RefCounted

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(UiKit.fullscreen_dim())
	var wrap: Dictionary = UiKit.center_panel(620)
	add_child(wrap["center"])
	var v: VBoxContainer = UiKit.vbox(8)
	wrap["panel"].add_child(v)
	v.add_child(UiKit.label("Choose your path", 40))
	v.add_child(UiKit.label("The route shapes your next upgrade draft", 20, UiKit.TEXT_FAINT))
	for choice: Dictionary in choices:
		v.add_child(_make_choice(choice))

func _make_choice(choice: Dictionary) -> FlameFrame:
	var node: RefCounted = choice["node"]
	var info: Dictionary = drafts.theme_info(node.theme)
	var col := Color(String(info["color"]))
	var is_boss: bool = node.theme == "boss"
	var is_elite: bool = bool(node.get("elite"))
	var title := String(info["name"])
	if is_boss:
		title = "Boss gate — the horde's champion"
	elif is_elite:
		title += "  ·  elite"
	var odds := ""
	if not is_boss:
		var w: Dictionary = info["weights"]
		odds = "%d%% attack · %d%% speed · %d%% econ" % [w["attack"], w["speed"], w["econ"]]
	else:
		odds = "Survive the champion to win the run"
	var b := UiKit.button(title + "\n" + odds, col.darkened(0.68), col, 24)
	b.custom_minimum_size = Vector2(0, 110)
	b.pressed.connect(func() -> void:
		chosen.emit(choice["index"])
		queue_free())
	var flame_tint := col.lerp(Color("ff7a2f"), 0.45)
	var intensity := 0.20
	if is_boss:
		flame_tint = Color("e2372f")
		intensity = 0.55
	elif is_elite:
		intensity = 0.34
	return FlameFrame.wrap(b, flame_tint, intensity, AURA_PAD, float(GATE_CORNER))
