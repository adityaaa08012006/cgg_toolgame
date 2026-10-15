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

func _ready() -> void:
	layer = 100
	_build_ui()

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
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

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
	label.add_theme_font_size_override("font_size", 13)
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


