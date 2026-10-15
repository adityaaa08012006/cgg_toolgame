extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var door_trigger: Area2D = $DoorExitTrigger

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sad Descent.ogg", -6.0)
	door_trigger.body_entered.connect(_on_door_entered)
	SceneTransition.show_area_banner("Sanctuary of Light", "Cathedral of Father Alden")
	
	await get_tree().create_timer(1.5).timeout
	trigger_church_intro()


func trigger_church_intro() -> void:
	dialogue_box.start_dialogue([
		{"speaker": "Father Alden", "text": "Arthur... stay still, my boy. Breathe. You are safe inside the sanctuary."},
		{"speaker": "Father Alden", "text": "When Oakhaven burned... Kaelen carried you through miles of suffocating smoke and ash. His hands were burned raw, but he refused to let you go."},
		{"speaker": "Father Alden", "text": "He collapsed at this altar, weeping and begging the heavens not to take you. For two days, he never left your side."},
		{"speaker": "Father Alden", "text": "Then last night, the dark skies shattered. A falling star crashed from above—striking your chest with pure, radiant light. Your wounds sealed before our eyes."},
		{"speaker": "Father Alden", "text": "Kaelen saw it. He kissed your forehead, drew his blade, and said: 'If the heavens chose Arthur, I will carve the road for him.' He marched north into the pass alone."},
		{"speaker": "Father Alden", "text": "Master Torren is waiting at the forge outside with arms fitted for you. Hurry, Arthur... find your brother before the shadows swallow him."}
	])

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneTransition.change_scene(
			"res://scenes/world/town_tiny_swords.tscn",
			"Haven Town",
			"Sanctuary of the Sunfire Blade"
		)
