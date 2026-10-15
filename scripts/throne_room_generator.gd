extends Node2D
class_name ThroneRoomGenerator

const MAP_WIDTH: int = 20
const MAP_HEIGHT: int = 15
const TILE_SZ: int = 64

const PATH_TERRAIN       := "res://art/tiny_swords/Terrain/Tileset/Tilemap_color5.png"
const PATH_CASTLE        := "res://art/tiny_swords/Buildings/Black Buildings/Castle.png"
const PATH_TOWER         := "res://art/tiny_swords/Buildings/Black Buildings/Tower.png"
const PATH_BARRACKS      := "res://art/tiny_swords/Buildings/Black Buildings/Barracks.png"
const PATH_ROCK1         := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock1.png"
const PATH_ROCK4         := "res://art/tiny_swords/Terrain/Decorations/Rocks/Rock4.png"
const PATH_FIRE_ANIM     := "res://art/tiny_swords/Particle FX/Fire_02.png"

var ground_layer: TileMapLayer
var carpet_layer: TileMapLayer
var border_layer: TileMapLayer
var fire_frames: SpriteFrames
var light_texture: Texture2D

func _ready() -> void:
	y_sort_enabled = true
	_prepare_fire_frames()
	_prepare_light_texture()
	_generate_throne_room()

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

func _generate_throne_room() -> void:
	_setup_floor()
	_setup_architecture()
	_setup_braziers()
	_setup_ambient_embers()

func _setup_floor() -> void:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE_SZ, TILE_SZ)

	var color_tex: Texture2D = load(PATH_TERRAIN)
	if not color_tex:
		color_tex = load("res://art/tiny_swords/Terrain/Tileset/Tilemap_color3.png")
		
	var src := TileSetAtlasSource.new()
	src.texture = color_tex
	src.texture_region_size = Vector2i(TILE_SZ, TILE_SZ)
	for c in range(9):
		for r in range(6):
			src.create_tile(Vector2i(c, r))
	ts.add_source(src, 0)

	# 1. Dark Ashen Obsidian Floor
	ground_layer = TileMapLayer.new()
	ground_layer.name = "ThroneFloorLayer"
	ground_layer.tile_set = ts
	ground_layer.z_index = -12
	ground_layer.modulate = Color(0.22, 0.15, 0.32, 1.0)
	add_child(ground_layer)

	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			var tile_coords := Vector2i(1, 1)
			if (x + y * 2) % 4 == 0:
				tile_coords = Vector2i(2, 1)
			elif (x * 3 + y) % 5 == 0:
				tile_coords = Vector2i(1, 2)
			ground_layer.set_cell(Vector2i(x, y), 0, tile_coords)

	# 2. Ornate Royal Crimson Aisle Carpet
	carpet_layer = TileMapLayer.new()
	carpet_layer.name = "CarpetLayer"
	carpet_layer.tile_set = ts
	carpet_layer.z_index = -9
	carpet_layer.modulate = Color(1.9, 0.12, 0.28, 0.92)
	add_child(carpet_layer)

	for y in range(4, MAP_HEIGHT - 1):
		carpet_layer.set_cell(Vector2i(9, y), 0, Vector2i(1, 1))
		carpet_layer.set_cell(Vector2i(10, y), 0, Vector2i(1, 1))
		
	# 3. Gold Runic Border
	border_layer = TileMapLayer.new()
	border_layer.name = "BorderLayer"
	border_layer.tile_set = ts
	border_layer.z_index = -8
	border_layer.modulate = Color(2.2, 1.7, 0.45, 0.8)
	add_child(border_layer)
	
	for y in range(4, MAP_HEIGHT - 1):
		border_layer.set_cell(Vector2i(8, y), 0, Vector2i(0, 1))
		border_layer.set_cell(Vector2i(11, y), 0, Vector2i(2, 1))

func _setup_architecture() -> void:
	# ── Grand Nether Citadel Facade (North Wall) ──
	var citadel := Sprite2D.new()
	citadel.texture = load(PATH_CASTLE)
	citadel.scale = Vector2(2.1, 2.1)
	citadel.position = Vector2(640, 125)
	citadel.modulate = Color(0.35, 0.22, 0.48, 1.0)
	citadel.z_index = -5
	add_child(citadel)

	# North Wall Spires flanking the Citadel
	_spawn_spire(Vector2(260, 130), Vector2(1.8, 1.8))
	_spawn_spire(Vector2(1020, 130), Vector2(1.8, 1.8))

	# Raised Stone Dais for the Demon Lord's Throne
	var dais := Sprite2D.new()
	dais.texture = load(PATH_BARRACKS)
	dais.scale = Vector2(1.15, 0.85)
	dais.position = Vector2(640, 205)
	dais.modulate = Color(0.28, 0.16, 0.38, 1.0)
	dais.z_index = -3
	add_child(dais)

	# Grand Obsidian Spire Columns along Outer Walls
	var side_spires = [
		Vector2(140, 360), Vector2(140, 600), Vector2(140, 840),
		Vector2(1140, 360), Vector2(1140, 600), Vector2(1140, 840)
	]
	for sp in side_spires:
		_spawn_spire(sp, Vector2(1.4, 1.4))

func _spawn_spire(pos: Vector2, scl: Vector2) -> void:
	var spire := Sprite2D.new()
	spire.texture = load(PATH_TOWER)
	spire.position = pos
	spire.scale = scl
	spire.modulate = Color(0.32, 0.18, 0.45, 1.0)
	add_child(spire)

	# Collision at base so hero and boss navigate properly around columns
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 6
	var col := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(48 * scl.x, 24 * scl.y)
	col.shape = box
	col.position = pos + Vector2(0, 40 * scl.y)
	body.add_child(col)
	add_child(body)

func _setup_braziers() -> void:
	# 6 Grand Braziers with real animated pixel art flame & dynamic point lighting
	var brazier_positions = [
		Vector2(360, 320), Vector2(920, 320),
		Vector2(360, 540), Vector2(920, 540),
		Vector2(360, 760), Vector2(920, 760)
	]
	for pos in brazier_positions:
		_spawn_animated_brazier(pos)

func _spawn_animated_brazier(pos: Vector2) -> void:
	# 1. Carved Stone Plinth Base
	var base := Sprite2D.new()
	base.texture = load(PATH_ROCK4)
	base.position = pos
	base.scale = Vector2(1.5, 1.5)
	base.modulate = Color(0.35, 0.22, 0.42, 1.0)
	add_child(base)

	# 2. Real Animated Hand-Drawn Pixel Art Flame
	if fire_frames:
		var fire := AnimatedSprite2D.new()
		fire.sprite_frames = fire_frames
		fire.play("burn")
		fire.modulate = Color(2.8, 0.6, 2.0, 0.95) # Radiant abyssal violet flame
		fire.scale = Vector2(1.15, 1.15)
		fire.position = pos + Vector2(0, -32)
		add_child(fire)

	# 3. Dynamic Radial PointLight2D with Organic Flame Flicker
	if light_texture:
		var light := PointLight2D.new()
		light.texture = light_texture
		light.color = Color(1.8, 0.45, 1.3, 1.0)
		light.energy = 1.15
		light.texture_scale = 2.4
		light.position = pos + Vector2(0, -28)
		add_child(light)

		var ltw = light.create_tween().set_loops()
		ltw.tween_property(light, "energy", 1.35, randf_range(0.2, 0.35))
		ltw.tween_property(light, "energy", 0.95, randf_range(0.2, 0.35))

func _setup_ambient_embers() -> void:
	# Volumetric Abyssal Embers drifting lazily across the throne hall
	var embers := CPUParticles2D.new()
	embers.name = "ThroneRoomEmbers"
	embers.position = Vector2(640, 960)
	embers.amount = 40
	embers.lifetime = 4.5
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(600, 20)
	embers.direction = Vector2(0, -1)
	embers.spread = 15.0
	embers.gravity = Vector2(0, -22)
	embers.initial_velocity_min = 45.0
	embers.initial_velocity_max = 85.0
	embers.scale_amount_min = 2.0
	embers.scale_amount_max = 3.5
	embers.color = Color(2.6, 0.4, 1.5, 0.7)
	embers.z_index = 4
	add_child(embers)
