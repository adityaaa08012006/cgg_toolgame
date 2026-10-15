extends Control

@onready var btn_start: Button = find_child("BtnStart", true, false) as Button
@onready var btn_controls: Button = find_child("BtnControls", true, false) as Button
@onready var btn_quit: Button = find_child("BtnQuit", true, false) as Button
@onready var controls_modal: Control = find_child("ControlsModal", true, false) as Control
@onready var btn_close_controls: Button = find_child("BtnClose", true, false) as Button

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Sad Descent.ogg", -4.0)

	btn_start.pressed.connect(_on_start_pressed)
	btn_controls.pressed.connect(_on_controls_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_close_controls.pressed.connect(_on_close_controls_pressed)

	_setup_button_hover(btn_start)
	_setup_button_hover(btn_controls)
	_setup_button_hover(btn_quit)
	_setup_button_hover(btn_close_controls)

	controls_modal.visible = false

func _setup_button_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func():
		AudioManager.play_sfx("res://audio/sfx/woosh1.ogg", -12.0)
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.1).set_trans(Tween.TRANS_QUAD)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD)
	)

func _on_start_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 1.0)
	var tw := create_tween()
	tw.tween_property($UIContainer, "modulate:a", 0.0, 0.4)
	await tw.finished
	SceneTransition.change_scene(
		"res://scenes/world/church_interior.tscn",
		"Sanctuary of Light",
		"Cathedral of Father Alden"
	)

func _on_controls_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	controls_modal.visible = true
	controls_modal.modulate.a = 0.0
	var tw := controls_modal.create_tween()
	tw.tween_property(controls_modal, "modulate:a", 1.0, 0.2)

func _on_close_controls_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	var tw := controls_modal.create_tween()
	tw.tween_property(controls_modal, "modulate:a", 0.0, 0.15)
	await tw.finished
	controls_modal.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
