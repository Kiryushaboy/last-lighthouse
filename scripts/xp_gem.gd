class_name XpGem
extends Node2D
## Подбираемый предмет: кристалл опыта или ракушка.
## Лежит, пока игрок не подойдёт, потом летит к нему.

signal collected(value: int)

const GLOW := preload("res://art/fx/glow.tres")
const GEM := preload("res://art/sprites/gem.svg")
const SHELL := preload("res://art/sprites/seashell.svg")

var value := 1
var is_shell := false  ## ракушка для мастерской вместо опыта
var player: Player

var _magnet := false
var _age := 0.0


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist < player.pickup_radius:
		_magnet = true
	if _magnet:
		global_position = global_position.move_toward(player.global_position, 650.0 * delta)
		if dist < 22.0:
			Sound.play("shell" if is_shell else "xp", -4.0 if is_shell else -12.0)
			collected.emit(value)
			queue_free()


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	var tex: Texture2D = SHELL if is_shell else GEM
	var glow_c := Color(1.0, 0.6, 0.75) if is_shell else Color(0.4, 1.0, 0.7)
	var pulse := 0.75 + 0.25 * sin(_age * 5.0 + get_instance_id())
	var g := 30.0 if is_shell else 24.0
	draw_texture_rect(GLOW, Rect2(-g, -g, g * 2.0, g * 2.0), false, Color(glow_c, 0.45 * pulse))
	# Выпрыгивает из врага и покачивается на волнах.
	var grow := clampf(_age / 0.2, 0.0, 1.0)
	var hop := -sin(clampf(_age / 0.35, 0.0, 1.0) * PI) * 22.0
	var bob := sin(_age * 3.0 + get_instance_id()) * 3.0
	var size := tex.get_size() * 0.5 * grow
	draw_texture_rect(tex, Rect2(Vector2(0, hop + bob) - size / 2.0, size), false)
