extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var kaelen: KaelenCompanion = $Kaelen
@onready var gateway_trigger: Area2D = $VanguardGatewayTrigger

var gateway_reached: bool = false

func _play_music(path: String, vol: float = -4.0) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music(path, vol)

func _play_sfx(path: String, vol: float = 0.0) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(path, vol)

func _change_scene(path: String, title: String = "", subtitle: String = "") -> void:
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.has_method("change_scene"):
		st.change_scene(path, title, subtitle)
	else:
		get_tree().change_scene_to_file(path)

func _emit_quest_update(text: String) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm and qm.has_signal("quest_updated"):
		qm.quest_updated.emit(text)

func _ready() -> void:
	_play_music("res://audio/music/brave_reaction.ogg", -4.0)
	_emit_quest_update("Seek the lone warrior along the Ashen Ridge")

	if gateway_trigger:
		gateway_trigger.body_entered.connect(_on_gateway_entered)

func _on_gateway_entered(body: Node2D) -> void:
	if gateway_reached:
		return
	if body.is_in_group("player"):
		if kaelen and kaelen.current_state == KaelenCompanion.State.FOLLOWING:
			gateway_reached = true
			_play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg")
			dialogue_box.start_dialogue([
				{"speaker": "Kaelen of Oakhaven", "text": "Arthur... wait. Pause for a second before we push this gate open."},
				{"speaker": "Kaelen of Oakhaven", "text": "Beyond this archway lies Gorgath's sanctum. He isn't like the beasts down in the valley. He tore through our knights in seconds."},
				{"speaker": "Kaelen of Oakhaven", "text": "If anything goes wrong in there... if only one of us can make it out... you do not look back. You hear me? The heavens chose you, Arthur."},
				{"speaker": "Kaelen of Oakhaven", "text": "Don't give me that stubborn look. We swore an oath on the riverbank when we were ten years old: brothers to the very end. I am proud to fight beside you."},
				{"speaker": "Kaelen of Oakhaven", "text": "Draw your steel, Arthur. Let's make that monster answer for Oakhaven."},
				{"speaker": "Narrator", "text": "CHAPTER II: THE ASHEN CRATER — GENERAL GORGATH"}
			], func():
				_change_scene(
					"res://scenes/ui/gateway_cutscene.tscn"
				)
			)
			_emit_quest_update("Breach the Vanguard Gateway and confront General Gorgath!")

		else:
			dialogue_box.start_dialogue([
				{"speaker": "Iron Gateway", "text": "The massive iron gates are barred tight against the mountain rock. You cannot breach this fortress without Kaelen by your side."}
			])

