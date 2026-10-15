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
	SHADOW_DASH,
	STAGGERED,
	FINAL_STAND,
	DEAD
}

var current_state: State = State.INTRO
var phase: int = 1 # 1: 100%-60%, 2: 60%-10%, 3: Final Stand
var state_timer: float = 0.0
var anim_timer: float = 0.0
var frame_idx: int = 0
var attack_combo_step: int = 0
var is_invulnerable: bool = false

# Movement
var speed: float = 130.0
var target: Node2D = null

# Animation rows on 23x5 spritesheet
# Row 0: Idle (9)
# Row 1: Run (6)
# Row 2: Attack (12)
# Row 3: Hurt (5)
# Row 4: Death (23)
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
var boss_banner_label: Label = null

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	add_to_group("demon_lord")
	
	sprite.texture = load("res://art/characters/enemies/NightBorne/NightBorne.png")
	sprite.hframes = 23
	sprite.vframes = 5
	sprite.frame = 0
	
	_setup_floating_label()
	
	current_state = State.INTRO
	state_timer = 2.0
	_set_anim(ROW_IDLE, 9, 0.12)

func _setup_floating_label() -> void:
	boss_banner_label = Label.new()
	boss_banner_label.text = ""
	boss_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_banner_label.add_theme_font_size_override("font_size", 14)
	boss_banner_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	boss_banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_banner_label.add_theme_constant_override("shadow_offset_x", 1)
	boss_banner_label.add_theme_constant_override("shadow_offset_y", 1)
	boss_banner_label.position = Vector2(-120, -75)
	boss_banner_label.custom_minimum_size = Vector2(240, 24)
	add_child(boss_banner_label)

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
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
			if target:
				_face_target()
			if state_timer <= 0:
				_choose_next_attack()
				
		State.CHASE:
			if target:
				_face_target()
				var to_t = (target.global_position - global_position)
				var dist = to_t.length()
				if dist > 60.0:
					velocity = to_t.normalized() * (speed * (1.25 if phase >= 2 else 1.0))
					_set_anim(ROW_RUN, 6, 0.08)
				else:
					velocity = Vector2.ZERO
					_enter_state(State.TRIPLE_COMBO)
			if state_timer <= 0:
				_choose_next_attack()
				
		State.TELEPORT_STRIKE:
			velocity = Vector2.ZERO
			# handled in coroutine
			
		State.TRIPLE_COMBO:
			velocity = velocity.move_toward(Vector2.ZERO, 400.0 * delta)
			
		State.HELLFIRE_GEYSERS:
			velocity = Vector2.ZERO
			
		State.VOID_NEEDLE_SPIRAL:
			velocity = Vector2.ZERO
			
		State.STAGGERED:
			velocity = velocity.move_toward(Vector2.ZERO, 250.0 * delta)
			if state_timer <= 0:
				_enter_state(State.IDLE)
				
		State.FINAL_STAND:
			velocity = Vector2.ZERO
			# Restrained by Kaelen's spirit
			
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
			speed_factor = 0.06
		elif current_row == ROW_DEATH:
			speed_factor = 0.08
		elif current_row == ROW_HURT:
			speed_factor = 0.07
		elif current_row == ROW_RUN:
			speed_factor = 0.08
		else:
			speed_factor = 0.11
			
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
			_set_anim(ROW_IDLE, 9, 0.11)
			state_timer = randf_range(0.4, 0.8) if phase >= 2 else randf_range(0.7, 1.3)
			
		State.CHASE:
			_set_anim(ROW_RUN, 6, 0.08)
			state_timer = randf_range(1.5, 2.5)
			
		State.TELEPORT_STRIKE:
			_execute_teleport_strike()
			
		State.TRIPLE_COMBO:
			_execute_triple_combo()
			
		State.HELLFIRE_GEYSERS:
			_execute_hellfire_geysers()
			
		State.VOID_NEEDLE_SPIRAL:
			_execute_void_needle_spiral()
			
		State.STAGGERED:
			_set_anim(ROW_HURT, 5, 0.1)
			state_timer = 1.0
			_show_banner("GUARD BROKEN!", Color(1.0, 0.8, 0.2))

func _choose_next_attack() -> void:
	if not target:
		_enter_state(State.IDLE)
		return
		
	var dist = (target.global_position - global_position).length()
	var r = randf()
	
	if phase == 1:
		if dist > 200.0:
			if r < 0.5:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		elif dist > 80.0:
			if r < 0.35:
				_enter_state(State.HELLFIRE_GEYSERS)
			elif r < 0.7:
				_enter_state(State.TELEPORT_STRIKE)
			else:
				_enter_state(State.CHASE)
		else:
			_enter_state(State.TRIPLE_COMBO)
	else:
		# Phase 2 (aggressive & bullet hell)
		if r < 0.25:
			_enter_state(State.TELEPORT_STRIKE)
		elif r < 0.50:
			_enter_state(State.VOID_NEEDLE_SPIRAL)
		elif r < 0.75:
			_enter_state(State.HELLFIRE_GEYSERS)
		else:
			_enter_state(State.TRIPLE_COMBO)

# ── ATTACK 1: Teleport Strike (Flash Step) ──
func _execute_teleport_strike() -> void:
	if not target:
		_enter_state(State.IDLE)
		return
		
	_show_banner("SHADOW BLINK!", Color(0.8, 0.3, 1.0))
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", 2.0)
	
	# Fade out
	var tw = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.15)
	await tw.finished
	
	if not is_instance_valid(target) or current_state == State.DEAD:
		return
		
	# Reappear 50px behind player
	var dir_to_face = -1.0 if target.global_position.x > global_position.x else 1.0
	var offset = Vector2(dir_to_face * 55.0, randf_range(-15, 15))
	global_position = target.global_position + offset
	_face_target()
	
	_spawn_afterimage()
	AudioManager.play_sfx("res://audio/sfx/woosh3.ogg", 2.0)
	var tw_in = create_tween()
	tw_in.tween_property(sprite, "modulate:a", 1.0, 0.1)
	await tw_in.finished
	
	# Immediate slash
	_set_anim(ROW_ATTACK, 12, 0.05)
	await get_tree().create_timer(0.3).timeout
	_check_melee_hit(24, 75.0)
	await get_tree().create_timer(0.35).timeout
	
	_enter_state(State.IDLE)

# ── ATTACK 2: Triple Void Crescent Combo ──
func _execute_triple_combo() -> void:
	_face_target()
	_show_banner("VOID CRESCENT!", Color(1.0, 0.2, 0.2))
	
	# Hit 1: Swift Slash
	_set_anim(ROW_ATTACK, 12, 0.05)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.25).timeout
	_check_melee_hit(15, 60.0)
	
	# Hit 2: Cross Slash
	await get_tree().create_timer(0.2).timeout
	_face_target()
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.05)
	AudioManager.play_sfx("res://audio/sfx/knifeSlice.ogg", 1.0)
	await get_tree().create_timer(0.25).timeout
	_check_melee_hit(15, 60.0)
	
	# Hit 3: Heavy Void Wave (leap-dodgable)
	await get_tree().create_timer(0.25).timeout
	_face_target()
	_show_banner("CLEAVE WAVE — LEAP [Q]!", Color(1.0, 0.9, 0.2))
	frame_idx = 0
	_set_anim(ROW_ATTACK, 12, 0.04)
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
	await get_tree().create_timer(0.2).timeout
	_spawn_void_cleave_wave()
	await get_tree().create_timer(0.4).timeout
	
	_enter_state(State.IDLE)

# ── ATTACK 3: Hellfire Geysers ──
func _execute_hellfire_geysers() -> void:
	_set_anim(ROW_IDLE, 9, 0.1)
	_show_banner("VOID GEYSERS!", Color(1.0, 0.3, 0.7))
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 2.0)
	
	var count = 5 if phase >= 2 else 3
	for i in range(count):
		if not is_instance_valid(target) or current_state == State.DEAD:
			break
		var pos = target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_spawn_geyser_rune(pos)
		await get_tree().create_timer(0.35).timeout
		
	await get_tree().create_timer(0.5).timeout
	_enter_state(State.IDLE)

func _spawn_geyser_rune(pos: Vector2) -> void:
	var circle = Node2D.new()
	circle.global_position = pos
	get_parent().add_child(circle)
	
	var warn = Line2D.new()
	warn.width = 3.0
	warn.default_color = Color(1.0, 0.1, 0.4, 0.8)
	var pts: Array[Vector2] = []
	for a in range(17):
		var angle = a * (TAU / 16.0)
		pts.append(Vector2(cos(angle), sin(angle)) * 36.0)
	warn.points = pts
	circle.add_child(warn)
	
	var tw = circle.create_tween()
	tw.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.6)
	await tw.finished
	
	if is_instance_valid(circle):
		# Detonate
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 1.0)
		var burst = Sprite2D.new()
		burst.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
		burst.modulate = Color(2.0, 0.2, 0.8, 0.9)
		burst.scale = Vector2(1.8, 1.8)
		circle.add_child(burst)
		
		# Check damage
		if is_instance_valid(target) and target.has_method("take_damage"):
			if (target.global_position - pos).length() <= 40.0:
				target.take_damage(28)
				
		var btw = circle.create_tween()
		btw.tween_property(burst, "modulate:a", 0.0, 0.3)
		btw.tween_callback(circle.queue_free)

# ── ATTACK 4: Void Needle Spiral (Phase 2) ──
func _execute_void_needle_spiral() -> void:
	_set_anim(ROW_IDLE, 9, 0.08)
	_show_banner("DOOMSDAY NEEDLES!", Color(0.6, 0.2, 1.0))
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/magic1.ogg", 3.0)
	
	var projectiles_count = 14
	var base_angle = randf() * TAU
	for p in range(projectiles_count):
		var angle = base_angle + p * (TAU / projectiles_count)
		_spawn_void_needle(Vector2(cos(angle), sin(angle)))
		
	await get_tree().create_timer(0.4).timeout
	
	# Second ring offset
	base_angle += (TAU / (projectiles_count * 2))
	for p in range(projectiles_count):
		var angle = base_angle + p * (TAU / projectiles_count)
		_spawn_void_needle(Vector2(cos(angle), sin(angle)))
		
	await get_tree().create_timer(0.7).timeout
	_enter_state(State.IDLE)

func _spawn_void_needle(dir: Vector2) -> void:
	var needle = Area2D.new()
	needle.collision_layer = 0
	needle.collision_mask = 2 # hits player
	needle.global_position = global_position + Vector2(0, -20)
	
	var spr = Sprite2D.new()
	spr.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_brown.png")
	spr.modulate = Color(1.8, 0.4, 2.5, 1.0)
	spr.scale = Vector2(0.35, 0.35)
	needle.add_child(spr)
	
	var shape = CollisionShape2D.new()
	var c = CircleShape2D.new()
	c.radius = 8.0
	shape.shape = c
	needle.add_child(shape)
	
	get_parent().add_child(needle)
	
	var speed_v = dir * 210.0
	var life = 2.5
	
	needle.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(16)
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
	spr.modulate = Color(3.0, 0.4, 0.8, 0.9)
	spr.scale = Vector2(0.25, 0.7)
	spr.rotation = PI / 2.0
	wave.add_child(spr)
	
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(24, 60)
	col.shape = box
	wave.add_child(col)
	
	get_parent().add_child(wave)
	
	wave.body_entered.connect(func(body):
		if body.is_in_group("player") and body.has_method("take_damage"):
			# Check if hero is in airborne leap
			if body.get("is_leaping"):
				return
			body.take_damage(32)
	)
	
	var tw = wave.create_tween()
	tw.tween_property(wave, "position:x", wave.position.x + dir * 320.0, 1.0)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 1.0)
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

func _show_banner(text: String, color: Color) -> void:
	if not boss_banner_label:
		return
	boss_banner_label.text = text
	boss_banner_label.modulate = color
	boss_banner_label.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(boss_banner_label, "modulate:a", 0.0, 1.2)

func take_damage(amount: int) -> void:
	if current_state == State.DEAD or is_invulnerable:
		return
		
	# In Final Stand, only Leap Strike or final attack kills
	if current_state == State.FINAL_STAND:
		_execute_final_death()
		return
		
	hp = max(0, hp - amount)
	hp_changed.emit(hp, max_hp)
	
	# Damage flash
	sprite.modulate = Color(2.5, 0.3, 0.3, 1.0)
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	
	# Phase transition checks
	if hp <= max_hp * 0.6 and phase == 1:
		phase = 2
		phase_changed.emit(2)
		_show_banner("PHASE 2: DOOMSDAY ASCENDANCE!", Color(1.0, 0.2, 0.5))
		AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 2.0)
		
	if hp <= max_hp * 0.1 and phase == 2:
		phase = 3
		phase_changed.emit(3)
		_enter_final_stand()
		return
		
	if randf() < 0.2 and current_state == State.IDLE:
		_set_anim(ROW_HURT, 5, 0.08)

func _enter_final_stand() -> void:
	current_state = State.FINAL_STAND
	velocity = Vector2.ZERO
	_set_anim(ROW_HURT, 5, 0.1)
	
	final_stand_triggered.emit()
	
	_show_banner("KAELEN'S SPIRIT AWAKENS!", Color(1.0, 0.9, 0.2))
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
		
	_show_banner("DOOMSDAY SEVERED!", Color(1.0, 0.95, 0.7))
	AudioManager.play_sfx("res://audio/sfx/explosionCrunch_000.ogg", 3.0)
	
	_set_anim(ROW_DEATH, 23, 0.08)
	
	# Death dissipation animation
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tw.finished
	
	defeated.emit()
