extends Node2D
class_name ThroneRoomGenerator

const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 15
const TILE_SZ: int = 64

const PATH_TERRAIN := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png"
const PATH_TOWER   := "res://art/tiny_swords/Buildings/Red Buildings/Tower.png"
const PATH_ROCK    := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"

var ground_layer: TileMapLayer

func _ready() -> void:
	y_sort_enabled = true
	_generate_throne_room()

func _generate_throne_room() -> void:
	_setup_floor()
	_setup_props()

func _setup_floor() -> void:
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
	ground_layer.name = "ThroneFloorLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -5
	ground_layer.modulate = Color(0.35, 0.25, 0.45, 1.0) # Dark obsidian Netherstone
	add_child(ground_layer)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coords := Vector2i(1, 1)
			if (x + y * 2) % 5 == 0:
				tile_coords = Vector2i(2, 1)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coords)

	# Red Royal / Demonic Carpet down the center aisle (cols 9 and 10)
	var carpet_layer := TileMapLayer.new()
	carpet_layer.name = "CarpetLayer"
	carpet_layer.tile_set = ts
	carpet_layer.z_index = -4
	carpet_layer.modulate = Color(1.6, 0.2, 0.35, 0.85) # Glowing deep crimson
	add_child(carpet_layer)

	for y in range(2, MAP_HEIGHT - 1):
		carpet_layer.set_cell(Vector2i(9, y), 0, Vector2i(1, 1))
		carpet_layer.set_cell(Vector2i(10, y), 0, Vector2i(1, 1))

func _setup_props() -> void:
	# Nether Citadel Spires flanking north throne
	_spawn_prop(PATH_TOWER, Vector2(220, 150), Vector2(1.3, 1.3), true, Color(0.6, 0.3, 0.8))
	_spawn_prop(PATH_TOWER, Vector2(1060, 150), Vector2(1.3, 1.3), true, Color(0.6, 0.3, 0.8))
	
	# Massive Obsidian Nether Throne in North Center
	var throne := Sprite2D.new()
	throne.texture = load(PATH_TOWER)
	throne.modulate = Color(0.3, 0.15, 0.45, 1.0)
	throne.scale = Vector2(1.6, 1.6)
	throne.position = Vector2(640, 160)
	add_child(throne)
	
	# Floating Void Core above throne
	var core := Sprite2D.new()
	core.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_brown.png")
	core.modulate = Color(2.5, 0.4, 3.0, 1.0)
	core.scale = Vector2(1.2, 1.2)
	core.position = Vector2(640, 90)
	add_child(core)
	
	var tw = core.create_tween().set_loops()
	tw.tween_property(core, "scale", Vector2(1.4, 1.4), 0.8)
	tw.tween_property(core, "scale", Vector2(1.1, 1.1), 0.8)

	# Demonic braziers / pillars along the aisle
	for py in [320, 520, 720]:
		_spawn_brazier(Vector2(440, py))
		_spawn_brazier(Vector2(840, py))

func _spawn_brazier(pos: Vector2) -> void:
	var rock := Sprite2D.new()
	rock.texture = load(PATH_ROCK)
	rock.modulate = Color(0.4, 0.25, 0.5)
	rock.scale = Vector2(1.4, 1.4)
	rock.position = pos
	add_child(rock)
	
	var fire := Sprite2D.new()
	fire.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	fire.modulate = Color(2.0, 0.3, 1.2, 0.85)
	fire.scale = Vector2(0.5, 0.5)
	fire.position = pos + Vector2(0, -18)
	add_child(fire)
	
	var ftw = fire.create_tween().set_loops()
	ftw.tween_property(fire, "scale", Vector2(0.65, 0.65), 0.35 + randf() * 0.1)
	ftw.tween_property(fire, "scale", Vector2(0.45, 0.45), 0.35 + randf() * 0.1)

func _spawn_prop(tex_path: String, pos: Vector2, scl: Vector2, has_collision: bool = false, col_mod: Color = Color.WHITE) -> void:
	var tex = load(tex_path)
	if not tex:
		return
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = pos
	spr.scale = scl
	spr.modulate = col_mod
	add_child(spr)

	if has_collision:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 6
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(60 * scl.x, 30 * scl.y)
		shape.shape = box
		shape.position = pos + Vector2(0, 20)
		body.add_child(shape)
		add_child(body)
