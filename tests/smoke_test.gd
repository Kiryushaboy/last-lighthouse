extends SceneTree
## Дымовой тест: играет одну ночь сам, без экрана.
## Герой бегает по кругу, на каждом уровне берёт первое улучшение.
## Запуск: godot --headless --path . --fixed-fps 60 -s res://tests/smoke_test.gd

var main: Node
var frames := 0


func _initialize() -> void:
	# Какую ночь кампании играть: NIGHT=4 godot ... (по умолчанию последняя, самая трудная).
	var night_env := OS.get_environment("NIGHT")
	root.get_node("SaveData").current_night = int(night_env) - 1 if night_env != "" else 11
	# Каким героем играть: HERO=mechanic godot ...
	var hero_env := OS.get_environment("HERO")
	if hero_env != "":
		# Сохранение грузится в _ready автозагрузки уже после _initialize, поэтому пишем в файл.
		var sd := root.get_node("SaveData")
		sd._ready()
		sd.hero = hero_env
		sd._save()
	# Чистый прогресс (без мастерской и героев) для проверки баланса: CLEAN=1.
	if OS.get_environment("CLEAN") == "1":
		var sd0 := root.get_node("SaveData")
		sd0._ready()
		sd0.levels = {}
		# PERKS=max — все бонусы мастерской куплены, PERKS=mid — половина.
		var perks_env := OS.get_environment("PERKS")
		for perk in sd0.PERKS:
			var top: int = perk.costs.size()
			if perks_env == "max":
				sd0.levels[perk.id] = top
			elif perks_env == "mid":
				sd0.levels[perk.id] = top / 2
		sd0.hero = hero_env if hero_env != "" else "keeper"
		if not sd0.heroes.has(sd0.hero):
			sd0.heroes.append(sd0.hero)
		sd0._save()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 2:
		return false
	# Бот поумнее: убегает от близких врагов, в спокойные моменты идёт за опытом,
	# держится ближе к центру арены. Играет хуже живого игрока, но уже собирает кристаллы.
	var t := frames / 60.0
	var away := Vector2.ZERO
	var me: Vector2 = main.player.global_position
	var danger := false
	for e: Node2D in main.enemies.get_children():
		var d := me.distance_to(e.global_position)
		if d < 170.0:
			danger = true
		if d < 260.0:
			away += (me - e.global_position) / maxf(d * d, 1.0)
	var dir := away.normalized() if away.length() > 0.0005 else Vector2.ZERO
	if not danger:
		var best: Node2D = null
		var best_d := 420.0
		for g: Node2D in main.gems.get_children():
			var gd := me.distance_to(g.global_position)
			if gd < best_d:
				best_d = gd
				best = g
		if best:
			dir = (dir * 0.5 + me.direction_to(best.global_position)).normalized()
	dir += -me / 900.0 * 0.6
	main.joystick.vector = dir.normalized() if dir.length() > 0.05 else Vector2.RIGHT.rotated(t * 0.5) * 0.3

	# Обучение: бот сразу листает подсказки.
	if main._tut and main._tut.busy() and frames % 30 == 0:
		main._tut.advance()

	# «Второй шанс» бот не берёт: проверяем честный результат.
	if main._reviving:
		main._reviving = false
		main._finish(false)

	var menu: CanvasLayer = main.upgrade_menu
	if menu.visible:
		var buttons := menu.get_node("Box/Choices").get_children().filter(
			func(b): return not b.is_queued_for_deletion())
		(buttons[0] as Button).pressed.emit()

	if frames % 1800 == 0:
		print("t=%3ds  врагов=%3d  уровень=%2d  жизни=%d  побед=%d  потеряно=%d" % [
			int(t), main.enemies.get_child_count(), main.level, main.player.hp, main.kills, main.hits_taken])

	if main._over:
		print("КОНЕЦ: %s на %d с, уровень %d" % [
			"победа" if main.won else "поражение", int(t), main.level])
		return true
	return frames > 60 * 420
