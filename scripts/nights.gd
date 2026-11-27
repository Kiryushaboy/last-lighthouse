class_name Nights
extends RefCounted
## Кампания «Маяки побережья»: 12 ночей, каждая сложнее предыдущей.
## Ночь = запись в LIST. Звёзды: ★ пережить, ★★ потерять не больше 2 сердец, ★★★ задание ночи.

const MAX_HITS_FOR_STAR := 2

## Враги: тип, с какой секунды, вес (как часто). Множители: hp, speed, spawn (сколько врагов).
## modifier: "" | "fog" (туман, видно недалеко) | "storm" (луч крутится быстрее, волны)
##           | "swarm" (вдвое больше врагов, но слабее) | "dark" (луч вдвое уже)
## task: kills — убить N, beam_kills — убить N врагов в луче, shells — собрать N ракушек.
const LIST := [
	{"title": "Старый причал", "time": 120, "enemies": [["crab", 0, 1.0]],
		"hp": 1.0, "speed": 1.0, "spawn": 1.0, "task": ["kills", 40]},
	{"title": "Мелководье", "time": 150, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5]],
		"hp": 1.0, "speed": 1.0, "spawn": 1.0, "task": ["kills", 70]},
	{"title": "Скалистый берег", "time": 180, "enemies": [["crab", 0, 1.0], ["jellyfish", 20, 0.5], ["squid", 90, 0.25]],
		"hp": 1.0, "speed": 1.0, "spawn": 1.1, "task": ["beam_kills", 15]},
	{"title": "Туманная бухта", "time": 180, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 90, 0.25]],
		"hp": 1.0, "speed": 1.0, "spawn": 1.1, "task": ["kills", 90]},
	{"title": "Логово спрута", "time": 240, "boss_at": 210, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.45], ["squid", 90, 0.25]],
		"hp": 1.1, "speed": 1.05, "spawn": 1.1, "task": ["beam_kills", 30]},
	{"title": "Штормовой мыс", "time": 210, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 60, 0.25], ["shell", 120, 0.15]],
		"hp": 1.2, "speed": 1.05, "spawn": 1.2, "task": ["kills", 150]},
	{"title": "Крабовый рой", "time": 210, "modifier": "swarm", "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.3]],
		"hp": 1.2, "speed": 1.1, "spawn": 1.2, "task": ["kills", 260]},
	{"title": "Тёмные воды", "time": 240, "modifier": "dark", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 60, 0.3], ["shell", 90, 0.15]],
		"hp": 1.3, "speed": 1.1, "spawn": 1.2, "task": ["shells", 8]},
	{"title": "Чернильный туман", "time": 240, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["squid", 0, 0.6], ["jellyfish", 60, 0.4]],
		"hp": 1.3, "speed": 1.1, "spawn": 1.3, "task": ["beam_kills", 45]},
	{"title": "Бронированный риф", "time": 270, "enemies": [["crab", 0, 1.0], ["shell", 0, 0.4], ["jellyfish", 60, 0.4], ["squid", 120, 0.3]],
		"hp": 1.4, "speed": 1.1, "spawn": 1.3, "task": ["kills", 220]},
	{"title": "Великая буря", "time": 270, "modifier": "storm", "boss_at": 240, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.3], ["shell", 60, 0.2]],
		"hp": 1.5, "speed": 1.15, "spawn": 1.4, "task": ["kills", 300]},
	{"title": "Последний маяк", "time": 300, "boss_at": 270, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 60, 0.3], ["shell", 90, 0.2]],
		"hp": 1.6, "speed": 1.2, "spawn": 1.5, "task": ["beam_kills", 70]},
]

const MODIFIER_TEXT := {
	"fog": "Туман: видно недалеко",
	"storm": "Шторм: луч крутится вдвое быстрее",
	"swarm": "Рой: врагов гораздо больше, но они слабее",
	"dark": "Тёмные воды: луч вдвое уже",
}


static func count() -> int:
	return LIST.size()


static func get_night(i: int) -> Dictionary:
	return LIST[clampi(i, 0, LIST.size() - 1)]


static func task_text(task: Array) -> String:
	match task[0]:
		"kills": return "Победить %d врагов" % task[1]
		"beam_kills": return "Победить %d врагов в луче маяка" % task[1]
		"shells": return "Собрать %d ракушек" % task[1]
	return ""


## Награда ракушками за каждую новую звезду: чем дальше ночь, тем щедрее.
static func star_reward(i: int) -> int:
	return 5 + i * 2


## Ночь открыта, если предыдущая пройдена хотя бы на одну звезду.
static func is_unlocked(i: int) -> bool:
	return i == 0 or SaveData.stars_of(i - 1) > 0
