class_name UiFx
extends RefCounted
## Анимации интерфейса: окна выпрыгивают, элементы появляются по очереди, кнопки пружинят.


## Окно появляется: фон темнеет, карточка вырастает с лёгким перехлёстом.
static func pop_in(card: Control, dim: CanvasItem = null) -> void:
	await card.get_tree().process_frame  # ждём, пока контейнер посчитает размеры
	card.pivot_offset = card.size / 2.0
	card.scale = Vector2(0.85, 0.85)
	card.modulate.a = 0.0
	var tw := card.create_tween().set_ignore_time_scale().set_parallel()
	tw.tween_property(card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.2)
	if dim:
		dim.modulate.a = 0.0
		tw.tween_property(dim, "modulate:a", 1.0, 0.25)


## Дети контейнера появляются по одному сверху вниз.
static func stagger(items: Array, step := 0.06, start := 0.05) -> void:
	if items.is_empty():
		return
	var first := items[0] as Control
	await first.get_tree().process_frame
	for i in items.size():
		var c := items[i] as Control
		if not is_instance_valid(c):
			continue
		c.pivot_offset = c.size / 2.0
		c.modulate.a = 0.0
		c.scale = Vector2(0.9, 0.9)
		var tw := c.create_tween().set_ignore_time_scale().set_parallel()
		tw.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(start + i * step)
		tw.tween_property(c, "scale", Vector2.ONE, 0.4).set_delay(start + i * step) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Кнопка проседает под пальцем и пружинит обратно.
static func add_press_feedback(b: BaseButton) -> void:
	b.resized.connect(func(): b.pivot_offset = b.size / 2.0)
	b.button_down.connect(func(): _scale_to(b, 0.94, 0.08))
	b.button_up.connect(func(): _scale_to(b, 1.0, 0.3))


## Короткий «бум» значения: увеличить и вернуть (счётчик ракушек, уровень).
static func bump(c: Control, amount := 1.25) -> void:
	c.pivot_offset = c.size / 2.0
	var tw := c.create_tween().set_ignore_time_scale()
	tw.tween_property(c, "scale", Vector2(amount, amount), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


static func _scale_to(c: Control, s: float, t: float) -> void:
	if not c.is_inside_tree():
		return
	var tw := c.create_tween().set_ignore_time_scale()
	tw.tween_property(c, "scale", Vector2(s, s), t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
