extends Node2D
class_name ThroneRoomGenerator

const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 15
const TILE_SZ: int = 64

const PATH_TERRAIN := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png"
const PATH_TOWER   := "res://art/tiny_swords/Buildings/Red Buildings/Tower.png"
const PATH_ROCK    := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"

var ground_layer: TileMapLayer
var magic_circle_nodes: Array[Node2D] = []

func _ready() -> void:
	y_sort_enabled = true
	_generate_throne_room()

func _process(delta: float) -> void:
	for circle in magic_circle_nodes:
		if is_instance_valid(circle):
			circle.rotation += 0.25 * delta

func _generate_throne_room() -> void:
	_setup_floor()
	_setup_occult_circle()
	_setup_props()
	_setup_floating_monoliths()

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

	# Obsidian Stone Foundation
	ground_layer = TileMapLayer.new()
	ground_layer.name = "ThroneFloorLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -10
	ground_layer.modulate = Color(0.28, 0.18, 0.38, 1.0) # Deep dark obsidian
	add_child(ground_layer)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coords := Vector2i(1, 1)
			if (x + y * 2) % 4 == 0:
				tile_coords = Vector2i(2, 1)
			elif (x * 3 + y) % 6 == 0:
				tile_coords = Vector2i(1, 2)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coords)

	# Ornate Royal Crimson Aisle Carpet
	var carpet_layer := TileMapLayer.new()
	carpet_layer.name = "CarpetLayer"
	carpet_layer.tile_set = ts
	carpet_layer.z_index = -8
	carpet_layer.modulate = Color(1.8, 0.15, 0.3, 0.9) # Glowing royal blood velvet
	add_child(carpet_layer)

	for y in range(3, MAP_HEIGHT - 1):
		carpet_layer.set_cell(Vector2i(9, y), 0, Vector2i(1, 1))
		carpet_layer.set_cell(Vector2i(10, y), 0, Vector2i(1, 1))
		
	# Gold/Rune Carpet Border
	var border_layer := TileMapLayer.new()
	border_layer.name = "BorderLayer"
	border_layer.tile_set = ts
	border_layer.z_index = -7
	border_layer.modulate = Color(2.0, 1.6, 0.4, 0.75) # Golden runes border
	add_child(border_layer)
	
	for y in range(3, MAP_HEIGHT - 1):
		border_layer.set_cell(Vector2i(8, y), 0, Vector2i(0, 1))
		border_layer.set_cell(Vector2i(11, y), 0, Vector2i(2, 1))

func _setup_occult_circle() -> void:
	# Giant glowing ritual circle in front of the throne
	var ritual_node := Node2D.new()
	ritual_node.position = Vector2(640, 380)
	ritual_node.z_index = -6
	add_child(ritual_node)
	magic_circle_nodes.append(ritual_node)

	# Outer glowing ring
	var outer_ring := Line2D.new()
	outer_ring.width = 4.0
	outer_ring.default_color = Color(2.5, 0.4, 2.8, 0.8)
	var pts: Array[Vector2] = []
	for i in range(33):
		var a = i * (TAU / 32.0)
		pts.append(Vector2(cos(a), sin(a)) * 160.0)
	outer_ring.points = pts
	ritual_node.add_child(outer_ring)

	# Inner glowing ring
	var inner_ring := Line2D.new()
	inner_ring.width = 2.5
	inner_ring.default_color = Color(3.0, 0.8, 1.2, 0.7)
	var in_pts: Array[Vector2] = []
	for i in range(17):
		var a = i * (TAU / 16.0)
		in_pts.append(Vector2(cos(a), sin(a)) * 110.0)
	inner_ring.points = in_pts
	ritual_node.add_child(inner_ring)

	# Occult star inside
	var star := Line2D.new()
	star.width = 2.0
	star.default_color = Color(2.0, 0.3, 2.5, 0.6)
	var s_pts: Array[Vector2] = []
	var num_pts = 6
	for i in range(num_pts + 1):
		var a = i * (TAU * 2.0 / num_pts)
		s_pts.append(Vector2(cos(a), sin(a)) * 105.0)
	star.points = s_pts
	ritual_node.add_child(star)

	# Pulse animation for the whole ritual circle
	var ptw = ritual_node.create_tween().set_loops()
	ptw.tween_property(ritual_node, "modulate", Color(1.2, 0.8, 1.4, 1.0), 1.2)
	ptw.tween_property(ritual_node, "modulate", Color(0.7, 0.4, 0.9, 0.8), 1.2)

func _setup_props() -> void:
	# Nether Spires flanking north
	_spawn_prop(PATH_TOWER, Vector2(180, 140), Vector2(1.4, 1.4), true, Color(0.5, 0.25, 0.75))
	_spawn_prop(PATH_TOWER, Vector2(1100, 140), Vector2(1.4, 1.4), true, Color(0.5, 0.25, 0.75))
	
	# Massive Obsidian Nether Throne
	var throne := Sprite2D.new()
	throne.texture = load(PATH_TOWER)
	throne.modulate = Color(0.25, 0.12, 0.4, 1.0)
	throne.scale = Vector2(1.8, 1.8)
	throne.position = Vector2(640, 150)
	add_child(throne)
	
	# Colossal Pulsing Abyssal Void Singularity above the throne
	var vortex := Node2D.new()
	vortex.position = Vector2(640, 80)
	vortex.z_index = -3
	add_child(vortex)
	magic_circle_nodes.append(vortex)

	# Singularity Outer Halo
	var halo := Sprite2D.new()
	halo.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_brown.png")
	halo.modulate = Color(3.5, 0.2, 4.0, 0.9)
	halo.scale = Vector2(2.4, 2.4)
	vortex.add_child(halo)

	# Singularity Dark Core
	var core := Sprite2D.new()
	core.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	core.modulate = Color(0.1, 0.05, 0.2, 1.0)
	core.scale = Vector2(1.2, 1.2)
	vortex.add_child(core)

	var vtw = vortex.create_tween().set_loops()
	vtw.tween_property(halo, "scale", Vector2(2.8, 2.8), 1.0).set_trans(Tween.TRANS_SINE)
	vtw.tween_property(halo, "scale", Vector2(2.2, 2.2), 1.0).set_trans(Tween.TRANS_SINE)

	# Grand Braziers with dynamic flame glow
	for py in [320, 520, 720]:
		_spawn_brazier(Vector2(360, py))
		_spawn_brazier(Vector2(920, py))

func _setup_floating_monoliths() -> void:
	# Floating obsidian monoliths hovering around the room
	var monolith_positions = [
		Vector2(260, 420),
		Vector2(260, 680),
		Vector2(1020, 420),
		Vector2(1020, 680)
	]
	
	for i in range(monolith_positions.size()):
		var pos = monolith_positions[i]
		var rock := Sprite2D.new()
		rock.texture = load(PATH_ROCK)
		rock.modulate = Color(0.35, 0.15, 0.55, 0.95)
		rock.scale = Vector2(1.6, 2.2)
		rock.position = pos
		rock.z_index = 0
		add_child(rock)
		
		# Floating Bobbing Tween
		var rtw = rock.create_tween().set_loops()
		var delay = i * 0.4
		rtw.tween_interval(delay)
		rtw.tween_property(rock, "position:y", pos.y - 18.0, 1.4).set_trans(Tween.TRANS_SINE)
		rtw.tween_property(rock, "position:y", pos.y + 8.0, 1.4).set_trans(Tween.TRANS_SINE)
		
		# Void crystal spark on top
		var crystal := Sprite2D.new()
		crystal.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
		crystal.modulate = Color(2.5, 0.4, 3.5, 0.8)
		crystal.scale = Vector2(0.4, 0.4)
		crystal.position = Vector2(0, -22)
		rock.add_child(crystal)

func _spawn_brazier(pos: Vector2) -> void:
	var rock := Sprite2D.new()
	rock.texture = load(PATH_ROCK)
	rock.modulate = Color(0.3, 0.2, 0.4)
	rock.scale = Vector2(1.5, 1.5)
	rock.position = pos
	add_child(rock)
	
	var fire := Sprite2D.new()
	fire.texture = load("res://art/ui/rpg_expansion/PNG/iconCircle_beige.png")
	fire.modulate = Color(2.8, 0.4, 1.6, 0.9)
	fire.scale = Vector2(0.65, 0.65)
	fire.position = pos + Vector2(0, -20)
	add_child(fire)
	
	var ftw = fire.create_tween().set_loops()
	ftw.tween_property(fire, "scale", Vector2(0.8, 0.8), 0.35 + randf() * 0.1)
	ftw.tween_property(fire, "scale", Vector2(0.55, 0.55), 0.35 + randf() * 0.1)

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
