class_name UpgradeIcon
extends Control
## Значок улучшения или бонуса: готовый рисунок из art/icons (их делает tools/make_icons.py)
## с мягким свечением своего цвета. Чуть «дышит», чтобы меню было живым.

const GLOW := preload("res://art/fx/glow.tres")

const COLORS := {
	"damage": Color(1.0, 0.45, 0.35), "fire_rate": Color(1.0, 0.75, 0.3), "multishot": Color(1.0, 0.85, 0.4),
	"pierce": Color(0.45, 0.7, 1.0), "speed": Color(0.35, 0.95, 0.65), "max_hp": Color(1.0, 0.4, 0.5),
	"magnet": Color(0.7, 0.55, 1.0), "beam": Color(1.0, 0.85, 0.4), "shield": Color(0.35, 0.85, 1.0),
	# Бонусы мастерской.
	"hp": Color(1.0, 0.4, 0.5), "power": Color(1.0, 0.45, 0.35), "crit": Color(1.0, 0.6, 0.3),
	"start": Color(0.8, 0.55, 1.0), "bubble": Color(0.35, 0.85, 1.0), "regen": Color(0.4, 0.95, 0.55),
	"pull": Color(0.7, 0.55, 1.0), "luck": Color(1.0, 0.6, 0.75),
}

var id := ""
var icon_size := 110.0
var glow := true
var _t := 0.0
var _tex: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(icon_size, icon_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_tex = texture_of(id)
	_t = randf() * 6.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


static func color_of(upgrade_id: String) -> Color:
	return COLORS.get(upgrade_id, Color.WHITE)


static func texture_of(upgrade_id: String) -> Texture2D:
	var path := "res://art/icons/%s.svg" % upgrade_id
	return load(path) if ResourceLoader.exists(path) else null


func _draw() -> void:
	var s := minf(size.x, size.y)
	var c := size / 2.0
	var pulse := 0.5 + 0.5 * sin(_t * 2.4)
	if glow:
		var g := s * 0.82
		draw_texture_rect(GLOW, Rect2(c - Vector2(g, g), Vector2(g, g) * 2.0), false, Color(color_of(id), 0.3 + 0.2 * pulse))
	if _tex:
		var k := s * (0.94 + 0.03 * pulse)
		draw_texture_rect(_tex, Rect2(c - Vector2(k, k) / 2.0, Vector2(k, k)), false)
