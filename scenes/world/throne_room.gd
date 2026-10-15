extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var hero: Hero = $Hero
@onready var boss: DemonLordNightborne = $DemonLordNightborne

var boss_hud_container: Control
var boss_title_label: Label
var boss_hp_bar: TextureProgressBar
var boss_hp_label: Label

func _ready() -> void:
	AudioManager.play_music("res://audio/music/duel_under_the_eclipse.ogg", -2.0)
	SceneTransition.show_area_banner("The Nether Citadel", "Throne of NightBorne")
	_build_boss_hud()
	
	var game_hud = get_node_or_null("CanvasLayer/GameHUD")
	if game_hud and game_hud.has_node("ObjectiveBanner"):
		game_hud.get_node("ObjectiveBanner").visible = false
		
	if boss:
		boss.hp_changed.connect(_on_boss_hp_changed)
		boss.phase_changed.connect(_on_boss_phase_changed)
		boss.final_stand_triggered.connect(_on_final_stand_triggered)
		boss.defeated.connect(_on_boss_defeated)
		
	QuestManager.quest_updated.emit("Defeat NightBorne and sever the Doomsday Requiem!")
	
	# Frame both Arthur (y=780) and NightBorne (y=320) in camera during dialogue
	if hero and hero.has_node("Camera2D"):
		var cam: Camera2D = hero.get_node("Camera2D")
		cam.top_level = true
		cam.global_position = Vector2(640, 520)
	
	await get_tree().create_timer(0.5).timeout
	_trigger_intro_dialogue()

func _build_boss_hud() -> void:
	boss_hud_container = Control.new()
	boss_hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hud_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_hud_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_hud_container.offset_top = 16.0
	boss_hud_container.visible = false
	boss_hud_container.modulate.a = 0.0
	$CanvasLayer.add_child(boss_hud_container)

	var game_font: FontFile = load("res://art/fonts/Fonts/Kenney Future.ttf")

	var panel := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = load("res://art/ui/rpg_expansion/PNG/panel_brown.png")
	style.texture_margin_left = 14.0
	style.texture_margin_top = 10.0
	style.texture_margin_right = 14.0
	style.texture_margin_bottom = 12.0
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(460, 72)
	panel.size = Vector2(460, 72)
	panel.position = Vector2(-230, 0)
	boss_hud_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	boss_title_label = Label.new()
	boss_title_label.text = "NIGHTBORNE — LORD OF THE ABYSS"
	boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_title_label.add_theme_font_override("font", game_font)
	boss_title_label.add_theme_font_size_override("font_size", 14)
	boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.5, 1.0))
	boss_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	boss_title_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_title_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(boss_title_label)

	var hp_box := CenterContainer.new()
	vbox.add_child(hp_box)

	boss_hp_bar = TextureProgressBar.new()
	boss_hp_bar.texture_under = load("res://art/ui/rpg_expansion/PNG/barBack_horizontalMid.png")
	boss_hp_bar.texture_progress = load("res://art/ui/rpg_expansion/PNG/barRed_horizontalMid.png")
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = boss.max_hp if boss else 650
	boss_hp_bar.value = boss_hp_bar.max_value
	boss_hp_bar.custom_minimum_size = Vector2(380, 20)
	boss_hp_bar.nine_patch_stretch = true
	boss_hp_bar.stretch_margin_left = 6
	boss_hp_bar.stretch_margin_right = 6
	boss_hp_bar.stretch_margin_top = 4
	boss_hp_bar.stretch_margin_bottom = 4
	hp_box.add_child(boss_hp_bar)

	boss_hp_label = Label.new()
	boss_hp_label.text = "%d / %d" % [boss_hp_bar.value, boss_hp_bar.max_value]
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_hp_label.add_theme_font_override("font", game_font)
	boss_hp_label.add_theme_font_size_override("font_size", 14)
	boss_hp_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	boss_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	boss_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	hp_box.add_child(boss_hp_label)

func _trigger_intro_dialogue() -> void:
	dialogue_box.start_dialogue([
		{"speaker": "Arthur", "text": "NightBorne! Release Kaelen! Your apocalypse spell ends here in the dirt!"},
		{"speaker": "NightBorne", "text": "A fledgling mortal blessed by a dying star... You dare step into the Obsidian Sanctum?"},
		{"speaker": "NightBorne", "text": "Look upon the Nether Core above my throne. Your beloved brother's soul fuels the final incantation of the Doomsday Requiem!"},
		{"speaker": "Kaelen's Echo", "text": "Arthur! Arthur, don't look at the core! He blinks behind you the moment you swing! Leap over his third void wave—DON'T LET HIM CAST!"},
		{"speaker": "NightBorne", "text": "Silence, vessel! Let us see if your starlight blade can pierce eternal midnight!"}
	], func():
		# Fade in Boss HUD now that dialogue is complete
		if boss_hud_container:
			boss_hud_container.visible = true
			var htw := create_tween()
			htw.tween_property(boss_hud_container, "modulate:a", 1.0, 0.6)

		# Pan camera back to track hero
		if hero and hero.has_node("Camera2D"):
			var cam: Camera2D = hero.get_node("Camera2D")
			var ctw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			ctw.tween_property(cam, "global_position", hero.global_position, 0.7)
			ctw.tween_callback(func():
				cam.top_level = false
				cam.position = Vector2.ZERO
			)

		if boss and is_instance_valid(boss) and boss.has_method("begin_combat"):
			boss.begin_combat()
	)

func _on_boss_hp_changed(curr: int, maximum: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = maximum
		boss_hp_bar.value = curr
	if boss_hp_label:
		boss_hp_label.text = "%d / %d" % [curr, maximum]

func _on_boss_phase_changed(new_phase: int) -> void:
	if new_phase == 2:
		AudioManager.play_music("res://audio/music/full_strength_unleashed.ogg", -2.0)
		if boss_title_label:
			boss_title_label.text = "NIGHTBORNE — DOOMSDAY OVERDRIVE"
			boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.1, 0.2, 1.0))

func _on_final_stand_triggered() -> void:
	# Visual & audio feedback without stopping combat with dialogue boxes
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 3.0)
	var cam = get_viewport().get_camera_2d()
	if cam:
		var ctw = create_tween()
		ctw.tween_property(cam, "offset", Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.08)
		ctw.tween_property(cam, "offset", Vector2.ZERO, 0.15)

func _on_boss_defeated() -> void:
	AudioManager.play_music("res://audio/music/Sad Town.ogg", -2.0)
	if boss_hud_container:
		var tw := create_tween()
		tw.tween_property(boss_hud_container, "modulate:a", 0.0, 1.0)
		tw.tween_callback(boss_hud_container.queue_free)

	QuestManager.quest_updated.emit("The Demon Lord is vanquished! Speak to Kaelen...")
	
	# Spawn Kaelen's astral body on the red carpet
	var kaelen := Sprite2D.new()
	kaelen.texture = load("res://art/characters/adventurer/FREE_Adventurer 2D Pixel Art/Sprites/IDLE/idle_down.png")
	kaelen.hframes = 8
	kaelen.frame = 0
	kaelen.modulate = Color(2.2, 1.8, 1.1, 0.95)
	kaelen.scale = Vector2(1.5, 1.5)
	kaelen.position = Vector2(640, 480)
	add_child(kaelen)
	
	# Frame camera between Arthur and Kaelen
	if hero and hero.has_node("Camera2D"):
		var cam: Camera2D = hero.get_node("Camera2D")
		cam.top_level = true
		var ctw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ctw.tween_property(cam, "global_position", (hero.global_position + kaelen.global_position) * 0.5, 0.8)

	await get_tree().create_timer(1.2).timeout
	
	dialogue_box.start_dialogue([
		{"speaker": "Arthur", "text": "Kaelen! Kaelen, hold on! The rift is crumbling! The Doomsday Requiem is broken! We won!"},
		{"speaker": "Kaelen", "text": "Heh... 'we'? Look at you... glowing with pure starlight... You really became Haven's champion, Arthur..."},
		{"speaker": "Arthur", "text": "Save your breath! Lean on me. Master Torren and Father Alden are waiting—I am carrying you all the way back to Haven Town!"},
		{"speaker": "Kaelen", "text": "Don't waste the journey, brother... When I severed his soul tether from inside the abyss... I felt the last ember in my hearth burn out."},
		{"speaker": "Arthur", "text": "You shouldn't have done that! We swore an oath in the ashes of Oakhaven: Neither of us falls alone!"},
		{"speaker": "Kaelen", "text": "Oakhaven burned because no one stood in the gap. Today... we stood. Tell me, Arthur... did the black clouds break? Did the sun come back?"},
		{"speaker": "Arthur", "text": "...Yes, Kaelen. The ash is blowing away. The sky is golden."},
		{"speaker": "Kaelen", "text": "Then light was the meaning to everything... Take my silver pendant, brother... and live... for both of us..."},
		{"speaker": "Narrator", "text": "Kaelen's hand gently loosens, leaving his warm silver pendant resting in Arthur's palm. The Nether Citadel dissolves into quiet morning mist."}
	], func():
		_return_to_town_epilogue()
	)

func _return_to_town_epilogue() -> void:
	GameManager.is_epilogue = true
	GameManager.stop_doom_countdown()
	SceneTransition.change_scene(
		"res://scenes/ui/dawn_cutscene.tscn"
	)
