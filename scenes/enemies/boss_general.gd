extends CharacterBody2D
class_name BossGeneral

signal hp_changed(current: int, maximum: int)
signal defeated

@export var max_hp: int = 550
var hp: int = 550
var hit_invulnerable_timer: float = 0.0

enum State {
	WAITING,
	CHASE,
	WINDUP_SWEEP,
	SWING_SWEEP,
	WINDUP_SLAM,
	SLAM_IMPACT,
	STAGGERED,
	RECOVERY,
	DEAD
}
var current_state: State = State.WAITING

var speed: float = 65.0
var move_cooldown: float = 2.0
var state_timer: float = 0.0
var is_enraged: bool = false

# Textures from Tiny Swords Black Units Warrior
const PATH_BASE := "res://art/tiny_swords/Units/Black Units/Warrior/"
var tex_idle: Texture2D
var tex_walk: Texture2D
var tex_atk1: Texture2D
var tex_atk2: Texture2D
var tex_guard: Texture2D
var tex_death: Texture2D

var anim_timer: float = 0.0
var frame_idx: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	_load_textures()
	current_state = State.WAITING
	state_timer = 2.0 # 2 seconds initial breathing room

func _load_textures() -> void:
	tex_idle  = load(PATH_BASE + "Warrior_Idle.png")       # 8 frames (192x192)
	tex_walk  = load(PATH_BASE + "Warrior_Run.png")        # 6 frames (192x192)
	tex_atk1  = load(PATH_BASE + "Warrior_Attack1.png")    # 4 frames (192x192 - broadsword slash)
	tex_atk2  = load(PATH_BASE + "Warrior_Attack2.png")    # 4 frames (192x192 - leap ground smash)
	tex_guard = load(PATH_BASE + "Warrior_Guard.png")      # 6 frames (192x192 - shield guard stance)
	tex_death = load("res://art/tiny_swords/Particle FX/Explosion_01.png") # 8 frames (192x192)

	if sprite:
		sprite.texture = tex_idle
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if hit_invulnerable_timer > 0.0:
		hit_invulnerable_timer -= delta

	queue_redraw()

	if GameManager.game_state == GameManager.GameState.DIALOGUE:
		velocity = Vector2.ZERO
		_play_anim(tex_idle, 8, 0.12, delta)
		move_and_slide()
		return

	# State Machine with Generous Telegraphs & Fair Pacing
	match current_state:
		State.WAITING:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 8, 0.12, delta)
			if state_timer <= 0.0:
				current_state = State.CHASE
				move_cooldown = 1.0

		State.CHASE:
			if move_cooldown > 0.0:
				move_cooldown -= delta

			var target := _get_combat_target()
			if not target:
				velocity = Vector2.ZERO
				_play_anim(tex_idle, 8, 0.12, delta)
				move_and_slide()
				return

			var dist: float = global_position.distance_to(target.global_position)
			var dir: Vector2 = (target.global_position - global_position).normalized()

			if dir.x < 0:
				sprite.flip_h = true
			elif dir.x > 0:
				sprite.flip_h = false

			# Select attack with fair cooldown
			if move_cooldown <= 0.0:
				if dist < 85.0:
					_start_sweep_windup()
					return
				elif dist >= 85.0 and dist <= 190.0:
					_start_slam_windup(dir)
					return

			# Menacing pursuit walk
			velocity = dir * speed
			_play_anim(tex_walk, 6, 0.11, delta)
			move_and_slide()

		State.WINDUP_SWEEP:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk1
			sprite.hframes = 4
			sprite.frame = 0 # Blade raised back
			if state_timer <= 0.0:
				_execute_sweep()

		State.WINDUP_SLAM:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk2
			sprite.hframes = 4
			sprite.frame = 0 # Crouched charging plunge
			if state_timer <= 0.0:
				_execute_slam()

		State.STAGGERED:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_guard
			sprite.hframes = 6
			sprite.frame = 3 # Guard-broken staggered stance
			if state_timer <= 0.0:
				current_state = State.RECOVERY
				state_timer = 1.2
				sprite.modulate = Color.WHITE

		State.RECOVERY:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 8, 0.14, delta)
			if state_timer <= 0.0:
				current_state = State.CHASE
				move_cooldown = 1.5

func _play_anim(tex: Texture2D, total_frames: int, speed_dur: float, delta: float) -> void:
	if sprite.texture != tex:
		sprite.texture = tex
		sprite.hframes = total_frames
		sprite.frame = 0
		frame_idx = 0
		anim_timer = 0.0

	anim_timer += delta
	if anim_timer >= speed_dur:
		anim_timer = 0.0
		frame_idx = (frame_idx + 1) % total_frames
		sprite.frame = frame_idx

func _get_combat_target() -> Node2D:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		return player
	return get_tree().get_first_node_in_group("allies") as Node2D

# --- Move 1: Dread Broadsword Cleave (Blockable with Shield!) ---
func _start_sweep_windup() -> void:
	current_state = State.WINDUP_SWEEP
	state_timer = 0.80 # 0.80s reaction window
	AudioManager.play_sfx("res://audio/sfx/woosh1.ogg", -4.0)

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 1.8, 0.4), 0.2)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _execute_sweep() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.SWING_SWEEP
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", -2.0)

	sprite.texture = tex_atk1
	sprite.hframes = 4
	for i in range(4):
		if current_state == State.DEAD:
			return
		sprite.frame = i
		if i == 1:
			_hit_sweep_target(18, 90.0)
		await get_tree().create_timer(0.08).timeout

	if current_state != State.DEAD:
		current_state = State.RECOVERY
		state_timer = 1.3

# --- Move 2: Abyssal Leap Plunge (Dodgeable, leaves him STAGGERED!) ---
func _start_slam_windup(dir: Vector2) -> void:
	current_state = State.WINDUP_SLAM
	state_timer = 0.95 # 0.95s windup with red ground indicator
	AudioManager.play_sfx("res://audio/sfx/woosh3.ogg", -2.0)

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.3, 0.3), 0.25)
	tw.tween_property(sprite, "modulate", Color(1.8, 0.5, 0.5), 0.3)

func _execute_slam() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.SLAM_IMPACT
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)

	sprite.texture = tex_atk2
	sprite.hframes = 4
	for i in range(4):
		if current_state == State.DEAD:
			return
		sprite.frame = i
		if i == 2:
			_hit_slam_target(32, 105.0)
		await get_tree().create_timer(0.06).timeout

	if current_state == State.DEAD:
		return

	# General overcommits on the downward plunge and staggers!
	current_state = State.STAGGERED
	state_timer = 2.2
	sprite.texture = tex_guard
	sprite.hframes = 6
	sprite.frame = 3
	sprite.modulate = Color(0.7, 1.0, 2.0) # Glowing blue/gold stagger hue

func _hit_sweep_target(amount: int, reach: float) -> void:
	if current_state == State.DEAD:
		return
	var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var off := player.global_position - global_position
		if off.length() <= reach and face_dir.dot(off.normalized()) > 0.05:
			player.take_damage(amount, global_position)

	var kaelen: Node2D = get_tree().get_first_node_in_group("allies") as Node2D
	if kaelen and kaelen.has_method("take_damage"):
		var koff := kaelen.global_position - global_position
		if koff.length() <= reach and face_dir.dot(koff.normalized()) > 0.05:
			kaelen.take_damage(amount / 2)

func _hit_slam_target(amount: int, reach: float) -> void:
	if current_state == State.DEAD:
		return
	var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var off := player.global_position - global_position
		if off.length() <= reach and face_dir.dot(off.normalized()) > 0.05:
			player.take_damage(amount, global_position)

	var kaelen: Node2D = get_tree().get_first_node_in_group("allies") as Node2D
	if kaelen and kaelen.has_method("take_damage"):
		var koff := kaelen.global_position - global_position
		if koff.length() <= reach and face_dir.dot(koff.normalized()) > 0.05:
			kaelen.take_damage(amount / 2)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	if GameManager.game_state == GameManager.GameState.DIALOGUE:
		return
	if hit_invulnerable_timer > 0.0:
		return
	hit_invulnerable_timer = 0.20

	var final_dmg: int = amount
	if current_state == State.STAGGERED:
		final_dmg = int(amount * 1.5) # +50% bonus damage when staggered
		AudioManager.play_sfx("res://audio/sfx/impactPunch_heavy_000.ogg", -2.0)

	hp -= final_dmg
	hp_changed.emit(max(0, hp), max_hp)

	var flash_color := Color(3.0, 1.8, 0.4) if current_state == State.STAGGERED else Color(2.5, 0.4, 0.4)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", flash_color, 0.08)
	tw.tween_property(sprite, "modulate", Color(0.7, 1.0, 2.0) if current_state == State.STAGGERED else Color.WHITE, 0.1)

	if hp <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	remove_from_group("enemies")
	remove_from_group("boss")
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	defeated.emit()
	AudioManager.play_sfx("res://audio/sfx/lowFrequency_explosion_000.ogg", 2.0)

	sprite.texture = tex_death
	sprite.hframes = 8
	for i in range(8):
		sprite.frame = i
		await get_tree().create_timer(0.08).timeout

	sprite.texture = tex_guard
	sprite.hframes = 6
	sprite.frame = 4
	sprite.modulate = Color(0.65, 0.65, 0.65, 0.75)

func _draw() -> void:
	# Ground warning indicator during Abyssal Leap windup
	if current_state == State.WINDUP_SLAM:
		var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		var slam_center := face_dir * 45.0
		draw_circle(slam_center, 35.0, Color(1.0, 0.2, 0.1, 0.32))
		draw_arc(slam_center, 35.0, 0, TAU, 28, Color(1.0, 0.3, 0.1, 0.85), 2.2)

	# Floating Vulnerability text when staggered
	elif current_state == State.STAGGERED:
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(-60, -55), "GUARD BROKEN! (+50% DMG)", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.9, 0.2, 1.0))
