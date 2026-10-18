extends Node

enum GameState { PLAYING, DIALOGUE, EMBARKED, GAME_OVER, VICTORY }

var game_state: GameState = GameState.PLAYING

var doom_timer: float = 30.0
const MAX_DOOM_TIME: float = 30.0
var doom_active: bool = false

var player_hp: int = 100
var player_max_hp: int = 100
var player_coins: int = 0

var has_armor: bool = false
var has_sword: bool = false
var is_epilogue: bool = false

# Checkpoint System
var checkpoint_scene: String = "res://scenes/world/town_tiny_swords.tscn"
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_name: String = "Haven Town"
var checkpoint_has_armor: bool = false
var checkpoint_has_sword: bool = false
var is_respawning: bool = false

signal doom_tick(time_remaining: float)
signal doom_expired
signal coins_changed(new_amount: int)
signal player_health_changed(hp: int, max_hp: int)
signal state_changed(new_state: GameState)
signal checkpoint_saved(checkpoint_name: String)
signal game_over_triggered
signal game_paused(is_paused: bool)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func start_doom_countdown(_duration: float = 30.0) -> void:
	pass

func stop_doom_countdown() -> void:
	pass

func take_damage(amount: int) -> void:
	player_hp = max(0, player_hp - amount)
	player_health_changed.emit(player_hp, player_max_hp)
	if player_hp == 0:
		set_game_state(GameState.GAME_OVER)

func heal(amount: int) -> void:
	player_hp = min(player_max_hp, player_hp + amount)
	player_health_changed.emit(player_hp, player_max_hp)

func add_coins(amount: int) -> void:
	player_coins += amount
	coins_changed.emit(player_coins)

func spend_coins(amount: int) -> bool:
	if player_coins >= amount:
		player_coins -= amount
		coins_changed.emit(player_coins)
		return true
	return false

func set_game_state(new_state: GameState) -> void:
	game_state = new_state
	state_changed.emit(new_state)

func reset_game() -> void:
	doom_timer = MAX_DOOM_TIME
	doom_active = false
	player_hp = player_max_hp
	player_coins = 0
	has_armor = false
	has_sword = false
	player_health_changed.emit(player_hp, player_max_hp)
	coins_changed.emit(player_coins)
	set_game_state(GameState.PLAYING)

func set_checkpoint(scene_path: String, pos: Vector2, cp_name: String = "") -> void:
	checkpoint_scene = scene_path
	checkpoint_position = pos
	if cp_name != "":
		checkpoint_name = cp_name
	checkpoint_has_armor = has_armor
	checkpoint_has_sword = has_sword
	checkpoint_saved.emit(checkpoint_name)

func is_checkpoint_for_current_scene(scene_path: String) -> bool:
	if checkpoint_scene == scene_path:
		return true
	if "town" in checkpoint_scene and "town" in scene_path:
		return true
	return false

func trigger_game_over() -> void:
	set_game_state(GameState.GAME_OVER)
	game_over_triggered.emit()

func respawn_at_checkpoint() -> void:
	is_respawning = true
	player_hp = player_max_hp
	has_armor = checkpoint_has_armor
	has_sword = checkpoint_has_sword
	player_health_changed.emit(player_hp, player_max_hp)
	set_game_state(GameState.PLAYING)
	if doom_active:
		doom_timer = MAX_DOOM_TIME
	get_tree().paused = false
	var st = get_node_or_null("/root/SceneTransition")
	if st and st.has_method("change_scene"):
		st.change_scene(checkpoint_scene, checkpoint_name, "Checkpoint Restored")
	else:
		get_tree().change_scene_to_file(checkpoint_scene)
