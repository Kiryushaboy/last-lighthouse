shader_type canvas_item;
// Фон карты: море в цветах главы с медленной рябью и бликами.
uniform vec4 deep : source_color = vec4(0.0, 0.02, 0.06, 1.0);
uniform vec4 shallow : source_color = vec4(0.02, 0.09, 0.17, 1.0);
uniform vec4 foam : source_color = vec4(0.3, 0.9, 1.0, 1.0);

void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.4;
	float r = sin(uv.x * 18.0 + t + sin(uv.y * 9.0 + t) * 2.0) + sin(uv.y * 24.0 - t * 0.8);
	vec3 col = mix(deep.rgb, shallow.rgb, smoothstep(0.0, 1.0, uv.y));
	col += foam.rgb * smoothstep(1.5, 2.0, r) * 0.07;
	// Светлее в середине, темнее к краям — взгляд тянется к тропе.
	float v = distance(uv, vec2(0.5, 0.5));
	col *= 1.15 - 0.5 * v;
	COLOR = vec4(col, 1.0);
}
