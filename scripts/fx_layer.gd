class_name FxLayer
extends Node2D
## Рисует все частицы мира одним узлом: искры, кольца, всплывающие цифры.
## Так дешевле, чем сотня отдельных узлов, и работает на слабых телефонах.

const MAX_PARTICLES := 600
const GLOW := preload("res://art/fx/glow.tres")

var _parts: Array[Dictionary] = []  ## {p, v, life, max, color, size}
var _rings: Array[Dictionary] = []  ## {p, life, max, color, radius, width}
var _texts: Array[Dictionary] = []  ## {p, life, max, text, color, big}
var _font: Font


func _ready() -> void:
	Fx.layer = self
	_font = ThemeDB.fallback_font
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # частицы светятся, складываясь
	material = mat
	# Цифры урона рисуются отдельным узлом без сложения цветов, иначе их не прочитать.
	var label_layer := Node2D.new()
	label_layer.z_index = 1
	label_layer.draw.connect(_draw_texts.bind(label_layer))
	label_layer.material = CanvasItemMaterial.new()  # обычное смешивание
	add_child(label_layer)
	set_meta("text_layer", label_layer)


func _exit_tree() -> void:
	if Fx.layer == self:
		Fx.layer = null


func burst(pos: Vector2, color: Color, count: int, speed: float, size: float) -> void:
	for i in count:
		if _parts.size() >= MAX_PARTICLES:
			_parts.pop_front()
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		var life := randf_range(0.25, 0.55)
		_parts.append({"p": pos, "v": dir * speed * randf_range(0.35, 1.0), "life": life, "max": life,
				"color": color, "size": size * randf_range(0.6, 1.3)})


func ring(pos: Vector2, color: Color, radius: float, duration: float, width: float) -> void:
	_rings.append({"p": pos, "life": duration, "max": duration, "color": color, "radius": radius, "width": width})


func float_text(pos: Vector2, value: String, color: Color, big: bool) -> void:
	if _texts.size() > 40:
		_texts.pop_front()
	_texts.append({"p": pos + Vector2(randf_range(-10, 10), -20), "life": 0.7, "max": 0.7,
			"text": value, "color": color, "big": big})


func _process(delta: float) -> void:
	for p in _parts:
		p.life -= delta
		p.p += p.v * delta
		p.v *= 1.0 - 4.0 * delta  # быстро тормозят, как брызги
	_parts = _parts.filter(func(p): return p.life > 0.0)
	for r in _rings:
		r.life -= delta
	_rings = _rings.filter(func(r): return r.life > 0.0)
	for t in _texts:
		t.life -= delta
		t.p.y -= 60.0 * delta
	_texts = _texts.filter(func(t): return t.life > 0.0)
	queue_redraw()
	(get_meta("text_layer") as Node2D).queue_redraw()


func _draw() -> void:
	for p in _parts:
		var k: float = p.life / p.max
		var s: float = p.size * (0.4 + 0.6 * k)
		var c: Color = p.color
		draw_texture_rect(GLOW, Rect2(p.p - Vector2(s, s) * 2.0, Vector2(s, s) * 4.0), false, Color(c, 0.45 * k))
		# Искра-росчерк вдоль полёта: выглядит как брызги света, а не точки.
		var tail: Vector2 = p.v * 0.035
		draw_line(p.p - tail, p.p, Color(c.lightened(0.6), k), s * 0.6)
	for r in _rings:
		var k: float = 1.0 - r.life / r.max
		var ease_k := 1.0 - pow(1.0 - k, 3.0)
		draw_arc(r.p, r.radius * ease_k, 0.0, TAU, 40, Color(r.color, (1.0 - k) * r.color.a), r.width * (1.0 - k) + 1.0)


func _draw_texts(node: Node2D) -> void:
	for t in _texts:
		var k: float = t.life / t.max
		var size := 40 if t.big else 28
		var pop := 1.0 + 0.4 * maxf(0.0, (k - 0.8) / 0.2)  # в первый миг чуть крупнее
		var fs := int(size * pop)
		var w := _font.get_string_size(t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos: Vector2 = t.p - Vector2(w / 2.0, 0)
		var a := minf(1.0, k * 2.5)
		node.draw_string_outline(_font, pos, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0, 0, 0, 0.8 * a))
		node.draw_string(_font, pos, t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(t.color, a))
