extends CharacterBody2D
class_name Hero

@export var speed: float = 175.0
@export var roll_speed: float = 280.0
@export var attack_damage: int = 50

enum State { IDLE, WALK, ATTACK, ROLL, BLOCK, HURT, DEAD }
var current_state: State = State.IDLE

var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_rolling: bool = false
var is_blocking: bool = false
var attack_cooldown: float = 0.0
var roll_cooldown: float = 0.0
var block_time: float = 0.0
var combo_step: int = 0
var combo_reset_timer: float = 0.0

var _prev_space: bool = false
var _prev_shift: bool = false

var anim_timer: float = 0.0
var current_frame_idx: int = 0

# Knight 2D Pixel Art v1.2 Sprites (Native frames: 112px wide x 96px high)
const TEX_IDLE = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/IDLE.png")       # 14 frames
const TEX_WALK = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/WALK.png")       # 8 frames
const TEX_RUN = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/RUN.png")         # 8 frames
const TEX_ATK1 = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/ATTACK 1.png")   # 8 frames
const TEX_ATK2 = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/ATTACK 2.png")   # 9 frames
const TEX_ATK3 = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/ATTACK 3.png")   # 11 frames
const TEX_BLOCK = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/BLOCK.png")     # 6 frames
const TEX_HURT = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/HURT.png")       # 8 frames
const TEX_DEATH = preload("res://art/characters/knight/FREE_Knight 2D Pixel Art v1.2/Sprites/DEATH.png")     # 15 frames

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player")
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if GameManager.game_state == GameManager.GameState.DIALOGUE:
		velocity = Vector2.ZERO
		current_state = State.IDLE
		is_blocking = false
		anim_timer += delta
		if anim_timer >= 0.08:
			anim_timer = 0.0
			current_frame_idx = (current_frame_idx + 1) % 14
		update_sprite_animation()
		move_and_slide()
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if roll_cooldown > 0.0:
		roll_cooldown -= delta

	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

	var space_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
	var shift_pressed: bool = Input.is_physical_key_pressed(KEY_SHIFT)
	var wants_dodge: bool = (
		Input.is_action_just_pressed("ui_accept")
		or (space_pressed and not _prev_space)
		or (shift_pressed and not _prev_shift)
	)
	_prev_space = space_pressed
	_prev_shift = shift_pressed

	if not is_attacking and not is_rolling:
		var input_vector := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)

		# Check Block/Guard Stance (Hold Right Click or K/X)
		var wants_block: bool = Input.is_action_pressed("cast_spell")
		if wants_block:
			if not is_blocking:
				is_blocking = true
				block_time = 0.0
				AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg", -4.0)
			block_time += delta
			current_state = State.BLOCK
		else:
			is_blocking = false

		# Dodge Roll Trigger
		if wants_dodge and roll_cooldown <= 0.0:
			var roll_dir: Vector2 = input_vector if input_vector != Vector2.ZERO else facing_direction
			do_roll(roll_dir.normalized())
			return

		# Movement Logic
		if input_vector != Vector2.ZERO:
			input_vector = input_vector.normalized()
			facing_direction = input_vector
			var current_speed: float = speed * 0.35 if is_blocking else speed
			velocity = input_vector * current_speed
			if not is_blocking:
				current_state = State.WALK

			if input_vector.x != 0.0:
				sprite.flip_h = (input_vector.x < 0.0)

			anim_timer += delta
			if anim_timer >= 0.09:
				anim_timer = 0.0
				current_frame_idx = (current_frame_idx + 1) % 8
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * 12.0 * delta)
			if not is_blocking:
				current_state = State.IDLE

			anim_timer += delta
			if anim_timer >= 0.08:
				anim_timer = 0.0
				current_frame_idx = (current_frame_idx + 1) % 14

		update_sprite_animation()

		# Attack action (J or Left Click) - only when not blocking
		if not is_blocking and Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
			do_combo_attack()

		move_and_slide()

func update_sprite_animation() -> void:
	if is_attacking or is_rolling:
		return

	if is_blocking:
		if sprite.texture != TEX_BLOCK:
			sprite.texture = TEX_BLOCK
			sprite.hframes = 6
			sprite.vframes = 1
		sprite.frame = 4 # Solid defensive guard frame
		return

	if current_state == State.WALK:
		if sprite.texture != TEX_RUN:
			sprite.texture = TEX_RUN
			sprite.hframes = 8
			sprite.vframes = 1
		sprite.frame = current_frame_idx % 8
	else:
		if sprite.texture != TEX_IDLE:
			sprite.texture = TEX_IDLE
			sprite.hframes = 14
			sprite.vframes = 1
		sprite.frame = current_frame_idx % 14

func do_combo_attack() -> void:
	is_attacking = true
	current_state = State.ATTACK
	velocity = Vector2.ZERO

	combo_step = (combo_step % 3) + 1
	combo_reset_timer = 0.7

	var atk_tex: Texture2D = TEX_ATK1
	var total_frames: int = 8
	var frame_dur: float = 0.038
	var sfx_name: String = "res://audio/sfx/knifeSlice.ogg"

	if combo_step == 1:
		atk_tex = TEX_ATK1
		total_frames = 8
		attack_damage = 16
		attack_cooldown = 0.26
		sfx_name = "res://audio/sfx/woosh1.ogg"
	elif combo_step == 2:
		atk_tex = TEX_ATK2
		total_frames = 9
		attack_damage = 22
		attack_cooldown = 0.30
		sfx_name = "res://audio/sfx/woosh2.ogg"
	else:
		atk_tex = TEX_ATK3
		total_frames = 11
		attack_damage = 32
		attack_cooldown = 0.42
		sfx_name = "res://audio/sfx/woosh3.ogg"

	AudioManager.play_sfx(sfx_name, -6.0)

	sprite.texture = atk_tex
	sprite.hframes = total_frames
	sprite.vframes = 1

	if attack_hitbox:
		attack_hitbox.position = Vector2(-28, -6) if sprite.flip_h else Vector2(28, -6)
		attack_hitbox.monitoring = true

	for frame_i in range(total_frames):
		sprite.frame = frame_i
		await get_tree().create_timer(frame_dur).timeout

	if attack_hitbox:
		attack_hitbox.monitoring = false

	is_attacking = false
	current_state = State.IDLE
	update_sprite_animation()

func do_roll(dir: Vector2) -> void:
	is_rolling = true
	current_state = State.ROLL
	roll_cooldown = 0.32
	velocity = dir * roll_speed
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", -2.0)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.4, 1.8, 2.5, 0.7), 0.08)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.14)

	# Evasion roll with i-frames & ghost trails
	var duration: float = 0.22
	var timer := 0.0
	var ghost_interval := 0.05
	var ghost_timer := 0.0

	while timer < duration:
		var dt: float = get_physics_process_delta_time()
		timer += dt
		ghost_timer += dt
		if ghost_timer >= ghost_interval:
			ghost_timer = 0.0
			_spawn_ghost_trail()
		move_and_slide()
		await get_tree().physics_frame

	is_rolling = false
	current_state = State.IDLE
	update_sprite_animation()

func _spawn_ghost_trail() -> void:
	if not sprite or not get_parent():
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.hframes = sprite.hframes
	ghost.vframes = sprite.vframes
	ghost.frame = sprite.frame
	ghost.flip_h = sprite.flip_h
	ghost.global_position = sprite.global_position
	ghost.scale = sprite.scale
	ghost.z_index = z_index - 1
	ghost.modulate = Color(0.4, 0.8, 1.6, 0.55)
	get_parent().add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.2)
	tween.tween_callback(ghost.queue_free)

func _spawn_block_spark() -> void:
	AudioManager.play_sfx("res://audio/sfx/hitHelmet1.ogg", -2.0)
	var flash_tween := create_tween()
	flash_tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.5, 1.0), 0.05)
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	var spark := Line2D.new()
	spark.width = 2.5
	spark.default_color = Color(1.0, 0.9, 0.45, 0.95)
	var pts: PackedVector2Array = []
	for i in range(10):
		var a: float = i * TAU / 9.0
		pts.append(Vector2(cos(a) * 16.0, sin(a) * 16.0))
	spark.points = pts
	spark.position = Vector2(14 if not sprite.flip_h else -14, -8)
	add_child(spark)

	var stween := spark.create_tween()
	stween.parallel().tween_property(spark, "scale", Vector2(1.8, 1.8), 0.14)
	stween.parallel().tween_property(spark, "modulate:a", 0.0, 0.14)
	stween.tween_callback(spark.queue_free)

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if is_rolling:
		return # 100% Invulnerability during dodge roll

	if is_blocking:
		_spawn_block_spark()
		# Guard pushback
		var push_dir: Vector2 = (global_position - attacker_pos).normalized() if attacker_pos != Vector2.ZERO else -facing_direction
		global_position += push_dir * 18.0

		if block_time < 0.25:
			# Perfect Guard / Parry: 0 damage
			return
		else:
			# Standard Block: 90% damage reduction (chip damage minimum 1)
			var chip: int = max(1, int(amount * 0.1))
			GameManager.take_damage(chip)
			return

	GameManager.take_damage(amount)
	AudioManager.play_sfx("res://audio/sfx/impactPunch_medium_000.ogg")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/knifeSlice.ogg", -4.0)
