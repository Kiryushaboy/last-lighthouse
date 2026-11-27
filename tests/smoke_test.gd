extends SceneTree
## Дымовой тест: играет одну ночь сам, без экрана.
## Герой бегает по кругу, на каждом уровне берёт первое улучшение.
## Запуск: godot --headless --path . --fixed-fps 60 -s res://tests/smoke_test.gd

var main: Node
var frames := 0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 2:
		return false
	# Убегаем от крабов, которые ближе 250 пикселей, иначе медленно кружим.
	var t := frames / 60.0
	var away := Vector2.ZERO
	var me: Vector2 = main.player.global_position
	for e: Node2D in main.enemies.get_children():
		var d := me.distance_to(e.global_position)
		if d < 250.0:
			away += (me - e.global_position) / maxf(d * d, 1.0)
	# Не прижиматься к стенам: тянет к центру арены.
	away += -me / 900.0 * 0.002
	main.joystick.vector = away.normalized() if away.length() > 0.0005 else Vector2.RIGHT.rotated(t * 0.5) * 0.3

	var menu: CanvasLayer = main.upgrade_menu
	if menu.visible:
		var buttons := menu.get_node("Box/Choices").get_children().filter(
			func(b): return not b.is_queued_for_deletion())
		(buttons[0] as Button).pressed.emit()

	if frames % 1200 == 0:
		print("t=%3ds  врагов=%3d  уровень=%2d  жизни=%d  взято=%s" % [
			int(t), main.enemies.get_child_count(), main.level, main.player.hp, main.upgrades_taken])

	if main._over:
		print("КОНЕЦ: %s на %d с, уровень %d" % [
			"победа" if main.won else "поражение", int(t), main.level])
		return true
	return frames > 60 * 420
