extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_CHANNELS: int = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)
	
	for i in range(MAX_SFX_CHANNELS):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

var _music_wanted: bool = false
var _unlocked_audio: bool = false

func _on_bgm_finished() -> void:
	if _music_wanted and bgm_player and bgm_player.stream:
		bgm_player.play()

var _stream_cache: Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	if not _unlocked_audio and event.is_pressed():
		_unlocked_audio = true
		if _music_wanted and bgm_player and bgm_player.stream and not bgm_player.playing:
			bgm_player.play()

func _get_stream(stream_path: String) -> AudioStream:
	if _stream_cache.has(stream_path):
		return _stream_cache[stream_path]
	if not ResourceLoader.exists(stream_path):
		return null
	var stream: AudioStream = load(stream_path) as AudioStream
	if stream:
		_stream_cache[stream_path] = stream
	return stream

func play_music(stream_path: String, volume_db: float = -6.0) -> void:
	_music_wanted = true
	var stream := _get_stream(stream_path)
	if stream:
		if stream is AudioStreamOggVorbis:
			stream.loop = true
		elif stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_player.stream = stream
		bgm_player.volume_db = volume_db
		bgm_player.play()

func stop_music() -> void:
	_music_wanted = false
	if bgm_player:
		bgm_player.stop()
		bgm_player.stream = null

func play_sfx(stream_path: String, volume_db: float = 0.0) -> void:
	var stream := _get_stream(stream_path)
	if stream:
		for p in sfx_players:
			if not p.playing:
				p.stream = stream
				p.volume_db = volume_db
				p.play()
				return
		sfx_players[0].stream = stream
		sfx_players[0].play()
