shader_type canvas_item;
// Туман: вокруг героя (центр экрана) видно, дальше всё тонет в серо-синей дымке.
uniform vec4 fog_color : source_color = vec4(0.22, 0.27, 0.36, 1.0);

void fragment() {
	vec2 d = (UV - vec2(0.5, 0.5)) * vec2(1.0, 1.78);
	float r = length(d);
	float drift = sin(TIME * 0.3 + UV.y * 6.0) * 0.03 + sin(TIME * 0.21 + UV.x * 5.0) * 0.03;
	float a = smoothstep(0.22, 0.55, r + drift);
	COLOR = vec4(fog_color.rgb, a * 0.92);
}
