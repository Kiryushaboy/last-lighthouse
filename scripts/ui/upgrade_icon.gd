class_name UpgradeIcon
extends Control
## Значок улучшения: рисуется кодом из простых фигур и спрайтов игры.

const HARPOON := preload("res://art/sprites/harpoon.svg")
const LIGHTHOUSE := preload("res://art/sprites/lighthouse.svg")
const GLOW := preload("res://art/fx/glow.tres")
const SHELL := preload("res://art/sprites/seashell.svg")

const COLORS := {
	"damage": Color(1.0, 0.45, 0.35), "fire_rate": Color(1.0, 0.75, 0.3), "multishot": Color(1.0, 0.85, 0.4),
	"pierce": Color(0.6, 0.8, 1.0), "speed": Color(0.45, 1.0, 0.75), "max_hp": Color(1.0, 0.4, 0.5),
	"magnet": Color(0.75, 0.6, 1.0), "beam": Color(1.0, 0.9, 0.55), "shield": Color(0.4, 0.9, 1.0),
	# Бонусы мастерской.
	"hp": Color(1.0, 0.4, 0.5), "crit": Color(1.0, 0.55, 0.3), "start": Color(0.85, 0.6, 1.0),
	"power": Color(1.0, 0.45, 0.35), "bubble": Color(0.4, 0.9, 1.0), "regen": Color(0.5, 1.0, 0.6), "pull": Color(0.75, 0.6, 1.0),
	"luck": Color(1.0, 0.75, 0.8),
}

var id := ""
var _t := 0.0


var icon_size := 110.0
var _k := 1.0
var _off := Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


static func color_of(upgrade_id: String) -> Color:
	return COLORS.get(upgrade_id, Color.WHITE)


func _draw() -> void:
	# Значок нарисован под размер 110; для маленьких просто масштабируем.
	_k = minf(size.x, size.y) / 110.0
	_off = size / 2.0 * (1.0 - _k)
	draw_set_transform(_off, 0.0, Vector2(_k, _k))
	var c := size / 2.0
	var col := color_of(id)
	var pulse := 0.85 + 0.15 * sin(_t * 3.0)
	draw_texture_rect(GLOW, Rect2(c - Vector2(70, 70), Vector2(140, 140)), false, Color(col, 0.35 * pulse))
	draw_circle(c, 46.0, Color(0.03, 0.06, 0.12, 0.9))
	draw_arc(c, 46.0, 0.0, TAU, 48, Color(col, 0.9), 3.0)
	match id:
		"damage", "power":
			_harpoon(c, -PI / 4.0, 2.2)
		"fire_rate":
			_harpoon(c + Vector2(-8, 10), -PI / 4.0, 1.6)
			_harpoon(c + Vector2(10, -8), -PI / 4.0, 1.6)
		"multishot":
			for a in [-0.45, 0.0, 0.45]:
				_harpoon(c + Vector2(0, 14), -PI / 2.0 + a, 1.5, Vector2(0, -14))
		"pierce":
			draw_arc(c, 18.0, 0.0, TAU, 24, Color(1, 0.4, 0.35), 5.0)
			_harpoon(c, 0.0, 2.2)
		"speed":
			for i in 3:
				var y := -14.0 + i * 14.0
				draw_line(c + Vector2(-30, y), c + Vector2(-4 - i * 4, y), Color(col, 0.6), 4.0)
			draw_polyline(PackedVector2Array([c + Vector2(0, -18), c + Vector2(18, 0), c + Vector2(0, 18)]), col, 7.0)
			draw_polyline(PackedVector2Array([c + Vector2(14, -18), c + Vector2(32, 0), c + Vector2(14, 18)]), col, 7.0)
		"max_hp":
			_heart(c + Vector2(0, 2), 26.0 * pulse, col)
		"magnet", "pull":
			draw_arc(c + Vector2(0, -4), 20.0, 0.0, PI, 24, col, 12.0)
			draw_rect(Rect2(c + Vector2(-26, -16), Vector2(12, 14)), Color(0.85, 0.85, 0.9))
			draw_rect(Rect2(c + Vector2(14, -16), Vector2(12, 14)), Color(0.85, 0.85, 0.9))
		"shield", "bubble":
			draw_circle(c, 28.0, Color(col, 0.18))
			draw_arc(c, 28.0, 0.0, TAU, 40, col, 5.0)
			draw_arc(c + Vector2(-8, -8), 14.0, PI * 1.05, PI * 1.5, 10, Color(1, 1, 1, 0.8), 4.0)
		"hp":
			_heart(c + Vector2(0, 2), 26.0 * pulse, col)
			draw_line(c + Vector2(22, -26), c + Vector2(22, -10), Color.WHITE, 5.0)
			draw_line(c + Vector2(14, -18), c + Vector2(30, -18), Color.WHITE, 5.0)
		"crit":
			var pts := PackedVector2Array()
			for i in 16:
				var r := 30.0 if i % 2 == 0 else 13.0
				pts.append(c + Vector2.RIGHT.rotated(TAU * i / 16.0 + _t * 0.5) * r)
			draw_colored_polygon(pts, col)
			draw_string(ThemeDB.fallback_font, c + Vector2(-15, 9), "×2", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.15, 0.05, 0.0))
		"start":
			draw_rect(Rect2(c + Vector2(-24, -8), Vector2(48, 32)), col)
			draw_rect(Rect2(c + Vector2(-28, -18), Vector2(56, 12)), col.lightened(0.2))
			draw_rect(Rect2(c + Vector2(-4, -18), Vector2(8, 42)), Color(1, 0.85, 0.4))
			draw_arc(c + Vector2(-9, -24), 8.0, 0.0, TAU, 12, Color(1, 0.85, 0.4), 4.0)
			draw_arc(c + Vector2(9, -24), 8.0, 0.0, TAU, 12, Color(1, 0.85, 0.4), 4.0)
		"regen":
			_heart(c + Vector2(0, 4), 22.0, Color(1.0, 0.4, 0.5))
			draw_arc(c, 34.0, -PI / 2.0 + _t * 2.0, -PI / 2.0 + _t * 2.0 + PI * 1.4, 24, col, 5.0)
		"luck":
			draw_texture_rect(SHELL, Rect2(c - Vector2(26, 26) * pulse, Vector2(52, 52) * pulse), false)
			draw_string(ThemeDB.fallback_font, c + Vector2(8, 30), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)
		"beam":
			var cone := PackedVector2Array([c + Vector2(0, 8), c + Vector2(-34, -30), c + Vector2(34, -30)])
			draw_colored_polygon(cone, Color(col, 0.35))
			draw_texture_rect(LIGHTHOUSE, Rect2(c - Vector2(24, 16), Vector2(48, 48)), false)


func _harpoon(at: Vector2, angle: float, scale_k: float, offset := Vector2.ZERO) -> void:
	var s := HARPOON.get_size() * 0.5 * scale_k
	draw_set_transform(_off + (at + offset.rotated(angle + PI / 2.0)) * _k, angle, Vector2(_k, _k))
	draw_texture_rect(HARPOON, Rect2(-s / 2.0, s), false)
	draw_set_transform(_off, 0.0, Vector2(_k, _k))


func _heart(at: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(at + Vector2(x, y) * r / 16.0)
	draw_colored_polygon(pts, col)
