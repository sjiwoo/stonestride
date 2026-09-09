shader_type canvas_item;
// Procedural wasteland backdrop for the path map: layered ridge silhouettes
// from fbm noise, slow drifting haze, and a vignette. No textures.

uniform vec4 sky_top : source_color = vec4(0.086, 0.11, 0.204, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.239, 0.192, 0.329, 1.0);
uniform vec4 ridge_color : source_color = vec4(0.12, 0.13, 0.24, 1.0);
uniform vec4 haze_color : source_color = vec4(0.94, 0.63, 0.28, 1.0);
uniform float scroll = 0.0; // map scroll offset in px, parallaxes the ridges

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), u.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 4; i++) {
		v += amp * vnoise(p);
		p = p * 2.03 + vec2(13.7, 7.1);
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec3 col = mix(sky_top.rgb, sky_bottom.rgb, uv.y);
	// Three ridge layers, each a noise-displaced horizon line with parallax.
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		float par = scroll * (0.00006 + fi * 0.00005);
		float horizon = 0.3 + fi * 0.22 + par;
		float ridge = fbm(vec2(uv.x * (2.2 + fi * 1.3) + fi * 9.1, fi * 4.7)) * (0.1 + fi * 0.035);
		float m = smoothstep(horizon + ridge, horizon + ridge + 0.008, uv.y);
		vec3 rc = mix(ridge_color.rgb, sky_top.rgb, 0.42 - fi * 0.18);
		col = mix(col, rc, m * (0.5 + fi * 0.22));
	}
	// Slow drifting haze band, faintly warm like distant embers.
	float haze = fbm(vec2(uv.x * 2.4 + TIME * 0.02, uv.y * 3.0 - TIME * 0.008));
	col += haze_color.rgb * smoothstep(0.62, 0.95, haze) * 0.045;
	// Vignette.
	float vig = smoothstep(0.95, 0.35, length(uv - vec2(0.5, 0.5)));
	col *= mix(0.72, 1.0, vig);
	// Respect the CanvasItem modulate (COLOR carries vertex color * modulate),
	// so the overlay can blend this pass over a painted backdrop.
	COLOR = vec4(col, 1.0) * COLOR;
}
