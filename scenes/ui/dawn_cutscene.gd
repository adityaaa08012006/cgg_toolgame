extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var subtitle_label: Label = $SubtitleContainer/SubtitleLabel
@onready var subtitle_container: Control = $SubtitleContainer
@onready var fade_rect: ColorRect = $FadeRect

const SHATTER_STREAM := "res://cutscenes/demon_king_shatter.ogv"
const DAWN_STREAM := "res://cutscenes/dawn_epilogue.ogv"

var cutscenes: Array[Dictionary] = [
	{
		"stream": SHATTER_STREAM,
		"subtitles": [
			{
				"time": 0.0,
				"text": "With a roar of celestial fury, NightBorne collapses... his abyssal form crumbling into cosmic dust."
			},
			{
				"time": 4.5,
				"text": "The Doomsday Requiem shatters. The shadow that choked the realm begins to unravel."
			}
		]
	},
	{
		"stream": DAWN_STREAM,
		"subtitles": [
			{
				"time": 0.0,
				"text": "Across the realm, golden sunlight breaks through the suffocating ash..."
			},
			{
				"time": 9.5,
				"text": "Clutching Kaelen's silver pendant to his chest, Arthur plants the Sunfire Blade into the cliff edge... His brother's oath fulfilled."
			}
		]
	}
]

var current_stage_idx: int = 0
var active_subtitle_idx: int = -1
var is_transitioning: bool = false
var elapsed_time: float = 0.0

func _ready() -> void:
	AudioManager.stop_music()
	fade_rect.modulate.a = 1.0
	video_player.finished.connect(_on_video_finished)
	_play_stage(0)

func _play_stage(stage_idx: int) -> void:
	if stage_idx >= cutscenes.size():
		_finish_all_cutscenes()
		return
		
	current_stage_idx = stage_idx
	is_transitioning = false
	elapsed_time = 0.0
	active_subtitle_idx = -1
	
	var stage_data = cutscenes[stage_idx]
	var stream: VideoStream = load(stage_data["stream"])
	if stream:
		video_player.stream = stream
		video_player.play()
	else:
		_advance_to_next_stage()
		return

	if stage_data["subtitles"].size() > 0:
		_show_subtitle(stage_data["subtitles"][0]["text"])
		active_subtitle_idx = 0
		
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.45)

func _process(delta: float) -> void:
	if not video_player.is_playing() or is_transitioning:
		return
	elapsed_time += delta
	var pos: float = video_player.get_stream_position()
	if pos <= 0.0:
		pos = elapsed_time
		
	var current_subs: Array = cutscenes[current_stage_idx]["subtitles"]
	var target_idx: int = 0
	for i in range(current_subs.size() - 1, -1, -1):
		if pos >= current_subs[i]["time"]:
			target_idx = i
			break
	if target_idx != active_subtitle_idx and target_idx < current_subs.size():
		active_subtitle_idx = target_idx
		_show_subtitle(current_subs[target_idx]["text"])

func _show_subtitle(text: String) -> void:
	if not subtitle_label or not subtitle_container:
		return
	subtitle_container.modulate.a = 0.0
	subtitle_label.text = text
	var tw = create_tween()
	tw.tween_property(subtitle_container, "modulate:a", 1.0, 0.35)

func _on_video_finished() -> void:
	_advance_to_next_stage()

func _advance_to_next_stage() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.4)
	await tw.finished
	video_player.stop()
	
	if current_stage_idx + 1 < cutscenes.size():
		_play_stage(current_stage_idx + 1)
	else:
		_finish_all_cutscenes()

func _finish_all_cutscenes() -> void:
	is_transitioning = true
	video_player.stop()
	
	GameManager.is_epilogue = true
	GameManager.stop_doom_countdown()
	SceneTransition.change_scene(
		"res://scenes/world/town_tiny_swords.tscn",
		"Haven Town — Dawn of Peace",
		"In Everlasting Honor of Kaelen"
	)

func _unhandled_input(event: InputEvent) -> void:
	if is_transitioning:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER)):
		_advance_to_next_stage()
