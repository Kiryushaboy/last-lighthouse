shader_type canvas_item;
// Ночное море: глубина, бегущая рябь, блики, пена у острова и туман к краям арены.
// Всё считается формулами, без текстур — легко для телефона.

uniform vec2 arena_half = vec2(900.0, 900.0);
uniform float island_radius = 300.0;
uniform vec4 deep : source_color = vec4(0.02, 0.07, 0.14, 1.0);
uniform vec4 shallow : source_color = vec4(0.05, 0.22, 0.32, 1.0);
uniform vec4 foam : source_color = vec4(0.75, 0.92, 1.0, 1.0);

varying vec2 world;

void vertex() {
	world = VERTEX;
}

float ripple(vec2 p, float t) {
	float v = sin(p.x * 0.018 + t * 0.9 + sin(p.y * 0.011 + t * 0.4) * 2.0);
	v += sin(p.y * 0.021 - t * 0.7 + sin(p.x * 0.013 - t * 0.5) * 2.0);
	v += 0.5 * sin((p.x + p.y) * 0.035 + t * 1.3);
	return v / 2.5;
}

void fragment() {
	float t = TIME;
	float d = length(world);
	// Глубина: светлее у острова, темнее вдали.
	float near_island = smoothstep(island_radius + 420.0, island_radius, d);
	vec3 col = mix(deep.rgb, shallow.rgb, near_island * 0.85 + 0.15);
	// Рябь и блики: тонкие светлые гребни.
	float r = ripple(world, t);
	float crest = smoothstep(0.55, 0.95, r);
	col += foam.rgb * crest * (0.05 + 0.10 * near_island);
	col *= 0.92 + 0.08 * r;
	// Пена прибоя вокруг острова, дышит.
	float surf = island_radius + 18.0 + sin(t * 1.4 + atan(world.y, world.x) * 6.0) * 6.0;
	float foam_line = smoothstep(26.0, 0.0, abs(d - surf));
	col = mix(col, foam.rgb, foam_line * 0.55);
	// Туман у краёв арены.
	vec2 e = abs(world) / arena_half;
	float edge = smoothstep(0.7, 1.0, max(e.x, e.y));
	col = mix(col, deep.rgb * 0.5, edge * 0.8);
	COLOR = vec4(col, 1.0);
}
