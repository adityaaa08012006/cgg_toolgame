extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var fade_rect: ColorRect = $FadeRect

const CITADEL_STREAM := "res://cutscenes/citadel_reveal.ogv"

func _ready() -> void:
	AudioManager.stop_music()
	fade_rect.modulate.a = 1.0
	
	video_player.finished.connect(_on_video_finished)
	var stream: VideoStream = load(CITADEL_STREAM)
	if stream:
		video_player.stream = stream
		video_player.play()
	else:
		_on_video_finished()
		return
		
	if subtitle_label:
		subtitle_label.text = "Beyond the mortal realm, towering above jagged peaks... NightBorne prepares the Doomsday Requiem."
		
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)

func _on_video_finished() -> void:
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	await tw.finished
	video_player.stop()
	SceneTransition.change_scene(
		"res://scenes/world/throne_room.tscn",
		"The Nether Citadel",
		"Throne of NightBorne"
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE):
		_on_video_finished()
