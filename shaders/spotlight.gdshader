shader_type canvas_item;
// Затемнение экрана с «окном» вокруг того, о чём говорит обучение.
// Окно — скруглённый прямоугольник с пульсирующей неоновой рамкой.

uniform vec2 screen = vec2(720.0, 1280.0);
uniform vec4 hole = vec4(-9999.0, -9999.0, 0.0, 0.0);  // центр и половины сторон, в пикселях
uniform float radius = 24.0;
uniform float grow = 0.0;      // запас вокруг окна: с него окно «сжимается» в цель
uniform float dim = 0.8;       // сила затемнения
uniform float open = 1.0;      // общее проявление 0..1
uniform vec4 glow : source_color = vec4(0.4, 0.9, 1.0, 1.0);

float sd_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void fragment() {
	vec2 p = UV * screen - hole.xy;
	vec2 half = hole.zw + grow;
	float r = min(radius + grow, min(half.x, half.y));
	float d = sd_box(p, half, r);
	float shade = smoothstep(-1.0, 10.0, d) * dim;
	float pulse = 0.5 + 0.5 * sin(TIME * 4.0);
	float line = smoothstep(3.2, 1.2, abs(d - 3.0));
	float halo = exp(-max(d - 3.0, 0.0) * 0.07) * step(0.0, d) * (0.28 + 0.22 * pulse);
	// бегущая волна от рамки наружу
	float wave_d = fract(TIME * 0.7) * 46.0;
	float wave = smoothstep(4.0, 0.0, abs(d - 6.0 - wave_d)) * (1.0 - fract(TIME * 0.7)) * 0.55;
	float light = clamp(line + halo + wave, 0.0, 1.0) * step(0.5, hole.z);
	vec3 col = mix(vec3(0.008, 0.025, 0.06), glow.rgb, light);
	COLOR = vec4(col, max(shade, light * 0.95) * open);
}
