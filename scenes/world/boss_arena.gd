extends Node2D

@onready var dialogue_box: DialogueBox = $CanvasLayer/DialogueBox
@onready var hero: Hero = $Hero
@onready var boss: BossGeneral = $BossGeneral

# Tiny Swords Boss HUD
var boss_hud_container: Control
var boss_hp_bar: TextureProgressBar
var boss_title_label: Label

func _ready() -> void:
	AudioManager.play_music("res://audio/music/Infinite Descent.ogg", -4.0)
	SceneTransition.show_area_banner("The Ashen Crater", "Sanctum of General Gorgath")
	_build_tiny_swords_boss_hud()

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
	boss_hud_container.offset_top = 18.0
	$CanvasLayer.add_child(boss_hud_container)

	# Tiny Swords Boss Title Ribbon
	boss_title_label = Label.new()
	boss_title_label.text = "GENERAL GORGATH — DEMON VANGUARD"
	boss_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bold_font: FontFile = load("res://art/fonts/Fonts/SegoeUI-Bold.ttf")
	if bold_font:
		boss_title_label.add_theme_font_override("font", bold_font)
	boss_title_label.add_theme_font_size_override("font_size", 13)
	boss_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	boss_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	boss_title_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_title_label.add_theme_constant_override("shadow_offset_y", 1)
	boss_title_label.position = Vector2(-200, 0)
	boss_title_label.size = Vector2(400, 20)
	boss_hud_container.add_child(boss_title_label)

	# Tiny Swords BigBar Base & Fill TextureProgressBar
	boss_hp_bar = TextureProgressBar.new()
	var bar_base: Texture2D = load("res://art/tiny_swords/UI Elements/UI Elements/Bars/BigBar_Base.png")
	var bar_fill: Texture2D = load("res://art/tiny_swords/UI Elements/UI Elements/Bars/BigBar_Fill.png")

	boss_hp_bar.texture_under = bar_base
	boss_hp_bar.texture_progress = bar_fill
	boss_hp_bar.nine_patch_stretch = true
	boss_hp_bar.stretch_margin_left = 32
	boss_hp_bar.stretch_margin_right = 32
	boss_hp_bar.stretch_margin_top = 16
	boss_hp_bar.stretch_margin_bottom = 16

	boss_hp_bar.custom_minimum_size = Vector2(420, 36)
	boss_hp_bar.size = Vector2(420, 36)
	boss_hp_bar.position = Vector2(-210, 20)
	boss_hp_bar.max_value = boss.max_hp if boss else 550
	boss_hp_bar.value = boss_hp_bar.max_value
	boss_hp_bar.tint_progress = Color(0.95, 0.22, 0.22, 1.0)
	boss_hud_container.add_child(boss_hp_bar)

func _on_boss_hp_changed(curr: int, maximum: int) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = maximum
		var tw := create_tween()
		tw.tween_property(boss_hp_bar, "value", float(curr), 0.2).set_trans(Tween.TRANS_CUBIC)

func _trigger_boss_intro() -> void:
	dialogue_box.start_dialogue([
		{"speaker": "General Gorgath", "text": "Puny mortal! You dare enter my sanctum? Your skull shall be crushed beneath my blade!"}
	])

func _on_boss_defeated() -> void:
	if boss_hud_container:
		var tw := create_tween()
		tw.tween_property(boss_hud_container, "modulate:a", 0.0, 1.0)
		tw.tween_callback(boss_hud_container.queue_free)

	QuestManager.quest_updated.emit("General Gorgath defeated! The demon vanguard has fallen!")
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)

	# Spawn Doom Core Item in center
	var core := Sprite2D.new()
	core.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	core.modulate = Color(2.5, 0.8, 0.2, 1.0)
	core.position = Vector2(640, 480)
	core.scale = Vector2(1.6, 1.6)
	add_child(core)

	await get_tree().create_timer(1.2).timeout

	dialogue_box.start_dialogue([
		{"speaker": "Narrator", "text": "VICTORY! General Gorgath has fallen! The pathway to the Demon Lord's Citadel is now open!"}
	])
