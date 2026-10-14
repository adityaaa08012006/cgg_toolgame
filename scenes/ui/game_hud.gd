extends CanvasLayer

@onready var hp_bar: TextureProgressBar = $HUDPanel/VBox/HPRow/HPBar
@onready var hp_label: Label = $HUDPanel/VBox/HPRow/HPVal
@onready var coins_label: Label = $HUDPanel/VBox/StatsRow/CoinVal
@onready var timer_label: Label = $HUDPanel/VBox/TimerRow/TimerVal
@onready var objective_label: Label = $ObjectiveBanner/ObjectiveText

func _ready() -> void:
	GameManager.player_health_changed.connect(_on_health_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.doom_tick.connect(_on_doom_tick)
	GameManager.doom_expired.connect(_on_doom_expired)
	QuestManager.quest_updated.connect(_on_quest_updated)

	_on_health_changed(GameManager.player_hp, GameManager.player_max_hp)
	_on_coins_changed(GameManager.player_coins)
	_on_doom_tick(GameManager.doom_timer)
	_on_quest_updated("Speak with Master Torren at the Forge.")

func _on_health_changed(hp: int, max_hp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if hp_label:
		hp_label.text = str(hp) + "/" + str(max_hp)

func _on_coins_changed(coins: int) -> void:
	if coins_label:
		coins_label.text = str(coins) + " G"

func _on_doom_tick(time_remaining: float) -> void:
	if timer_label:
		if GameManager.doom_active:
			timer_label.text = "%.1fs" % time_remaining
			if time_remaining <= 10.0:
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
			else:
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			timer_label.text = "--"
			timer_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _on_doom_expired() -> void:
	if timer_label:
		timer_label.text = "0.0s (DOOM!)"
		timer_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))

func _on_quest_updated(text: String) -> void:
	if objective_label:
		objective_label.text = text
