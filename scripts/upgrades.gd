class_name Upgrades
extends RefCounted
## Список улучшений и то, как каждое меняет игрока.
## Новое улучшение = строка в LIST + ветка в apply().

const MAX_LEVEL := 3

const LIST := [
	{"id": "damage", "title": "Острые гарпуны", "desc": "+1 к урону"},
	{"id": "fire_rate", "title": "Быстрая перезарядка", "desc": "Стрельба на 20% чаще"},
	{"id": "multishot", "title": "Веер", "desc": "+1 снаряд за выстрел"},
	{"id": "pierce", "title": "Пробивание", "desc": "Снаряд пробивает ещё 1 врага"},
	{"id": "speed", "title": "Лёгкие сапоги", "desc": "+15% к скорости"},
	{"id": "max_hp", "title": "Крепкий смотритель", "desc": "+1 жизнь и лечение"},
	{"id": "magnet", "title": "Магнит", "desc": "Опыт притягивается издалека"},
]


static func apply(id: String, player: Player) -> void:
	match id:
		"damage":
			player.damage += 1
		"fire_rate":
			player.fire_interval *= 0.8
		"multishot":
			player.projectiles += 1
		"pierce":
			player.pierce += 1
		"speed":
			player.speed *= 1.15
		"max_hp":
			player.max_hp += 1
			player.heal(1)
		"magnet":
			player.pickup_radius *= 1.6
		_:
			push_warning("Неизвестное улучшение: %s" % id)


## Выбирает до count случайных улучшений, которые ещё не взяты MAX_LEVEL раз.
static func pick_choices(taken: Dictionary, count: int) -> Array:
	var available := LIST.filter(func(u): return taken.get(u.id, 0) < MAX_LEVEL)
	available.shuffle()
	return available.slice(0, count)
