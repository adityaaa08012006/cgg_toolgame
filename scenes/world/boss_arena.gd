extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var hero: Hero = $Hero
@onready var boss: BossGeneral = $BossGeneral

# Tiny Swords Boss HUD
var boss_hud_container: Control
var boss_title_label: Label
var boss_hp_bar: TextureProgressBar
var boss_hp_label: Label

func _play_music(path: String, vol: float = -4.0) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music(path, vol)

func _play_sfx(path: String, vol: float = 0.0) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(path, vol)

func _show_area_banner(title: String, subtitle: String) -> void:
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.has_method("show_area_banner"):
		st.show_area_banner(title, subtitle)

func _emit_quest_update(text: String) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm and qm.has_signal("quest_updated"):
		qm.quest_updated.emit(text)

func _ready() -> void:
	_play_music("res://audio/music/Infinite Descent.ogg", -4.0)
	_show_area_banner("The Ashen Crater", "Sanctum of General Gorgath")
	_build_tiny_swords_boss_hud()

	var game_hud = get_node_or_null("CanvasLayer/GameHUD")
	if game_hud and game_hud.has_node("ObjectiveBanner"):
		game_hud.get_node("ObjectiveBanner").visible = false

	if boss:
		boss.hp_changed.connect(_on_boss_hp_changed)
		boss.defeated.connect(_on_boss_defeated)

	await get_tree().create_timer(0.4).timeout
	_trigger_boss_intro()

func _build_tiny_swords_boss_hud() -> void:
	boss_hud_container = Control.new()
	boss_hud_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_hud_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_hud_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_hud_container.offset_top = 16.0
	$CanvasLayer.add_child(boss_hud_container)

	var game_font: FontFile = load("res://art/fonts/Fonts/SegoeUI-Bold.ttf")

	# Clean RPG wooden panel frame matching Player HUD
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
	panel.custom_minimum_size = Vector2(420, 68)
	panel.size = Vector2(420, 68)
	panel.position = Vector2(-210, 0)
	boss_hud_container.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Boss Name & Title Banner
	boss_title_label = Label.new()
	boss_title_label.text = "GENERAL GORGATH — DEMON VANGUARD"
	boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if game_font:
		boss_title_label.add_theme_font_override("font", game_font)
	boss_title_label.add_theme_font_size_override("font_size", 13)
	boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	boss_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	boss_title_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_title_label.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(boss_title_label)

	# Inset Bar Container
	var bar_container := PanelContainer.new()
	var inset_style := StyleBoxTexture.new()
	inset_style.texture = load("res://art/ui/rpg_expansion/PNG/panelInset_brown.png")
	inset_style.texture_margin_left = 4.0
	inset_style.texture_margin_right = 4.0
	inset_style.texture_margin_top = 4.0
	inset_style.texture_margin_bottom = 4.0
	bar_container.add_theme_stylebox_override("panel", inset_style)
	vbox.add_child(bar_container)

	# Seamless RPG Bar textures
	boss_hp_bar = TextureProgressBar.new()
	boss_hp_bar.texture_under = load("res://art/ui/rpg_expansion/PNG/barBack_horizontalMid.png")
	boss_hp_bar.texture_progress = load("res://art/ui/rpg_expansion/PNG/barRed_horizontalMid.png")
	boss_hp_bar.nine_patch_stretch = true
	boss_hp_bar.custom_minimum_size = Vector2(380, 20)
	boss_hp_bar.size = Vector2(380, 20)
	boss_hp_bar.max_value = boss.max_hp if boss else 550
	boss_hp_bar.value = boss_hp_bar.max_value
	bar_container.add_child(boss_hp_bar)

	# Numeric HP Label superimposed over bar
	boss_hp_label = Label.new()
	boss_hp_label.text = "%d / %d HP" % [int(boss_hp_bar.value), int(boss_hp_bar.max_value)]
	boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if game_font:
		boss_hp_label.add_theme_font_override("font", game_font)
	boss_hp_label.add_theme_font_size_override("font_size", 12)
	boss_hp_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	boss_hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	boss_hp_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_hp_label.add_theme_constant_override("shadow_offset_y", 1)
	bar_container.add_child(boss_hp_label)

func _on_boss_hp_changed(curr: int, maximum: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = maximum
		var tw := create_tween()
		tw.tween_property(boss_hp_bar, "value", float(curr), 0.18).set_trans(Tween.TRANS_CUBIC)
	if boss_hp_label:
		boss_hp_label.text = "%d / %d HP" % [max(0, curr), maximum]

func _trigger_boss_intro() -> void:
	var kaelen = get_node_or_null("Kaelen")
	if not kaelen:
		dialogue_box.start_dialogue([
			{"speaker": "General Gorgath", "text": "Foolish mortal! You have stepped into the domain of the shadow vanguard! Fall before the Bringer of Death!"}
		])
		return

	# Step 1: Pre-battle dialogue before the sacrifice
	dialogue_box.start_dialogue([
		{"speaker": "Kaelen of Oakhaven", "text": "Gorgath... Look at his blade, Arthur. It still reeks of the ash from our town square."},
		{"speaker": "General Gorgath", "text": "Two little rats from the embers... I remember the taste of your burning home. Your people screamed so sweetly before the silence took them."},
		{"speaker": "Kaelen of Oakhaven", "text": "You will answer for every drop of their blood, monster! Arthur carries the starlight of retribution—we will carve your black heart out!"},
		{"speaker": "General Gorgath", "text": "Retribution? No... A boy glowing with stolen divine embers, and a brother burning with blind, pathetic devotion. The Demon Lord's dark altar will relish breaking a soul like yours."}
	], func():
		_execute_portal_sacrifice_sequence(kaelen)
	)

func _execute_portal_sacrifice_sequence(kaelen: Node2D) -> void:
	if boss and boss.has_method("play_cast_cutscene"):
		boss.play_cast_cutscene(3.0)

	_play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)

	# Spawn swirling abyss portal beneath Kaelen
	var portal := Sprite2D.new()
	portal.texture = load("res://art/characters/enemies/Bringer-Of-Death/sheets/Spell.png")
	portal.hframes = 16
	portal.frame = 8
	portal.scale = Vector2(2.8, 1.4)
	portal.modulate = Color(2.5, 0.2, 3.0, 0.0)
	portal.global_position = kaelen.global_position + Vector2(0, 10)
	portal.z_index = kaelen.z_index - 1
	add_child(portal)

	var ptw := create_tween()
	ptw.parallel().tween_property(portal, "modulate:a", 1.0, 0.4)
	ptw.parallel().tween_property(portal, "scale", Vector2(3.2, 1.6), 0.5)

	var ktw := kaelen.create_tween()
	ktw.parallel().tween_property(kaelen, "position:y", kaelen.position.y - 28.0, 0.6)
	ktw.parallel().tween_property(kaelen, "modulate", Color(0.6, 0.1, 1.4, 0.9), 0.6)

	await get_tree().create_timer(0.6).timeout
	_play_sfx("res://audio/sfx/woosh3.ogg", 2.0)

	dialogue_box.start_dialogue([
		{"speaker": "Kaelen of Oakhaven", "text": "ARTHUR! GET BACK—DO NOT TOUCH THE SHADOWS!"},
		{"speaker": "Kaelen of Oakhaven", "text": "The chains... they're ripping into my soul! Arthur, don't look at me—LOOK AT GORGATH!"},
		{"speaker": "Kaelen of Oakhaven", "text": "Remember what we swore! You survive this fight! Shatter his vanguard and come kick down the citadel doors! PROMISE ME, ARTHUR! PROMISE M—"}
	], func():
		_finalize_sacrifice(kaelen, portal)
	)

func _finalize_sacrifice(kaelen: Node2D, portal: Sprite2D) -> void:
	_play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 3.0)

	var itw := create_tween()
	itw.parallel().tween_property(kaelen, "scale", Vector2.ZERO, 0.35)
	itw.parallel().tween_property(kaelen, "rotation", 3.14, 0.35)
	itw.parallel().tween_property(portal, "scale", Vector2.ZERO, 0.4)
	itw.parallel().tween_property(portal, "modulate", Color(4.0, 0.5, 5.0, 0.0), 0.4)

	await itw.finished
	if is_instance_valid(kaelen):
		kaelen.queue_free()
	if is_instance_valid(portal):
		portal.queue_free()

	await get_tree().create_timer(0.3).timeout

	dialogue_box.start_dialogue([
		{"speaker": "General Gorgath", "text": "His screaming soul now kneels in chains at our Master's throne. Now, little fallen star... let us see what you bleed."}
	])

func _on_boss_defeated() -> void:
	if boss_hud_container:
		var tw := create_tween()
		tw.tween_property(boss_hud_container, "modulate:a", 0.0, 1.0)
		tw.tween_callback(boss_hud_container.queue_free)

	_emit_quest_update("Vanguard defeated! Advance to the Demon Lord's Citadel to save Kaelen!")
	_play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)

	# Spawn Doom Core Item in center
	var core := Sprite2D.new()
	core.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	core.modulate = Color(2.5, 0.8, 0.2, 1.0)
	core.position = Vector2(640, 480)
	core.scale = Vector2(1.6, 1.6)
	add_child(core)

	await get_tree().create_timer(1.2).timeout

	dialogue_box.start_dialogue([
		{"speaker": "Narrator", "text": "General Gorgath's scythe shatters against the frozen rock. His dark essence dissipates into the biting wind, leaving the crater in deafening silence."},
		{"speaker": "Narrator", "text": "Embedded in the ash lies Kaelen's dropped silver pendant, pulsing faintly with a familiar, desperate warmth."},
		{"speaker": "Kaelen's Whisper", "text": "Arthur... I can feel it... his scythe broke... I knew you wouldn't let him win..."},
		{"speaker": "Kaelen's Whisper", "text": "It's so cold down here in the dark... but your light reached me... I'm holding on, brother... don't you dare give up on me..."},
		{"speaker": "Narrator", "text": "Clutching the pendant, Arthur raises the Sunfire Blade toward the black spires of the Demon Lord's Citadel. He will not lose his brother twice."}
	], func():
		_open_abyssal_rift()
	)

func _open_abyssal_rift() -> void:
	_emit_quest_update("Enter the Abyssal Rift to storm the Nether Citadel!")
	_play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	
	var portal := Area2D.new()
	portal.position = Vector2(640, 480)
	
	var spr := Sprite2D.new()
	spr.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_brown.png")
	spr.modulate = Color(2.5, 0.4, 3.5, 0.9)
	spr.scale = Vector2(2.0, 2.0)
	portal.add_child(spr)
	
	var tw = spr.create_tween().set_loops()
	tw.tween_property(spr, "scale", Vector2(2.4, 2.4), 0.6)
	tw.tween_property(spr, "scale", Vector2(1.8, 1.8), 0.6)
	
	var col := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 45.0
	col.shape = c
	portal.add_child(col)
	
	var label := Label.new()
	label.text = "ABYSSAL RIFT [ENTER]"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-150, -60)
	label.custom_minimum_size = Vector2(300, 24)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(1.0, 0.6, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	portal.add_child(label)
	
	portal.body_entered.connect(func(body):
		if body.is_in_group("player"):
			SceneTransition.change_scene(
				"res://scenes/ui/citadel_cutscene.tscn"
			)
	)
	
	add_child(portal)
