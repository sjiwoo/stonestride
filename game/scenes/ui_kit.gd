class_name UiKit
extends RefCounted
## Shared code-built UI helpers so every menu speaks the same visual language.

const BG := Color("1b2440")
const PANEL := Color("2a2540")
const PANEL_LIGHT := Color("3d3658")
const TEXT := Color("efecf7")
const TEXT_DIM := Color("a9a2c4")
const TEXT_FAINT := Color("8f88ad")
const GOLD := Color("ffb347")
const GOLD_DARK := Color("4a2c00")
const GOOD := Color("9fe1cb")
const BAD := Color("f09595")

const CATEGORY_COLORS := {
	"attack": Color("e05a4e"),
	"speed": Color("5dcaa5"),
	"econ": Color("ffb347"),
}

static func label(text: String, size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

static func flat_style(bg: Color, radius: int = 12, border: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb

static func button(text: String, bg: Color, fg: Color, font_size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", fg)
	b.add_theme_color_override("font_pressed_color", fg)
	b.add_theme_color_override("font_hover_color", fg)
	var sb := flat_style(bg, 14)
	b.add_theme_stylebox_override("normal", sb)
	var sb_down := flat_style(bg.darkened(0.15), 14)
	b.add_theme_stylebox_override("pressed", sb_down)
	b.add_theme_stylebox_override("hover", flat_style(bg.lightened(0.06), 14))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.custom_minimum_size = Vector2(0, 84)
	return b

static func primary_button(text: String) -> Button:
	return button(text, GOLD, GOLD_DARK)

static func ghost_button(text: String) -> Button:
	return button(text, PANEL, TEXT_DIM)

static func panel(bg: Color = PANEL, radius: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat_style(bg, radius))
	return p

static func vbox(gap: int = 16) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	return v

static func hbox(gap: int = 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	return h

static func spacer(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	return c

static func slider(value: float, on_change: Callable) -> HSlider:
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(0, 48)
	s.value_changed.connect(on_change)
	return s

static func fullscreen_dim(alpha: float = 0.6) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.04, 0.05, 0.09, alpha)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r

static func center_panel(width: float) -> Dictionary:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	var p := panel()
	p.custom_minimum_size = Vector2(width, 0)
	center.add_child(p)
	return {"center": center, "panel": p}
