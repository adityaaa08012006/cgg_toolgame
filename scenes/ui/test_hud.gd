extends Control

@onready var doom_label: Label = $DoomLabel
@onready var coins_label: Label = $CoinsLabel
@onready var objective_label: Label = $ObjectiveLabel

func _ready() -> void:
	GameManager.doom_tick.connect(_on_doom_tick)
	GameManager.coins_changed.connect(_on_coins_changed)
	QuestManager.quest_updated.connect(_on_quest_updated)
	objective_label.text = "Objective: " + QuestManager.get_objective_text()

func _on_doom_tick(time_left: float) -> void:
	doom_label.text = "DOOM IN: %.1fs" % max(0.0, time_left)
	if time_left < 10.0:
		doom_label.modulate = Color.RED
	else:
		doom_label.modulate = Color.WHITE

func _on_coins_changed(new_amount: int) -> void:
	coins_label.text = "GOLD: %d" % new_amount

func _on_quest_updated(new_text: String) -> void:
	objective_label.text = "Objective: " + new_text
