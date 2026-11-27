class_name NightBadge
extends Control
## Значок ночи на карте: маленький маяк с номером. Пройденная — светится, закрытая — тёмная.

var number := 1
var unlocked := true
var boss := false
var done := false
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(96, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var gold := Color(1, 0.8, 0.4)
	var col := gold if unlocked else Color(1, 1, 1, 0.2)
	if unlocked and not done:
		# Текущая цель пульсирует.
		var p := 0.5 + 0.5 * sin(_t * 3.0)
		draw_texture_rect(preload("res://art/fx/glow.tres"), Rect2(c - Vector2(60, 60), Vector2(120, 120)), false, Color(1, 0.8, 0.4, 0.25 + 0.25 * p))
	draw_circle(c, 40.0, Color(0.03, 0.06, 0.12))
	draw_arc(c, 40.0, 0.0, TAU, 40, Color(1, 0.4, 0.4) if boss and unlocked else col, 4.0)
	var font := ThemeDB.fallback_font
	var s := str(number)
	var fs := 36
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, c + Vector2(-w / 2.0, 13), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	if not unlocked:
		# Замочек.
		draw_rect(Rect2(c + Vector2(14, 14), Vector2(22, 18)), Color(0.6, 0.65, 0.75))
		draw_arc(c + Vector2(25, 14), 7.0, PI, TAU, 10, Color(0.6, 0.65, 0.75), 3.0)
