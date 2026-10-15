extends CharacterBody2D
class_name DemonLordNightborne

signal hp_changed(current: int, maximum: int)
signal phase_changed(phase_number: int)
signal defeated
signal final_stand_triggered

@export var max_hp: int = 650
var hp: int = 650

enum State {
	INTRO,
	IDLE,
	CHASE,
	TELEPORT_STRIKE,
	TRIPLE_COMBO,
	HELLFIRE_GEYSERS,
	VOID_NEEDLE_SPIRAL,
	STAGGERED,
	FINAL_STAND,
	DEAD
}

var current_state: State = State.INTRO
var phase: int = 1 # 1: 100%-60%, 2: 60%-10%, 3: Final Stand
var state_timer: float = 0.0
var anim_timer: float = 0.0
var frame_idx: int = 0
var is_invulnerable: bool = false

# Movement & Spacing
var speed: float = 125.0
var target: Node2D = null

# Animation rows on 23x5 spritesheet
const ROW_IDLE := 0
const ROW_RUN := 1
const ROW_ATTACK := 2
const ROW_HURT := 3
const ROW_DEATH := 4

var current_row: int = ROW_IDLE
var row_frame_count: int = 9

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_box: Area2D = $HitBox

var kaelen_spirit: Sprite2D = null
var ember_particles: CPUParticles2D = null

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	
	hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	add_to_group("demon_lord")
	
	sprite.texture = load("res://art/characters/enemies/NightBorne/NightBorne_crimson.png")
	sprite.hframes = 23
	sprite.vframes = 5
	sprite.frame = 0
	
	_setup_ember_aura()
	
	current_state = State.INTRO
	velocity = Vector2.ZERO
	_set_anim(ROW_IDLE, 9, 0.12)

func _setup_ember_aura() -> void:
	ember_particles = CPUParticles2D.new()
	ember_particles.amount = 20
	ember_particles.lifetime = 1.0
	ember_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ember_particles.emission_rect_extents = Vector2(16, 26)
	ember_particles.position = Vector2(0, -20)
	ember_particles.gravity = Vector2(0, -35)
	ember_particles.scale_amount_min = 2.0
	ember_particles.scale_amount_max = 3.5
	ember_particles.color = Color(3.0, 0.25, 0.15, 0.8)
	add_child(ember_particles)

func begin_combat() -> void:
	if current_state == State.INTRO:
		_spawn_afterimage()
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
		_enter_state(State.IDLE)

func _find_target() -> void:
	if not target or not is_instance_valid(target):
		var heroes = get_tree().get_nodes_in_group("player")
		if heroes.size() > 0:
			target = heroes[0]

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	_find_target()
	_update_animation(delta)
	
	state_timer -= delta
	
	match current_state:
		State.INTRO:
			velocity = Vector2.ZERO
			if target:
				_face_target()
				
		State.IDLE:
			if target and is_instance_valid(target):
				_face_target()
				var to_t = (target.global_position - global_position)
				var dist = to_t.length()
				if dist < 85.0:
					# Backstep spacing so boss never stays glued against the hero
					velocity = -to_t.normalized() * (speed * 0.85)
					_set_anim(ROW_RUN, 6, 0.08)
				else:
					velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			else:
				velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
				
			if state_timer <= 0:
				_choose_next_attack()
				
		State.CHASE:
			if target and is_instance_valid(target):
				_face_target()
				var to_t = (target.global_position - global_position)
				var dist = to_t.length()
				if dist > 115.0:
					velocity = to_t.normalized() * (speed * (1.15 if phase >= 2 else 1.0))
					_set_anim(ROW_RUN, 6, 0.08)
				else:
					velocity = Vector2.ZERO
					_choose_next_attack()
			else:
				velocity = Vector2.ZERO
				_enter_state(State.IDLE)
				
			if state_timer <= 0:
				_choose_next_attack()
				
		State.TELEPORT_STRIKE, State.TRIPLE_COMBO, State.HELLFIRE_GEYSERS, State.VOID_NEEDLE_SPIRAL:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			
		State.STAGGERED:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if state_timer <= 0:
				_enter_state(State.IDLE)
				
		State.FINAL_STAND:
			velocity = Vector2.ZERO
			
	move_and_slide()

func _face_target() -> void:
	if not target or not is_instance_valid(target):
		return
	if target.global_position.x < global_position.x:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _set_anim(row: int, count: int, frame_time: float) -> void:
	if current_row != row:
		current_row = row
		row_frame_count = count
		anim_timer = frame_time
		frame_idx = 0
		sprite.frame = current_row * 23

func _update_animation(delta: float) -> void:
	anim_timer -= delta
	if anim_timer <= 0:
		var speed_factor = 0.09
		if current_row == ROW_ATTACK:
			speed_factor = 0.065
		elif current_row == ROW_DEATH:
			speed_factor = 0.08
		elif current_row == ROW_HURT:
			speed_factor = 0.08
		elif current_row == ROW_RUN:
			speed_factor = 0.09
		else:
			speed_factor = 0.12
			
		anim_timer = speed_factor
		frame_idx += 1
		
		if current_row == ROW_DEATH:
			if frame_idx >= row_frame_count:
				frame_idx = row_frame_count - 1
		else:
			if frame_idx >= row_frame_count:
				frame_idx = 0
				
		sprite.frame = current_row * 23 + frame_idx

func _enter_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return
	current_state = new_state
	match new_state:
		State.IDLE:
			_set_anim(ROW_IDLE, 9, 0.12)
			state_timer = randf_range(0.5, 0.8) if phase >= 2 else randf_range(0.65, 1.0)
			
		State.CHASE:
			_set_anim(ROW_RUN, 6, 0.08)
			state_timer = 2.0
			
		State.TELEPORT_STRIKE:
			_execute_teleport_strike()
			
		State.TRIPLE_COMBO:
			_execute_triple_combo()
			
		State.HELLFIRE_GEYSERS:
			_execute_hellfire_geysers()
			
		State.STAGGERED:
			_set_anim(ROW_HURT, 5, 0.12)
			state_timer = 0.8

func _choose_next_attack() -> void:
	if current_state == State.DEAD:
		return
	if not target or not is_instance_valid(target):
		_enter_state(State.IDLE)
		return
		
	var dist = (target.global_position - global_position).length()
	var r = randf()
	
	if phase == 1:
		if dist > 240.0:
			if r < 0.6:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		elif dist > 115.0:
			if r < 0.4:
				_enter_state(State.HELLFIRE_GEYSERS)
			elif r < 0.75:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		else:
			_enter_state(State.TRIPLE_COMBO)
	else:
		# Phase 2 (Doomsday Overdrive)
		if dist > 200.0:
			if r < 0.6:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		elif dist > 115.0:
			if r < 0.5:
				_enter_state(State.HELLFIRE_GEYSERS)
			else:
				_enter_state(State.TELEPORT_STRIKE)
		else:
			if r < 0.6:
				_enter_state(State.TRIPLE_COMBO)
			else:
				_enter_state(State.HELLFIRE_GEYSERS)

# ── ATTACK 1: Teleport Strike (Flash Step) ──
func _execute_teleport_strike() -> void:
	if not target or current_state == State.DEAD:
		_enter_state(State.IDLE)
		return
		
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", 1.0)
	
	# Telegraph: Crimson glow before vanishing
	var pre_tw = create_tween()
	pre_tw.tween_property(sprite, "modulate", Color(3.5, 0.3, 0.2, 1.0), 0.22)
	await pre_tw.finished
	if current_state == State.DEAD:
		return
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.12)
	await tw.finished
	if current_state == State.DEAD or not is_instance_valid(target):
		return
		
	# Reappear with breathing room (115px away) instead of inside the player
	var dir_to_face = -1.0 if target.global_position.x > global_position.x else 1.0
	var offset = Vector2(dir_to_face * 115.0, randf_range(-15, 15))
	global_position = target.global_position + offset
	_face_target()
	
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh3.ogg", 1.0)
	var tw_in = create_tween()
	tw_in.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	await tw_in.finished
	if current_state == State.DEAD:
		return
	
	# Clear 0.45s wind-up telegraph
	_set_anim(ROW_IDLE, 9, 0.08)
	sprite.modulate = Color(3.5, 0.3, 0.2, 1.0)
	await get_tree().create_timer(0.45).timeout
	if current_state == State.DEAD:
		return
	sprite.modulate = Color.WHITE
	
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.25).timeout
	if current_state == State.DEAD:
		return
	_check_melee_hit(22, 100.0)
	await get_tree().create_timer(0.4).timeout
	
	if current_state != State.DEAD:
		_enter_state(State.IDLE)

# ── ATTACK 2: Triple Void Crescent Combo ──
func _execute_triple_combo() -> void:
	if current_state == State.DEAD:
		return
	_face_target()
	
	# Hit 1 Telegraph & Slash
	sprite.modulate = Color(3.0, 0.3, 0.2, 1.0)
	await get_tree().create_timer(0.38).timeout
	if current_state == State.DEAD:
		return
	sprite.modulate = Color.WHITE
	
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.25).timeout
	if current_state == State.DEAD:
		return
	_check_melee_hit(14, 90.0)
	
	# Brief cadence pause between swings
	await get_tree().create_timer(0.32).timeout
	if current_state == State.DEAD:
		return
	_face_target()
	
	# Hit 2: Cross Slash
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.25).timeout
	if current_state == State.DEAD:
		return
	_check_melee_hit(14, 90.0)
	
	# Hit 3: Heavy Crimson Cleave Wave with clear 0.55s charge
	await get_tree().create_timer(0.35).timeout
	if current_state == State.DEAD:
		return
	_face_target()
	
	var charge_tw = create_tween()
	charge_tw.tween_property(sprite, "modulate", Color(3.5, 0.5, 0.15, 1.0), 0.55)
	await charge_tw.finished
	if current_state == State.DEAD:
		return
	sprite.modulate = Color.WHITE
	
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.05)
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
	await get_tree().create_timer(0.22).timeout
	if current_state == State.DEAD:
		return
	_spawn_void_cleave_wave()
	
	# Punish window after combo
	await get_tree().create_timer(0.6).timeout
	if current_state != State.DEAD:
		_enter_state(State.IDLE)

# ── ATTACK 3: Hellfire Geysers ──
func _execute_hellfire_geysers() -> void:
	if current_state == State.DEAD:
		return
	_set_anim(ROW_IDLE, 9, 0.12)
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	
	var count = 4 if phase >= 2 else 3
	for i in range(count):
		if not is_instance_valid(target) or current_state == State.DEAD:
			break
		var pos = target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_spawn_geyser_rune(pos)
		await get_tree().create_timer(0.45).timeout
		if current_state == State.DEAD:
			return
		
	await get_tree().create_timer(0.65).timeout
	if current_state != State.DEAD:
		_enter_state(State.IDLE)

func _spawn_geyser_rune(pos: Vector2) -> void:
	if current_state == State.DEAD:
		return
	var circle = Node2D.new()
	circle.global_position = pos
	get_parent().add_child(circle)
	
	var warn = Line2D.new()
	warn.width = 3.5
	warn.default_color = Color(3.0, 0.3, 0.1, 0.9)
	var pts: Array[Vector2] = []
	for a in range(17):
		var angle = a * (TAU / 16.0)
		pts.append(Vector2(cos(angle), sin(angle)) * 40.0)
	warn.points = pts
	circle.add_child(warn)
	
	var tw = circle.create_tween()
	tw.tween_property(circle, "scale", Vector2(1.25, 1.25), 0.75)
	await tw.finished
	
	if is_instance_valid(circle):
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 1.0)
		var burst = Sprite2D.new()
		burst.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
		burst.modulate = Color(3.5, 0.35, 0.1, 0.95)
		burst.scale = Vector2(1.8, 1.8)
		circle.add_child(burst)
		
		if is_instance_valid(target) and target.has_method("take_damage"):
			if (target.global_position - pos).length() <= 45.0:
				target.take_damage(25)
				
		var btw = circle.create_tween()
		btw.tween_property(burst, "modulate:a", 0.0, 0.35)
		btw.tween_callback(circle.queue_free)



func _spawn_void_cleave_wave() -> void:
	if current_state == State.DEAD:
		return
	var wave = Area2D.new()
	wave.collision_layer = 0
	wave.collision_mask = 2
	
	var dir = -1.0 if sprite.flip_h else 1.0
	var spr = Sprite2D.new()
	spr.texture = load("res://art/ui/rpg_expansion/PNG/buttonLong_brown.png")
	spr.modulate = Color(3.5, 0.4, 0.1, 0.95)
	spr.scale = Vector2(0.3, 0.8)
	spr.rotation = PI / 2.0
	wave.add_child(spr)
	
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(24, 70)
	col.shape = box
	wave.add_child(col)
	
	get_parent().add_child(wave)
	wave.global_position = global_position + Vector2(dir * 30.0, -20)
	
	wave.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			if body.get("is_leaping"):
				return
			body.take_damage(28)
	)
	
	var tw = wave.create_tween()
	tw.tween_property(wave, "global_position:x", wave.global_position.x + dir * 380.0, 1.2)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 1.2)
	tw.tween_callback(wave.queue_free)

func _check_melee_hit(damage: int, reach: float) -> void:
	if not target or not is_instance_valid(target) or current_state == State.DEAD:
		return
	var dist = (target.global_position - global_position).length()
	if dist <= reach:
		if target.has_method("take_damage"):
			target.take_damage(damage)
			AudioManager.play_sfx("res://audio/sfx/impactPunch_heavy_000.ogg", 1.0)

func _spawn_afterimage() -> void:
	var img = Sprite2D.new()
	img.texture = sprite.texture
	img.hframes = sprite.hframes
	img.vframes = sprite.vframes
	img.frame = sprite.frame
	img.flip_h = sprite.flip_h
	img.global_position = sprite.global_position
	img.scale = sprite.scale
	img.modulate = Color(1.8, 0.2, 0.1, 0.6)
	get_parent().add_child(img)
	
	var tw = img.create_tween()
	tw.tween_property(img, "modulate:a", 0.0, 0.3)
	tw.tween_callback(img.queue_free)

func take_damage(amount: int, _attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD or is_invulnerable:
		return
		
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	if SceneTransition and SceneTransition.has_method("spawn_damage_number"):
		SceneTransition.spawn_damage_number(global_position + Vector2(0, -35), amount, Color(1.0, 0.85, 0.2))
	
	# Damage flash
	sprite.modulate = Color(2.5, 0.3, 0.3, 1.0)
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if hp <= 0:
		_execute_final_death()
		return
		
	if hp <= max_hp * 0.5 and phase == 1:
		phase = 2
		phase_changed.emit(2)
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
		_enter_state(State.IDLE)

func _execute_final_death() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	hp = 0
	hp_changed.emit(0, max_hp)
	
	# Disable collisions & processing immediately so no further attacks or locks can occur
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hit_box:
		hit_box.set_deferred("monitoring", false)
		hit_box.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	
	if is_instance_valid(kaelen_spirit):
		kaelen_spirit.queue_free()
	if is_instance_valid(ember_particles):
		ember_particles.emitting = false
		
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 3.0)
	_set_anim(ROW_DEATH, 23, 0.08)
	
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tw.finished
	
	defeated.emit()
	queue_free()
