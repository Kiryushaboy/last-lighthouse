shader_type canvas_item;
// Цветная вспышка по краям экрана: в центре прозрачно, к краям гуще.
uniform vec4 tint : source_color = vec4(1.0, 0.0, 0.0, 0.0);

void fragment() {
	vec2 d = UV - vec2(0.5);
	float v = smoothstep(0.25, 0.75, length(d * vec2(1.0, 0.75)) * 1.4);
	COLOR = vec4(tint.rgb, tint.a * v);
}
