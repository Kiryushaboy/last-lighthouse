class_name Weed
extends Enemy
## Саргассовый ком: большой и вязкий. При гибели из него выползают пиявки.

const LEECHES := 3


func _move(delta: float, current_speed: float) -> void:
	super._move(delta, current_speed)
	_body.rotation += delta * 0.8


func _on_death_fx() -> void:
	super._on_death_fx()
	for i in LEECHES:
		spawn_request.emit("leech", global_position + Vector2.RIGHT.rotated(TAU * i / LEECHES + randf()) * 26.0)
