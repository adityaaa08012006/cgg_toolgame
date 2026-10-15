extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var fade_rect: ColorRect = $FadeRect

const DAWN_STREAM := "res://cutscenes/dawn_epilogue.ogv"

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
		
	if subtitle_label:
		subtitle_label.text = "The Doomsday Requiem is broken. Across the realm, golden sunlight breaks through the suffocating ash..."
		
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)

func _on_video_finished() -> void:
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
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER)):
		_on_video_finished()
