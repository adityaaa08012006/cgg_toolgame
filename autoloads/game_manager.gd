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

signal doom_tick(time_remaining: float)
signal doom_expired
signal coins_changed(new_amount: int)
signal player_health_changed(hp: int, max_hp: int)
signal state_changed(new_state: GameState)

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

func _process(delta: float) -> void:
	if doom_active and doom_timer > 0.0:
		doom_timer -= delta
		doom_tick.emit(doom_timer)
		if doom_timer <= 0.0:
			doom_timer = 0.0
			doom_active = false
			doom_expired.emit()
			set_game_state(GameState.GAME_OVER)

func start_doom_countdown(duration: float = 30.0) -> void:
	doom_timer = duration
	doom_active = true
	doom_tick.emit(doom_timer)

func stop_doom_countdown() -> void:
	doom_active = false

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
