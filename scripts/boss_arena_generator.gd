extends Node2D
class_name BossArenaGenerator

const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 15
const TILE_SZ: int = 64

const PATH_TERRAIN := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png"
const PATH_ROCK1   := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"
const PATH_ROCK2   := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock2.png"
const PATH_ROCK3   := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock3.png"
const PATH_BUSH    := "res://art/tiny_swords/Terrain/Decorations/Bushes/Bushe1.png"
const PATH_TOWER   := "res://art/tiny_swords/Buildings/Red Buildings/Tower.png"

var ground_layer: TileMapLayer

func _ready() -> void:
	y_sort_enabled = true
	_generate_arena()

func _generate_arena() -> void:
	_setup_terrain_layers()
	_populate_boundaries()

func _setup_terrain_layers() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SZ, TILE_SZ)

	var color_tex: Texture2D = load(PATH_TERRAIN)
	var src := TileSetAtlasSource.new()
	src.texture = color_tex
	src.texture_region_size = Vector2i(TILE_SZ, TILE_SZ)
	for c in range(9):
		for r in range(6):
			src.create_tile(Vector2i(c, r))
	ts.add_source(src, 0)

	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -5
	add_child(ground_layer)

	# Fill plateau floor with central terrain tile (col 1, row 1)
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			# Slight variation for natural texture
			var tile_coords := Vector2i(1, 1)
			if (x + y * 3) % 7 == 0:
				tile_coords = Vector2i(2, 1)
			elif (x * 2 + y) % 9 == 0:
				tile_coords = Vector2i(1, 2)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coords)

func _populate_boundaries() -> void:
	# North Demon Towers
	_spawn_prop(PATH_TOWER, Vector2(180, 110), Vector2(1.2, 1.2), true)
	_spawn_prop(PATH_TOWER, Vector2(1100, 110), Vector2(1.2, 1.2), true)

	# Top and Bottom Boulder Barricades
	for c in range(1, MAP_WIDTH - 1, 2):
		var rock_tex := PATH_ROCK1 if c % 3 == 0 else (PATH_ROCK2 if c % 3 == 1 else PATH_ROCK3)
		_spawn_prop(rock_tex, Vector2(c * TILE_SZ + 32, 60), Vector2(1.4, 1.4), true)
		_spawn_prop(rock_tex, Vector2(c * TILE_SZ + 32, (MAP_HEIGHT - 1) * TILE_SZ + 20), Vector2(1.4, 1.4), true)

	# Left and Right Cliffs
	for r in range(1, MAP_HEIGHT - 1, 2):
		var rock_tex := PATH_ROCK2 if r % 2 == 0 else PATH_ROCK3
		_spawn_prop(rock_tex, Vector2(50, r * TILE_SZ + 32), Vector2(1.4, 1.4), true)
		_spawn_prop(rock_tex, Vector2((MAP_WIDTH - 1) * TILE_SZ + 20, r * TILE_SZ + 32), Vector2(1.4, 1.4), true)

	# Scorched Bushes around perimeter
	var bush_positions: Array[Vector2] = [
		Vector2(260, 120), Vector2(1020, 120),
		Vector2(120, 320), Vector2(1160, 320),
		Vector2(120, 680), Vector2(1160, 680),
		Vector2(320, 840), Vector2(960, 840)
	]
	for bp in bush_positions:
		_spawn_prop(PATH_BUSH, bp, Vector2(1.0, 1.0), true)

func _spawn_prop(tex_path: String, pos: Vector2, prop_scale: Vector2, has_collision: bool) -> void:
	var tex: Texture2D = load(tex_path)
	if not tex:
		return

	if has_collision:
		var sb := StaticBody2D.new()
		sb.position = pos
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.scale = prop_scale
		sb.add_child(sp)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = (tex.get_width() * prop_scale.x) * 0.28
		col.shape = shape
		col.position = Vector2(0, tex.get_height() * prop_scale.y * 0.2)
		sb.add_child(col)
		add_child(sb)
	else:
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.position = pos
		sp.scale = prop_scale
		add_child(sp)
