class_name Nights
extends RefCounted
## Кампания «Маяки побережья»: 5 глав по 6 ночей, ночь длится 5 минут, последняя ночь главы — с боссом.
## Ночь = запись в LIST. Звёзды: ★ пережить, ★★ потерять не больше 2 сердец, ★★★ задание ночи.

const MAX_HITS_FOR_STAR := 2
const ENDLESS := 99  ## номер «Бесконечной ночи» в SaveData.current_night

## Бесконечная ночь: награда за кампанию. Времени нет, каждые 2 минуты событие, каждые 5 — спрут.
const ENDLESS_NIGHT := {"title": "Бесконечная ночь", "time": 0, "endless": true,
	"enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 90, 0.3], ["shell", 150, 0.2],
		["puffer", 240, 0.2], ["eel", 330, 0.3], ["narwhal", 450, 0.2], ["angler", 600, 0.3]],
	"hp": 2.0, "speed": 1.15, "spawn": 1.3, "task": ["kills", 0]}
const EVENT_EVERY := 120.0
const EVENT_LENGTH := 45.0
const BOSS_EVERY := 300.0

const NIGHTS_PER_CHAPTER := 6

## Главы: название, время суток, музыка, босс главы и цвета моря/острова (theme).
const CHAPTERS := [
	{"title": "Старый причал", "music": ["battle", "chapter1"], "boss_music": "boss", "time_of_day": "Ночь", "boss": "crab_king",
		"theme": {"deep": Color(0.0, 0.02, 0.06), "shallow": Color(0.02, 0.09, 0.17), "foam": Color(0.3, 0.9, 1.0), "island": Color(0.09, 0.11, 0.17), "island_top": Color(0.12, 0.14, 0.21), "rock": Color(0.17, 0.2, 0.29), "rim": Color(0.3, 0.9, 1.0), "bg": Color(0.06, 0.08, 0.12), "fog": Color(0.22, 0.27, 0.36)}},
	{"title": "Туманная бухта", "music": ["chapter2", "chapter1"], "boss_music": "boss2", "time_of_day": "Рассвет", "boss": "octopus",
		"theme": {"deep": Color(0.06, 0.04, 0.11), "shallow": Color(0.24, 0.15, 0.27), "foam": Color(1.0, 0.72, 0.8), "island": Color(0.17, 0.12, 0.2), "island_top": Color(0.22, 0.16, 0.26), "rock": Color(0.3, 0.22, 0.33), "rim": Color(1.0, 0.66, 0.74), "bg": Color(0.13, 0.09, 0.16), "fog": Color(0.42, 0.32, 0.42)}},
	{"title": "Штормовое море", "music": ["chapter3"], "boss_music": "boss", "time_of_day": "Гроза", "boss": "serpent",
		"theme": {"deep": Color(0.01, 0.03, 0.04), "shallow": Color(0.05, 0.13, 0.14), "foam": Color(0.6, 1.0, 0.85), "island": Color(0.08, 0.11, 0.12), "island_top": Color(0.11, 0.15, 0.16), "rock": Color(0.18, 0.24, 0.25), "rim": Color(0.55, 1.0, 0.8), "bg": Color(0.04, 0.06, 0.07), "fog": Color(0.2, 0.27, 0.28)}},
	{"title": "Ледяной север", "music": ["chapter4"], "boss_music": "boss2", "time_of_day": "Полярный день", "boss": "whale",
		"theme": {"deep": Color(0.04, 0.14, 0.24), "shallow": Color(0.2, 0.42, 0.55), "foam": Color(0.92, 0.98, 1.0), "island": Color(0.55, 0.65, 0.75), "island_top": Color(0.72, 0.8, 0.88), "rock": Color(0.85, 0.92, 0.97), "rim": Color(0.8, 0.97, 1.0), "bg": Color(0.14, 0.24, 0.33), "fog": Color(0.75, 0.82, 0.88)}},
	{"title": "Бездна", "music": ["chapter5"], "boss_music": "boss", "time_of_day": "Глубокая ночь", "boss": "kraken",
		"theme": {"deep": Color(0.0, 0.0, 0.01), "shallow": Color(0.04, 0.01, 0.09), "foam": Color(0.75, 0.4, 1.0), "island": Color(0.06, 0.04, 0.1), "island_top": Color(0.09, 0.06, 0.14), "rock": Color(0.15, 0.1, 0.22), "rim": Color(0.72, 0.4, 1.0), "bg": Color(0.02, 0.01, 0.04), "fog": Color(0.12, 0.08, 0.18)}},
]

## Враги: тип, с какой секунды, вес (как часто). Множители: hp, speed, spawn (сколько врагов).
## modifier: "" | "fog" (туман, видно недалеко) | "storm" (луч крутится быстрее, волны)
##           | "swarm" (вдвое больше врагов, но слабее) | "dark" (луч вдвое уже)
## task: kills — убить N, beam_kills — убить N врагов в луче, shells — собрать N ракушек.
const LIST := [
	{"title": "Старый причал", "chapter": 0, "time": 300, "enemies": [["crab", 0, 1.0]],
		"hp": 1.0, "speed": 1.0, "spawn": 1.0, "task": ["kills", 260]},
	{"title": "Мелководье", "chapter": 0, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 60, 0.4]],
		"hp": 1.08, "speed": 1.012, "spawn": 1.025, "task": ["kills", 270]},
	{"title": "Скалистый берег", "chapter": 0, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5]],
		"hp": 1.16, "speed": 1.024, "spawn": 1.05, "task": ["beam_kills", 65]},
	{"title": "Рыбацкие сети", "chapter": 0, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 150, 0.2]],
		"hp": 1.24, "speed": 1.036, "spawn": 1.075, "task": ["shells", 9]},
	{"title": "Крабовый рой", "chapter": 0, "time": 300, "modifier": "swarm", "enemies": [["crab", 0, 1.0], ["jellyfish", 60, 0.3]],
		"hp": 1.32, "speed": 1.048, "spawn": 1.1, "task": ["kills", 460]},
	{"title": "Хозяин причала", "chapter": 0, "time": 300, "boss_at": 270, "enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 90, 0.25]],
		"hp": 1.4, "speed": 1.06, "spawn": 1.125, "task": ["beam_kills", 80]},
	{"title": "Первый туман", "chapter": 1, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["puffer", 45, 0.3]],
		"hp": 1.48, "speed": 1.072, "spawn": 1.15, "task": ["kills", 340]},
	{"title": "Тихая бухта", "chapter": 1, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 60, 0.3], ["puffer", 45, 0.3]],
		"hp": 1.56, "speed": 1.084, "spawn": 1.175, "task": ["beam_kills", 85]},
	{"title": "Молочная мгла", "chapter": 1, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["squid", 0, 0.4], ["jellyfish", 60, 0.4], ["puffer", 45, 0.3]],
		"hp": 1.64, "speed": 1.096, "spawn": 1.2, "task": ["kills", 370]},
	{"title": "Затонувшая лодка", "chapter": 1, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.35], ["puffer", 45, 0.3]],
		"hp": 1.72, "speed": 1.108, "spawn": 1.225, "task": ["shells", 11]},
	{"title": "Чернильный туман", "chapter": 1, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["squid", 0, 0.6], ["jellyfish", 60, 0.4], ["puffer", 45, 0.3]],
		"hp": 1.8, "speed": 1.12, "spawn": 1.25, "task": ["beam_kills", 100]},
	{"title": "Спрут из тумана", "chapter": 1, "time": 300, "boss_at": 270, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.35], ["puffer", 45, 0.3]],
		"hp": 1.88, "speed": 1.132, "spawn": 1.275, "task": ["kills", 410]},
	{"title": "Первые волны", "chapter": 2, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["shell", 60, 0.15], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 1.96, "speed": 1.144, "spawn": 1.3, "task": ["kills", 420]},
	{"title": "Штормовой мыс", "chapter": 2, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.3], ["shell", 90, 0.2], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 2.04, "speed": 1.156, "spawn": 1.325, "task": ["beam_kills", 110]},
	{"title": "Девятый вал", "chapter": 2, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["shell", 0, 0.3], ["squid", 60, 0.3], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 2.12, "speed": 1.168, "spawn": 1.35, "task": ["kills", 450]},
	{"title": "Бронированный риф", "chapter": 2, "time": 300, "enemies": [["crab", 0, 1.0], ["shell", 0, 0.45], ["jellyfish", 60, 0.4], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 2.2, "speed": 1.18, "spawn": 1.375, "task": ["shells", 13]},
	{"title": "Великая буря", "chapter": 2, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.3], ["shell", 60, 0.25], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 2.28, "speed": 1.192, "spawn": 1.4, "task": ["beam_kills", 120]},
	{"title": "Морской змей", "chapter": 2, "time": 300, "boss_at": 270, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.3], ["shell", 60, 0.2], ["eel", 20, 0.45], ["puffer", 120, 0.2]],
		"hp": 2.36, "speed": 1.204, "spawn": 1.425, "task": ["kills", 490]},
	{"title": "Ледяная кромка", "chapter": 3, "time": 300, "enemies": [["crab", 0, 1.0], ["shell", 0, 0.3], ["jellyfish", 30, 0.4], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.44, "speed": 1.216, "spawn": 1.45, "task": ["kills", 510]},
	{"title": "Северное сияние", "chapter": 3, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.3], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.52, "speed": 1.228, "spawn": 1.475, "task": ["beam_kills", 135]},
	{"title": "Торосы", "chapter": 3, "time": 300, "modifier": "swarm", "enemies": [["crab", 0, 1.0], ["shell", 30, 0.3], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.6, "speed": 1.24, "spawn": 1.5, "task": ["kills", 810]},
	{"title": "Белая мгла", "chapter": 3, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 1.0], ["squid", 0, 0.4], ["shell", 60, 0.3], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.68, "speed": 1.252, "spawn": 1.525, "task": ["shells", 15]},
	{"title": "Полярный день", "chapter": 3, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.35], ["shell", 30, 0.3], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.76, "speed": 1.264, "spawn": 1.55, "task": ["beam_kills", 145]},
	{"title": "Ледяной кит", "chapter": 3, "time": 300, "boss_at": 270, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.35], ["shell", 60, 0.3], ["narwhal", 45, 0.25], ["eel", 120, 0.25]],
		"hp": 2.84, "speed": 1.276, "spawn": 1.575, "task": ["kills", 580]},
	{"title": "Сумеречная зона", "chapter": 4, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 30, 0.35], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 2.92, "speed": 1.288, "spawn": 1.6, "task": ["kills", 590]},
	{"title": "Огни глубин", "chapter": 4, "time": 300, "enemies": [["crab", 0, 1.0], ["squid", 0, 0.45], ["shell", 30, 0.3], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 3.0, "speed": 1.3, "spawn": 1.625, "task": ["beam_kills", 160]},
	{"title": "Чёрная вода", "chapter": 4, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["shell", 30, 0.35], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 3.08, "speed": 1.312, "spawn": 1.65, "task": ["kills", 620]},
	{"title": "Холодный ключ", "chapter": 4, "time": 300, "modifier": "swarm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.4], ["squid", 30, 0.3], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 3.16, "speed": 1.324, "spawn": 1.675, "task": ["shells", 17]},
	{"title": "Край бездны", "chapter": 4, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 0, 0.4], ["shell", 30, 0.35], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 3.24, "speed": 1.336, "spawn": 1.7, "task": ["beam_kills", 170]},
	{"title": "Последний маяк", "chapter": 4, "time": 300, "boss_at": 270, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.5], ["squid", 0, 0.4], ["shell", 30, 0.35], ["angler", 0, 0.5], ["narwhal", 90, 0.2], ["puffer", 150, 0.2]],
		"hp": 3.32, "speed": 1.348, "spawn": 1.725, "task": ["kills", 660]},
]

const MODIFIER_TEXT := {
	"fog": "Туман: видно недалеко",
	"storm": "Шторм: луч крутится вдвое быстрее",
	"swarm": "Рой: врагов гораздо больше, но они слабее",
	"dark": "Тёмные воды: луч вдвое уже",
}


static func chapter_of(i: int) -> Dictionary:
	if i == ENDLESS:
		return CHAPTERS[CHAPTERS.size() - 1]
	return CHAPTERS[clampi(i / NIGHTS_PER_CHAPTER, 0, CHAPTERS.size() - 1)]


## Музыка ночи: у главы один или два трека, ночи чередуют их.
static func music_of(i: int) -> String:
	var tracks: Array = chapter_of(i).music
	if i == ENDLESS:
		return tracks[0]
	return tracks[(i % NIGHTS_PER_CHAPTER) % tracks.size()]


static func theme_of(i: int) -> Dictionary:
	return chapter_of(i).theme


static func count() -> int:
	return LIST.size()


static func get_night(i: int) -> Dictionary:
	if i == ENDLESS:
		return ENDLESS_NIGHT
	return LIST[clampi(i, 0, LIST.size() - 1)]


## Бесконечная ночь открывается, когда пройдена последняя ночь кампании.
static func endless_unlocked() -> bool:
	return SaveData.stars_of(LIST.size() - 1) > 0


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
	if i == ENDLESS:
		return endless_unlocked()
	return i == 0 or SaveData.stars_of(i - 1) > 0
