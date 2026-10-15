extends CharacterBody2D
class_name Demon

@export var max_hp: int = 35
@export_enum("Red", "Black") var unit_color: String = "Red"
var hp: int = 35
var speed: float = 80.0
var attack_cooldown: float = 0.0

var tex_idle: Texture2D
var tex_run: Texture2D
var tex_atk1: Texture2D
var tex_atk2: Texture2D

var anim_timer: float = 0.0
var frame_idx: int = 0
var is_attacking: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_load_textures()
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)

func _load_textures() -> void:
	var prefix := "res://art/tiny_swords/Units/" + unit_color + " Units/Warrior/Warrior_"
	tex_idle = load(prefix + "Idle.png")
	tex_run  = load(prefix + "Run.png")
	tex_atk1 = load(prefix + "Attack1.png")
	tex_atk2 = load(prefix + "Attack2.png")
	if sprite:
		sprite.texture = tex_idle
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0

func _physics_process(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if is_attacking:
		return

	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		var dir: Vector2 = (player.global_position - global_position).normalized()

		if dir.x < 0:
			sprite.flip_h = true
		elif dir.x > 0:
			sprite.flip_h = false

		if dist < 50.0 and attack_cooldown <= 0.0:
			do_attack(player)
			return

		velocity = dir * speed
		if sprite.texture != tex_run:
			sprite.texture = tex_run
			sprite.hframes = 6
			sprite.vframes = 1
			frame_idx = 0
			anim_timer = 0.0

		anim_timer += delta
		if anim_timer >= 0.10:
			anim_timer = 0.0
			frame_idx = (frame_idx + 1) % 6
		sprite.frame = frame_idx

		move_and_slide()
	else:
		if sprite.texture != tex_idle:
			sprite.texture = tex_idle
			sprite.hframes = 8
			sprite.vframes = 1
			frame_idx = 0
			anim_timer = 0.0
		anim_timer += delta
		if anim_timer >= 0.12:
			anim_timer = 0.0
			frame_idx = (frame_idx + 1) % 8
		sprite.frame = frame_idx

func do_attack(target: Node2D) -> void:
	if is_attacking or not is_inside_tree() or hp <= 0:
		return
	is_attacking = true
	attack_cooldown = 1.1
	velocity = Vector2.ZERO
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", -4.0)

	var chosen_atk := tex_atk1 if randf() < 0.5 else tex_atk2
	sprite.texture = chosen_atk
	sprite.hframes = 4
	sprite.vframes = 1

	for f in range(4):
		if not is_inside_tree() or hp <= 0:
			return
		sprite.frame = f
		if f == 2 and is_instance_valid(target) and global_position.distance_to(target.global_position) < 58.0:
			if target.has_method("take_damage"):
				target.take_damage(15)
		await get_tree().create_timer(0.09).timeout

	if is_inside_tree() and hp > 0:
		frame_idx = 0
		anim_timer = 0.0
		sprite.texture = tex_idle
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0
		is_attacking = false

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO) -> void:
	hp -= amount
	if SceneTransition and SceneTransition.has_method("spawn_damage_number"):
		SceneTransition.spawn_damage_number(global_position + Vector2(0, -22), amount, Color(1.0, 1.0, 1.0))
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# Knockback
	var kb_origin := attacker_pos
	if kb_origin == Vector2.ZERO:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			kb_origin = player.global_position
	if kb_origin != Vector2.ZERO:
		var kb_dir: Vector2 = (global_position - kb_origin).normalized()
		velocity = kb_dir * 180.0
		move_and_slide()

	if hp <= 0:
		die()

func die() -> void:
	QuestManager.record_demon_kill()
	_spawn_coin_drop()
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/knifeSlice.ogg", -2.0)
	queue_free()

func _spawn_coin_drop() -> void:
	var coin_scene = preload("res://scenes/world/coin_pickup.tscn")
	var coin = coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().call_deferred("add_child", coin)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and attack_cooldown <= 0.0:
		do_attack(body)
