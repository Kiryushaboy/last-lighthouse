class_name UiTheme
extends RefCounted
## Интерфейс в цветах главы: рамки, свечение и фон окон берут цвета из Nights.CHAPTERS[].theme.
## Меняем общую тему проекта, поэтому перекрашиваются сразу все кнопки и окна.

static var chapter := -1
static var accent := Color(0.3, 0.85, 1.0)


## Перекрасить интерфейс под главу. Повторный вызов с той же главой ничего не делает.
static func apply(ch: int) -> void:
	ch = clampi(ch, 0, Nights.CHAPTERS.size() - 1)
	if ch == chapter:
		return
	chapter = ch
	var th: Dictionary = Nights.CHAPTERS[ch].theme
	accent = th.rim
	var base: Color = th.bg
	# Фон окон всегда тёмный, чтобы текст читался и в светлых главах (Ледяной север).
	var dark := Color.from_hsv(base.h, minf(base.s, 0.75), minf(base.v, 0.16) * 0.75 + 0.02)
	var theme := ThemeDB.get_project_theme()
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	normal.bg_color = Color(dark.lightened(0.06), 0.95)
	normal.border_color = Color(accent, 0.6)
	normal.shadow_color = Color(accent, 0.2)
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	panel.bg_color = Color(dark, 0.95)
	panel.border_color = Color(accent, 0.5)
	panel.shadow_color = Color(accent, 0.16)
	var fill := theme.get_stylebox("fill", "ProgressBar") as StyleBoxFlat
	fill.bg_color = accent.lerp(Color(0.35, 0.95, 0.7), 0.35)
	fill.shadow_color = Color(fill.bg_color, 0.45)


## Тёмный цвет для плиток внутри окон.
static func tile_bg() -> Color:
	var panel := ThemeDB.get_project_theme().get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	return panel.bg_color.lightened(0.07)
