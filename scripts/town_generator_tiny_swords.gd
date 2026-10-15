extends Node2D
class_name TownGeneratorTinySwords

# World Constants
const MAP_WIDTH_TILES: int = 20
const MAP_HEIGHT_TILES: int = 20
const TILE_SIZE: int = 64 # Tiny Swords native tile size (20 * 64 = 1280x1280 px)

# Asset Paths - Tiny Swords
const PATH_TERRAIN_COLOR1 := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color1.png"
const PATH_TERRAIN_COLOR2 := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color2.png"

# Buildings
const PATH_BLDG_MONASTERY := "res://art/tiny_swords/Buildings/Blue Buildings/Monastery.png"
const PATH_BLDG_BARRACKS  := "res://art/tiny_swords/Buildings/Blue Buildings/Barracks.png"
const PATH_BLDG_HOUSE1    := "res://art/tiny_swords/Buildings/Blue Buildings/House1.png"
const PATH_BLDG_HOUSE2    := "res://art/tiny_swords/Buildings/Blue Buildings/House2.png"
const PATH_BLDG_HOUSE3    := "res://art/tiny_swords/Buildings/Blue Buildings/House3.png"
const PATH_BLDG_TOWER     := "res://art/tiny_swords/Buildings/Blue Buildings/Tower.png"
const PATH_BLDG_CASTLE    := "res://art/tiny_swords/Buildings/Blue Buildings/Castle.png"

# Foliage & Nature
const PATH_TREE1          := "res://art/tiny_swords/Terrain/Resources/Wood/Trees/Tree1.png"
const PATH_TREE2          := "res://art/tiny_swords/Terrain/Resources/Wood/Trees/Tree2.png"
const PATH_TREE3          := "res://art/tiny_swords/Terrain/Resources/Wood/Trees/Tree3.png"
const PATH_BUSH1          := "res://art/tiny_swords/Terrain/Decorations/Bushes/Bushe1.png"
const PATH_BUSH2          := "res://art/tiny_swords/Terrain/Decorations/Bushes/Bushe2.png"
const PATH_ROCK1          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"
const PATH_ROCK2          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock2.png"
const PATH_ROCK3          := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock3.png"

# Animals & Resources
const PATH_SHEEP_GRASS    := "res://art/tiny_swords/Terrain/Resources/Meat/Sheep/Sheep_Grass.png"
const PATH_SHEEP_IDLE     := "res://art/tiny_swords/Terrain/Resources/Meat/Sheep/Sheep_Idle.png"
const PATH_GOLD_STONE     := "res://art/tiny_swords/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png"

# Kenney Stepping Stones for authentic road texture
const PATH_KENNEY_TOWN    := "res://art/tiles/tiny-town/Tilemap/tilemap_packed.png"

var ground_layer: TileMapLayer
var road_layer: TileMapLayer
var buildings_node: Node2D
var nature_node: Node2D

func _ready() -> void:
	y_sort_enabled = true
	generate_town()

func generate_town() -> void:
	_setup_tilemap_layers()
	_generate_meadow_ground()
	_generate_cobblestone_roads()
	_generate_buildings()
	_generate_foliage_and_trees()
	_generate_wildlife_and_decorations()

func _setup_tilemap_layers() -> void:
	# 1. Base Meadow Layer (64x64 tiles)
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var color1_tex: Texture2D = load(PATH_TERRAIN_COLOR1)
	var src_color1 := TileSetAtlasSource.new()
	src_color1.texture = color1_tex
	src_color1.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for c in range(9):
		for r in range(6):
			src_color1.create_tile(Vector2i(c, r))
	ts.add_source(src_color1, 0)

	var color2_tex: Texture2D = load(PATH_TERRAIN_COLOR2)
	var src_color2 := TileSetAtlasSource.new()
	src_color2.texture = color2_tex
	src_color2.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for c in range(9):
		for r in range(6):
			src_color2.create_tile(Vector2i(c, r))
	ts.add_source(src_color2, 1)

	# Stepping stone road texture source (16x16 scaled 4x = 64x64 or 32x32)
	var kenney_tex: Texture2D = load(PATH_KENNEY_TOWN)
	var src_kenney := TileSetAtlasSource.new()
	src_kenney.texture = kenney_tex
	src_kenney.texture_region_size = Vector2i(16, 16)
	for c in range(12):
		for r in range(11):
			src_kenney.create_tile(Vector2i(c, r))
	ts.add_source(src_kenney, 2)

	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -5
	add_child(ground_layer)

	# 2. Road & Plaza Layer
	road_layer = TileMapLayer.new()
	road_layer.name = "RoadLayer"
	var ts_road := TileSet.new()
	ts_road.tile_size = Vector2i(16, 16)
	var src_road := TileSetAtlasSource.new()
	src_road.texture = kenney_tex
	src_road.texture_region_size = Vector2i(16, 16)
	for c in range(12):
		for r in range(11):
			src_road.create_tile(Vector2i(c, r))
	ts_road.add_source(src_road, 0)
	road_layer.tile_set = ts_road
	road_layer.scale = Vector2(2.0, 2.0)
	road_layer.z_index = -4
	add_child(road_layer)

	# 3. Y-Sorted Entities & Buildings
	buildings_node = Node2D.new()
	buildings_node.name = "Buildings"
	buildings_node.y_sort_enabled = true
	add_child(buildings_node)

	nature_node = Node2D.new()
	nature_node.name = "Nature"
	nature_node.y_sort_enabled = true
	add_child(nature_node)

func _generate_meadow_ground() -> void:
	for x in range(MAP_WIDTH_TILES):
		for y in range(MAP_HEIGHT_TILES):
			# Base seamless lush meadow grass
			var tile_coord := Vector2i(1, 1)
			# Natural flower scatter
			if (x * 7 + y * 11) % 5 == 0:
				tile_coord = Vector2i(6, 1) # Yellow wildflowers
			elif (x * 13 + y * 9) % 7 == 0:
				tile_coord = Vector2i(1, 2) # Textured blade grass

			ground_layer.set_cell(Vector2i(x, y), 0, tile_coord)

func _generate_cobblestone_roads() -> void:
	# 1. Main North-South Highway (Cols 19-20)
	# Connects seamlessly from the Church doorstep (Row 8, y=256) all the way through the South Gate (Row 39, y=1280)
	for y in range(8, 40):
		road_layer.set_cell(Vector2i(19, y), 0, Vector2i(7, 3))
		road_layer.set_cell(Vector2i(20, y), 0, Vector2i(7, 3))

	# 2. East-West Main Street (Rows 19-20, center y=640)
	for x in range(4, 36):
		road_layer.set_cell(Vector2i(x, 19), 0, Vector2i(7, 3))
		road_layer.set_cell(Vector2i(x, 20), 0, Vector2i(7, 3))

	# 3. North Avenue connecting Forge and Herbalist (Row 11)
	# Extends into Master Torren's forge yard (Cols 6-9) and Eldrin's herb garden (Cols 26-29)
	for x in range(6, 30):
		road_layer.set_cell(Vector2i(x, 11), 0, Vector2i(7, 3))
	# Direct doorstep path into Master Torren's Forge
	road_layer.set_cell(Vector2i(8, 10), 0, Vector2i(7, 3))
	road_layer.set_cell(Vector2i(9, 10), 0, Vector2i(7, 3))
	# Direct doorstep path into Eldrin's Cottage
	road_layer.set_cell(Vector2i(27, 10), 0, Vector2i(7, 3))
	road_layer.set_cell(Vector2i(28, 10), 0, Vector2i(7, 3))

	# 4. South Avenue connecting residential cottages (Row 26)
	for x in range(6, 30):
		road_layer.set_cell(Vector2i(x, 26), 0, Vector2i(7, 3))
	road_layer.set_cell(Vector2i(8, 25), 0, Vector2i(7, 3))
	road_layer.set_cell(Vector2i(27, 25), 0, Vector2i(7, 3))

	# 5. Sacred Central Altar Plaza (Cols 17 to 22, Rows 17 to 22 in 32px coords)
	for px in range(17, 23):
		for py in range(17, 23):
			road_layer.set_cell(Vector2i(px, py), 0, Vector2i(7, 3))

func _generate_buildings() -> void:
	# 0. Royal Castle Citadel (Towering majestic battlements behind the Monastery)
	_spawn_building(PATH_BLDG_CASTLE, Vector2(640, 80), Vector2(280, 64), Vector2(0, 50))

	# 1. North Church Sanctuary: Grand Tiny Swords Monastery (192x320 with open doorway)
	_spawn_monastery()

	# 2. Master Torren's Barracks & Forge (192x256)
	_spawn_building(PATH_BLDG_BARRACKS, Vector2(272, 300), Vector2(150, 60), Vector2(0, 60))

	# 3. Eldrin the Herbalist's Sanctuary (128x192)
	_spawn_building(PATH_BLDG_HOUSE1, Vector2(880, 300), Vector2(100, 50), Vector2(0, 45))

	# 4. South-West Village Cottage (128x192)
	_spawn_building(PATH_BLDG_HOUSE2, Vector2(272, 800), Vector2(100, 50), Vector2(0, 45))

	# 5. South-East Village Cottage (128x192)
	_spawn_building(PATH_BLDG_HOUSE3, Vector2(880, 800), Vector2(100, 50), Vector2(0, 45))

	# 6. Fortress Watchtowers (128x256)
	_spawn_building(PATH_BLDG_TOWER, Vector2(120, 160), Vector2(80, 60), Vector2(0, 60))
	_spawn_building(PATH_BLDG_TOWER, Vector2(1160, 160), Vector2(80, 60), Vector2(0, 60))
	_spawn_building(PATH_BLDG_TOWER, Vector2(120, 1100), Vector2(80, 60), Vector2(0, 60))
	_spawn_building(PATH_BLDG_TOWER, Vector2(1160, 1100), Vector2(80, 60), Vector2(0, 60))

	# South Gate Guardian Towers (flanking the gateway at x=640)
	_spawn_building(PATH_BLDG_TOWER, Vector2(490, 1120), Vector2(80, 60), Vector2(0, 60))
	_spawn_building(PATH_BLDG_TOWER, Vector2(790, 1120), Vector2(80, 60), Vector2(0, 60))

	# Stone curtain walls sealing South Gate perimeter
	for x in range(3, 15):
		road_layer.set_cell(Vector2i(x, 35), 0, Vector2i(1, 8))
		road_layer.set_cell(Vector2i(x, 36), 0, Vector2i(1, 9))
	for x in range(25, 37):
		road_layer.set_cell(Vector2i(x, 35), 0, Vector2i(1, 8))
		road_layer.set_cell(Vector2i(x, 36), 0, Vector2i(1, 9))

	# Stone curtain walls sealing North perimeter
	for x in range(3, 15):
		road_layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 8))
		road_layer.set_cell(Vector2i(x, 3), 0, Vector2i(1, 9))
	for x in range(25, 37):
		road_layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 8))
		road_layer.set_cell(Vector2i(x, 3), 0, Vector2i(1, 9))

func _spawn_building(tex_path: String, pos: Vector2, col_size: Vector2, col_offset: Vector2) -> Node2D:
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

	buildings_node.add_child(body)
	return body

func _spawn_monastery() -> Node2D:
	var body := StaticBody2D.new()
	body.position = Vector2(640, 200)
	body.collision_layer = 1
	body.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(PATH_BLDG_MONASTERY)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(spr)

	# Left wing collision wall
	var shape_l := CollisionShape2D.new()
	var rect_l := RectangleShape2D.new()
	rect_l.size = Vector2(56, 64)
	shape_l.shape = rect_l
	shape_l.position = Vector2(-58, 70)
	body.add_child(shape_l)

	# Right wing collision wall
	var shape_r := CollisionShape2D.new()
	var rect_r := RectangleShape2D.new()
	rect_r.size = Vector2(56, 64)
	shape_r.shape = rect_r
	shape_r.position = Vector2(58, 70)
	body.add_child(shape_r)

	# Back interior wall (behind doorway so player cannot clip through back of church)
	var shape_b := CollisionShape2D.new()
	var rect_b := RectangleShape2D.new()
	rect_b.size = Vector2(60, 24)
	shape_b.shape = rect_b
	shape_b.position = Vector2(0, 48)
	body.add_child(shape_b)

	buildings_node.add_child(body)
	return body

func _generate_foliage_and_trees() -> void:
	# North Churchyard Groves (Animated wind-swaying trees)
	var tree_coords: Array[Vector2] = [
		Vector2(160, 440), Vector2(400, 160), Vector2(880, 160), Vector2(1120, 440),
		Vector2(180, 640), Vector2(1100, 640),
		Vector2(160, 960), Vector2(420, 980), Vector2(860, 980), Vector2(1120, 960)
	]
	for i in range(tree_coords.size()):
		var t_pos: Vector2 = tree_coords[i]
		var path := PATH_TREE1 if i % 2 == 0 else PATH_TREE2
		_spawn_animated_tree(path, t_pos)

	# Lush Flower Bushes around Herbalist & Residences
	var bush_coords: Array[Vector2] = [
		Vector2(810, 360), Vector2(950, 360), Vector2(880, 220), # Eldrin's herb garden
		Vector2(200, 350), Vector2(340, 350),                     # Smithy yard
		Vector2(200, 850), Vector2(340, 850),                     # SW cottage
		Vector2(810, 850), Vector2(950, 850)                      # SE cottage
	]
	for i in range(bush_coords.size()):
		var b_pos: Vector2 = bush_coords[i]
		var b_path := PATH_BUSH1 if i % 2 == 0 else PATH_BUSH2
		_spawn_animated_bush(b_path, b_pos)

func _spawn_animated_tree(tex_path: String, pos: Vector2) -> Node2D:
	var tree_root := StaticBody2D.new()
	tree_root.position = pos
	tree_root.collision_layer = 1
	tree_root.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 8
	spr.vframes = 1
	spr.position = Vector2(0, -60) # Y-sort anchor at base of trunk
	tree_root.add_child(spr)

	# Base trunk collision
	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 16.0
	shape.shape = circ
	shape.position = Vector2(0, 10)
	tree_root.add_child(shape)

	# Create subtle wind animation loop
	var timer := Timer.new()
	timer.wait_time = randf_range(0.12, 0.16)
	timer.autostart = true
	timer.timeout.connect(func():
		spr.frame = (spr.frame + 1) % 8
	)
	tree_root.add_child(timer)

	nature_node.add_child(tree_root)
	return tree_root

func _spawn_animated_bush(tex_path: String, pos: Vector2) -> Node2D:
	var bush := StaticBody2D.new()
	bush.position = pos
	bush.collision_layer = 1
	bush.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 8
	spr.vframes = 1
	spr.scale = Vector2(0.85, 0.85)
	spr.position = Vector2(0, -6)
	bush.add_child(spr)

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 14.0
	shape.shape = circ
	shape.position = Vector2(0, 2)
	bush.add_child(shape)

	var timer := Timer.new()
	timer.wait_time = randf_range(0.14, 0.20)
	timer.autostart = true
	timer.timeout.connect(func():
		spr.frame = (spr.frame + 1) % 8
	)
	bush.add_child(timer)

	nature_node.add_child(bush)
	return bush

func _generate_wildlife_and_decorations() -> void:
	# 1. Pasture Sheep (Grazing peacefully in the village meadow)
	var sheep_coords: Array[Vector2] = [
		Vector2(450, 460),
		Vector2(500, 520),
		Vector2(780, 480)
	]
	for i in range(sheep_coords.size()):
		_spawn_grazing_sheep(sheep_coords[i], i * 0.4)

	# 2. Natural Boulders / Rocks
	var rock_coords: Array[Vector2] = [
		Vector2(350, 680), Vector2(930, 680),
		Vector2(530, 240), Vector2(750, 240)
	]
	for i in range(rock_coords.size()):
		var r_path := PATH_ROCK1 if i % 2 == 0 else PATH_ROCK2
		var rock_body := StaticBody2D.new()
		rock_body.position = rock_coords[i]
		rock_body.collision_layer = 1
		rock_body.collision_mask = 2

		var spr := Sprite2D.new()
		spr.texture = load(r_path)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.position = Vector2(0, -6)
		rock_body.add_child(spr)

		var shape := CollisionShape2D.new()
		var col := CapsuleShape2D.new()
		col.radius = 12.0
		col.height = 36.0
		shape.shape = col
		shape.rotation_degrees = 90
		shape.position = Vector2(0, 2)
		rock_body.add_child(shape)

		nature_node.add_child(rock_body)

	# 3. Sparkling Golden Stones flanking the Central Goddess Plaza
	var gold_coords: Array[Vector2] = [
		Vector2(530, 560), Vector2(750, 560),
		Vector2(530, 720), Vector2(750, 720)
	]
	for g_pos: Vector2 in gold_coords:
		var gold_body := StaticBody2D.new()
		gold_body.position = g_pos
		gold_body.collision_layer = 1
		gold_body.collision_mask = 2

		var spr := Sprite2D.new()
		spr.texture = load(PATH_GOLD_STONE)
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.scale = Vector2(0.7, 0.7)
		spr.position = Vector2(0, -6)
		gold_body.add_child(spr)

		var shape := CollisionShape2D.new()
		var circ := CircleShape2D.new()
		circ.radius = 12.0
		shape.shape = circ
		shape.position = Vector2(0, 0)
		gold_body.add_child(shape)

		nature_node.add_child(gold_body)

func _spawn_grazing_sheep(pos: Vector2, _delay: float) -> Node2D:
	var sheep := StaticBody2D.new()
	sheep.position = pos
	sheep.collision_layer = 1
	sheep.collision_mask = 2

	var spr := Sprite2D.new()
	spr.texture = load(PATH_SHEEP_GRASS)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.hframes = 12
	spr.vframes = 1
	spr.scale = Vector2(0.75, 0.75)
	spr.position = Vector2(0, -8)
	sheep.add_child(spr)

	var shape := CollisionShape2D.new()
	var circ := CircleShape2D.new()
	circ.radius = 12.0
	shape.shape = circ
	shape.position = Vector2(0, 2)
	sheep.add_child(shape)

	var timer := Timer.new()
	timer.wait_time = 0.12
	timer.autostart = true
	timer.timeout.connect(func():
		spr.frame = (spr.frame + 1) % 12
	)
	sheep.add_child(timer)

	nature_node.add_child(sheep)
	return sheep
