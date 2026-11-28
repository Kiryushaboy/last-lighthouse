extends Node2D
## Главная сцена: таймер ночи, появление врагов, опыт, уровни, конец забега.

## Сцены врагов по имени; какие и когда приходят — решает ночь кампании (scripts/nights.gd).
const ENEMY_SCENES := {
	"crab": preload("res://scenes/enemies/crab.tscn"),
	"jellyfish": preload("res://scenes/enemies/jellyfish.tscn"),
	"squid": preload("res://scenes/enemies/squid.tscn"),
	"shell": preload("res://scenes/enemies/shell.tscn"),
	"puffer": preload("res://scenes/enemies/puffer.tscn"),
	"eel": preload("res://scenes/enemies/eel.tscn"),
	"narwhal": preload("res://scenes/enemies/narwhal.tscn"),
	"angler": preload("res://scenes/enemies/angler.tscn"),
}
const GEM_SCENE := preload("res://scenes/xp_gem.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss.tscn")
const MENU_SCENE := "res://scenes/menu.tscn"
const MAP_SCENE := "res://scenes/map.tscn"
const FOG_SHADER := preload("res://shaders/fog.gdshader")
const ARENA := Rect2(-900, -900, 1800, 1800)
const MAX_ENEMIES := 150
const SPAWN_DISTANCE := 800.0  ## чуть дальше края экрана

@onready var player: Player = $World/Player
@onready var camera: Camera2D = $World/Player/Camera2D
@onready var enemies: Node2D = $World/Enemies
@onready var gems: Node2D = $World/Gems
@onready var beam: Beam = $World/Beam
@onready var enemy_projectiles: Node2D = $World/EnemyProjectiles
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: Hud = $HUD
@onready var joystick: TouchJoystick = $Controls/Joystick
@onready var upgrade_menu: UpgradeMenu = $UpgradeMenu
@onready var end_screen: EndScreen = $EndScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var workshop: Workshop = $Workshop

var night_index := 0
var night: Dictionary
var run_time := 300.0  ## сколько длится ночь
var boss_at := -1.0  ## когда приходит спрут; -1 — в эту ночь его нет
var time_left := 300.0
var _regen_t := 0.0
var _bosses_met := 0
var elapsed := 0.0  ## сколько секунд идёт ночь
var endless := false
var _next_event := Nights.EVENT_EVERY
var _event_end := -1.0
var _event := ""
var _fog_layer: CanvasLayer
var _base_turn := 25.0
var kills := 0
var beam_kills := 0
var hits_taken := 0
var stars_got := 0
var level := 1
var xp := 0
var xp_to_next := xp_needed(1)
var upgrades_taken := {}  ## id улучшения -> сколько раз взято

var _pending_levels := 0
var _over := false
var won := false
var shells_this_run := 0
var boss: Boss
var _last_hp := 0
var _spawn_mult := 1.0
var _hp_mult := 1.0


func _ready() -> void:
	Fx.reset()
	night_index = SaveData.current_night
	UiTheme.apply(Nights.CHAPTERS.find(Nights.chapter_of(night_index)))
	Sound.play_music(Nights.music_of(night_index))
	night = Nights.get_night(night_index)
	run_time = night.time
	time_left = run_time
	boss_at = night.get("boss_at", -1.0)
	endless = night.get("endless", false)
	if endless:
		boss_at = Nights.BOSS_EVERY - 60.0
	_base_turn = beam.turn_speed_deg
	_set_modifier(night.get("modifier", ""), true)
	player.arena_rect = ARENA
	player.bullet_container = $World/Bullets
	camera.limit_left = int(ARENA.position.x)
	camera.limit_top = int(ARENA.position.y)
	camera.limit_right = int(ARENA.end.x)
	camera.limit_bottom = int(ARENA.end.y)

	_apply_workshop()
	player.died.connect(_on_player_died)
	player.health_changed.connect(hud.set_health)
	player.health_changed.connect(_count_hits)
	spawn_timer.timeout.connect(_on_spawn_timer)
	upgrade_menu.chosen.connect(_on_upgrade_chosen)
	end_screen.restart_pressed.connect(_restart)
	end_screen.workshop_pressed.connect(func(): end_screen.hide(); workshop.open())
	workshop.closed.connect(end_screen.show)
	hud.pause_pressed.connect(_open_pause)
	pause_menu.open_requested.connect(_open_pause)
	pause_menu.resume_pressed.connect(_close_pause)
	pause_menu.restart_pressed.connect(_restart)
	pause_menu.menu_pressed.connect(_to_menu)
	end_screen.menu_pressed.connect(_to_map)
	end_screen.next_pressed.connect(_next_night)

	hud.set_health(player.hp, player.max_hp)
	hud.set_xp(xp, xp_to_next, level)
	hud.set_time(time_left)
	_last_hp = player.hp
	if endless:
		hud.show_night_banner("Бесконечная ночь", "Каждые 2 минуты событие, каждые 5 — спрут",
				"продержитесь как можно дольше")
	else:
		hud.show_night_banner("Ночь %d · %s" % [night_index + 1, night.title],
				Nights.MODIFIER_TEXT.get(night.get("modifier", ""), ""), Nights.task_text(night.task))
	_update_task()


func _process(delta: float) -> void:
	if _over:
		return
	elapsed += delta
	_update_regen(delta)
	time_left = maxf(run_time - elapsed, 0.0)
	# В бесконечной ночи таймер идёт вперёд: сколько продержались.
	hud.set_time(elapsed if endless else time_left, endless)
	player.joystick_vector = joystick.vector
	if endless:
		_update_events()
	if boss_at >= 0.0 and boss == null and elapsed >= boss_at:
		_spawn_boss()
	# Без спрута рассвет наступает, когда кончилось время.
	if not endless and boss_at < 0.0 and time_left <= 0.0:
		_finish(true)
	# Рассвет наступает, только когда спрут побеждён. До тех пор таймер стоит на 0:00.


func _notification(what: int) -> void:
	# Свернули приложение на телефоне: открываем паузу, чтобы не погибнуть без нас.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_open_pause()


## Вечные бонусы из мастерской действуют с первой секунды забега.
func _apply_workshop() -> void:
	Heroes.apply(Heroes.current(), player)
	player.max_hp += SaveData.level_of("hp")
	player.hp = player.max_hp
	player.crit_chance = 0.08 * SaveData.level_of("crit")
	player.speed *= 1.0 + 0.05 * SaveData.level_of("speed")
	player.damage += SaveData.level_of("power")
	player.pickup_radius *= 1.0 + 0.15 * SaveData.level_of("pull")
	if SaveData.level_of("bubble") > 0:
		upgrades_taken["shield"] = 1
		Upgrades.apply("shield", player, 1)
	for i in SaveData.level_of("start"):
		var choice := Upgrades.pick_choices(upgrades_taken, 1, player.weapon)
		if choice.is_empty():
			break
		upgrades_taken[choice[0].id] = upgrades_taken.get(choice[0].id, 0) + 1
		Upgrades.apply(choice[0].id, player, upgrades_taken[choice[0].id])


# --- Пауза -------------------------------------------------------------

func _open_pause() -> void:
	if _over or upgrade_menu.visible or pause_menu.visible:
		return
	joystick.reset()
	get_tree().paused = true
	pause_menu.show_upgrades(upgrades_taken)
	pause_menu.show()


func _close_pause() -> void:
	pause_menu.hide()
	get_tree().paused = false


# --- Враги -------------------------------------------------------------

## Особое условие ночи (туман, шторм, рой, тёмные воды). on=false снимает его —
## так бесконечная ночь включает и выключает события.
func _set_modifier(mod: String, on: bool) -> void:
	match mod:
		"fog":
			if _fog_layer == null:
				_fog_layer = CanvasLayer.new()
				_fog_layer.layer = 1
				var rect := ColorRect.new()
				rect.set_anchors_preset(Control.PRESET_FULL_RECT)
				rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var m := ShaderMaterial.new()
				m.shader = FOG_SHADER
				m.set_shader_parameter("fog_color", Nights.theme_of(night_index).fog)
				rect.material = m
				_fog_layer.add_child(rect)
				add_child(_fog_layer)
				move_child(_fog_layer, 0)  # под интерфейсом
				rect.modulate.a = 0.0
			var r := _fog_layer.get_child(0) as ColorRect
			create_tween().tween_property(r, "modulate:a", 1.0 if on else 0.0, 1.5)
		"storm":
			beam.turn_speed_deg = _base_turn * (2.0 if on else 1.0)
			var water := $World/Arena.get_child(0) as Polygon2D
			if water:
				(water.material as ShaderMaterial).set_shader_parameter("foam",
						Color(0.6, 0.95, 1.0) if on else Color(0.3, 0.9, 1.0))
		"swarm":
			_spawn_mult = 1.6 if on else 1.0
			_hp_mult = 0.5 if on else 1.0
		"dark":
			beam.width_mult = 0.5 if on else 1.0


## Бесконечная ночь: каждые 2 минуты на 45 секунд случайное событие.
func _update_events() -> void:
	if _event != "" and elapsed >= _event_end:
		_set_modifier(_event, false)
		_event = ""
	if elapsed >= _next_event:
		_next_event += Nights.EVENT_EVERY
		_event = ["fog", "storm", "swarm", "dark"].pick_random()
		_event_end = elapsed + Nights.EVENT_LENGTH
		_set_modifier(_event, true)
		Sound.play("warning", -6.0)
		hud.show_night_banner("Событие!", Nights.MODIFIER_TEXT[_event], "продержитесь %d секунд" % int(Nights.EVENT_LENGTH))


func _count_hits(hp: int, _max_hp: int) -> void:
	if hp < _last_hp:
		hits_taken += 1
		_update_task()
	_last_hp = hp


func _task_progress() -> int:
	match night.task[0]:
		"kills": return kills
		"beam_kills": return beam_kills
		"shells": return shells_this_run
	return 0


func _update_task() -> void:
	if endless:
		var b := int(SaveData.best_time)
		hud.set_record("Рекорд: %d:%02d · врагов %d" % [b / 60, b % 60, SaveData.best_kills], kills)
		return
	hud.set_star_tasks(hits_taken, Nights.MAX_HITS_FOR_STAR, Nights.task_text(night.task), _task_progress(), night.task[1])


func _on_spawn_timer() -> void:
	# Чем дольше идёт ночь, тем больше врагов за раз и тем чаще они приходят.
	# Когда пришёл босс, мелочи вдвое меньше, чтобы было видно его атаки.
	var count := int((1.0 + elapsed / 150.0) * night.spawn * _spawn_mult)
	if is_instance_valid(boss):
		count = maxi(1, count / 2)
	for i in count:
		if enemies.get_child_count() >= MAX_ENEMIES:
			break
		_spawn_enemy(elapsed)
	spawn_timer.wait_time = maxf(0.6, 1.4 - elapsed / 500.0)


## enemy_type и at задаёт подмога босса; обычные враги выбираются по ночи и выходят из-за края экрана.
func _spawn_enemy(elapsed: float, enemy_type := "", at := Vector2.INF) -> void:
	var scene: PackedScene = ENEMY_SCENES[enemy_type] if enemy_type != "" else _pick_enemy_type(elapsed)
	var enemy := scene.instantiate() as Enemy
	enemy.target = player
	enemy.beam = beam
	# Каждые две минуты враги крепче и чуть быстрее.
	enemy.max_hp += int(elapsed / 120.0) * maxi(1, enemy.max_hp / 2)
	# И от ночи к ночи (night.hp растёт с номером ночи).
	enemy.max_hp = maxi(1, roundi(enemy.max_hp * night.hp * _hp_mult))
	enemy.speed *= (1.0 + minf(elapsed / 300.0, 1.0) * 0.5) * night.speed
	if enemy is Squid:
		(enemy as Squid).projectile_container = enemy_projectiles
	elif enemy is Puffer:
		(enemy as Puffer).projectile_container = enemy_projectiles
	enemy.killed.connect(_on_enemy_killed.bind(enemy.shell_chance))
	enemies.add_child(enemy)
	if at != Vector2.INF:
		enemy.global_position = at
		return
	var angle := randf() * TAU
	var pos := player.global_position + Vector2.RIGHT.rotated(angle) * SPAWN_DISTANCE
	enemy.global_position = pos.clamp(ARENA.position, ARENA.end)


func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate() as Boss
	# В бесконечной ночи боссы идут по кругу, в кампании — босс главы.
	var kinds := Boss.KINDS.keys()
	boss.setup(kinds[_bosses_met % kinds.size()] if endless else Nights.chapter_of(night_index).boss)
	_bosses_met += 1
	boss.summon.connect(_on_boss_summon)
	boss.target = player
	boss.beam = beam
	boss.projectile_container = enemy_projectiles
	boss.max_hp = int(boss.max_hp * night.hp)
	if endless:
		boss.max_hp = int(boss.max_hp * (1.0 + elapsed / 400.0))  # каждый следующий спрут крепче
	boss.killed.connect(_on_boss_killed)
	boss.health_changed.connect(hud.set_boss_health)
	enemies.add_child(boss)
	var pos := player.global_position + Vector2.UP * SPAWN_DISTANCE * 0.8
	boss.global_position = pos.clamp(ARENA.position, ARENA.end)
	hud.show_boss(boss.hp, boss.max_hp, boss.title)
	Sound.play_music(Nights.chapter_of(night_index).boss_music)
	Sound.play("warning")
	_boss_intro()


## Подмога босса: несколько врагов выныривают рядом с ним.
func _on_boss_summon(enemy_type: String, count: int) -> void:
	if not is_instance_valid(boss) or not ENEMY_SCENES.has(enemy_type):
		return
	for i in count:
		if enemies.get_child_count() >= MAX_ENEMIES:
			break
		var at := boss.global_position + Vector2.RIGHT.rotated(TAU * i / count) * (boss.radius + 60.0)
		_spawn_enemy(elapsed, enemy_type, at.clamp(ARENA.position, ARENA.end))


## Появление босса: игра замирает, камера летит к спруту, надпись, затем камера возвращается.
func _boss_intro() -> void:
	joystick.reset()
	get_tree().paused = true
	Settings.vibrate(450, 1.0)
	Fx.flash(Color(0.5, 0.2, 0.8, 0.45), 0.6)
	hud.show_boss_banner(boss.title + "!", boss.subtitle)
	var to_boss := boss.global_position - player.global_position
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(camera, "offset", to_boss, 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(camera, "zoom", Vector2(1.25, 1.25), 0.7).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(Fx.ring.bind(boss.global_position, boss.color.lightened(0.3), 220.0, 0.6, 10.0))
	tw.tween_callback(Sound.play.bind("slam"))
	tw.tween_interval(1.3)
	tw.tween_property(camera, "offset", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(camera, "zoom", Vector2.ONE, 0.5).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(_end_boss_intro)


func _end_boss_intro() -> void:
	if not _over and not upgrade_menu.visible and not pause_menu.visible:
		get_tree().paused = false


func _on_boss_killed(_at: Vector2, _xp: int) -> void:
	_add_shells(30)
	if endless:
		# Спрут повержен, но ночь продолжается: следующий придёт через 5 минут, крепче.
		boss = null
		boss_at = elapsed + Nights.BOSS_EVERY
		hud.hide_boss()
		Sound.play_music(Nights.music_of(night_index))
		return
	_finish(true)


## «Второе дыхание» из мастерской: раз в N секунд лечит одно сердце.
func _update_regen(delta: float) -> void:
	var lvl := SaveData.level_of("regen")
	if lvl == 0 or player.hp >= player.max_hp:
		_regen_t = 0.0
		return
	_regen_t += delta
	if _regen_t >= float(SaveData.REGEN_EVERY[lvl]):
		_regen_t = 0.0
		player.heal(1)
		Fx.ring(player.global_position, Color(1.0, 0.4, 0.5))


func _add_shells(amount: int) -> void:
	shells_this_run += amount
	hud.set_shells(shells_this_run)
	_update_task()


## Случайный тип врага с учётом весов среди уже открывшихся к этой секунде.
func _pick_enemy_type(elapsed: float) -> PackedScene:
	# Записи ночи: [тип, с какой секунды, вес].
	var open: Array = night.enemies.filter(func(t): return elapsed >= t[1])
	var total := 0.0
	for t in open:
		total += t[2]
	var roll := randf() * total
	for t in open:
		roll -= t[2]
		if roll <= 0.0:
			return ENEMY_SCENES[t[0]]
	return ENEMY_SCENES[open[0][0]]


func _on_enemy_killed(at: Vector2, xp_value: int, shell_chance: float) -> void:
	kills += 1
	if beam.contains(at):
		beam_kills += 1
	_update_task()
	# Враг погиб во время расчёта физики, поэтому предметы создаём чуть позже.
	_spawn_gem.call_deferred(at, xp_value)
	if randf() < shell_chance:
		_spawn_gem.call_deferred(at + Vector2(14, 0), 1, true)


func _spawn_gem(at: Vector2, value: int, is_shell := false) -> void:
	var gem := GEM_SCENE.instantiate() as XpGem
	gem.value = value
	gem.is_shell = is_shell
	gem.player = player
	gem.collected.connect(_add_shells if is_shell else _add_xp)
	gems.add_child(gem)
	gem.global_position = at


# --- Опыт и улучшения --------------------------------------------------

## Сколько опыта нужно до следующего уровня. Кривая подобрана так, чтобы за 5-минутную ночь
## выходило около 12–15 улучшений: в начале примерно раз в 20 секунд, к концу — раз в минуту.
static func xp_needed(lvl: int) -> int:
	var k := lvl - 1
	return int(5.0 + 4.0 * k + 0.5 * k * k)


func _add_xp(amount: int) -> void:
	if _over:
		return
	xp += amount
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = xp_needed(level)
		_pending_levels += 1
	hud.set_xp(xp, xp_to_next, level)
	if _pending_levels > 0 and not upgrade_menu.visible:
		_offer_upgrade()


func _offer_upgrade() -> void:
	var choices := Upgrades.pick_choices(upgrades_taken, 3, player.weapon)
	if choices.is_empty():
		_pending_levels = 0
		return
	_pending_levels -= 1
	joystick.reset()
	get_tree().paused = true
	Sound.play("levelup")
	Settings.vibrate(60, 0.6)
	Fx.flash(Color(1, 0.85, 0.4, 0.5), 0.5)
	Fx.ring(player.global_position, Color(1, 0.85, 0.4), 260.0, 0.6, 10.0)
	Fx.burst(player.global_position, Color(1, 0.85, 0.4), 24, 380.0, 6.0)
	upgrade_menu.show_choices(choices, upgrades_taken, player)


func _on_upgrade_chosen(id: String) -> void:
	upgrades_taken[id] = upgrades_taken.get(id, 0) + 1
	Upgrades.apply(id, player, upgrades_taken[id])
	hud.set_health(player.hp, player.max_hp)
	get_tree().paused = false
	if _pending_levels > 0:
		_offer_upgrade()


# --- Конец забега ------------------------------------------------------

func _on_player_died() -> void:
	_finish(false)


func _finish(victory: bool) -> void:
	if _over:
		return
	_over = true
	won = victory
	joystick.reset()
	upgrade_menu.hide()
	get_tree().paused = true
	# Звёзды: пережить ночь, потерять не больше 2 сердец, выполнить задание.
	var star_flags := [victory, victory and hits_taken <= Nights.MAX_HITS_FOR_STAR,
			victory and _task_progress() >= night.task[1]]
	var star_bonus := 0
	var records := [false, false]
	if endless:
		star_flags = [false, false, false]
		records = SaveData.record_endless(elapsed, kills)
	else:
		stars_got = star_flags.count(true)
		var new_stars := SaveData.record_stars(night_index, stars_got)
		star_bonus = new_stars * Nights.star_reward(night_index)
	# Бонус за выживание: ракушка за каждые 20 секунд ночи, плюс награда за новые звёзды.
	shells_this_run += int(elapsed / 20.0) + star_bonus
	# «Удачливый ныряльщик»: +10% за уровень.
	shells_this_run = int(round(shells_this_run * (1.0 + 0.1 * SaveData.level_of("luck"))))
	SaveData.add_shells(shells_this_run)
	Sound.play("win" if victory else "lose")
	Fx.reset()
	end_screen.show_result({
		"won": victory, "night": night_index, "title": night.title, "level": level,
		"survived": elapsed, "shells": shells_this_run, "star_bonus": star_bonus,
		"stars": star_flags, "hits": hits_taken, "task": Nights.task_text(night.task),
		"task_progress": _task_progress(), "task_goal": night.task[1],
		"has_next": not endless and night_index + 1 < Nights.count(),
		"endless": endless, "kills": kills, "records": records,
	})


func _restart() -> void:
	Fx.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _next_night() -> void:
	SaveData.current_night = mini(night_index + 1, Nights.count() - 1)
	_restart()


func _to_map() -> void:
	Fx.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAP_SCENE)


func _to_menu() -> void:
	Fx.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)
