extends CharacterBody2D
class_name Hero

@export var speed: float = 175.0
@export var roll_speed: float = 280.0
@export var attack_damage: int = 50

enum State { IDLE, WALK, ATTACK, ROLL, HURT, DEAD }
var current_state: State = State.IDLE

var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_rolling: bool = false
var attack_cooldown: float = 0.0
var combo_step: int = 0
var combo_reset_timer: float = 0.0

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
		anim_timer += delta
		if anim_timer >= 0.08:
			anim_timer = 0.0
			current_frame_idx = (current_frame_idx + 1) % 14
		update_sprite_animation()
		move_and_slide()
		return

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_step = 0

	if not is_attacking and not is_rolling:
		var input_vector := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)

		if input_vector != Vector2.ZERO:
			input_vector = input_vector.normalized()
			facing_direction = input_vector
			velocity = input_vector * speed
			current_state = State.WALK

			if input_vector.x != 0.0:
				sprite.flip_h = (input_vector.x < 0.0)

			anim_timer += delta
			if anim_timer >= 0.09:
				anim_timer = 0.0
				current_frame_idx = (current_frame_idx + 1) % 8
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * 12.0 * delta)
			current_state = State.IDLE

			anim_timer += delta
			if anim_timer >= 0.08:
				anim_timer = 0.0
				current_frame_idx = (current_frame_idx + 1) % 14

		update_sprite_animation()

		# Attack action (J or Left Click)
		if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
			do_combo_attack()
		# Block / Magic action (K or Right Click)
		elif Input.is_action_just_pressed("cast_spell") and attack_cooldown <= 0.0:
			do_block_stance()
		# Roll action (Space or Shift)
		elif Input.is_action_just_pressed("ui_accept") and input_vector != Vector2.ZERO:
			do_roll(input_vector)

		move_and_slide()

func update_sprite_animation() -> void:
	if is_attacking or is_rolling:
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
		attack_damage = 40
		attack_cooldown = 0.28
		sfx_name = "res://audio/sfx/woosh1.ogg"
	elif combo_step == 2:
		atk_tex = TEX_ATK2
		total_frames = 9
		attack_damage = 55
		attack_cooldown = 0.32
		sfx_name = "res://audio/sfx/woosh2.ogg"
	else:
		atk_tex = TEX_ATK3
		total_frames = 11
		attack_damage = 80
		attack_cooldown = 0.45
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
	velocity = dir * roll_speed
	AudioManager.play_sfx("res://audio/sfx/woosh4.ogg", -2.0)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 2.0, 0.7), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	# 0.25 second evasion roll with i-frames
	var timer := 0.0
	while timer < 0.25:
		timer += get_physics_process_delta_time()
		move_and_slide()
		await get_tree().physics_frame

	is_rolling = false
	current_state = State.IDLE
	update_sprite_animation()

func do_block_stance() -> void:
	attack_cooldown = 0.6
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/metalClick.ogg")
	sprite.texture = TEX_BLOCK
	sprite.hframes = 6
	sprite.vframes = 1
	for frame_i in range(6):
		sprite.frame = frame_i
		await get_tree().create_timer(0.04).timeout
	update_sprite_animation()

func take_damage(amount: int) -> void:
	if is_rolling:
		return # Invincibility during dodge roll
	GameManager.take_damage(amount)
	AudioManager.play_sfx("res://audio/sfx/impactPunch_medium_000.ogg")
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		AudioManager.play_sfx("res://audio/kenney_rpg/Audio/knifeSlice.ogg", -4.0)
