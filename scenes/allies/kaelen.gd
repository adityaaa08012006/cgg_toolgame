extends CharacterBody2D
class_name KaelenCompanion

enum State { WAITING, DIALOGUE, FOLLOWING }
var current_state: State = State.WAITING

const DIR_DOWN: String = "down"
const DIR_UP: String = "up"
const DIR_LEFT: String = "left"
const DIR_RIGHT: String = "right"
var current_dir: String = DIR_DOWN

const PATH_BASE := "res://art/characters/adventurer/FREE_Adventurer 2D Pixel Art/Sprites"
var idle_textures: Dictionary = {}
var run_textures: Dictionary = {}
var atk_textures: Dictionary = {}

var anim_timer: float = 0.0
var frame_idx: int = 0
var player_in_interact_range: bool = false
var is_combat_attacking: bool = false
var combat_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_container: Control = $PromptContainer
@onready var interact_area: Area2D = $InteractArea

var callout_label: Label
var callout_timer: float = 0.0

signal kaelen_joined

func _ready() -> void:
	add_to_group("allies")
	_load_textures()
	_setup_callout_ui()

	if prompt_container:
		prompt_container.visible = false

	if interact_area:
		interact_area.body_entered.connect(_on_interact_body_entered)
		interact_area.body_exited.connect(_on_interact_body_exited)

func _setup_callout_ui() -> void:
	callout_label = Label.new()
	callout_label.visible = false
	callout_label.position = Vector2(-120, -52)
	callout_label.custom_minimum_size = Vector2(240, 24)
	callout_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	callout_label.add_theme_font_size_override("font_size", 12)
	callout_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	callout_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	callout_label.add_theme_constant_override("shadow_offset_x", 1)
	callout_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(callout_label)

func say_battle_callout(text: String) -> void:
	if not callout_label:
		return
	callout_label.text = text
	callout_label.visible = true
	callout_timer = 2.2
	AudioManager.play_sfx("res://audio/sfx/confirmation_001.ogg", -12.0)

func _load_textures() -> void:
	for d in [DIR_DOWN, DIR_UP, DIR_LEFT, DIR_RIGHT]:
		idle_textures[d] = load("%s/IDLE/idle_%s.png" % [PATH_BASE, d])
		run_textures[d] = load("%s/RUN/run_%s.png" % [PATH_BASE, d])
		atk_textures[d] = load("%s/ATTACK 1/attack 1_%s.png" % [PATH_BASE, d])

	if sprite:
		sprite.texture = idle_textures[DIR_DOWN]
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.WAITING and player_in_interact_range and event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue() -> void:
	current_state = State.DIALOGUE
	if prompt_container:
		prompt_container.visible = false

	var dlg_box = get_tree().get_first_node_in_group("dialogue_box")
	if dlg_box:
		var lines: Array[Dictionary] = [
			{"speaker": "Kaelen of Oakhaven", "text": "Halt, warrior! You bear the Sunfire Blade of Haven... Then Father Alden's prayer was heard."},
			{"speaker": "Kaelen of Oakhaven", "text": "I am Kaelen. My home village of Oakhaven was reduced to ash by the demon vanguard."},
			{"speaker": "Kaelen of Oakhaven", "text": "We cannot face the Demon Lord directly yet. His forward fortress is guarded by General Malidrax, the Ashen Dread."},
			{"speaker": "Kaelen of Oakhaven", "text": "Malidrax holds the seal to the inner domain. Together, our blades can bring him down."},
			{"speaker": "Kaelen of Oakhaven", "text": "Let us breach the Vanguard Gateway ahead and storm the citadel together!"}
		]
		dlg_box.start_dialogue(lines, _on_dialogue_finished)
	else:
		_on_dialogue_finished()

func _on_dialogue_finished() -> void:
	current_state = State.FOLLOWING
	QuestManager.quest_updated.emit("Advance with Kaelen to the Vanguard Gateway!")
	kaelen_joined.emit()

func _physics_process(delta: float) -> void:
	if GameManager.game_state == GameManager.GameState.DIALOGUE:
		velocity = Vector2.ZERO
		_animate_idle(delta)
		move_and_slide()
		return

	if callout_timer > 0.0:
		callout_timer -= delta
		if callout_timer <= 0.0 and callout_label:
			callout_label.visible = false

	if combat_cooldown > 0.0:
		combat_cooldown -= delta

	if current_state != State.FOLLOWING:
		_animate_idle(delta)
		return

	if is_combat_attacking:
		move_and_slide()
		return

	# Combat Target Priority
	var boss: Node2D = get_tree().get_first_node_in_group("boss") as Node2D
	if boss and ("current_state" in boss and boss.current_state == 7):
		boss = null
	if not boss:
		var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
		for e in enemies:
			if is_instance_valid(e) and e is Node2D and not ("current_state" in e and e.current_state == 7):
				boss = e as Node2D
				break

	if boss and global_position.distance_to(boss.global_position) < 320.0:
		_process_combat_ai(boss, delta)
		return
	elif is_combat_attacking:
		is_combat_attacking = false
		if sprite:
			sprite.texture = idle_textures.get(current_dir, idle_textures[DIR_DOWN])
			sprite.hframes = 8
			sprite.frame = 0
			sprite.modulate = Color.WHITE

	# Default: Follow Hero
	var hero: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if not hero:
		velocity = Vector2.ZERO
		_animate_idle(delta)
		return

	var dist: float = global_position.distance_to(hero.global_position)
	if dist > 65.0:
		var dir: Vector2 = (hero.global_position - global_position).normalized()
		_update_direction(dir)
		var hero_speed: float = 175.0
		if "speed" in hero:
			hero_speed = hero.speed
		velocity = dir * hero_speed
		move_and_slide()
		_animate_run(delta)
	else:
		velocity = Vector2.ZERO
		_animate_idle(delta)

func _process_combat_ai(target: Node2D, delta: float) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree() or ("current_state" in target and target.current_state == 7):
		is_combat_attacking = false
		return

	var hero: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var flank_pos := target.global_position + Vector2(65.0, 30.0)
	if hero:
		var hero_dir: Vector2 = (target.global_position - hero.global_position).normalized()
		flank_pos = target.global_position + Vector2(-hero_dir.y, hero_dir.x) * 60.0

	var dist_to_flank: float = global_position.distance_to(flank_pos)
	var dir_to_flank: Vector2 = (flank_pos - global_position).normalized()
	var dist_to_boss: float = global_position.distance_to(target.global_position)
	_update_direction((target.global_position - global_position).normalized())

	if dist_to_boss <= 65.0 and combat_cooldown <= 0.0:
		_perform_ally_attack(target)
	elif dist_to_flank > 15.0:
		velocity = dir_to_flank * 140.0
		move_and_slide()
		_animate_run(delta)
	else:
		velocity = Vector2.ZERO
		_animate_idle(delta)

func _perform_ally_attack(target: Node2D) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree() or ("current_state" in target and target.current_state == 7):
		return

	is_combat_attacking = true
	velocity = Vector2.ZERO
	combat_cooldown = 1.6

	var atk_tex: Texture2D = atk_textures.get(current_dir, atk_textures[DIR_DOWN])
	if sprite:
		sprite.texture = atk_tex
		sprite.hframes = 8
		sprite.frame = 0

	AudioManager.play_sfx("res://audio/sfx/sword1.ogg", -4.0)

	for i in range(8):
		if not is_instance_valid(target) or not target.is_inside_tree() or ("current_state" in target and target.current_state == 7):
			break
		if sprite:
			sprite.frame = i
		if i == 4 and target and target.has_method("take_damage") and global_position.distance_to(target.global_position) < 65.0:
			target.take_damage(10)
		await get_tree().create_timer(0.04).timeout

	is_combat_attacking = false
	if sprite:
		sprite.texture = idle_textures.get(current_dir, idle_textures[DIR_DOWN])
		sprite.hframes = 8
		sprite.frame = 0
		sprite.modulate = Color.WHITE

func take_damage(amount: int) -> void:
	AudioManager.play_sfx("res://audio/sfx/impactPunch_medium_000.ogg", -4.0)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 0.3, 0.3), 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _update_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		current_dir = DIR_RIGHT if dir.x > 0 else DIR_LEFT
	else:
		current_dir = DIR_DOWN if dir.y > 0 else DIR_UP

func _animate_run(delta: float) -> void:
	var target_tex: Texture2D = run_textures.get(current_dir, run_textures[DIR_DOWN])
	if sprite.texture != target_tex:
		sprite.texture = target_tex
		sprite.hframes = 8
		sprite.vframes = 1

	anim_timer += delta
	if anim_timer >= 0.09:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % 8
	sprite.frame = frame_idx

func _animate_idle(delta: float) -> void:
	var target_tex: Texture2D = idle_textures.get(current_dir, idle_textures[DIR_DOWN])
	if sprite.texture != target_tex:
		sprite.texture = target_tex
		sprite.hframes = 8
		sprite.vframes = 1

	anim_timer += delta
	if anim_timer >= 0.13:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % 8
	sprite.frame = frame_idx

func _on_interact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_state == State.WAITING:
		player_in_interact_range = true
		if prompt_container:
			prompt_container.visible = true

func _on_interact_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_interact_range = false
		if prompt_container:
			prompt_container.visible = false

