extends Control
## Run summary: victory or defeat, stats, retry or back to menu.

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var s: Dictionary = Game.last_summary
	var victory: bool = s.get("victory", false)
	var bg := ColorRect.new()
	bg.color = UiKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v: VBoxContainer = UiKit.vbox(16)
	v.set_anchors_preset(Control.PRESET_TOP_WIDE)
	v.offset_top = 200
	v.offset_left = 60
	v.offset_right = -60
	add_child(v)
	var title: Label = UiKit.label("Victory" if victory else "The march ends", 60,
		UiKit.GOOD if victory else UiKit.BAD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub: Label = UiKit.label(
		"The horde's champion is rubble." if victory else "The swarm drags your champion down at last.",
		24, UiKit.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	v.add_child(UiKit.spacer(20))
	var stats: PanelContainer = UiKit.panel()
	var sv: VBoxContainer = UiKit.vbox(10)
	stats.add_child(sv)
	sv.add_child(_stat_row("Checkpoints reached", str(s.get("wave", 1))))
	sv.add_child(_stat_row("Distance marched", "%d m" % int(s.get("distance", 0))))
	sv.add_child(_stat_row("Monsters squashed", str(s.get("kills", 0))))
	sv.add_child(_stat_row("Gold earned", "%d g" % int(s.get("gold", 0))))
	v.add_child(stats)
	v.add_child(UiKit.spacer(20))
	var again := UiKit.primary_button("Run again")
	again.pressed.connect(func() -> void:
		Game.start_run()
		Router.goto("res://game/scenes/march.tscn"))
	v.add_child(again)
	var menu := UiKit.ghost_button("Main menu")
	menu.pressed.connect(func() -> void:
		Router.goto("res://game/scenes/main_menu.tscn"))
	v.add_child(menu)

func _stat_row(name_text: String, value_text: String) -> HBoxContainer:
	var h: HBoxContainer = UiKit.hbox()
	var l: Label = UiKit.label(name_text, 24, UiKit.TEXT_DIM)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(UiKit.label(value_text, 24))
	return h
