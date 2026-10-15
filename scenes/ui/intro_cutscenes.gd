extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var subtitle_container: Control = $SubtitleContainer
@onready var skip_label: Label = $SkipLabel
@onready var fade_rect: ColorRect = $FadeRect

var cutscenes: Array[Dictionary] = [
	{
		"stream": "res://cutscenes/demon_lord_intro.ogv",
		"subtitle": "In the abyssal heights of the Nether Peak, the Demon Lord unleashes the Doomsday Requiem..."
	},
	{
		"stream": "res://cutscenes/hero_blessing.ogv",
		"subtitle": "Through the shattered skies, an ancient celestial star descends... blessing the fallen champion of Haven."
	}
]

var current_idx: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	AudioManager.stop_music()
	
	fade_rect.modulate.a = 1.0
	fade_rect.visible = true
	
	video_player.finished.connect(_on_video_finished)
	_play_cutscene(0)

func _play_cutscene(idx: int) -> void:
	if idx >= cutscenes.size():
		_finish_all_cutscenes()
		return
		
	current_idx = idx
	is_transitioning = true
	
	var data: Dictionary = cutscenes[idx]
	var stream: VideoStream = load(data["stream"])
	if not stream:
		_on_video_finished()
		return
		
	video_player.stream = stream
	video_player.play()
	
	if subtitle_label:
		subtitle_label.text = data.get("subtitle", "")
		subtitle_container.modulate.a = 0.0
		var stw := create_tween()
		stw.tween_property(subtitle_container, "modulate:a", 1.0, 0.6)
	
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	await tw.finished
	is_transitioning = false

func _on_video_finished() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var tw := create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	await tw.finished
	
	_play_cutscene(current_idx + 1)

func _finish_all_cutscenes() -> void:
	video_player.stop()
	SceneTransition.change_scene(
		"res://scenes/world/church_interior.tscn",
		"Sanctuary of Light",
		"Cathedral of Father Alden"
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER)):
		_skip_current()

func _skip_current() -> void:
	_on_video_finished()
