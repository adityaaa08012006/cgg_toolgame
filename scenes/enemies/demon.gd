extends CharacterBody2D
class_name Demon

@export var max_hp: int = 80
var hp: int = 80
var speed: float = 75.0
var attack_cooldown: float = 0.0

const TEX_IDLE = preload("res://art/characters/tiny_rpg_02/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A/Demon_A_Idle.png")
const TEX_WALK = preload("res://art/characters/tiny_rpg_02/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A/Demon_A_Walk.png")
const TEX_ATK = preload("res://art/characters/tiny_rpg_02/Tiny RPG Character Asset Pack 02 -Free Demon_A&Blood Monster_A/Characters(100x100 split)/Demon_A/Demon_A/Demon_A_Attack01.png")

var anim_timer: float = 0.0
var frame_idx: int = 0
var is_attacking: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	if hit_area:
		hit_area.body_entered.connect(_on_hit_area_body_entered)

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

		if dist < 48.0 and attack_cooldown <= 0.0:
			do_attack(player)
			return

		velocity = dir * speed
		if sprite.texture != TEX_WALK:
			sprite.texture = TEX_WALK
			sprite.hframes = 8
			sprite.vframes = 1

		anim_timer += delta
		if anim_timer >= 0.11:
			anim_timer = 0.0
			frame_idx = (frame_idx + 1) % 8
		sprite.frame = frame_idx

		move_and_slide()
	else:
		if sprite.texture != TEX_IDLE:
			sprite.texture = TEX_IDLE
			sprite.hframes = 6
			sprite.vframes = 1
		anim_timer += delta
		if anim_timer >= 0.14:
			anim_timer = 0.0
			frame_idx = (frame_idx + 1) % 6
		sprite.frame = frame_idx

func do_attack(target: Node2D) -> void:
	if is_attacking or not is_inside_tree() or hp <= 0:
		return
	is_attacking = true
	attack_cooldown = 1.2
	velocity = Vector2.ZERO
	AudioManager.play_sfx("res://audio/sfx/woosh2.ogg", -4.0)

	sprite.texture = TEX_ATK
	sprite.hframes = 7
	sprite.vframes = 1

	for f in range(7):
		if not is_inside_tree() or hp <= 0:
			return
		sprite.frame = f
		if f == 4 and is_instance_valid(target) and global_position.distance_to(target.global_position) < 54.0:
			if target.has_method("take_damage"):
				target.take_damage(15)
		await get_tree().create_timer(0.08).timeout

	if is_inside_tree() and hp > 0:
		frame_idx = 0
		anim_timer = 0.0
		sprite.texture = TEX_IDLE
		sprite.hframes = 6
		sprite.frame = 0
		is_attacking = false

func take_damage(amount: int) -> void:
	hp -= amount
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(3.5, 0.2, 0.2), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	# Knockback
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var kb_dir: Vector2 = (global_position - player.global_position).normalized()
		velocity = kb_dir * 180.0
		move_and_slide()

	if hp <= 0:
		die()

func die() -> void:
	QuestManager.record_demon_kill()
	# Spawn dropped coin
	_spawn_coin_drop()
	AudioManager.play_sfx("res://audio/kenney_rpg/Audio/knifeSlice.ogg", -2.0)
	queue_free()

func _spawn_coin_drop() -> void:
	var coin_scene = preload("res://scenes/world/coin_pickup.tscn")
	var coin = coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().add_child(coin)

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and attack_cooldown <= 0.0:
		do_attack(body)
