class_name XpGem
extends Node2D
## Подбираемый предмет: кристалл опыта или ракушка.
## Лежит, пока игрок не подойдёт, потом летит к нему.

signal collected(value: int)

const GEM := preload("res://art/sprites/gem.svg")
const SHELL := preload("res://art/sprites/seashell.svg")

var value := 1
var is_shell := false  ## ракушка для мастерской вместо опыта
var player: Player

var _magnet := false


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < player.pickup_radius:
		_magnet = true
	if _magnet:
		global_position = global_position.move_toward(player.global_position, 650.0 * delta)
		if dist < 22.0:
			collected.emit(value)
			queue_free()


func _draw() -> void:
	var tex: Texture2D = SHELL if is_shell else GEM
	var size := tex.get_size() * 0.5
	draw_texture_rect(tex, Rect2(-size / 2.0, size), false)
