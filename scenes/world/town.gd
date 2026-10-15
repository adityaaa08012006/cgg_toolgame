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
	if GameManager.is_epilogue:
		AudioManager.play_music("res://audio/music/Sad Descent.ogg", -4.0)
		SceneTransition.show_area_banner("Haven Town — Dawn of Peace", "In Everlasting Honor of Kaelen")
		QuestManager.quest_updated.emit("Lay Kaelen's silver pendant upon the Ancient Shrine.")
	else:
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
	if GameManager.is_epilogue:
		smith_npc.dialogue_lines = [
			"You brought back peace, lad... but the price was etched on your face the moment you walked through that gate.",
			"Kaelen was a true son of Oakhaven. His memory will live in every blade I forge."
		]
	else:
		smith_npc.dialogue_lines = [
			"Arthur! You're actually on your feet... By the gods, Kaelen wasn't speaking in delirium after all.",
			"That boy came in here with blistered hands, slammed a fragment of the fallen celestial meteor onto my anvil, and swore he'd hold me responsible if I didn't have steel ready for you.",
			"Here—take this Sunfire Blade and Knight's Armor. The blade holds the living warmth of the star that chose you.",
			"Demonic fiends have cut off the southern road. Cut them down, bring their corrupted cores to the Goddess Altar to cleanse the barrier, and go catch that stubborn fool before he gets himself killed!"
		]
		smith_npc.dialogue_completed.connect(on_smith_equip_gear)

func _setup_herbalist_interaction() -> void:
	herbalist_npc.npc_name = "Eldrin the Herbalist"
	if GameManager.is_epilogue:
		herbalist_npc.dialogue_lines = [
			"The black clouds have dissolved... look up, Arthur. The sun hasn't shone this brightly in thirty years.",
			"Oakhaven's sacrifice saved us all. We will never forget what you two gave for this valley."
		]
	else:
		herbalist_npc.dialogue_lines = [
			"The stench of sulfur is choking the valley, child. Those things roaming the road... they are not of this earth.",
			"When Kaelen passed through, I begged him to let me treat his burns. He just shook his head, looking toward the mountains as if his own life didn't matter.",
			"He kept repeating: 'Arthur is alive. That's all that matters.' Be safe, young knight... a bond like that is rarer than gold."
		]

func _setup_sentinel_interaction() -> void:
	sentinel_npc.npc_name = "Sentinel Gareth"
	if GameManager.is_epilogue:
		sentinel_npc.dialogue_lines = [
			"Arthur... the gates of Haven stand open for you forever. Every soldier salutes you and Kaelen.",
			"Take heart, champion. His light will guide our kingdom for generations."
		]
	else:
		sentinel_npc.dialogue_lines = [
			"Arthur, stay back! I cannot let you through the barricade unarmed—two of my guards fell to those shadow beasts minutes ago.",
			"Torren has your gear waiting at the forge. Get your sword in hand, help us purge the road, and I will open the gates to the Mountain Pass!"
		]

func _unhandled_input(event: InputEvent) -> void:
	if altar_player_in_range and event.is_action_pressed("interact") and GameManager.game_state == GameManager.GameState.PLAYING:
		_interact_altar()

func _interact_altar() -> void:
	if GameManager.is_epilogue:
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
		dialogue_box.start_dialogue([
			{"speaker": "Ancient Shrine", "text": "Arthur kneels in the soft grass before the moss-covered stones."},
			{"speaker": "Ancient Shrine", "text": "Gently, he places Kaelen's warm silver pendant into the sacred basin. A radiant pillar of golden sunlight descends, enveloping the shrine in peace."},
			{"speaker": "Ancient Shrine", "text": "High above, the sanctuary bells toll across the green valley. Oakhaven's oath is fulfilled: neither brother fell alone."},
			{"speaker": "Narrator", "text": "DEMO COMPLETE — Thank you for playing Half-Minute Hero: The Starlight Oath!"}
		])
		return

	if not GameManager.has_sword:
		dialogue_box.start_dialogue([
			{"speaker": "Ancient Shrine", "text": "A solemn warmth emanates from the moss-covered stones. The shrine remains silent, awaiting a warrior clad in steel."}
		])
	elif QuestManager.demons_killed < QuestManager.required_demons:
		dialogue_box.start_dialogue([
			{"speaker": "Ancient Shrine", "text": "The shrine's sacred flame trembles under a suffocating dark curse. The shadow beasts ravaging the South Gate must be slain to lift the miasma."}
		])
	elif GameManager.player_coins < QuestManager.required_coins:
		dialogue_box.start_dialogue([
			{"speaker": "Ancient Shrine", "text": "The altar requires the radiant tribute gathered from the fallen fiends to dispel the abyssal seal upon the gate."}
		])
	elif not QuestManager.quest_complete:
		# Complete quest & unseal gate!
		if QuestManager.offer_coins():
			AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg")
			dialogue_box.start_dialogue([
				{"speaker": "Ancient Shrine", "text": "The shrine blazes with blinding celestial sunlight! A ringing shockwave surges across Haven, shattering the demonic curse upon the South Gate. The road north to Kaelen is open!"}
			])
	else:
		dialogue_box.start_dialogue([
			{"speaker": "Ancient Shrine", "text": "The barrier is broken. The mountain wind calls to you... ride to your brother's side."}
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
