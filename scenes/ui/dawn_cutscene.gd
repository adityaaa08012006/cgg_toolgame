extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var subtitle_container: Control = $SubtitleContainer
@onready var fade_rect: ColorRect = $FadeRect

const DAWN_STREAM := "res://cutscenes/dawn_epilogue.ogv"

var subtitles: Array[Dictionary] = [
	{
		"time": 0.0,
		"text": "The Doomsday Requiem is broken. Across the realm, golden sunlight breaks through the suffocating ash..."
	},
	{
		"time": 9.5,
		"text": "Clutching Kaelen's silver pendant to his chest, Arthur plants the Sunfire Blade into the cliff edge... His brother's oath fulfilled."
	}
]

var active_subtitle_idx: int = -1
var is_ending: bool = false
var elapsed_time: float = 0.0

func _ready() -> void:
	AudioManager.stop_music()
	fade_rect.modulate.a = 1.0
	
	video_player.finished.connect(_on_video_finished)
	var stream: VideoStream = load(DAWN_STREAM)
	if stream:
		video_player.stream = stream
		video_player.play()
	else:
		_on_video_finished()
		return
		
	_update_subtitle_for_time(0.0)
	
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)

func _process(delta: float) -> void:
	if not video_player.is_playing() or is_ending:
		return
	elapsed_time += delta
	var pos: float = video_player.get_stream_position()
	if pos <= 0.0:
		pos = elapsed_time
	_update_subtitle_for_time(pos)

func _update_subtitle_for_time(pos: float) -> void:
	var target_idx: int = 0
	for i in range(subtitles.size() - 1, -1, -1):
		if pos >= subtitles[i]["time"]:
			target_idx = i
			break
	if target_idx != active_subtitle_idx:
		active_subtitle_idx = target_idx
		_show_subtitle(subtitles[target_idx]["text"])

func _show_subtitle(text: String) -> void:
	if not subtitle_label or not subtitle_container:
		return
	subtitle_container.modulate.a = 0.0
	subtitle_label.text = text
	var tw = create_tween()
	tw.tween_property(subtitle_container, "modulate:a", 1.0, 0.4)

func _on_video_finished() -> void:
	if is_ending:
		return
	is_ending = true
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	await tw.finished
	video_player.stop()
	
	GameManager.is_epilogue = true
	GameManager.stop_doom_countdown()
	SceneTransition.change_scene(
		"res://scenes/world/town_tiny_swords.tscn",
		"Haven Town — Dawn of Peace",
		"In Everlasting Honor of Kaelen"
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_ending:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER)):
		_on_video_finished()
