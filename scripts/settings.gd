extends Node
## Настройки игрока. Хранятся в файле на устройстве и переживают перезапуск.
## Подключено как автозагрузка «Settings»: доступно из любого скрипта.

signal changed

const PATH := "user://settings.cfg"
const SENSITIVITY_MIN := 0.5
const SENSITIVITY_MAX := 2.0

## 1.0 — как в версии 0.1.0. Больше — меньше двигать пальцем до полной скорости.
var sensitivity := 1.0


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		sensitivity = clampf(cfg.get_value("controls", "sensitivity", 1.0), SENSITIVITY_MIN, SENSITIVITY_MAX)


func set_sensitivity(value: float) -> void:
	sensitivity = clampf(value, SENSITIVITY_MIN, SENSITIVITY_MAX)
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("controls", "sensitivity", sensitivity)
	cfg.save(PATH)
	changed.emit()
