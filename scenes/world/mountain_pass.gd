extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var kaelen: KaelenCompanion = $Kaelen
@onready var gateway_trigger: Area2D = $VanguardGatewayTrigger

var gateway_reached: bool = false

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sad Descent.ogg", -5.0)
	QuestManager.quest_updated.emit("Seek the lone warrior along the Ashen Ridge")

	if gateway_trigger:
		gateway_trigger.body_entered.connect(_on_gateway_entered)

func _on_gateway_entered(body: Node2D) -> void:
	if gateway_reached:
		return
	if body.is_in_group("player"):
		if kaelen and kaelen.current_state == KaelenCompanion.State.FOLLOWING:
			gateway_reached = true
			AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg")
			dialogue_box.start_dialogue([
				{"speaker": "Kaelen of Oakhaven", "text": "This is it! The Vanguard Gateway! Gorgath's demon reinforcements are already swarming behind us!"},
				{"speaker": "Kaelen of Oakhaven", "text": "I will hold the gateway and keep the demon horde at bay! Step into the sanctum, brother—slay General Gorgath!"},
				{"speaker": "Narrator", "text": "CHAPTER II: THE ASHEN CRATER — GENERAL GORGATH"}
			], func():
				SceneTransition.change_scene(
					"res://scenes/world/boss_arena.tscn",
					"The Ashen Crater",
					"Sanctum of General Gorgath"
				)
			)
			QuestManager.quest_updated.emit("Breach the Vanguard Gateway and confront General Gorgath!")

		else:
			dialogue_box.start_dialogue([
				{"speaker": "Vanguard Gateway", "text": "The iron portal is sealed by demon dread wards. You cannot breach it alone without an ally."}
			])

