extends Node
## Настройки игрока. Хранятся в файле на устройстве и переживают перезапуск.
## Подключено как автозагрузка «Settings»: доступно из любого скрипта.

signal changed

const PATH := "user://settings.cfg"
const SENSITIVITY_MIN := 0.5
const SENSITIVITY_MAX := 2.0

## 1.0 — как в версии 0.1.0. Больше — меньше двигать пальцем до полной скорости.
var sensitivity := 1.0
var sound_on := true
var music_on := true
var vibration_on := true
var intro_seen := false  ## интро-ролик уже показывали


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sensitivity = clampf(cfg.get_value("controls", "sensitivity", 1.0), SENSITIVITY_MIN, SENSITIVITY_MAX)
		sound_on = cfg.get_value("audio", "sound", true)
		music_on = cfg.get_value("audio", "music", true)
		vibration_on = cfg.get_value("controls", "vibration", true)
		intro_seen = cfg.get_value("intro", "seen", false)


func set_sensitivity(value: float) -> void:
	sensitivity = clampf(value, SENSITIVITY_MIN, SENSITIVITY_MAX)
	_save()


func set_sound(on: bool) -> void:
	sound_on = on
	_save()


func set_music(on: bool) -> void:
	music_on = on
	_save()


func set_vibration(on: bool) -> void:
	vibration_on = on
	_save()
	if on:
		vibrate(60, 0.6)


## Вибрация телефона: duration_ms — длительность, strength — сила 0..1.
func vibrate(duration_ms: int, strength := 0.5) -> void:
	if vibration_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, clampf(strength, 0.05, 1.0))


func mark_intro_seen() -> void:
	if not intro_seen:
		intro_seen = true
		_save()


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "sensitivity", sensitivity)
	cfg.set_value("audio", "sound", sound_on)
	cfg.set_value("audio", "music", music_on)
	cfg.set_value("controls", "vibration", vibration_on)
	cfg.set_value("intro", "seen", intro_seen)
	cfg.save(PATH)
	changed.emit()
