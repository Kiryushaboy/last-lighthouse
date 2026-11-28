extends Node
## Прогресс между забегами: ракушки и уровни вечных бонусов мастерской.
## Автозагрузка «SaveData», хранится в user://save.cfg на устройстве.

signal changed

const PATH := "user://save.cfg"

## Бонусы мастерской. Цена уровня n = costs[n].
## Через сколько секунд «Второе дыхание» лечит одно сердце, по уровням.
const REGEN_EVERY := [0, 60, 45, 30]

const PERKS := [
	{"id": "hp", "title": "Крепкое здоровье", "desc": "+1 жизнь на старте", "costs": [10, 20, 35, 55, 80, 200, 350, 500]},
	{"id": "power", "title": "Закалённые гарпуны", "desc": "+1 к урону оружия", "costs": [60, 150, 300, 600, 1000, 1500]},
	{"id": "crit", "title": "Острые гарпуны", "desc": "+8% шанс двойного урона", "costs": [10, 20, 35, 55, 80]},
	{"id": "speed", "title": "Удобные сапоги", "desc": "+5% к скорости", "costs": [10, 20, 35, 55, 80]},
	{"id": "start", "title": "Опытный", "desc": "+1 случайное улучшение на старте", "costs": [30, 60, 100]},
	{"id": "bubble", "title": "Запасной пузырь", "desc": "Щит с самого начала ночи", "costs": [120]},
	{"id": "regen", "title": "Второе дыхание", "desc": "Сердце восстанавливается само", "costs": [40, 80, 130]},
	{"id": "pull", "title": "Морской магнит", "desc": "+15% к радиусу сбора", "costs": [15, 30, 50]},
	{"id": "luck", "title": "Удачливый ныряльщик", "desc": "+10% ракушек за ночь", "costs": [25, 50, 90]},
]

var shells := 0
var levels := {}  ## id бонуса -> купленный уровень
var stars := {}  ## номер ночи -> лучший результат в звёздах (0..3)
var current_night := 0  ## какую ночь сейчас играем (не сохраняется)
var hero := "keeper"  ## выбранный герой
var heroes := ["keeper"]  ## открытые герои
var best_time := 0.0  ## рекорд бесконечной ночи: секунд
var best_kills := 0  ## рекорд бесконечной ночи: врагов
## Тестовый режим (секретный код в меню): все ночи и герои открыты, бонусы меняются свободно.
var test_mode := false
var no_ads := false  ## куплено «Без рекламы»: награды без роликов
var chest_day := ""  ## дата последнего сундука дня, ГГГГ-ММ-ДД
var tutorial_done := false  ## обучение пройдено (или игрок уже играл до его появления)
var _test_backup := {}  ## бонусы и герой до включения режима, чтобы вернуть при выключении
const TEST_CODE_HASH := "4021a7b089496e8071def7586497ef50876068d4de9a7b9b53f22ee3348baca7"


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		shells = cfg.get_value("progress", "shells", 0)
		levels = cfg.get_value("progress", "levels", {})
		stars = cfg.get_value("progress", "stars", {})
		best_time = cfg.get_value("endless", "best_time", 0.0)
		hero = cfg.get_value("heroes", "current", "keeper")
		heroes = cfg.get_value("heroes", "owned", ["keeper"])
		best_kills = cfg.get_value("endless", "best_kills", 0)
		test_mode = cfg.get_value("test", "on", false)
		# У тех, кто уже играл, обучение считаем пройденным.
		tutorial_done = cfg.get_value("progress", "tutorial_done", not stars.is_empty())
		_test_backup = cfg.get_value("test", "backup", {})
		no_ads = cfg.get_value("shop", "no_ads", false)
		chest_day = cfg.get_value("shop", "chest_day", "")
		_refund_removed_heroes()
	# Меню и карта сразу показывают главу, на которой игрок остановился.
	if current_night == 0:
		current_night = Nights.progress_night()


## Героев Боцмана и Фонарщицу убрали в 0.13: кто их купил, получает ракушки обратно.
func _refund_removed_heroes() -> void:
	var refund := {"bosun": 150, "lamplighter": 450}
	var changed_any := false
	for id in refund:
		if id in heroes:
			heroes.erase(id)
			shells += refund[id]
			changed_any = true
	if refund.has(hero):
		hero = "keeper"
		changed_any = true
	if changed_any:
		_save()


func level_of(id: String) -> int:
	return levels.get(id, 0)


func perk(id: String) -> Dictionary:
	for p in PERKS:
		if p.id == id:
			return p
	return {}


## Цена следующего уровня или -1, если бонус прокачан до конца.
func next_cost(id: String) -> int:
	var costs: Array = perk(id).costs
	var lvl := level_of(id)
	return costs[lvl] if lvl < costs.size() else -1


func buy(id: String) -> bool:
	var cost := next_cost(id)
	if cost < 0 or shells < cost:
		return false
	shells -= cost
	levels[id] = level_of(id) + 1
	_save()
	return true


## Включить тестовый режим по коду. Возвращает false, если код неверный.
func enter_test_code(code: String) -> bool:
	if code.strip_edges().sha256_text() != TEST_CODE_HASH:
		return false
	if not test_mode:
		_test_backup = {"levels": levels.duplicate(), "hero": hero}
		test_mode = true
		for p in PERKS:
			levels[p.id] = p.costs.size()
		_save()
	return true


## Выключить тестовый режим: бонусы и герой возвращаются к тому, что было до него.
func leave_test_mode() -> void:
	if not test_mode:
		return
	test_mode = false
	levels = _test_backup.get("levels", {})
	hero = _test_backup.get("hero", "keeper")
	if not hero in heroes:
		hero = "keeper"
	_test_backup = {}
	_save()


## Тестовый режим: поднять или опустить уровень бонуса бесплатно.
func shift_level(id: String, step: int) -> void:
	levels[id] = clampi(level_of(id) + step, 0, perk(id).costs.size())
	_save()


func set_tutorial_done(done: bool) -> void:
	tutorial_done = done
	_save()


func hero_owned(id: String) -> bool:
	return test_mode or id in heroes


func stars_of(night: int) -> int:
	return stars.get(night, 0)


func total_stars() -> int:
	var t := 0
	for k in stars:
		t += stars[k]
	return t


## Записать результат ночи. Возвращает, сколько звёзд получено впервые (за них награда).
func record_stars(night: int, got: int) -> int:
	var before := stars_of(night)
	if got > before:
		stars[night] = got
		_save()
	return maxi(got - before, 0)


## Записать результат бесконечной ночи. Возвращает [новый рекорд времени?, новый рекорд врагов?].
func record_endless(time: float, kills: int) -> Array:
	var r := [time > best_time, kills > best_kills]
	best_time = maxf(best_time, time)
	best_kills = maxi(best_kills, kills)
	_save()
	return r


## Купить героя за ракушки (или просто выбрать, если уже открыт).
func choose_hero(id: String, cost: int) -> bool:
	if test_mode:
		hero = id
		_save()
		return true
	if not id in heroes:
		if shells < cost:
			return false
		shells -= cost
		heroes.append(id)
	hero = id
	_save()
	return true


## Герой куплен за деньги в магазине.
func unlock_hero(id: String) -> void:
	if not id in heroes:
		heroes.append(id)
	_save()


func set_no_ads(on: bool) -> void:
	no_ads = on
	_save()


## Тестовый режим: забыть покупки и сундук, чтобы проверить всё заново.
func reset_shop() -> void:
	no_ads = false
	chest_day = ""
	for id in ["witch", "siren"]:
		heroes.erase(id)
	if not hero in heroes:
		hero = "keeper"
	_save()


func add_shells(amount: int) -> void:
	shells += amount
	_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "shells", shells)
	cfg.set_value("progress", "levels", levels)
	cfg.set_value("progress", "stars", stars)
	cfg.set_value("endless", "best_time", best_time)
	cfg.set_value("heroes", "current", hero)
	cfg.set_value("heroes", "owned", heroes)
	cfg.set_value("endless", "best_kills", best_kills)
	cfg.set_value("test", "on", test_mode)
	cfg.set_value("progress", "tutorial_done", tutorial_done)
	cfg.set_value("test", "backup", _test_backup)
	cfg.set_value("shop", "no_ads", no_ads)
	cfg.set_value("shop", "chest_day", chest_day)
	cfg.save(PATH)
	changed.emit()
