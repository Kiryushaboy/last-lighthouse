extends Node2D
## Картинка заставки: ночное небо, маяк с лучами, название игры.

const FG := preload("res://art/icon/icon_fg_432.png")
const GLOW := preload("res://art/fx/glow.tres")
const TITLE_FONT := preload("res://ui/fonts/RussoOne-Regular.ttf")
const TEXT_FONT := preload("res://ui/fonts/Rubik-VariableFont_wght.ttf")


func _draw() -> void:
	var w := 720.0
	var h := 1280.0
	# Небо: сверху темнее, к морю светлее.
	var steps := 64
	for i in steps:
		var t := float(i) / steps
		draw_rect(Rect2(0, h * t, w, h / steps + 1), Color("#0b1630").lerp(Color("#06253d"), t))
	# Звёзды.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var p := Vector2(rng.randf() * w, rng.randf() * 520.0)
		draw_circle(p, rng.randf_range(1.0, 2.6), Color(1, 1, 1, rng.randf_range(0.3, 0.9)))
	var c := Vector2(w / 2.0, 470.0)
	# Лучи маяка.
	var lamp := c + Vector2(0, -105)
	for side in [-1.0, 1.0]:
		var cone := PackedVector2Array([lamp, lamp + Vector2(side * 420, -120), lamp + Vector2(side * 420, 60)])
		draw_colored_polygon(cone, Color(1.0, 0.85, 0.45, 0.16))
	draw_texture_rect(GLOW, Rect2(lamp - Vector2(170, 170), Vector2(340, 340)), false, Color(1.0, 0.8, 0.4, 0.55))
	draw_texture_rect(FG, Rect2(c - Vector2(216, 216), Vector2(432, 432)), false)
	# Название и подпись.
	_text(TITLE_FONT, "ПОСЛЕДНИЙ", 760.0, 76, Color("#ffd25a"))
	_text(TITLE_FONT, "МАЯК", 850.0, 96, Color("#ffd25a"))
	_text(TEXT_FONT, "Продержитесь до рассвета", 930.0, 30, Color(1, 1, 1, 0.7))


func _text(font: Font, s: String, y: float, size: int, col: Color) -> void:
	var tw := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var pos := Vector2((720.0 - tw) / 2.0, y)
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 14, Color(1.0, 0.6, 0.2, 0.25))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
