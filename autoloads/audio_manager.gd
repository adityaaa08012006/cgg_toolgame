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

func _on_bgm_finished() -> void:
	if bgm_player and bgm_player.stream:
		bgm_player.play()

func play_music(stream_path: String, volume_db: float = -6.0) -> void:
	if not FileAccess.file_exists(stream_path):
		return
	var stream = load(stream_path)
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
	bgm_player.stop()

func play_sfx(stream_path: String, volume_db: float = 0.0) -> void:
	if not FileAccess.file_exists(stream_path):
		return
	var stream = load(stream_path)
	if stream:
		for p in sfx_players:
			if not p.playing:
				p.stream = stream
				p.volume_db = volume_db
				p.play()
				return
		sfx_players[0].stream = stream
		sfx_players[0].play()
