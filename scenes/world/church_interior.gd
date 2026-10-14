extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var door_trigger: Area2D = $DoorExitTrigger

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sad Descent.ogg", -6.0)
	door_trigger.body_entered.connect(_on_door_entered)
	
	await get_tree().create_timer(0.4).timeout
	trigger_church_intro()

func trigger_church_intro() -> void:
	dialogue_box.start_dialogue([
		{"speaker": "Father Alden", "text": "The Demon Lord has cast the Doomsday Requiem upon our world!"},
		{"speaker": "Father Alden", "text": "Your blade alone is too weak against the shadow. Master Torren awaits at the forge outside."},
		{"speaker": "Father Alden", "text": "He will temper your sword into the Sunfire Blade and forge divine armor for your quest!"}
	])

func _on_door_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/world/town.tscn")
