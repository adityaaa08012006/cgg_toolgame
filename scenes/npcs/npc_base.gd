extends StaticBody2D
class_name NPC

@export var npc_name: String = "Priest Alden"
@export var character_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(0.85, 0.85)
@export var hframes: int = 8
@export var vframes: int = 4
@export var frame: int = 0
@export var dialogue_lines: Array[String] = [
	"The Demon Lord has cast the Doomsday Requiem upon our world!",
	"Your blade alone is too weak against the shadow. Master Torren awaits at the forge outside.",
	"He will temper your sword into the Sunfire Blade and forge divine armor for your quest!"
]

@onready var prompt_container: HBoxContainer = $PromptContainer
@onready var interact_area: Area2D = $InteractArea
var player_in_range: bool = false

signal dialogue_completed

func _ready() -> void:
	add_to_group("npcs")
	var spr: Sprite2D = get_node_or_null("Sprite2D")
	if spr:
		if character_texture:
			spr.texture = character_texture
		spr.scale = sprite_scale
		spr.hframes = hframes
		spr.vframes = vframes
		spr.frame = frame
	if prompt_container:
		prompt_container.visible = false
	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)
		interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and GameManager.game_state == GameManager.GameState.PLAYING:
		trigger_dialogue()

func trigger_dialogue() -> void:
	var dlg_box = get_tree().get_first_node_in_group("dialogue_box")
	if dlg_box:
		var formatted_lines: Array[Dictionary] = []
		for line in dialogue_lines:
			formatted_lines.append({"speaker": npc_name, "text": line})
		dlg_box.start_dialogue(formatted_lines, _on_dialogue_finished)

func _on_dialogue_finished() -> void:
	dialogue_completed.emit()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_container:
			prompt_container.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_container:
			prompt_container.visible = false
