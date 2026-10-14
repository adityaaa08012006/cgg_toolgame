extends Node2D
class_name MountainPassGenerator

const MAP_WIDTH_TILES: int = 20
const MAP_HEIGHT_TILES: int = 20
const TILE_SIZE: int = 64

const PATH_TERRAIN_COLOR3 := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png"
const PATH_KENNEY_TOWN    := "res://art/tiles/tiny-town/Tilemap/tilemap_packed.png"
const PATH_BLDG_TOWER     := "res://art/tiny_swords/Buildings/Blue Buildings/Tower.png"
const PATH_BLDG_CASTLE    := "res://art/tiny_swords/Buildings/Blue Buildings/Castle.png"
const PATH_TREE_PINE      := "res://art/tiny_swords/Terrain/Resources/Wood/Trees/Tree1.png"
const PATH_ROCK1          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"
const PATH_ROCK2          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock2.png"
const PATH_ROCK3          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock3.png"
const PATH_BUSH           := "res://art/tiny_swords/Terrain/Decorations/Bushes/Bushe1.png"

var ground_layer: TileMapLayer
var road_layer: TileMapLayer
var entities_node: Node2D

func _ready() -> void:
	y_sort_enabled = true
	generate_mountain_pass()

func generate_mountain_pass() -> void:
	_setup_tilemap_layers()
	_generate_mountain_ground()
	_generate_ashen_trail()
	_generate_vanguard_gateway()
	_generate_mountain_cliffs_and_foliage()

func _setup_tilemap_layers() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var color3_tex: Texture2D = load(PATH_TERRAIN_COLOR3)
	var src_color3 := TileSetAtlasSource.new()
	src_color3.texture = color3_tex
	src_color3.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for c in range(9):
		for r in range(6):
			src_color3.create_tile(Vector2i(c, r))
	ts.add_source(src_color3, 0)

	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -5
	add_child(ground_layer)

	var kenney_tex: Texture2D = load(PATH_KENNEY_TOWN)
	var ts_road := TileSet.new()
	ts_road.tile_size = Vector2i(16, 16)
	var src_road := TileSetAtlasSource.new()
	src_road.texture = kenney_tex
	src_road.texture_region_size = Vector2i(16, 16)
	for c in range(12):
		for r in range(11):
			src_road.create_tile(Vector2i(c, r))
	ts_road.add_source(src_road, 0)

	road_layer = TileMapLayer.new()
	road_layer.name = "RoadLayer"
	road_layer.tile_set = ts_road
	road_layer.scale = Vector2(2.0, 2.0)
	road_layer.z_index = -4
	add_child(road_layer)

	entities_node = Node2D.new()
	entities_node.name = "Entities"
	entities_node.y_sort_enabled = true
	add_child(entities_node)

func _generate_mountain_ground() -> void:
	for x in range(MAP_WIDTH_TILES):
		for y in range(MAP_HEIGHT_TILES):
			var tile_coord := Vector2i(1, 1)
			if (x * 7 + y * 13) % 4 == 0:
				tile_coord = Vector2i(1, 2)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coord)

func _generate_ashen_trail() -> void:
	# Main ashen path winding through the mountain pass (Cols 19-20, y=0 to 40)
	for y in range(4, 40):
		road_layer.set_cell(Vector2i(19, y), 0, Vector2i(7, 3))
		road_layer.set_cell(Vector2i(20, y), 0, Vector2i(7, 3))

	# Milestone / Camp clearing where Kaelen waits (Cols 17-23, Rows 21-23, y ≈ 700)
	for px in range(17, 23):
		for py in range(21, 24):
			road_layer.set_cell(Vector2i(px, py), 0, Vector2i(7, 3))

func _generate_vanguard_gateway() -> void:
	# Vanguard Citadel gateway across the north ridge
	_spawn_static_prop(PATH_BLDG_CASTLE, Vector2(640, 70), Vector2(280, 64), Vector2(0, 50))
	_spawn_static_prop(PATH_BLDG_TOWER, Vector2(490, 160), Vector2(80, 60), Vector2(0, 60))
	_spawn_static_prop(PATH_BLDG_TOWER, Vector2(790, 160), Vector2(80, 60), Vector2(0, 60))

func _generate_mountain_cliffs_and_foliage() -> void:
	# Dense mountain rock cliffs lining the west flank
	var west_rocks: Array[Vector2] = [
		Vector2(140, 200), Vector2(240, 320), Vector2(160, 480),
		Vector2(260, 620), Vector2(180, 780), Vector2(260, 940), Vector2(150, 1080)
	]
	for pos in west_rocks:
		_spawn_rock(pos)

	# Dense mountain rock cliffs lining the east flank
	var east_rocks: Array[Vector2] = [
		Vector2(1140, 200), Vector2(1040, 320), Vector2(1120, 480),
		Vector2(1020, 620), Vector2(1100, 780), Vector2(1020, 940), Vector2(1130, 1080)
	]
	for pos in east_rocks:
		_spawn_rock(pos)

	# Hardy mountain pines
	var pine_coords: Array[Vector2] = [
		Vector2(320, 240), Vector2(960, 240),
		Vector2(340, 520), Vector2(940, 520),
		Vector2(320, 840), Vector2(960, 840),
		Vector2(380, 1100), Vector2(900, 1100)
	]
	for pos in pine_coords:
		_spawn_pine(pos)

func _spawn_static_prop(tex_path: String, pos: Vector2, col_size: Vector2, col_offset: Vector2) -> Node2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(spr)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = col_size
	shape.shape = rect
	shape.position = col_offset
	body.add_child(shape)

	entities_node.add_child(body)
	return body

func _spawn_rock(pos: Vector2) -> Node2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(PATH_ROCK1)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.position = Vector2(0, -6)
	body.add_child(spr)

	var shape := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 14.0
	cap.height = 42.0
	shape.shape = cap
	shape.rotation_degrees = 90
	shape.position = Vector2(0, 2)
	body.add_child(shape)

	entities_node.add_child(body)
	return body

func _spawn_pine(pos: Vector2) -> Node2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(PATH_TREE_PINE)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 8
	spr.vframes = 1
	spr.position = Vector2(0, -60)
	body.add_child(spr)

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 16.0
	shape.shape = circ
	shape.position = Vector2(0, 8)
	body.add_child(shape)

	var timer := Timer.new()
	timer.wait_time = randf_range(0.12, 0.16)
	timer.autostart = true
	timer.timeout.connect(func():
		spr.frame = (spr.frame + 1) % 8
	)
	body.add_child(timer)

	entities_node.add_child(body)
	return body
