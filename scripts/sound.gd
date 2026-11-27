extends Node
## Звуки и музыка. Автозагрузка «Sound»: Sound.play("shoot") из любого скрипта.
## Все звуки синтезированы скриптом tools/make_audio.py, лицензии не нужны.

const NAMES := ["shoot", "hit", "death", "xp", "shell", "levelup", "hurt",
		"warning", "slam", "win", "lose", "click"]
const POOL_SIZE := 12
## Частые звуки не чаще раза в столько секунд, чтобы не было каши.
const MIN_GAP := {"shoot": 0.05, "hit": 0.04, "death": 0.05, "xp": 0.04}

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # звуки меню работают и на паузе
	for n in NAMES:
		_streams[n] = load("res://audio/%s.wav" % n)
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	var stream := load("res://audio/music.ogg") as AudioStreamOggVorbis
	stream.loop = true
	_music.stream = stream
	_music.volume_db = -6.0
	add_child(_music)
	Settings.changed.connect(_apply_settings)
	# Щелчок на любой кнопке в игре, без подключения в каждом меню.
	get_tree().node_added.connect(_on_node_added)
	_apply_settings()


func play(sound_name: String, volume_db := 0.0) -> void:
	if not Settings.sound_on or not _streams.has(sound_name):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sound_name, -1.0) < MIN_GAP.get(sound_name, 0.0):
		return
	_last_played[sound_name] = now
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[sound_name]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.94, 1.06)  # чуть разная высота, чтобы не надоедало
	p.play()


func _apply_settings() -> void:
	if Settings.music_on and not _music.playing:
		_music.play()
	elif not Settings.music_on:
		_music.stop()


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play.bind("click", -6.0))
		UiFx.add_press_feedback(node as BaseButton)
