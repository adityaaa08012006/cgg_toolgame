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
	WINDUP_SPELL,
	CAST_SPELL,
	STAGGERED,
	RECOVERY,
	DEAD
}
var current_state: State = State.WAITING

var speed: float = 75.0
var move_cooldown: float = 1.8
var state_timer: float = 0.0

# Bringer of Death Sprite Sheets (140x93 native frames)
const PATH_BASE := "res://art/characters/enemies/Bringer-Of-Death/sheets/"
var tex_idle: Texture2D
var tex_walk: Texture2D
var tex_atk: Texture2D
var tex_cast: Texture2D
var tex_spell: Texture2D
var tex_hurt: Texture2D
var tex_death: Texture2D

var anim_timer: float = 0.0
var frame_idx: int = 0
var facing_left: bool = true

# Spell ground warning
var spell_warn_pos: Vector2 = Vector2.ZERO
var spell_warn_radius: float = 48.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var guard_break_label: Label

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	_load_textures()
	_setup_guard_break_label()
	current_state = State.WAITING
	state_timer = 1.5

func _setup_guard_break_label() -> void:
	guard_break_label = Label.new()
	var game_font: Font = load("res://art/fonts/Fonts/Kenney Future.ttf")
	if not game_font:
		game_font = ThemeDB.fallback_font
	guard_break_label.add_theme_font_override("font", game_font)
	guard_break_label.add_theme_font_size_override("font_size", 10)
	guard_break_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	guard_break_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	guard_break_label.add_theme_constant_override("shadow_offset_x", 1)
	guard_break_label.add_theme_constant_override("shadow_offset_y", 1)
	guard_break_label.text = "GUARD BROKEN! (+50% DMG)"
	guard_break_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guard_break_label.position = Vector2(-120, -55)
	guard_break_label.size = Vector2(240, 20)
	guard_break_label.visible = false
	add_child(guard_break_label)

func _load_textures() -> void:
	tex_idle  = load(PATH_BASE + "Idle.png")    # 8 frames
	tex_walk  = load(PATH_BASE + "Walk.png")    # 8 frames
	tex_atk   = load(PATH_BASE + "Attack.png")  # 10 frames
	tex_cast  = load(PATH_BASE + "Cast.png")    # 9 frames
	tex_spell = load(PATH_BASE + "Spell.png")   # 16 frames
	tex_hurt  = load(PATH_BASE + "Hurt.png")    # 3 frames
	tex_death = load(PATH_BASE + "Death.png")   # 10 frames

	if sprite:
		sprite.texture = tex_idle
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0
		_update_facing(true)

func _is_in_dialogue() -> bool:
	var gm = get_node_or_null("/root/GameManager")
	return gm != null and gm.get("game_state") == 1 # GameState.DIALOGUE

func _play_sfx(path: String, vol: float = 0.0) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx(path, vol)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if hit_invulnerable_timer > 0.0:
		hit_invulnerable_timer -= delta

	queue_redraw()

	if _is_in_dialogue():
		velocity = Vector2.ZERO
		_play_anim(tex_idle, 8, 0.12, delta)
		move_and_slide()
		return

	# Pure 1v1 Hero targeting
	var target: Node2D = get_tree().get_first_node_in_group("player") as Node2D

	match current_state:
		State.WAITING:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 8, 0.12, delta)
			if state_timer <= 0.0:
				current_state = State.CHASE
				move_cooldown = 1.20

		State.CHASE:
			if move_cooldown > 0.0:
				move_cooldown -= delta

			if not target:
				velocity = Vector2.ZERO
				_play_anim(tex_idle, 8, 0.12, delta)
				move_and_slide()
				return

			var dist: float = global_position.distance_to(target.global_position)
			var dir: Vector2 = (target.global_position - global_position).normalized()
			_update_facing(dir.x < 0)

			# Select attack based on distance
			if move_cooldown <= 0.0:
				if dist <= 110.0:
					_start_cleave_windup()
					return
				elif dist > 110.0 and dist <= 340.0:
					_start_spell_windup(target.global_position)
					return

			# Menacing slow march
			velocity = dir * speed
			_play_anim(tex_walk, 8, 0.11, delta)
			move_and_slide()

		State.WINDUP_SWEEP:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_atk
			sprite.hframes = 10
			sprite.frame = 1 # Scythe held back
			if state_timer <= 0.0:
				_execute_cleave()

		State.WINDUP_SPELL:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_cast, 9, 0.10, delta)
			if state_timer <= 0.0:
				_execute_spell()

		State.STAGGERED:
			state_timer -= delta
			velocity = Vector2.ZERO
			sprite.texture = tex_hurt
			sprite.hframes = 3
			sprite.frame = 1 # Reeling pose
			if state_timer <= 0.0:
				current_state = State.RECOVERY
				state_timer = 0.60
				sprite.modulate = Color.WHITE
				if guard_break_label:
					guard_break_label.visible = false

		State.RECOVERY:
			state_timer -= delta
			velocity = Vector2.ZERO
			_play_anim(tex_idle, 8, 0.12, delta)
			if state_timer <= 0.0:
				current_state = State.CHASE
				move_cooldown = 1.30
				queue_redraw()

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

func _update_facing(look_left: bool) -> void:
	facing_left = look_left
	sprite.flip_h = not look_left
	sprite.offset = Vector2(-36 if look_left else 36, -46)

# --- Move 1: Abyssal Scythe Cleave (Blockable with Shield!) ---
func _start_cleave_windup() -> void:
	current_state = State.WINDUP_SWEEP
	state_timer = 0.65 # Clear telegraph reaction window for parry/block
	_play_sfx("res://audio/sfx/woosh2.ogg", -2.0)

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 1.8, 0.4), 0.25)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.30)

func _execute_cleave() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.SWING_SWEEP
	_play_sfx("res://audio/sfx/knifeSlice.ogg", -2.0)

	sprite.texture = tex_atk
	sprite.hframes = 10
	for i in range(10):
		if current_state == State.DEAD:
			return
		sprite.frame = i
		if i == 4:
			_hit_cleave_target(22, 115.0)
		await get_tree().create_timer(0.045).timeout

	if current_state != State.DEAD:
		current_state = State.RECOVERY
		state_timer = 0.90

func play_cast_cutscene(_duration: float = 2.0) -> void:
	if sprite and tex_cast:
		sprite.texture = tex_cast
		sprite.hframes = 9
		sprite.frame = 4
		var tw := create_tween()
		tw.tween_property(sprite, "modulate", Color(2.2, 0.3, 2.5), 0.3)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)

# --- Move 2: Dark Eruption (Dodgeable, leaves him STAGGERED ONLY IF HE MISSES!) ---
func _start_spell_windup(target_pos: Vector2) -> void:
	current_state = State.WINDUP_SPELL
	state_timer = 1.05 # Ample ground warning window to roll away
	spell_warn_pos = target_pos
	_play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", -2.0)

	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(2.2, 0.3, 0.3), 0.35)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.40)

func _execute_spell() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.CAST_SPELL
	_play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)

	# Erupt spell pillar at warned position
	var target_pos := spell_warn_pos
	spell_warn_pos = Vector2.ZERO

	# Synchronous check: did the eruption hit the player?
	var player_hit: bool = false
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(target_pos) <= spell_warn_radius:
		player.take_damage(28, target_pos)
		player_hit = true

	# Fire visual pillar animation
	_spawn_spell_pillar(target_pos)

	if player_hit:
		# Attack CONNECTED: Boss maintains composure, recovery without guard break
		current_state = State.RECOVERY
		state_timer = 0.90
		sprite.texture = tex_idle
		sprite.hframes = 8
		sprite.frame = 0
		sprite.modulate = Color.WHITE
		if guard_break_label:
			guard_break_label.visible = false
	else:
		# Attack MISSED (Player dodged!): Boss overextends and suffers Guard Break Stagger!
		current_state = State.STAGGERED
		state_timer = 1.8
		sprite.texture = tex_hurt
		sprite.hframes = 3
		sprite.frame = 1
		sprite.modulate = Color(0.7, 1.0, 2.0) # Glowing blue/gold stagger hue
		if guard_break_label:
			guard_break_label.visible = true

func _spawn_spell_pillar(pos: Vector2) -> void:
	var pillar := Sprite2D.new()
	pillar.texture = tex_spell
	pillar.hframes = 16
	pillar.global_position = pos + Vector2(0, -30)
	pillar.scale = Vector2(2.0, 2.0)
	pillar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pillar.modulate = Color(1.8, 0.4, 0.4, 1.0)
	get_parent().add_child(pillar)

	var tw := create_tween()
	tw.tween_method(func(frame_val: int):
		if is_instance_valid(pillar):
			pillar.frame = frame_val
	, 0, 15, 0.52)
	tw.tween_callback(func():
		if is_instance_valid(pillar):
			pillar.queue_free()
	)

func _hit_cleave_target(amount: int, reach: float) -> void:
	if current_state == State.DEAD:
		return
	var face_dir := Vector2.LEFT if facing_left else Vector2.RIGHT
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var off := player.global_position - global_position
		if off.length() <= reach and face_dir.dot(off.normalized()) > 0.0:
			player.take_damage(amount, global_position)

func take_damage(amount: int, _attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return
	if _is_in_dialogue():
		return
	if hit_invulnerable_timer > 0.0:
		return
	hit_invulnerable_timer = 0.18

	var final_dmg: int = amount
	if current_state == State.STAGGERED:
		final_dmg = int(amount * 1.5) # +50% bonus damage when staggered
		_play_sfx("res://audio/sfx/impactPunch_heavy_000.ogg", -2.0)

	hp -= final_dmg
	hp_changed.emit(max(0, hp), max_hp)
	var num_col := Color(1.0, 0.9, 0.2) if current_state == State.STAGGERED else Color(1.0, 1.0, 1.0)
	if SceneTransition and SceneTransition.has_method("spawn_damage_number"):
		SceneTransition.spawn_damage_number(global_position + Vector2(0, -38), final_dmg, num_col)

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
	if guard_break_label:
		guard_break_label.visible = false
	queue_redraw()
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	var hitbox = get_node_or_null("HitBox")
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)

	defeated.emit()
	_play_sfx("res://audio/sfx/lowFrequency_explosion_000.ogg", 2.0)

	# 10-frame death dissolve
	sprite.texture = tex_death
	sprite.hframes = 10
	for i in range(10):
		sprite.frame = i
		await get_tree().create_timer(0.08).timeout

	# Fade remainder into shadow and queue_free
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)

func _draw() -> void:
	if current_state == State.DEAD:
		return

	# Ground warning rune for Dark Eruption
	if current_state == State.WINDUP_SPELL and spell_warn_pos != Vector2.ZERO:
		var local_warn := to_local(spell_warn_pos)
		draw_circle(local_warn, spell_warn_radius, Color(0.9, 0.1, 0.2, 0.25))
		draw_arc(local_warn, spell_warn_radius, 0, TAU, 32, Color(1.0, 0.2, 0.2, 0.85), 2.2)
