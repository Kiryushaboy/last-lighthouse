extends Control
## Заставка при запуске. Картинки готовые (их рисует tools/make_splash.py в высоком разрешении),
## на лету двигаются только два луча и название — поэтому заставка чёткая и не тормозит.
## Потом интро-ролик (только при первом запуске) или сразу меню.

const MENU_SCENE := "res://scenes/menu.tscn"
const INTRO_SCENE := "res://scenes/intro.tscn"  ## интро-ролик, только при первом запуске
const BG := preload("res://art/splash/bg.png")
const BEAM := preload("res://art/splash/beam.png")
const TITLE := preload("res://art/splash/title.png")
const LAMP := Vector2(0.5, 0.37)  ## где на фоне фонарь маяка (доли картинки)
const HORIZON := 0.60
const FADE_IN := 0.6
const MIN_HOLD := 2.6
const FADE_OUT := 0.6

var _bg: TextureRect
var _beams: Array[TextureRect] = []
var _title: TextureRect
var _t := 0.0
var _leaving := false
var _next_scene := MENU_SCENE


func _ready() -> void:
	if not Settings.intro_seen:
		_next_scene = INTRO_SCENE
	RenderingServer.set_default_clear_color(Color.BLACK)
	_bg = _picture(BG)
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for i in 2:
		var b := _picture(BEAM)
		b.material = add
		_beams.append(b)
	_title = _picture(TITLE)
	_title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title.modulate.a = 0.0
	resized.connect(_layout)
	_layout()

	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE)
	# Меню грузим в фоне, когда заставка уже проявилась.
	tw.tween_callback(func(): if _next_scene == MENU_SCENE: ResourceLoader.load_threaded_request(MENU_SCENE))
	var tt := create_tween().set_parallel()
	_title.scale = Vector2(0.86, 0.86)
	tt.tween_property(_title, "modulate:a", 1.0, 0.5).set_delay(0.35)
	tt.tween_property(_title, "scale", Vector2.ONE, 0.7).set_delay(0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _picture(tex: Texture2D) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


## Расставить лучи и название под размер экрана: фон заполняет экран, обрезаясь по краям.
func _layout() -> void:
	var tex := BG.get_size()
	var k := maxf(size.x / tex.x, size.y / tex.y)
	var origin := (size - tex * k) / 2.0
	_bg.position = Vector2.ZERO
	_bg.size = size
	var lamp := origin + tex * LAMP * k
	var length := size.length() * 1.1
	for b in _beams:
		b.size = Vector2(length, length * 0.5)
		b.pivot_offset = Vector2(0, b.size.y / 2.0)
		b.position = lamp - b.pivot_offset
	# Название — под маяком, во всю ширину с полями, но не ниже края экрана.
	var tw := minf(size.x * 0.92, size.y * 0.75)
	var th := tw * TITLE.get_height() / TITLE.get_width()
	var top := origin.y + tex.y * (HORIZON + 0.035) * k
	top = minf(top, size.y - th - size.y * 0.04)
	_title.size = Vector2(tw, th)
	_title.position = Vector2((size.x - tw) / 2.0, top)
	_title.pivot_offset = _title.size / 2.0


func _process(delta: float) -> void:
	_t += delta
	# Лучи медленно вращаются; тот, что «смотрит» на зрителя, ярче и шире.
	var a := _t * 0.5 - 0.6
	for i in 2:
		var ang := a + PI * i
		var b := _beams[i]
		var dir := Vector2(cos(ang), sin(ang) * 0.4)
		b.rotation = dir.angle()
		b.scale = Vector2(0.55 + 0.45 * dir.length(), 0.8 + 0.5 * maxf(sin(ang), 0.0))
		b.modulate.a = 0.5 + 0.4 * sin(ang)
	# Уходим, когда и заставку показали достаточно, и меню уже загрузилось: затухание не дёргается.
	if not _leaving and _t >= FADE_IN + MIN_HOLD \
			and (_next_scene == INTRO_SCENE or ResourceLoader.load_threaded_get_status(MENU_SCENE) == ResourceLoader.THREAD_LOAD_LOADED):
		_leaving = true
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(_go)


func _go() -> void:
	# Интро грузим обычным load(): сцена крошечная, а в фоновом потоке её скрипт у Godot 4.7 не загружается.
	# Меню интро потом загрузит само, пока идёт ролик.
	var scene: PackedScene = load(_next_scene) if _next_scene == INTRO_SCENE \
		else ResourceLoader.load_threaded_get(MENU_SCENE) as PackedScene
	get_tree().change_scene_to_packed(scene)
