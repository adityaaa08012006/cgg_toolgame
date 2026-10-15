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
		{"speaker": "Father Alden", "text": "Arthur... open your eyes, my son! When the Demon Lord unleashed the Doomsday Requiem, we thought the world was lost."},
		{"speaker": "Father Alden", "text": "Then the skies tore open! A celestial star fell straight into this sanctuary, blessing your heart with divine flame!"},
		{"speaker": "Father Alden", "text": "Your sworn companion, Kaelen, dragged your broken body from the burning ashes of Oakhaven. He wept and prayed at your altar for days without rest."},
		{"speaker": "Father Alden", "text": "When the starlight awakened your soul, Kaelen took up his sword and rode ahead to the Mountain Pass to scout the demon vanguard."},
		{"speaker": "Father Alden", "text": "Master Torren awaits at the forge outside to temper the star-ember into the Sunfire Blade! Hurry to your brother's side, Arthur!"}
	])

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneTransition.change_scene(
			"res://scenes/world/town_tiny_swords.tscn",
			"Haven Town",
			"Sanctuary of the Sunfire Blade"
		)
