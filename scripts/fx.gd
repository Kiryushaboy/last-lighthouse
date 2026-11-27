extends Node
## Визуальные эффекты («сочность»): частицы, тряска камеры, вспышки экрана, стоп-кадр.
## Автозагрузка «Fx»: Fx.burst(pos, color), Fx.shake(0.4), Fx.flash(Color.RED) из любого скрипта.
## Частицы рисует узел FxLayer в мире (scripts/fx_layer.gd); если его нет, эффекты просто пропускаются.

var layer: Node2D  ## текущий FxLayer, регистрируется сам
var trauma := 0.0  ## 0..1, сила тряски; камера читает и затухает сама

var _overlay: ColorRect
var _overlay_tween: Tween
var _hitstop_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var canvas := CanvasLayer.new()
	canvas.layer = 8
	add_child(canvas)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/vignette_flash.gdshader")
	_overlay.material = mat
	canvas.add_child(_overlay)
	_set_flash(Color(1, 1, 1, 0))


func _process(delta: float) -> void:
	trauma = maxf(trauma - delta * 1.6, 0.0)
	if _hitstop_left > 0.0:
		# delta уже замедлен time_scale, переводим обратно в реальные секунды.
		_hitstop_left -= delta / maxf(Engine.time_scale, 0.01)
		if _hitstop_left <= 0.0:
			Engine.time_scale = 1.0


## Тряска камеры. 0.2 — лёгкий толчок, 0.6 — удар босса.
func shake(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)
	# Сильные толчки отдаются вибрацией телефона; мелкие (смерть каждого краба) — нет.
	if amount >= 0.12:
		Settings.vibrate(int(70.0 + amount * 260.0), 0.55 + amount * 0.45)


## Короткий стоп-кадр: мир почти замирает на долю секунды — удар ощущается весомее.
func hitstop(seconds: float) -> void:
	_hitstop_left = maxf(_hitstop_left, seconds)
	Engine.time_scale = 0.05


func reset() -> void:
	_hitstop_left = 0.0
	Engine.time_scale = 1.0
	trauma = 0.0
	_set_flash(Color(1, 1, 1, 0))


## Вспышка по краям экрана (красная при уроне, белая на новом уровне).
func flash(color: Color, duration := 0.35) -> void:
	if _overlay_tween:
		_overlay_tween.kill()
	_set_flash(color)
	_overlay_tween = create_tween().set_ignore_time_scale()
	_overlay_tween.tween_method(func(a: float): _set_flash(Color(color, a)), color.a, 0.0, duration)


func _set_flash(c: Color) -> void:
	(_overlay.material as ShaderMaterial).set_shader_parameter("tint", c)
	_overlay.visible = c.a > 0.001


# --- Частицы (пересылаются в FxLayer) ------------------------------------

func burst(pos: Vector2, color: Color, count := 10, speed := 260.0, size := 5.0) -> void:
	if is_instance_valid(layer):
		layer.burst(pos, color, count, speed, size)


func ring(pos: Vector2, color: Color, radius := 60.0, duration := 0.35, width := 6.0) -> void:
	if is_instance_valid(layer):
		layer.ring(pos, color, radius, duration, width)


func text(pos: Vector2, value: String, color := Color.WHITE, big := false) -> void:
	if is_instance_valid(layer):
		layer.float_text(pos, value, color, big)


## Молния: ломаная линия через точки, гаснет за долю секунды.
func bolt(points: PackedVector2Array, color: Color) -> void:
	if is_instance_valid(layer):
		layer.bolt(points, color)
