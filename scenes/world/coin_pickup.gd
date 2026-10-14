extends Area2D

@export var value: int = 50

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Gentle floating bob animation
	var tween := create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -4.0, 0.4).as_relative()
	tween.tween_property($Sprite2D, "position:y", 4.0, 0.4).as_relative()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.add_coins(value)
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/coin.ogg")
		# Collect burst effect
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.1)
		await tween.finished
		queue_free()
