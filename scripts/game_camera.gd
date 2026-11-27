extends Camera2D
## Камера с тряской: сила берётся из Fx.trauma, смещение — плавный шум, а не дёрганый рандом.

const MAX_OFFSET := 26.0
const MAX_ROLL := 0.03

var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	_noise.frequency = 2.0
	ignore_rotation = false


func _process(delta: float) -> void:
	_t += delta * 30.0
	var k := Fx.trauma * Fx.trauma
	offset = Vector2(_noise.get_noise_2d(_t, 0.0), _noise.get_noise_2d(0.0, _t)) * MAX_OFFSET * k
	rotation = _noise.get_noise_2d(_t, _t) * MAX_ROLL * k
