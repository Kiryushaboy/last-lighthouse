extends Node
## Звуки и музыка. Автозагрузка «Sound»: Sound.play("shoot") из любого скрипта.
## Звуки — паки Kenney (CC0), музыка — OpenGameArt (CC0). Источники в CREDITS.md.

## Сколько вариантов у каждого звука: audio/sfx/<имя>_<номер>.ogg. Случайный вариант = меньше повторов.
const VARIANTS := {
	"shoot": [1, 2, 3], "hit": [0, 1, 2], "death": [0, 1, 2], "xp": [1, 2, 3], "shell": [1],
	"levelup": [1], "hurt": [0, 1], "warning": [1], "slam": [1], "win": [1], "lose": [1], "click": [1],
}
const MUSIC := {"menu": "res://audio/music/menu.ogg", "battle": "res://audio/music/battle.ogg",
		"boss": "res://audio/music/boss.ogg"}
## Громкость треков выровнена на слух по замерам: меню тише остальных в исходнике.
const MUSIC_DB := {"menu": -4.0, "battle": -11.0, "boss": -10.0}
const POOL_SIZE := 14
## Поправка громкости каждого звука (дБ), чтобы паки звучали ровно.
const TRIM := {"win": -6.0, "lose": -6.0, "warning": -5.0, "shell": -4.0, "slam": 4.0, "click": 2.0}
## Частые звуки не чаще раза в столько секунд, чтобы не было каши.
const MIN_GAP := {"shoot": 0.06, "hit": 0.04, "death": 0.05, "xp": 0.04}

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer
var _music_name := ""
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # звуки меню работают и на паузе
	for sound_name in VARIANTS:
		var list: Array[AudioStream] = []
		for v in VARIANTS[sound_name]:
			list.append(load("res://audio/sfx/%s_%d.ogg" % [sound_name, v]))
		_streams[sound_name] = list
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	Settings.changed.connect(_apply_settings)
	# Щелчок и пружинка на любой кнопке в игре, без подключения в каждом меню.
	get_tree().node_added.connect(_on_node_added)


func play(sound_name: String, volume_db := 0.0) -> void:
	if not Settings.sound_on or not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sound_name, -1.0) < MIN_GAP.get(sound_name, 0.0):
		return
	_last_played[sound_name] = now
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = (_streams[sound_name] as Array).pick_random()
	p.volume_db = volume_db + TRIM.get(sound_name, 0.0)
	p.pitch_scale = randf_range(0.94, 1.06)  # чуть разная высота, чтобы не надоедало
	p.play()


## Сменить музыку с плавным переходом. Тот же трек не перезапускается.
func play_music(track: String) -> void:
	if track == _music_name:
		return
	_music_name = track
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_ignore_time_scale()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, 0.6)
	_music_tween.tween_callback(_start_track)


func _start_track() -> void:
	var stream := load(MUSIC[_music_name]) as AudioStreamOggVorbis
	stream.loop = true
	_music.stream = stream
	_music.volume_db = -30.0
	if Settings.music_on:
		_music.play()
	create_tween().set_ignore_time_scale().tween_property(_music, "volume_db", MUSIC_DB[_music_name], 1.0)


func _apply_settings() -> void:
	if Settings.music_on and not _music.playing and _music.stream:
		_music.volume_db = MUSIC_DB.get(_music_name, -10.0)
		_music.play()
	elif not Settings.music_on:
		_music.stop()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind("click", -6.0))
		UiFx.add_press_feedback(node as BaseButton)
