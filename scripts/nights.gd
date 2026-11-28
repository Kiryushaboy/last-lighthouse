class_name Nights
extends RefCounted
## Кампания «Маяки побережья»: 10 глав по 6 ночей, ночь длится 5 минут, последняя ночь главы — с боссом.
## Ночь = запись в LIST. Звёзды: ★ пережить, ★★ потерять не больше 2 сердец, ★★★ задание ночи.

const MAX_HITS_FOR_STAR := 2
const ENDLESS := 99  ## номер «Бесконечной ночи» в SaveData.current_night

## Бесконечная ночь: награда за кампанию. Времени нет, каждые 2 минуты событие, каждые 5 — спрут.
const ENDLESS_NIGHT := {"title": "Бесконечная ночь", "time": 0, "endless": true,
	"enemies": [["crab", 0, 1.0], ["jellyfish", 30, 0.5], ["squid", 90, 0.3], ["shell", 150, 0.2],
		["puffer", 240, 0.2], ["eel", 330, 0.3], ["narwhal", 450, 0.2], ["angler", 600, 0.3],
		["seahorse", 720, 0.3], ["ghost", 840, 0.3], ["ember", 960, 0.2], ["weed", 1080, 0.2], ["wisp", 1200, 0.3]],
	"hp": 2.0, "speed": 1.15, "spawn": 1.3, "task": ["kills", 0]}
## Обучение при первом запуске: короткая ночь, темп ускорен (pace), по ходу подсказки старого смотрителя.
const TUTORIAL := 98
const TUTORIAL_NIGHT := {"title": "Первая вахта", "time": 120, "tutorial": true, "pace": 2.2,
	"enemies": [["crab", 0, 1.0], ["jellyfish", 50, 0.4]],
	"hp": 0.8, "speed": 0.9, "spawn": 1.0, "task": ["kills", 80]}
const EVENT_EVERY := 120.0
const EVENT_LENGTH := 45.0
const BOSS_EVERY := 300.0

const NIGHTS_PER_CHAPTER := 6
const ENDLESS_AFTER := 29  ## бесконечная ночь открывается после «Бездны» (5-я глава), как и раньше

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
	{"title": "Коралловый риф", "music": ["chapter6"], "boss_music": "boss2", "time_of_day": "Закат", "boss": "jelly_queen",
		"theme": {"deep": Color(0.07, 0.02, 0.07), "shallow": Color(0.3, 0.12, 0.16), "foam": Color(1.0, 0.75, 0.45), "island": Color(0.2, 0.11, 0.13), "island_top": Color(0.27, 0.15, 0.16), "rock": Color(0.4, 0.22, 0.2), "rim": Color(1.0, 0.6, 0.3), "bg": Color(0.14, 0.07, 0.08), "fog": Color(0.45, 0.28, 0.26)}},
	{"title": "Кладбище кораблей", "music": ["chapter7"], "boss_music": "boss", "time_of_day": "Полночь", "boss": "ghost_ship",
		"theme": {"deep": Color(0.0, 0.03, 0.03), "shallow": Color(0.03, 0.14, 0.12), "foam": Color(0.5, 1.0, 0.8), "island": Color(0.07, 0.12, 0.12), "island_top": Color(0.1, 0.16, 0.16), "rock": Color(0.16, 0.25, 0.24), "rim": Color(0.4, 1.0, 0.75), "bg": Color(0.03, 0.07, 0.07), "fog": Color(0.18, 0.3, 0.28)}},
	{"title": "Огненные острова", "music": ["chapter8"], "boss_music": "boss2", "time_of_day": "Зарево", "boss": "lava_turtle",
		"theme": {"deep": Color(0.05, 0.01, 0.0), "shallow": Color(0.22, 0.06, 0.02), "foam": Color(1.0, 0.6, 0.2), "island": Color(0.13, 0.08, 0.07), "island_top": Color(0.18, 0.11, 0.09), "rock": Color(0.3, 0.16, 0.12), "rim": Color(1.0, 0.42, 0.15), "bg": Color(0.1, 0.04, 0.03), "fog": Color(0.35, 0.18, 0.12)}},
	{"title": "Саргассово море", "music": ["chapter9"], "boss_music": "boss", "time_of_day": "Сумерки", "boss": "hydra",
		"theme": {"deep": Color(0.02, 0.04, 0.01), "shallow": Color(0.1, 0.16, 0.05), "foam": Color(0.85, 1.0, 0.45), "island": Color(0.1, 0.13, 0.07), "island_top": Color(0.14, 0.18, 0.09), "rock": Color(0.22, 0.28, 0.14), "rim": Color(0.75, 0.95, 0.3), "bg": Color(0.05, 0.08, 0.03), "fog": Color(0.26, 0.32, 0.16)}},
	{"title": "Око бури", "music": ["chapter10"], "boss_music": "boss2", "time_of_day": "Перед рассветом", "boss": "leviathan",
		"theme": {"deep": Color(0.01, 0.02, 0.09), "shallow": Color(0.06, 0.12, 0.34), "foam": Color(1.0, 0.95, 0.6), "island": Color(0.1, 0.12, 0.24), "island_top": Color(0.14, 0.17, 0.32), "rock": Color(0.24, 0.28, 0.46), "rim": Color(1.0, 0.88, 0.4), "bg": Color(0.05, 0.06, 0.16), "fog": Color(0.26, 0.3, 0.5)}},
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
	{"title": "Розовая отмель", "chapter": 5, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3]],
		"hp": 3.37, "speed": 1.35, "spawn": 1.737, "task": ["kills", 670]},
	{"title": "Коралловый сад", "chapter": 5, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3], ["eel", 120, 0.25]],
		"hp": 3.42, "speed": 1.35, "spawn": 1.749, "task": ["beam_kills", 180]},
	{"title": "Стая коньков", "chapter": 5, "time": 300, "modifier": "swarm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3], ["eel", 120, 0.25], ["squid", 90, 0.25]],
		"hp": 3.47, "speed": 1.35, "spawn": 1.761, "task": ["kills", 1010]},
	{"title": "Жемчужная лагуна", "chapter": 5, "time": 300, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3], ["eel", 120, 0.25], ["squid", 90, 0.25]],
		"hp": 3.52, "speed": 1.35, "spawn": 1.773, "task": ["shells", 19]},
	{"title": "Жгучий прилив", "chapter": 5, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3], ["eel", 120, 0.25], ["squid", 90, 0.25]],
		"hp": 3.57, "speed": 1.35, "spawn": 1.785, "task": ["beam_kills", 190]},
	{"title": "Королева медуз", "chapter": 5, "time": 300, "boss_at": 270, "enemies": [["crab", 0, 1.0], ["jellyfish", 0, 0.6], ["seahorse", 0, 0.55], ["puffer", 60, 0.3], ["eel", 120, 0.25], ["squid", 90, 0.25]],
		"hp": 3.62, "speed": 1.35, "spawn": 1.797, "task": ["kills", 730]},
	{"title": "Сломанные мачты", "chapter": 6, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3]],
		"hp": 3.67, "speed": 1.35, "spawn": 1.809, "task": ["kills", 740]},
	{"title": "Ржавый якорь", "chapter": 6, "time": 300, "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3], ["shell", 60, 0.3]],
		"hp": 3.72, "speed": 1.35, "spawn": 1.821, "task": ["beam_kills", 200]},
	{"title": "Огни святого Эльма", "chapter": 6, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3], ["shell", 60, 0.3], ["seahorse", 120, 0.25]],
		"hp": 3.77, "speed": 1.35, "spawn": 1.833, "task": ["kills", 770]},
	{"title": "Сундук мертвеца", "chapter": 6, "time": 300, "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3], ["shell", 60, 0.3], ["seahorse", 120, 0.25]],
		"hp": 3.82, "speed": 1.35, "spawn": 1.845, "task": ["shells", 21]},
	{"title": "Мёртвый штиль", "chapter": 6, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3], ["shell", 60, 0.3], ["seahorse", 120, 0.25]],
		"hp": 3.87, "speed": 1.35, "spawn": 1.857, "task": ["beam_kills", 210]},
	{"title": "Летучий голландец", "chapter": 6, "time": 300, "boss_at": 270, "modifier": "fog", "enemies": [["crab", 0, 0.8], ["ghost", 0, 0.6], ["angler", 30, 0.4], ["squid", 30, 0.3], ["shell", 60, 0.3], ["seahorse", 120, 0.25]],
		"hp": 3.92, "speed": 1.35, "spawn": 1.869, "task": ["kills", 800]},
	{"title": "Чёрный песок", "chapter": 7, "time": 300, "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25]],
		"hp": 3.97, "speed": 1.35, "spawn": 1.881, "task": ["kills", 820]},
	{"title": "Кипящая бухта", "chapter": 7, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25], ["puffer", 30, 0.3]],
		"hp": 4.02, "speed": 1.35, "spawn": 1.893, "task": ["beam_kills", 220]},
	{"title": "Пепельный дождь", "chapter": 7, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25], ["puffer", 30, 0.3], ["ghost", 150, 0.2]],
		"hp": 4.07, "speed": 1.35, "spawn": 1.905, "task": ["kills", 840]},
	{"title": "Лавовый поток", "chapter": 7, "time": 300, "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25], ["puffer", 30, 0.3], ["ghost", 150, 0.2]],
		"hp": 4.12, "speed": 1.35, "spawn": 1.917, "task": ["shells", 23]},
	{"title": "Дым над водой", "chapter": 7, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25], ["puffer", 30, 0.3], ["ghost", 150, 0.2]],
		"hp": 4.17, "speed": 1.35, "spawn": 1.929, "task": ["beam_kills", 220]},
	{"title": "Огненная черепаха", "chapter": 7, "time": 300, "boss_at": 270, "enemies": [["crab", 0, 0.8], ["ember", 0, 0.45], ["shell", 0, 0.3], ["narwhal", 60, 0.25], ["puffer", 30, 0.3], ["ghost", 150, 0.2]],
		"hp": 4.22, "speed": 1.35, "spawn": 1.941, "task": ["kills", 880]},
	{"title": "Зелёный ковёр", "chapter": 8, "time": 300, "modifier": "fog", "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4]],
		"hp": 4.27, "speed": 1.35, "spawn": 1.953, "task": ["kills", 890]},
	{"title": "Цепкие заросли", "chapter": 8, "time": 300, "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4], ["angler", 90, 0.3]],
		"hp": 4.32, "speed": 1.35, "spawn": 1.965, "task": ["beam_kills", 230]},
	{"title": "Гнилая вода", "chapter": 8, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4], ["angler", 90, 0.3], ["ember", 150, 0.2]],
		"hp": 4.37, "speed": 1.35, "spawn": 1.977, "task": ["kills", 910]},
	{"title": "Тихая трясина", "chapter": 8, "time": 300, "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4], ["angler", 90, 0.3], ["ember", 150, 0.2]],
		"hp": 4.42, "speed": 1.35, "spawn": 1.989, "task": ["shells", 25]},
	{"title": "Пиявочный рой", "chapter": 8, "time": 300, "modifier": "swarm", "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4], ["angler", 90, 0.3], ["ember", 150, 0.2]],
		"hp": 4.47, "speed": 1.35, "spawn": 2.001, "task": ["beam_kills", 240]},
	{"title": "Гидра", "chapter": 8, "time": 300, "boss_at": 270, "modifier": "fog", "enemies": [["crab", 0, 0.7], ["weed", 0, 0.45], ["eel", 0, 0.4], ["jellyfish", 30, 0.4], ["angler", 90, 0.3], ["ember", 150, 0.2]],
		"hp": 4.52, "speed": 1.35, "spawn": 2.013, "task": ["kills", 950]},
	{"title": "Стена дождя", "chapter": 9, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25]],
		"hp": 4.57, "speed": 1.35, "spawn": 2.025, "task": ["kills", 960]},
	{"title": "Вихрь", "chapter": 9, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25], ["narwhal", 60, 0.25]],
		"hp": 4.62, "speed": 1.35, "spawn": 2.037, "task": ["beam_kills", 250]},
	{"title": "Громовой раскат", "chapter": 9, "time": 300, "modifier": "dark", "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25], ["narwhal", 60, 0.25], ["weed", 120, 0.25], ["seahorse", 0, 0.3]],
		"hp": 4.67, "speed": 1.35, "spawn": 2.049, "task": ["kills", 980]},
	{"title": "Затишье", "chapter": 9, "time": 300, "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25], ["narwhal", 60, 0.25], ["weed", 120, 0.25], ["seahorse", 0, 0.3]],
		"hp": 4.72, "speed": 1.35, "spawn": 2.061, "task": ["shells", 27]},
	{"title": "Последняя волна", "chapter": 9, "time": 300, "modifier": "storm", "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25], ["narwhal", 60, 0.25], ["weed", 120, 0.25], ["seahorse", 0, 0.3]],
		"hp": 4.77, "speed": 1.35, "spawn": 2.073, "task": ["beam_kills", 260]},
	{"title": "Левиафан", "chapter": 9, "time": 300, "boss_at": 270, "modifier": "storm", "enemies": [["crab", 0, 0.6], ["wisp", 0, 0.55], ["ghost", 30, 0.3], ["ember", 60, 0.25], ["narwhal", 60, 0.25], ["weed", 120, 0.25], ["seahorse", 0, 0.3]],
		"hp": 4.82, "speed": 1.35, "spawn": 2.085, "task": ["kills", 1020]},
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
	if i == TUTORIAL:
		return CHAPTERS[0]
	return CHAPTERS[clampi(i / NIGHTS_PER_CHAPTER, 0, CHAPTERS.size() - 1)]


## Музыка ночи: у главы один или два трека, ночи чередуют их.
static func music_of(i: int) -> String:
	var tracks: Array = chapter_of(i).music
	if i == ENDLESS or i == TUTORIAL:
		return tracks[0]
	return tracks[(i % NIGHTS_PER_CHAPTER) % tracks.size()]


## Глава, до которой дошёл игрок: по первой открытой и ещё не пройденной ночи.
static func progress_chapter() -> int:
	return progress_night() / NIGHTS_PER_CHAPTER


## Ночь, на которой игрок остановился: первая открытая и ещё не пройденная.
static func progress_night() -> int:
	var last := 0
	for i in LIST.size():
		if not (i == 0 or SaveData.stars_of(i - 1) > 0):
			break
		last = i
		if SaveData.stars_of(i) == 0:
			break
	return last


static func theme_of(i: int) -> Dictionary:
	return chapter_of(i).theme


static func count() -> int:
	return LIST.size()


static func get_night(i: int) -> Dictionary:
	if i == ENDLESS:
		return ENDLESS_NIGHT
	if i == TUTORIAL:
		return TUTORIAL_NIGHT
	return LIST[clampi(i, 0, LIST.size() - 1)]


## Бесконечная ночь открывается после пятой главы.
static func endless_unlocked() -> bool:
	return SaveData.stars_of(ENDLESS_AFTER) > 0


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
	if SaveData.test_mode:
		return true
	if i == ENDLESS:
		return endless_unlocked()
	return i == 0 or SaveData.stars_of(i - 1) > 0
