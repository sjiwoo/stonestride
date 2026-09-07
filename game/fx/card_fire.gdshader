shader_type canvas_item;
// Subtle animated flame aura drawn just outside a rounded-rect card.
// Applied to a ColorRect that extends `pad` px past the card on every side.
// intensity 0 = invisible, ~0.25 = faint embers, ~0.9 = selected flare.

uniform vec4 tint : source_color = vec4(0.88, 0.35, 0.18, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.25;
uniform vec2 rect_size = vec2(620.0, 220.0);
uniform float pad = 16.0;
uniform float corner = 16.0;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		v += amp * vnoise(p);
		p = p * 2.1 + vec2(11.3, 7.7);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 center = rect_size * 0.5;
	vec2 inner_half = center - vec2(pad);
	vec2 d = abs(px - center) - inner_half + vec2(corner);
	float sdf = length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - corner;
	// sdf < 0 inside the card, 0 at its border, up to ~pad at the aura's outer edge.
	float outside = smoothstep(-1.5, 0.5, sdf);
	float rim = clamp(1.0 - sdf / pad, 0.0, 1.0);
	// Flames elongate upward: compress noise on y and scroll it up over time.
	vec2 np = vec2(px.x * 0.045, px.y * 0.06 - TIME * 2.4);
	float n = fbm(np);
	float n2 = fbm(np * 1.9 + vec2(5.2, TIME * 0.7));
	// Licks: noise gates how far each flame tongue reaches from the border.
	float lick = smoothstep(0.30, 0.95, rim * (0.45 + 0.85 * n));
	// Ember glow: a soft constant band hugging the border.
	float ember = smoothstep(0.15, 0.85, rim) * (0.30 + 0.25 * n2);
	float a = outside * clamp(lick + ember, 0.0, 1.0) * intensity;
	// Hot core near the border shifts toward yellow-white.
	float heat = clamp(n * lick * 1.4 + rim * 0.25, 0.0, 1.0);
	vec3 col = mix(tint.rgb * 0.85, vec3(1.0, 0.83, 0.45), heat * 0.6);
	COLOR = vec4(col, a * tint.a);
}
