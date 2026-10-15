extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var smith_npc: NPC = $MasterTorren
@onready var herbalist_npc: NPC = $Eldrin
@onready var sentinel_npc: NPC = $Sentinel
@onready var altar_trigger: Area2D = $GoddessAltarArea
@onready var south_gate_trigger: Area2D = $SouthGateExitTrigger
@onready var church_door_trigger: Area2D = $ChurchEntranceTrigger

var altar_player_in_range: bool = false
var demon_scene = preload("res://scenes/enemies/demon.tscn")

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sad Town.ogg", -6.0)

	altar_trigger.body_entered.connect(_on_altar_entered)
	altar_trigger.body_exited.connect(_on_altar_exited)
	south_gate_trigger.body_entered.connect(_on_south_gate_entered)
	church_door_trigger.body_entered.connect(_on_church_door_entered)

	# Configure Custom Dialogue and Triggers for Town NPCs
	_setup_smith_interaction()
	_setup_herbalist_interaction()
	_setup_sentinel_interaction()

	QuestManager.quest_updated.connect(_on_quest_updated)
	QuestManager.gate_unsealed.connect(_on_quest_completed)

func _setup_smith_interaction() -> void:
	smith_npc.npc_name = "Master Torren"
	smith_npc.dialogue_lines = [
		"Arthur, you're awake! Praise the celestial light! Kaelen carried you here through fire and ash after Oakhaven fell.",
		"Before marching north to the pass, he grabbed my anvil and made me swear I would forge your arms before the demon horde strikes.",
		"Take this Sunfire Blade and Knight's Plate—infused with the very star-ember that spared your life!",
		"Two shadow demons guard the South Gate! Slay them, gather 100 gold, and purify the Goddess Altar to unseal the road to Kaelen!"
	]
	smith_npc.dialogue_completed.connect(on_smith_equip_gear)

func _setup_herbalist_interaction() -> void:
	herbalist_npc.npc_name = "Eldrin the Herbalist"
	herbalist_npc.dialogue_lines = [
		"The falling star that struck the cathedral was a miracle from the ancients, young knight.",
		"Kaelen's devotion to you is unbreakable—he watched your pulse for days without closing his eyes.",
		"Arm yourself at the forge, break the demon blockade at the South Gate, and ride to your brother's side!"
	]

func _setup_sentinel_interaction() -> void:
	sentinel_npc.npc_name = "Sentinel Gareth"
	sentinel_npc.dialogue_lines = [
		"Halt, Arthur! Kaelen gave strict orders not to let you through unarmed. Master Torren's forge lies west.",
		"Once you are armed, slay the demons, purify the Goddess Altar, and we will open the way to the Ashen Ridge!"
	]

func _unhandled_input(event: InputEvent) -> void:
	if altar_player_in_range and event.is_action_pressed("interact") and GameManager.game_state == GameManager.GameState.PLAYING:
		_interact_altar()

func _interact_altar() -> void:
	if not GameManager.has_sword:
		dialogue_box.start_dialogue([
			{"speaker": "Goddess Statue", "text": "The sanctuary ward is silent. You must first seek Master Torren's forge to arm your spirit."}
		])
	elif QuestManager.demons_killed < QuestManager.required_demons:
		var remaining := QuestManager.required_demons - QuestManager.demons_killed
		dialogue_box.start_dialogue([
			{"speaker": "Goddess Statue", "text": "The shadow fiends still roam the South Gate (%d remaining). Strike them down and return with their gold!" % remaining}
		])
	elif GameManager.player_coins < QuestManager.required_coins:
		var needed := QuestManager.required_coins - GameManager.player_coins
		dialogue_box.start_dialogue([
			{"speaker": "Goddess Statue", "text": "You must collect the dropped demon gold! (%d more gold needed for the sacred offering)." % needed}
		])
	elif not QuestManager.quest_complete:
		# Complete quest & unseal gate!
		if QuestManager.offer_coins():
			AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg")
			dialogue_box.start_dialogue([
				{"speaker": "Goddess Statue", "text": "The celestial light answers your offering! The dark barrier upon the South Gate is shattered! Go forth, Champion of Haven!"}
			])
	else:
		dialogue_box.start_dialogue([
			{"speaker": "Goddess Statue", "text": "The road to the Demon Lord's Domain lies open. Ride with the dawn!"}
		])

func on_smith_equip_gear() -> void:
	if not GameManager.has_sword:
		GameManager.has_sword = true
		GameManager.has_armor = true
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg")
		GameManager.start_doom_countdown(30.0)

		# Spawn the 2 demons at South Gate road (near gate y=1152)
		var demon1 = demon_scene.instantiate()
		demon1.position = Vector2(600, 1060)
		demon1.unit_color = "Red"
		add_child(demon1)

		var demon2 = demon_scene.instantiate()
		demon2.position = Vector2(680, 1060)
		demon2.unit_color = "Black"
		add_child(demon2)

		QuestManager.quest_updated.emit(QuestManager.get_objective_text())

func _on_altar_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		altar_player_in_range = true
		$GoddessAltarArea/PromptContainer.visible = true

func _on_altar_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		altar_player_in_range = false
		$GoddessAltarArea/PromptContainer.visible = false

func _on_south_gate_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if QuestManager.quest_complete:
			GameManager.stop_doom_countdown()
			SceneTransition.change_scene(
				"res://scenes/world/mountain_pass.tscn",
				"Ashen Mountain Pass",
				"Ridge of the Demon Vanguard"
			)
		else:
			AudioManager.play_sfx("res://audio/sfx/impactPunch_heavy_000.ogg")

func _on_church_door_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SceneTransition.change_scene(
			"res://scenes/world/church_interior.tscn",
			"Sanctuary of Light",
			"Cathedral of Father Alden"
		)

func _on_quest_updated(_text: String) -> void:
	pass

func _on_quest_completed() -> void:
	if has_node("SouthGateBarrier"):
		$SouthGateBarrier/CollisionShape2D.set_deferred("disabled", true)
	elif has_node("SouthGateBarrierCol"):
		$SouthGateBarrierCol.set_deferred("disabled", true)
	if has_node("TownRenderer"):
		get_node("TownRenderer").queue_redraw()
