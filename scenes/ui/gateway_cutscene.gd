extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var subtitle_container: Control = $SubtitleContainer
@onready var skip_label: Label = $SkipLabel
@onready var fade_rect: ColorRect = $FadeRect

var is_finishing: bool = false

func _ready() -> void:
	AudioManager.stop_music()
	fade_rect.modulate.a = 1.0
	fade_rect.visible = true
	
	video_player.finished.connect(_finish)
	
	var stream: VideoStream = load("res://cutscenes/march_to_vanguard.ogv")
	if stream:
		video_player.stream = stream
		video_player.play()
		
		subtitle_label.text = "United by an unbreakable oath, Arthur and Kaelen march across the threshold into the Ashen Crater to confront General Gorgath."
		subtitle_container.modulate.a = 0.0
		var stw := create_tween()
		stw.tween_property(subtitle_container, "modulate:a", 1.0, 0.6)
		
		var tw := create_tween()
		tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	else:
		_finish()

func _finish() -> void:
	if is_finishing:
		return
	is_finishing = true
	video_player.stop()
	
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
	await tw.finished
	
	SceneTransition.change_scene(
		"res://scenes/world/boss_arena.tscn",
		"The Ashen Crater",
		"Sanctum of General Gorgath"
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_finishing:
		return
	if event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE):
		_finish()
