extends CanvasLayer

var overlay: ColorRect
var banner_root: PanelContainer
var board_panel: PanelContainer
var banner_container: VBoxContainer
var header_label: Label
var title_label: Label
var divider: ColorRect
var subtitle_label: Label
var banner_tween: Tween

var font_bold: FontFile = preload("res://art/fonts/Fonts/Kenney Future.ttf")
var font_reg: FontFile = preload("res://art/fonts/Fonts/Kenney Future Narrow.ttf")
var board_tex: Texture2D = preload("res://art/ui/rpg_expansion/PNG/panel_brown.png")

# Pause Menu UI
var pause_overlay: ColorRect
var pause_panel: PanelContainer
var controls_modal: PanelContainer

# Game Over UI
var game_over_overlay: ColorRect
var game_over_panel: PanelContainer
var game_over_cp_label: Label

# Checkpoint Toast UI
var toast_root: PanelContainer
var toast_label: Label
var toast_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	_build_pause_menu()
	_build_game_over_menu()
	_build_checkpoint_toast()
	GameManager.checkpoint_saved.connect(_on_checkpoint_saved)
	GameManager.game_over_triggered.connect(show_game_over)

func _build_ui() -> void:
	# Fullscreen black fade overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	# Outer Wooden Plaque with Drop Shadow (Mounted at Top Center, compact height)
	banner_root = PanelContainer.new()
	banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner_root.custom_minimum_size = Vector2(340, 0)
	banner_root.offset_top = 16.0
	banner_root.modulate.a = 0.0

	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.12, 0.09, 0.06, 0.95) # Dark aged wood backing
	shadow_style.border_color = Color(0.25, 0.17, 0.1, 1.0) # Carved outer rim
	shadow_style.set_border_width_all(2)
	shadow_style.set_corner_radius_all(6)
	shadow_style.shadow_color = Color(0, 0, 0, 0.75) # Deep drop shadow
	shadow_style.shadow_size = 8
	shadow_style.shadow_offset = Vector2(0, 3)
	shadow_style.content_margin_left = 2
	shadow_style.content_margin_right = 2
	shadow_style.content_margin_top = 2
	shadow_style.content_margin_bottom = 2
	banner_root.add_theme_stylebox_override("panel", shadow_style)
	add_child(banner_root)

	# RPG Wooden Sign Board Plaque
	board_panel = PanelContainer.new()
	board_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wood_style := StyleBoxTexture.new()
	wood_style.texture = board_tex
	wood_style.texture_margin_left = 12.0
	wood_style.texture_margin_top = 12.0
	wood_style.texture_margin_right = 12.0
	wood_style.texture_margin_bottom = 12.0
	board_panel.add_theme_stylebox_override("panel", wood_style)
	banner_root.add_child(board_panel)

	# Inner Margins (Compact so it never blocks characters below)
	var margin_cont := MarginContainer.new()
	margin_cont.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_cont.add_theme_constant_override("margin_left", 24)
	margin_cont.add_theme_constant_override("margin_right", 24)
	margin_cont.add_theme_constant_override("margin_top", 6)
	margin_cont.add_theme_constant_override("margin_bottom", 6)
	board_panel.add_child(margin_cont)

	# Text Container
	banner_container = VBoxContainer.new()
	banner_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_container.alignment = BoxContainer.ALIGNMENT_CENTER
	banner_container.add_theme_constant_override("separation", 1)
	margin_cont.add_child(banner_container)

	header_label = Label.new()
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_label.add_theme_font_override("font", font_bold)
	header_label.add_theme_font_size_override("font_size", 10)
	header_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	header_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.95))
	header_label.add_theme_constant_override("shadow_offset_x", 1)
	header_label.add_theme_constant_override("shadow_offset_y", 1)
	banner_container.add_child(header_label)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", font_bold)
	title_label.add_theme_font_size_override("font_size", 18)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.93, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 1.0))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.06, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	banner_container.add_child(title_label)

	divider = ColorRect.new()
	divider.custom_minimum_size = Vector2(140, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.color = Color(0.92, 0.76, 0.32, 0.85)
	banner_container.add_child(divider)

	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_override("font", font_reg)
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 0.95))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0.12, 0.08, 0.04, 0.85))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 1)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 1)
	banner_container.add_child(subtitle_label)

func change_scene(target_scene: String, area_title: String = "", area_subtitle: String = "") -> void:
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	get_tree().paused = false

	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if "cutscene" in target_scene:
		AudioManager.stop_music()

	get_tree().change_scene_to_file(target_scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(overlay, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween_in.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if area_title != "":
		show_area_banner(area_title, area_subtitle)

func show_area_banner(title: String, subtitle: String = "") -> void:
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()

	header_label.text = "— REALM OF HAVEN —"
	title_label.text = title.to_upper()
	subtitle_label.text = subtitle
	subtitle_label.visible = subtitle != ""
	divider.visible = subtitle != ""

	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", -12.0)

	banner_root.modulate.a = 0.0
	banner_root.offset_top = 6.0

	banner_tween = create_tween()
	# Fast slide down onto screen & fade in (0.3s)
	banner_tween.tween_property(banner_root, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	banner_tween.parallel().tween_property(banner_root, "offset_top", 16.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Fast hold (1.1s)
	banner_tween.tween_interval(1.1)
	# Slide up slightly & fade out (0.3s)
	banner_tween.tween_property(banner_root, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	banner_tween.parallel().tween_property(banner_root, "offset_top", 8.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func hide_area_banner() -> void:
	if not banner_root or banner_root.modulate.a == 0.0:
		return
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.tween_property(banner_root, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	banner_tween.parallel().tween_property(banner_root, "offset_top", 6.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func spawn_damage_number(world_pos: Vector2, amount: int, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.top_level = true
	label.global_position = world_pos + Vector2(randf_range(-14.0, 14.0), randf_range(-22.0, -12.0))
	label.z_index = 200
	if font_bold:
		label.add_theme_font_override("font", font_bold)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(label)
		var tw = label.create_tween()
		tw.set_parallel(true)
		tw.tween_property(label, "position:y", label.position.y - 28.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(label, "scale", Vector2(1.3, 1.3), 0.08)
		tw.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.12)
		tw.parallel().tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.2)
		tw.chain().tween_callback(label.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		_handle_pause_key()

func _handle_pause_key() -> void:
	if game_over_overlay and game_over_overlay.visible:
		return
	var cur_scene = get_tree().current_scene
	if not cur_scene:
		return
	var scene_path: String = cur_scene.scene_file_path
	if "title_screen" in scene_path or "cutscene" in scene_path:
		return
	toggle_pause()

func toggle_pause() -> void:
	if not pause_overlay:
		return
	var should_pause: bool = not get_tree().paused
	get_tree().paused = should_pause
	pause_overlay.visible = should_pause
	if should_pause:
		pause_overlay.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(pause_overlay, "modulate:a", 1.0, 0.15)
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
		if controls_modal:
			controls_modal.visible = false
		if pause_panel:
			pause_panel.visible = true
	else:
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)

func _create_styled_button(text: String, is_primary: bool = false) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_override("font", font_bold)
	btn.add_theme_font_size_override("font_size", 13 if is_primary else 11)
	btn.custom_minimum_size = Vector2(240, 36 if is_primary else 32)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.24, 0.16, 0.1, 0.96) if is_primary else Color(0.16, 0.11, 0.07, 0.94)
	normal_style.border_color = Color(0.9, 0.75, 0.3, 0.95) if is_primary else Color(0.48, 0.36, 0.22, 0.8)
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 12
	normal_style.content_margin_right = 12
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.38, 0.24, 0.12, 0.98) if is_primary else Color(0.28, 0.18, 0.1, 0.98)
	hover_style.border_color = Color(1.0, 0.88, 0.4, 1.0)
	hover_style.set_border_width_all(2)
	hover_style.set_corner_radius_all(4)
	hover_style.content_margin_left = 12
	hover_style.content_margin_right = 12
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.12, 0.08, 0.05, 1.0)
	pressed_style.border_color = Color(1.0, 0.92, 0.5, 1.0)
	pressed_style.set_border_width_all(2)
	pressed_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.6))
	btn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("shadow_offset_x", 1)
	btn.add_theme_constant_override("shadow_offset_y", 1)

	btn.mouse_entered.connect(func():
		AudioManager.play_sfx("res://audio/sfx/woosh1.ogg", -12.0)
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
	)
	return btn

func _build_pause_menu() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0, 0, 0, 0.72)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.add_child(center)

	pause_panel = PanelContainer.new()
	pause_panel.custom_minimum_size = Vector2(300, 320)
	var wood_style := StyleBoxTexture.new()
	wood_style.texture = board_tex
	wood_style.texture_margin_left = 14.0
	wood_style.texture_margin_top = 14.0
	wood_style.texture_margin_right = 14.0
	wood_style.texture_margin_bottom = 14.0
	pause_panel.add_theme_stylebox_override("panel", wood_style)
	center.add_child(pause_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	pause_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(title)

	var p_divider := ColorRect.new()
	p_divider.custom_minimum_size = Vector2(140, 2)
	p_divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p_divider.color = Color(0.92, 0.76, 0.32, 0.8)
	vbox.add_child(p_divider)

	var btn_resume := _create_styled_button("RESUME", true)
	btn_resume.pressed.connect(toggle_pause)
	vbox.add_child(btn_resume)

	var btn_cp := _create_styled_button("RESPAWN AT CHECKPOINT")
	btn_cp.pressed.connect(_on_pause_respawn_pressed)
	vbox.add_child(btn_cp)

	var btn_ctrl := _create_styled_button("CONTROLS")
	btn_ctrl.pressed.connect(_on_pause_controls_pressed)
	vbox.add_child(btn_ctrl)

	var btn_restart := _create_styled_button("RESTART AREA")
	btn_restart.pressed.connect(_on_pause_restart_pressed)
	vbox.add_child(btn_restart)

	var btn_title := _create_styled_button("RETURN TO TITLE")
	btn_title.pressed.connect(_on_pause_title_pressed)
	vbox.add_child(btn_title)

	# Controls Modal
	controls_modal = PanelContainer.new()
	controls_modal.visible = false
	controls_modal.custom_minimum_size = Vector2(340, 310)
	var ctrl_style := StyleBoxFlat.new()
	ctrl_style.bg_color = Color(0.1, 0.08, 0.06, 0.98)
	ctrl_style.border_color = Color(0.85, 0.7, 0.3, 1.0)
	ctrl_style.set_border_width_all(2)
	ctrl_style.set_corner_radius_all(6)
	controls_modal.add_theme_stylebox_override("panel", ctrl_style)
	center.add_child(controls_modal)

	var c_margin := MarginContainer.new()
	c_margin.add_theme_constant_override("margin_left", 16)
	c_margin.add_theme_constant_override("margin_right", 16)
	c_margin.add_theme_constant_override("margin_top", 14)
	c_margin.add_theme_constant_override("margin_bottom", 14)
	controls_modal.add_child(c_margin)

	var c_vbox := VBoxContainer.new()
	c_vbox.add_theme_constant_override("separation", 8)
	c_margin.add_child(c_vbox)

	var c_title := Label.new()
	c_title.text = "CONTROLS GUIDE"
	c_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_title.add_theme_font_override("font", font_bold)
	c_title.add_theme_font_size_override("font_size", 15)
	c_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	c_vbox.add_child(c_title)

	var ctrl_text := Label.new()
	ctrl_text.text = "• WASD / Arrows : Move\n• J / Left Click : Attack Combo\n• K / X / Right Click : Guard / Block\n• Space / Shift : Dodge Roll\n• L / Q / Middle Click : Leap Attack\n• E : Interact / Talk\n• Esc : Pause Game\n• F11 : Toggle Fullscreen"
	ctrl_text.add_theme_font_override("font", font_reg)
	ctrl_text.add_theme_font_size_override("font_size", 12)
	ctrl_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	c_vbox.add_child(ctrl_text)

	var btn_close_ctrl := _create_styled_button("BACK", true)
	btn_close_ctrl.pressed.connect(func():
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
		controls_modal.visible = false
		pause_panel.visible = true
	)
	c_vbox.add_child(btn_close_ctrl)

func _on_pause_controls_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	pause_panel.visible = false
	controls_modal.visible = true

func _on_pause_respawn_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", -4.0)
	toggle_pause()
	GameManager.respawn_at_checkpoint()

func _on_pause_restart_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	toggle_pause()
	var cur_scene = get_tree().current_scene
	if cur_scene:
		change_scene(cur_scene.scene_file_path)

func _on_pause_title_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	toggle_pause()
	change_scene("res://scenes/ui/title_screen.tscn")

func _build_game_over_menu() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.12, 0.02, 0.02, 0.88)
	game_over_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.visible = false
	game_over_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(game_over_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_overlay.add_child(center)

	game_over_panel = PanelContainer.new()
	game_over_panel.custom_minimum_size = Vector2(320, 270)
	var wood_style := StyleBoxTexture.new()
	wood_style.texture = board_tex
	wood_style.texture_margin_left = 14.0
	wood_style.texture_margin_top = 14.0
	wood_style.texture_margin_right = 14.0
	wood_style.texture_margin_bottom = 14.0
	game_over_panel.add_theme_stylebox_override("panel", wood_style)
	center.add_child(game_over_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	game_over_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var go_title := Label.new()
	go_title.text = "GAME OVER"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_override("font", font_bold)
	go_title.add_theme_font_size_override("font_size", 24)
	go_title.add_theme_color_override("font_color", Color(1.0, 0.28, 0.28))
	go_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	go_title.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(go_title)

	var go_sub := Label.new()
	go_sub.text = "The celestial light has faded..."
	go_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_sub.add_theme_font_override("font", font_reg)
	go_sub.add_theme_font_size_override("font_size", 12)
	go_sub.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	vbox.add_child(go_sub)

	game_over_cp_label = Label.new()
	game_over_cp_label.text = "Last Checkpoint: Haven Town"
	game_over_cp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_cp_label.add_theme_font_override("font", font_reg)
	game_over_cp_label.add_theme_font_size_override("font_size", 11)
	game_over_cp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	vbox.add_child(game_over_cp_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(160, 2)
	divider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	divider.color = Color(0.85, 0.25, 0.25, 0.85)
	vbox.add_child(divider)

	var btn_respawn := _create_styled_button("RESPAWN AT CHECKPOINT", true)
	btn_respawn.pressed.connect(_on_game_over_respawn_pressed)
	vbox.add_child(btn_respawn)

	var btn_title := _create_styled_button("RETURN TO TITLE")
	btn_title.pressed.connect(_on_game_over_title_pressed)
	vbox.add_child(btn_title)

func show_game_over() -> void:
	if not game_over_overlay:
		return
	get_tree().paused = true
	game_over_overlay.visible = true
	game_over_overlay.modulate.a = 0.0
	if game_over_cp_label:
		game_over_cp_label.text = "Last Checkpoint: %s" % GameManager.checkpoint_name
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", -2.0)
	var tw := create_tween()
	tw.tween_property(game_over_overlay, "modulate:a", 1.0, 0.5)

func hide_game_over() -> void:
	if game_over_overlay:
		game_over_overlay.visible = false
	get_tree().paused = false

func _on_game_over_respawn_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	hide_game_over()
	GameManager.respawn_at_checkpoint()

func _on_game_over_title_pressed() -> void:
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
	hide_game_over()
	change_scene("res://scenes/ui/title_screen.tscn")

func _build_checkpoint_toast() -> void:
	toast_root = PanelContainer.new()
	toast_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_root.custom_minimum_size = Vector2(280, 34)
	toast_root.offset_bottom = -20.0
	toast_root.modulate.a = 0.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.05, 0.95)
	style.border_color = Color(0.85, 0.72, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.8)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	toast_root.add_theme_stylebox_override("panel", style)
	add_child(toast_root)

	toast_label = Label.new()
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_override("font", font_bold)
	toast_label.add_theme_font_size_override("font_size", 11)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	toast_label.add_theme_constant_override("shadow_offset_x", 1)
	toast_label.add_theme_constant_override("shadow_offset_y", 1)
	toast_root.add_child(toast_label)

func _on_checkpoint_saved(cp_name: String) -> void:
	if not toast_root:
		return
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()

	toast_label.text = "CHECKPOINT SAVED — %s" % cp_name.to_upper()
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", -12.0)

	toast_root.modulate.a = 0.0
	toast_root.offset_bottom = -10.0

	toast_tween = create_tween()
	toast_tween.tween_property(toast_root, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	toast_tween.parallel().tween_property(toast_root, "offset_bottom", -20.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	toast_tween.tween_interval(1.8)
	toast_tween.tween_property(toast_root, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	toast_tween.parallel().tween_property(toast_root, "offset_bottom", -10.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


