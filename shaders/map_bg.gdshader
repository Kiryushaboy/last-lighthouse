shader_type canvas_item;
// Фон карты: ночное море с медленной рябью и светлой полосой берега слева.
void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.4;
	float r = sin(uv.x * 18.0 + t + sin(uv.y * 9.0 + t) * 2.0) + sin(uv.y * 24.0 - t * 0.8);
	vec3 col = mix(vec3(0.0, 0.02, 0.06), vec3(0.02, 0.09, 0.17), uv.y);
	col += vec3(0.3, 0.9, 1.0) * smoothstep(1.6, 2.0, r) * 0.05;
	float shore = smoothstep(0.08, 0.0, uv.x + sin(uv.y * 20.0) * 0.01);
	col = mix(col, vec3(0.12, 0.14, 0.21), shore);
	COLOR = vec4(col, 1.0);
}
