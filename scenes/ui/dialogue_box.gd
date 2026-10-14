extends CanvasLayer
class_name DialogueBox

@onready var panel: PanelContainer = $PanelContainer
@onready var speaker_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HeaderBox/BannerPanel/SpeakerMargin/SpeakerLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/VBoxContainer/TextLabel
@onready var prompt_label: Label = $PanelContainer/MarginContainer/VBoxContainer/FooterBox/PromptLabel

var dialogue_queue: Array = []
var current_line: int = -1
var is_active: bool = false
var on_finished_callback: Callable

signal dialogue_started
signal dialogue_finished

func _ready() -> void:
	visible = false

func start_dialogue(lines: Array, callback: Callable = Callable()) -> void:
	if SceneTransition and SceneTransition.has_method("hide_area_banner"):
		SceneTransition.hide_area_banner()
	dialogue_queue = lines
	current_line = -1
	on_finished_callback = callback
	is_active = true
	visible = true
	GameManager.set_game_state(GameManager.GameState.DIALOGUE)
	dialogue_started.emit()
	advance()


func advance() -> void:
	current_line += 1
	if current_line < dialogue_queue.size():
		var entry: Dictionary = dialogue_queue[current_line]
		speaker_label.text = entry.get("speaker", "???")
		text_label.text = entry.get("text", "")
		AudioManager.play_sfx("res://audio/ui_audio/Audio/click3.ogg", -12.0)
	else:
		end_dialogue()

func end_dialogue() -> void:
	is_active = false
	visible = false
	GameManager.set_game_state(GameManager.GameState.PLAYING)
	dialogue_finished.emit()
	if on_finished_callback.is_valid():
		on_finished_callback.call()

func _unhandled_input(event: InputEvent) -> void:
	if is_active and (event.is_action_pressed("interact") or event.is_action_pressed("attack")):
		advance()
		get_viewport().set_input_as_handled()
