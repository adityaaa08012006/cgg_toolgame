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

# Textures from Tiny RPG Pack 02 Demon_A
const PATH_BASE := "res://art/characters/tiny_rpg_02/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A with shadows/"
var tex_idle: Texture2D
var tex_walk: Texture2D
var tex_atk1: Texture2D
var tex_atk2: Texture2D
var tex_hurt: Texture2D
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
	tex_idle  = load(PATH_BASE + "Demon_A_Idle.png")       # 6 frames (100x100)
	tex_walk  = load(PATH_BASE + "Demon_A_Walk.png")       # 8 frames (100x100)
	tex_atk1  = load(PATH_BASE + "Demon_A_Attack01.png")   # 7 frames (100x100)
	tex_atk2  = load(PATH_BASE + "Demon_A_Attack02.png")   # 7 frames (100x100)
	tex_hurt  = load(PATH_BASE + "Demon_A_Hurt.png")       # 4 frames (100x100)
	tex_death = load(PATH_BASE + "Demon_A_Death.png")      # 4 frames (100x100)

	if sprite:
		sprite.texture = tex_idle
		sprite.hframes = 6
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
		_play_anim(tex_idle, 6, 0.12, delta)
		move_and_slide()
		return

	# State Machine with Generous Telegraphs & Fair Pacing
	match current_state:
		State.WAITING:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 6, 0.12, delta)
			if state_timer <= 0.0:
				current_state = State.CHASE
				move_cooldown = 1.0

		State.CHASE:
			if move_cooldown > 0.0:
				move_cooldown -= delta

			var target := _get_combat_target()
			if not target:
				velocity = Vector2.ZERO
				_play_anim(tex_idle, 6, 0.12, delta)
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
				if dist < 65.0:
					_start_sweep_windup()
					return
				elif dist >= 65.0 and dist <= 160.0:
					_start_slam_windup(dir)
					return

			# Menacing pursuit walk
			velocity = dir * speed
			_play_anim(tex_walk, 8, 0.10, delta)
			move_and_slide()

		State.WINDUP_SWEEP:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk1
			sprite.hframes = 7
			sprite.frame = 1 # Talon raised back
			if state_timer <= 0.0:
				_execute_sweep()

		State.WINDUP_SLAM:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk2
			sprite.hframes = 7
			sprite.frame = 1 # Crouched charging hellfire
			if state_timer <= 0.0:
				_execute_slam()

		State.STAGGERED:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk2
			sprite.hframes = 7
			sprite.frame = 5 # Landed recovery pose
			if state_timer <= 0.0:
				current_state = State.RECOVERY
				state_timer = 1.2
				sprite.modulate = Color.WHITE

		State.RECOVERY:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 6, 0.14, delta)
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

# --- Move 1: Talon Rake (Blockable with Shield!) ---
func _start_sweep_windup() -> void:
	current_state = State.WINDUP_SWEEP
	state_timer = 0.75 # 0.75s reaction window
	AudioManager.play_sfx("res://audio/sfx/woosh1.ogg", -4.0)

	_callout_kaelen("He's lunging with his talons! Hold Right Click to block!")

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 1.8, 0.4), 0.2)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _execute_sweep() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.SWING_SWEEP
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", -2.0)

	sprite.texture = tex_atk1
	sprite.hframes = 7
	for i in range(1, 7):
		if current_state == State.DEAD:
			return
		sprite.frame = i
		if i == 3:
			_hit_sweep_target(16, 60.0)
		await get_tree().create_timer(0.05).timeout

	if current_state != State.DEAD:
		current_state = State.RECOVERY
		state_timer = 1.4

# --- Move 2: Hellfire Leap & Burst (Dodgeable, leaves him STAGGERED!) ---
func _start_slam_windup(dir: Vector2) -> void:
	current_state = State.WINDUP_SLAM
	state_timer = 0.95 # 0.95s windup with red ground indicator
	AudioManager.play_sfx("res://audio/sfx/woosh3.ogg", -2.0)

	_callout_kaelen("Hellfire burst! Dodge roll sideways!")

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(3.0, 0.3, 0.3), 0.25)
	tw.tween_property(sprite, "modulate", Color(1.8, 0.5, 0.5), 0.3)

func _execute_slam() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.SLAM_IMPACT
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)

	sprite.texture = tex_atk2
	sprite.hframes = 7
	for i in range(2, 5):
		if current_state == State.DEAD:
			return
		sprite.frame = i
		await get_tree().create_timer(0.045).timeout

	if current_state == State.DEAD:
		return

	_hit_slam_target(28, 70.0)

	# Demon overcommits and recovers from the ground impact!
	current_state = State.STAGGERED
	state_timer = 2.0
	sprite.frame = 5
	sprite.modulate = Color(0.7, 1.0, 2.0) # Glowing blue/gold stagger hue

	_callout_kaelen("He's wide open! Strike now, brother!")

func _hit_sweep_target(amount: int, reach: float) -> void:
	if current_state == State.DEAD:
		return
	var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var off := player.global_position - global_position
		if off.length() <= reach and face_dir.dot(off.normalized()) > 0.1:
			player.take_damage(amount, global_position)

	var kaelen: Node2D = get_tree().get_first_node_in_group("allies") as Node2D
	if kaelen and kaelen.has_method("take_damage"):
		var koff := kaelen.global_position - global_position
		if koff.length() <= reach and face_dir.dot(koff.normalized()) > 0.1:
			kaelen.take_damage(amount / 2)

func _hit_slam_target(amount: int, reach: float) -> void:
	if current_state == State.DEAD:
		return
	var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var off := player.global_position - global_position
		if off.length() <= reach and face_dir.dot(off.normalized()) > 0.1:
			player.take_damage(amount, global_position)

	var kaelen: Node2D = get_tree().get_first_node_in_group("allies") as Node2D
	if kaelen and kaelen.has_method("take_damage"):
		var koff := kaelen.global_position - global_position
		if koff.length() <= reach and face_dir.dot(koff.normalized()) > 0.1:
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
	sprite.hframes = 4
	for i in range(4):
		sprite.frame = i
		await get_tree().create_timer(0.14).timeout

func _callout_kaelen(text: String) -> void:
	var kaelen: Node2D = get_tree().get_first_node_in_group("allies") as Node2D
	if kaelen and kaelen.has_method("say_battle_callout"):
		kaelen.say_battle_callout(text)

func _draw() -> void:
	# Ground warning indicator during Hellfire Leap windup (scaled for 2.5 node scale)
	if current_state == State.WINDUP_SLAM:
		var face_dir := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
		var slam_center := face_dir * 28.0
		draw_circle(slam_center, 24.0, Color(1.0, 0.2, 0.1, 0.28))
		draw_arc(slam_center, 24.0, 0, TAU, 24, Color(1.0, 0.3, 0.1, 0.75), 1.8)

	# Floating Vulnerability text when staggered
	elif current_state == State.STAGGERED:
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(-45, -28), "VULNERABLE! (+50% DMG)", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.9, 0.2, 1.0))
