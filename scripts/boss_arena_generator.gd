extends Node2D
class_name BossArenaGenerator

const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 15
const TILE_SZ: int = 64

const PATH_TERRAIN_CRIMSON := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color4.png"
const PATH_TERRAIN_STONE   := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png"
const PATH_CASTLE          := "res://art/tiny_swords/Buildings/Red Buildings/Castle.png"
const PATH_TOWER           := "res://art/tiny_swords/Buildings/Red Buildings/Tower.png"
const PATH_BARRACKS        := "res://art/tiny_swords/Buildings/Red Buildings/Barracks.png"
const PATH_ARCHERY         := "res://art/tiny_swords/Buildings/Red Buildings/Archery.png"
const PATH_ROCK1           := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"
const PATH_ROCK2           := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock2.png"
const PATH_ROCK3           := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock3.png"
const PATH_ROCK4           := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock4.png"
const PATH_FIRE_ANIM       := "res://art/tiny_swords/Particle FX/Fire_02.png"

var ground_layer: TileMapLayer
var path_layer: TileMapLayer
var fire_frames: SpriteFrames
var light_texture: Texture2D

func _ready() -> void:
	y_sort_enabled = true
	_prepare_fire_frames()
	_prepare_light_texture()
	_generate_vanguard_arena()

func _prepare_fire_frames() -> void:
	fire_frames = SpriteFrames.new()
	fire_frames.add_animation("burn")
	fire_frames.set_animation_speed("burn", 12.0)
	fire_frames.set_animation_loop("burn", true)
	
	var fire_tex: Texture2D = load(PATH_FIRE_ANIM)
	if fire_tex:
		for f in range(10):
			var atlas := AtlasTexture.new()
			atlas.atlas = fire_tex
			atlas.region = Rect2(f * 64, 0, 64, 64)
			fire_frames.add_frame("burn", atlas)

func _prepare_light_texture() -> void:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.width = 128
	gtex.height = 128
	light_texture = gtex

func _generate_vanguard_arena() -> void:
	_setup_floor_layers()
	_setup_fortress_architecture()
	_setup_war_braziers()
	_setup_perimeter_crags()
	_setup_ambient_war_embers()

func _setup_floor_layers() -> void:
	var ts_crimson := TileSet.new()
	ts_crimson.tile_size = Vector2i(TILE_SZ, TILE_SZ)

	var color_tex: Texture2D = load(PATH_TERRAIN_CRIMSON)
	if not color_tex:
		color_tex = load("res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png")

	var src := TileSetAtlasSource.new()
	src.texture = color_tex
	src.texture_region_size = Vector2i(TILE_SZ, TILE_SZ)
	for c in range(9):
		for r in range(6):
			src.create_tile(Vector2i(c, r))
	ts_crimson.add_source(src, 0)

	# 1. Base Scorched Volcanic Floor
	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = ts_crimson
	ground_layer.z_index = -6
	add_child(ground_layer)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coords := Vector2i(1, 1)
			if (x * 3 + y * 7) % 5 == 0:
				tile_coords = Vector2i(2, 1)
			elif (x + y * 2) % 6 == 0:
				tile_coords = Vector2i(1, 2)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coords)

	# 2. Central Stone Battleground Path
	var ts_stone := TileSet.new()
	ts_stone.tile_size = Vector2i(TILE_SZ, TILE_SZ)
	var stone_tex: Texture2D = load(PATH_TERRAIN_STONE)
	if stone_tex:
		var s_src := TileSetAtlasSource.new()
		s_src.texture = stone_tex
		s_src.texture_region_size = Vector2i(TILE_SZ, TILE_SZ)
		for c in range(9):
			for r in range(6):
				s_src.create_tile(Vector2i(c, r))
		ts_stone.add_source(s_src, 0)

		path_layer = TileMapLayer.new()
		path_layer.name = "PathLayer"
		path_layer.tile_set = ts_stone
		path_layer.z_index = -5
		add_child(path_layer)

		# Paved pathway running from south entrance toward the north vanguard gate
		for x in range(8, 12):
			for y in range(3, MAP_HEIGHT):
				var p_coord := Vector2i(1, 1)
				if (x + y) % 3 == 0:
					p_coord = Vector2i(2, 1)
				path_layer.set_cell(Vector2i(x, y), 0, p_coord)

func _setup_fortress_architecture() -> void:
	# 1. Central Vanguard Gatehouse (Castle backdrop at north)
	_spawn_prop(PATH_CASTLE, Vector2(640, 100), Vector2(1.25, 1.25), true)

	# 2. Imposing Flanking Watchtowers
	_spawn_prop(PATH_TOWER, Vector2(300, 130), Vector2(1.15, 1.15), true)
	_spawn_prop(PATH_TOWER, Vector2(980, 130), Vector2(1.15, 1.15), true)

	# 3. Outer Vanguard Barracks
	_spawn_prop(PATH_BARRACKS, Vector2(130, 160), Vector2(1.0, 1.0), true)
	_spawn_prop(PATH_BARRACKS, Vector2(1150, 160), Vector2(1.0, 1.0), true)

	# 4. Flanking Archery Posts
	_spawn_prop(PATH_ARCHERY, Vector2(90, 520), Vector2(1.0, 1.0), true)
	_spawn_prop(PATH_ARCHERY, Vector2(1190, 520), Vector2(1.0, 1.0), true)

func _setup_war_braziers() -> void:
	var brazier_positions: Array[Vector2] = [
		Vector2(500, 190), Vector2(780, 190), # Flanking the north fortress gate
		Vector2(260, 480), Vector2(1020, 480), # Flanking the middle battlefield
		Vector2(380, 800), Vector2(900, 800)  # Flanking the south pathway
	]
	for bpos in brazier_positions:
		_spawn_animated_brazier(bpos)

func _spawn_animated_brazier(pos: Vector2) -> void:
	# 1. Heavy Stone Base
	var base := Sprite2D.new()
	base.texture = load(PATH_ROCK4)
	base.position = pos
	base.scale = Vector2(1.35, 1.35)
	base.modulate = Color(0.45, 0.28, 0.25, 1.0)
	add_child(base)

	# 2. Real Animated Hand-Drawn Flame
	if fire_frames:
		var fire := AnimatedSprite2D.new()
		fire.sprite_frames = fire_frames
		fire.play("burn")
		fire.modulate = Color(2.8, 1.2, 0.4, 0.95) # Intense crimson-amber flame
		fire.scale = Vector2(1.1, 1.1)
		fire.position = pos + Vector2(0, -30)
		add_child(fire)

	# 3. Dynamic Radial PointLight2D with Organic Flame Flicker
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = Color(1.8, 0.7, 0.25, 1.0)
		light.energy = 1.2
		light.texture_scale = 2.5
		light.position = pos + Vector2(0, -26)
		add_child(light)

		var ltw = light.create_tween().set_loops()
		ltw.tween_property(light, "energy", 1.4, randf_range(0.2, 0.35))
		ltw.tween_property(light, "energy", 1.0, randf_range(0.2, 0.35))

func _setup_perimeter_crags() -> void:
	# Heavy boulders and jagged rock barriers along the boundaries
	for c in range(1, MAP_WIDTH - 1, 2):
		if c < 6 or c > 13: # Keep south-center path clear
			_spawn_prop(PATH_ROCK1, Vector2(c * TILE_SZ + 32, (MAP_HEIGHT - 1) * TILE_SZ + 15), Vector2(1.3, 1.3), true)

	# Left & Right rugged rock barriers
	for r in range(4, MAP_HEIGHT - 1, 2):
		var rtex := PATH_ROCK2 if r % 2 == 0 else PATH_ROCK3
		_spawn_prop(rtex, Vector2(50, r * TILE_SZ + 32), Vector2(1.3, 1.3), true)
		_spawn_prop(rtex, Vector2((MAP_WIDTH - 1) * TILE_SZ + 15, r * TILE_SZ + 32), Vector2(1.3, 1.3), true)

func _setup_ambient_war_embers() -> void:
	var embers := CPUParticles2D.new()
	embers.name = "VanguardEmbers"
	embers.position = Vector2(640, 960)
	embers.amount = 45
	embers.lifetime = 4.5
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(600, 20)
	embers.direction = Vector2(0, -1)
	embers.spread = 20.0
	embers.gravity = Vector2(12, -28)
	embers.initial_velocity_min = 40.0
	embers.initial_velocity_max = 75.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 4.0
	embers.color = Color(2.8, 1.1, 0.3, 0.9) # Radiant fiery ember sparks
	add_child(embers)

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
