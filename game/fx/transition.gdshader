shader_type canvas_item;
// Radial wipe used by the scene router. progress 0 = clear, 1 = fully covered.
// Coverage circle grows from the center; alpha is 1 inside, 0 outside.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(0.063, 0.075, 0.122, 1.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.y *= 1.78;
	float d = length(p);
	float r = progress * 1.15;
	float cov = 1.0 - smoothstep(max(r - 0.08, 0.0), r + 0.001, d);
	COLOR = vec4(tint.rgb, cov);
}
