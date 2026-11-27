class_name SafeArea
extends RefCounted
## Отступы от краёв экрана: вырез камеры, закруглённые углы, жестовая полоска внизу.
## Берём системную «безопасную зону» и добавляем свой небольшой запас.

const MIN_TOP := 36.0  ## минимум сверху, в пикселях игры (экран 720 в ширину)
const MIN_BOTTOM := 32.0


## Отступы сверху и снизу в координатах игры.
static func insets(viewport: Viewport) -> Vector2:
	var top := MIN_TOP
	var bottom := MIN_BOTTOM
	var screen := DisplayServer.screen_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if screen.y > 0 and safe.size.y > 0:
		var k := viewport.get_visible_rect().size.y / float(screen.y)
		top = maxf(top, safe.position.y * k + 12.0)
		bottom = maxf(bottom, (screen.y - safe.end.y) * k + 12.0)
	return Vector2(top, bottom)


## Сдвинуть растянутый на весь экран элемент внутрь безопасной зоны.
static func apply(control: Control) -> void:
	var i := insets(control.get_viewport())
	control.offset_top += i.x
	control.offset_bottom -= i.y


## То же для MarginContainer: добавить к его отступам.
static func apply_margin(m: MarginContainer) -> void:
	var i := insets(m.get_viewport())
	m.add_theme_constant_override("margin_top", m.get_theme_constant("margin_top") + int(i.x))
	m.add_theme_constant_override("margin_bottom", m.get_theme_constant("margin_bottom") + int(i.y))
