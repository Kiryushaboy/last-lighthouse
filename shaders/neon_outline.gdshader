shader_type canvas_item;
// Неоновый контур: яркая кромка вокруг спрайта и мягкое свечение наружу.
// Прямоугольник рисования чуть расширяется (pad), чтобы свечению было где поместиться.
uniform vec4 glow_color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float width = 3.0;  // толщина кромки в пикселях текстуры
uniform float pad = 0.4;

vec4 tex(sampler2D t, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return vec4(0.0);
	return texture(t, uv);
}

void vertex() {
	VERTEX *= 1.0 + pad;
	UV = (UV - 0.5) * (1.0 + pad) + 0.5;
}

void fragment() {
	vec4 c = tex(TEXTURE, UV) * COLOR;
	vec2 px = TEXTURE_PIXEL_SIZE * width;
	float rim = 0.0;
	float halo = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = 6.2831853 * float(i) / 12.0;
		vec2 d = vec2(cos(ang), sin(ang));
		rim = max(rim, tex(TEXTURE, UV + d * px).a);
		halo += tex(TEXTURE, UV + d * px * 3.0).a;
	}
	halo /= 12.0;
	vec4 outer = vec4(glow_color.rgb, max(rim, halo) * glow_color.a);
	vec3 lit = mix(outer.rgb, c.rgb, c.a);
	COLOR = vec4(lit, max(outer.a, c.a));
}
