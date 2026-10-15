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
	REPOSITION,
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
var speed: float = 95.0
var target: Node2D = null
var reposition_dir: Vector2 = Vector2.ZERO

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

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	add_to_group("demon_lord")
	
	sprite.texture = load("res://art/characters/enemies/NightBorne/NightBorne.png")
	sprite.hframes = 23
	sprite.vframes = 5
	sprite.frame = 0
	
	current_state = State.INTRO
	state_timer = 2.0
	_set_anim(ROW_IDLE, 9, 0.12)

func _find_target() -> void:
	if not target or not is_instance_valid(target):
		var heroes = get_tree().get_nodes_in_group("player")
		if heroes.size() > 0:
			target = heroes[0]

func _physics_process(delta: float) -> void:
	_find_target()
	_update_animation(delta)
	
	if current_state == State.DEAD:
		return
		
	state_timer -= delta
	
	match current_state:
		State.INTRO:
			velocity = Vector2.ZERO
			if state_timer <= 0:
				_enter_state(State.IDLE)
				
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, 350.0 * delta)
			if target:
				_face_target()
			if state_timer <= 0:
				_choose_next_attack()
				
		State.CHASE:
			if target:
				_face_target()
				var to_t = (target.global_position - global_position)
				var dist = to_t.length()
				if dist > 85.0:
					velocity = to_t.normalized() * (speed * (1.15 if phase >= 2 else 1.0))
					_set_anim(ROW_RUN, 6, 0.09)
				else:
					velocity = Vector2.ZERO
					_enter_state(State.TRIPLE_COMBO)
			if state_timer <= 0:
				_enter_state(State.REPOSITION)
				
		State.REPOSITION:
			# Glides backward or circles Arthur to maintain tactical distance
			if target:
				_face_target()
				velocity = reposition_dir * (speed * 0.85)
				_set_anim(ROW_RUN, 6, 0.10)
			if state_timer <= 0:
				_enter_state(State.IDLE)
				
		State.TELEPORT_STRIKE, State.TRIPLE_COMBO, State.HELLFIRE_GEYSERS, State.VOID_NEEDLE_SPIRAL:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			
		State.STAGGERED:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if state_timer <= 0:
				_enter_state(State.REPOSITION)
				
		State.FINAL_STAND:
			velocity = Vector2.ZERO
			
	move_and_slide()

func _face_target() -> void:
	if not target:
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
	current_state = new_state
	match new_state:
		State.IDLE:
			_set_anim(ROW_IDLE, 9, 0.12)
			state_timer = randf_range(1.0, 1.6) if phase >= 2 else randf_range(1.4, 2.0)
			
		State.CHASE:
			_set_anim(ROW_RUN, 6, 0.09)
			state_timer = 2.0
			
		State.REPOSITION:
			_start_reposition()
			
		State.TELEPORT_STRIKE:
			_execute_teleport_strike()
			
		State.TRIPLE_COMBO:
			_execute_triple_combo()
			
		State.HELLFIRE_GEYSERS:
			_execute_hellfire_geysers()
			
		State.VOID_NEEDLE_SPIRAL:
			_execute_void_needle_spiral()
			
		State.STAGGERED:
			_set_anim(ROW_HURT, 5, 0.12)
			state_timer = 1.2

func _start_reposition() -> void:
	_set_anim(ROW_RUN, 6, 0.10)
	state_timer = randf_range(1.2, 1.8)
	if target:
		# Either back away directly or strafe sideways
		var away = (global_position - target.global_position).normalized()
		var perp = Vector2(-away.y, away.x) * (1.0 if randf() < 0.5 else -1.0)
		reposition_dir = (away * 0.7 + perp * 0.6).normalized()
	else:
		reposition_dir = Vector2.ZERO

func _choose_next_attack() -> void:
	if not target:
		_enter_state(State.IDLE)
		return
		
	var dist = (target.global_position - global_position).length()
	var r = randf()
	
	if phase == 1:
		if dist > 220.0:
			if r < 0.45:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		elif dist > 110.0:
			if r < 0.4:
				_enter_state(State.HELLFIRE_GEYSERS)
			elif r < 0.7:
				_enter_state(State.CHASE)
			else:
				_enter_state(State.REPOSITION)
		else:
			_enter_state(State.TRIPLE_COMBO)
	else:
		# Phase 2 (faster variety, clear windows)
		if dist > 180.0:
			if r < 0.4:
				_enter_state(State.VOID_NEEDLE_SPIRAL)
			elif r < 0.75:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		else:
			if r < 0.5:
				_enter_state(State.TRIPLE_COMBO)
			else:
				_enter_state(State.HELLFIRE_GEYSERS)

# ── ATTACK 1: Teleport Strike (Flash Step) ──
func _execute_teleport_strike() -> void:
	if not target:
		_enter_state(State.IDLE)
		return
		
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", 1.0)
	
	# Telegraph: Glow before vanishing
	var pre_tw = create_tween()
	pre_tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 3.0, 1.0), 0.25)
	await pre_tw.finished
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
	await tw.finished
	
	if not is_instance_valid(target) or current_state == State.DEAD:
		return
		
	# Reappear at healthy 80px distance with clear recovery
	var dir_to_face = -1.0 if target.global_position.x > global_position.x else 1.0
	var offset = Vector2(dir_to_face * 80.0, randf_range(-20, 20))
	global_position = target.global_position + offset
	_face_target()
	
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh3.ogg", 1.0)
	var tw_in = create_tween()
	tw_in.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	await tw_in.finished
	
	# Clear 0.55s wind-up telegraph so player can react and dodge
	_set_anim(ROW_IDLE, 9, 0.08)
	sprite.modulate = Color(2.5, 0.3, 0.8, 1.0)
	await get_tree().create_timer(0.55).timeout
	sprite.modulate = Color.WHITE
	
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.3).timeout
	_check_melee_hit(22, 90.0)
	await get_tree().create_timer(0.4).timeout
	
	_enter_state(State.REPOSITION)

# ── ATTACK 2: Triple Void Crescent Combo ──
func _execute_triple_combo() -> void:
	_face_target()
	
	# Hit 1 Telegraph & Slash
	sprite.modulate = Color(2.0, 0.5, 2.5, 1.0)
	await get_tree().create_timer(0.45).timeout
	sprite.modulate = Color.WHITE
	
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.28).timeout
	_check_melee_hit(14, 75.0)
	
	# Generous pause between swings
	await get_tree().create_timer(0.4).timeout
	_face_target()
	
	# Hit 2: Cross Slash
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.06)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.28).timeout
	_check_melee_hit(14, 75.0)
	
	# Hit 3: Heavy Void Wave with large 0.75s charge
	await get_tree().create_timer(0.45).timeout
	_face_target()
	
	# Heavy starlight charge visual
	var charge_tw = create_tween()
	charge_tw.tween_property(sprite, "modulate", Color(3.0, 0.8, 0.2, 1.0), 0.75)
	await charge_tw.finished
	sprite.modulate = Color.WHITE
	
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.05)
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
	await get_tree().create_timer(0.25).timeout
	_spawn_void_cleave_wave()
	
	# Generous recovery window: 1.2s opening
	await get_tree().create_timer(0.6).timeout
	_enter_state(State.REPOSITION)

# ── ATTACK 3: Hellfire Geysers ──
func _execute_hellfire_geysers() -> void:
	_set_anim(ROW_IDLE, 9, 0.12)
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	
	var count = 4 if phase >= 2 else 3
	for i in range(count):
		if not is_instance_valid(target) or current_state == State.DEAD:
			break
		var pos = target.global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
		_spawn_geyser_rune(pos)
		await get_tree().create_timer(0.55).timeout
		
	await get_tree().create_timer(0.8).timeout
	_enter_state(State.REPOSITION)

func _spawn_geyser_rune(pos: Vector2) -> void:
	var circle = Node2D.new()
	circle.global_position = pos
	get_parent().add_child(circle)
	
	var warn = Line2D.new()
	warn.width = 3.5
	warn.default_color = Color(1.0, 0.2, 0.5, 0.85)
	var pts: Array[Vector2] = []
	for a in range(17):
		var angle = a * (TAU / 16.0)
		pts.append(Vector2(cos(angle), sin(angle)) * 40.0)
	warn.points = pts
	circle.add_child(warn)
	
	# 0.9s delay gives player plenty of time to step out
	var tw = circle.create_tween()
	tw.tween_property(circle, "scale", Vector2(1.25, 1.25), 0.9)
	await tw.finished
	
	if is_instance_valid(circle):
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 1.0)
		var burst = Sprite2D.new()
		burst.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
		burst.modulate = Color(2.2, 0.2, 0.8, 0.9)
		burst.scale = Vector2(1.8, 1.8)
		circle.add_child(burst)
		
		if is_instance_valid(target) and target.has_method("take_damage"):
			if (target.global_position - pos).length() <= 45.0:
				target.take_damage(25)
				
		var btw = circle.create_tween()
		btw.tween_property(burst, "modulate:a", 0.0, 0.35)
		btw.tween_callback(circle.queue_free)

# ── ATTACK 4: Void Needle Spiral (Phase 2) ──
func _execute_void_needle_spiral() -> void:
	_set_anim(ROW_IDLE, 9, 0.10)
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	
	# Clear windup charge
	var ctw = create_tween()
	ctw.tween_property(sprite, "modulate", Color(2.5, 0.4, 3.5, 1.0), 0.6)
	await ctw.finished
	sprite.modulate = Color.WHITE
	
	var projectiles_count = 10
	var base_angle = randf() * TAU
	for p in range(projectiles_count):
		var angle = base_angle + p * (TAU / projectiles_count)
		_spawn_void_needle(Vector2(cos(angle), sin(angle)))
		
	await get_tree().create_timer(0.6).timeout
	
	# Second ring offset with wide gaps
	base_angle += (TAU / (projectiles_count * 2))
	for p in range(projectiles_count):
		var angle = base_angle + p * (TAU / projectiles_count)
		_spawn_void_needle(Vector2(cos(angle), sin(angle)))
		
	await get_tree().create_timer(1.2).timeout
	_enter_state(State.REPOSITION)

func _spawn_void_needle(dir: Vector2) -> void:
	var needle = Area2D.new()
	needle.collision_layer = 0
	needle.collision_mask = 2
	needle.global_position = global_position + Vector2(0, -20)
	
	var spr = Sprite2D.new()
	spr.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_brown.png")
	spr.modulate = Color(2.2, 0.5, 3.0, 1.0)
	spr.scale = Vector2(0.4, 0.4)
	needle.add_child(spr)
	
	var shape = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = 8.0
	shape.shape = c
	needle.add_child(shape)
	
	get_parent().add_child(needle)
	
	# 140px/s speed makes it comfortable to weave through
	var speed_v = dir * 140.0
	var life = 3.0
	
	needle.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(14)
			needle.queue_free()
	)
	
	var tw = needle.create_tween()
	tw.tween_property(needle, "position", needle.position + speed_v * life, life)
	tw.tween_callback(needle.queue_free)

func _spawn_void_cleave_wave() -> void:
	var wave = Area2D.new()
	wave.collision_layer = 0
	wave.collision_mask = 2
	wave.global_position = global_position + Vector2(0, -16)
	
	var dir = -1.0 if sprite.flip_h else 1.0
	var spr = Sprite2D.new()
	spr.texture = load("res://art/ui/rpg_expansion/PNG/buttonLong_brown.png")
	spr.modulate = Color(3.5, 0.4, 0.9, 0.9)
	spr.scale = Vector2(0.3, 0.8)
	spr.rotation = PI / 2.0
	wave.add_child(spr)
	
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(24, 70)
	col.shape = box
	wave.add_child(col)
	
	get_parent().add_child(wave)
	
	wave.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			if body.get("is_leaping"):
				return
			body.take_damage(28)
	)
	
	var tw = wave.create_tween()
	tw.tween_property(wave, "position:x", wave.position.x + dir * 340.0, 1.2)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 1.2)
	tw.tween_callback(wave.queue_free)

func _check_melee_hit(damage: int, reach: float) -> void:
	if not target or not is_instance_valid(target):
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
	img.scale = scale
	img.modulate = Color(0.8, 0.1, 1.2, 0.6)
	get_parent().add_child(img)
	
	var tw = img.create_tween()
	tw.tween_property(img, "modulate:a", 0.0, 0.3)
	tw.tween_callback(img.queue_free)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD or is_invulnerable:
		return
		
	if current_state == State.FINAL_STAND:
		_execute_final_death()
		return
		
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	
	# Damage flash
	sprite.modulate = Color(2.5, 0.3, 0.3, 1.0)
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	if hp <= max_hp * 0.6 and phase == 1:
		phase = 2
		phase_changed.emit(2)
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
		_enter_state(State.REPOSITION)
		
	if hp <= max_hp * 0.1 and phase == 2:
		phase = 3
		phase_changed.emit(3)
		_enter_final_stand()
		return

func _enter_final_stand() -> void:
	current_state = State.FINAL_STAND
	velocity = Vector2.ZERO
	_set_anim(ROW_HURT, 5, 0.12)
	
	final_stand_triggered.emit()
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 3.0)
	
	# Manifest Kaelen's golden astral spirit grappling NightBorne
	kaelen_spirit = Sprite2D.new()
	kaelen_spirit.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	kaelen_spirit.modulate = Color(3.0, 2.2, 0.5, 0.8)
	kaelen_spirit.scale = Vector2(2.5, 2.5)
	kaelen_spirit.position = Vector2(0, -20)
	add_child(kaelen_spirit)
	
	var tw = kaelen_spirit.create_tween().set_loops()
	tw.tween_property(kaelen_spirit, "scale", Vector2(2.8, 2.8), 0.4)
	tw.tween_property(kaelen_spirit, "scale", Vector2(2.3, 2.3), 0.4)

func _execute_final_death() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	hp = 0
	hp_changed.emit(0, max_hp)
	
	if is_instance_valid(kaelen_spirit):
		kaelen_spirit.queue_free()
		
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 3.0)
	_set_anim(ROW_DEATH, 23, 0.08)
	
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tw.finished
	
	defeated.emit()
