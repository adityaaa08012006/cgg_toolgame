extends CanvasLayer
class_name DialogueBox

@onready var panel: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/MarginContainer/MainHBox/PortraitRect
@onready var speaker_label: Label = $PanelContainer/MarginContainer/MainHBox/ContentVBox/HeaderBox/BannerPanel/SpeakerMargin/SpeakerLabel
@onready var text_label: Label = $PanelContainer/MarginContainer/MainHBox/ContentVBox/TextLabel
@onready var prompt_label: Label = $PanelContainer/MarginContainer/MainHBox/ContentVBox/FooterBox/PromptLabel

const PORTRAIT_MAP: Dictionary = {
	"arthur": "res://art/portraits/arthur.png",
	"kaelen": "res://art/portraits/kaelen.png",
	"kaelen of oakhaven": "res://art/portraits/kaelen.png",
	"kaelen's echo": "res://art/portraits/kaelen_echo.png",
	"nightborne": "res://art/portraits/nightborne.png",
	"general gorgath": "res://art/portraits/general_gorgath.png",
	"father alden": "res://art/portraits/father_alden.png",
	"master torren": "res://art/portraits/master_torren.png"
}

var dialogue_queue: Array = []
var current_line: int = -1
var is_active: bool = false
var is_typing: bool = false
var type_tween: Tween
var prompt_tween: Tween
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
	_start_prompt_bounce()
	advance()

func advance() -> void:
	if is_typing:
		if type_tween:
			type_tween.kill()
		text_label.visible_ratio = 1.0
		is_typing = false
		return

	current_line += 1
	if current_line < dialogue_queue.size():
		var entry: Dictionary = dialogue_queue[current_line]
		var speaker_str: String = entry.get("speaker", "???")
		speaker_label.text = speaker_str
		text_label.text = entry.get("text", "")
		text_label.visible_ratio = 0.0
		
		# Portrait lookup
		var speaker_key: String = speaker_str.strip_edges().to_lower()
		var custom_portrait: String = entry.get("portrait", "")
		var portrait_path: String = ""
		if not custom_portrait.is_empty():
			portrait_path = custom_portrait
		elif PORTRAIT_MAP.has(speaker_key):
			portrait_path = PORTRAIT_MAP[speaker_key]
			
		if not portrait_path.is_empty():
			var tex: Texture2D = null
			if ResourceLoader.exists(portrait_path):
				var res = load(portrait_path)
				if res is Texture2D:
					tex = res
			if not tex:
				var global_p := ProjectSettings.globalize_path(portrait_path)
				var img := Image.load_from_file(global_p)
				if img and not img.is_empty():
					tex = ImageTexture.create_from_image(img)
			if tex:
				portrait_rect.texture = tex
				portrait_rect.visible = true
			else:
				portrait_rect.visible = false
		else:
			portrait_rect.visible = false
			
		# Typewriter animation
		is_typing = true
		if type_tween:
			type_tween.kill()
		var duration: float = clamp(float(text_label.text.length()) * 0.022, 0.35, 2.5)
		type_tween = create_tween()
		type_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
		type_tween.tween_callback(func(): is_typing = false)

		AudioManager.play_sfx("res://audio/ui_audio/Audio/click3.ogg", -12.0)
	else:
		end_dialogue()

func _start_prompt_bounce() -> void:
	if prompt_tween:
		prompt_tween.kill()
	var footer = prompt_label.get_parent()
	if footer:
		prompt_tween = create_tween().set_loops()
		prompt_tween.tween_property(footer, "position:y", 2.0, 0.45).as_relative()
		prompt_tween.tween_property(footer, "position:y", -2.0, 0.45).as_relative()

func end_dialogue() -> void:
	if type_tween:
		type_tween.kill()
	if prompt_tween:
		prompt_tween.kill()
	is_typing = false
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
