extends Node2D
class_name TownGenerator

const GRID_WIDTH: int = 40
const GRID_HEIGHT: int = 40
const NATIVE_TILE_SIZE: int = 16
const WORLD_SCALE: float = 2.0 # 16px * 2.0 = 32px per cell (1280x1280 map)

# Atlas Paths
const TT_ATLAS_PATH: String = "res://art/tiles/tiny-town/Tilemap/tilemap_packed.png"
const TD_ATLAS_PATH: String = "res://art/tiles/tiny-dungeon/Tilemap/tilemap_packed.png"

const SRC_TOWN: int = 0
const SRC_DUNGEON: int = 1

# --- Tiny Town Atlas Coordinates Vector2i(col, row) ---
# Nature & Ground
const TT_GRASS := Vector2i(0, 0)
const TT_FLOWER_MEADOW := Vector2i(2, 0)
const TT_STEPPING_STONES := Vector2i(7, 3)

# Trees & Foliage (Authentic 1x2 pixel art trees with canopy and trunk)
const TT_CYPRESS_TOP := Vector2i(4, 0)
const TT_CYPRESS_BASE := Vector2i(4, 1)

const TT_AUTUMN_TOP := Vector2i(3, 0)
const TT_AUTUMN_BASE := Vector2i(3, 1)

# Fences (Row 3)
const TT_FENCE_L := Vector2i(8, 3)
const TT_FENCE_M := Vector2i(9, 3)
const TT_FENCE_R := Vector2i(10, 3)

# Props
const TT_WELL := Vector2i(8, 8)
const TT_BEEHIVE_A := Vector2i(9, 7)
const TT_BEEHIVE_B := Vector2i(10, 7)
const TT_SIGNPOST := Vector2i(7, 9)
const TT_GODDESS_STATUE := Vector2i(8, 9)
const TT_CART := Vector2i(10, 8)

# Timber Cottage Tiles (Slate Blue Roof)
const TT_SLATE_L := Vector2i(0, 4)
const TT_SLATE_M := Vector2i(1, 4)
const TT_SLATE_R := Vector2i(2, 4)
const TT_SLATE_DORMER := Vector2i(3, 4)

const TT_WOOD_WINDOW := Vector2i(0, 7)
const TT_WOOD_DOOR := Vector2i(1, 7)
const TT_WOOD_WALL_R := Vector2i(3, 6)

# Castle Fortress (Cols 0..5, Rows 8..10) - Used for Grand Church Citadel
const TT_CASTLE_BATTLEMENT_L := Vector2i(0, 8)
const TT_CASTLE_BATTLEMENT_LI := Vector2i(1, 8)
const TT_CASTLE_RAMPART_LADDER := Vector2i(2, 8)
const TT_CASTLE_RAMPART_GUARD := Vector2i(3, 8)
const TT_CASTLE_BATTLEMENT_RI := Vector2i(4, 8)
const TT_CASTLE_BATTLEMENT_R := Vector2i(5, 8)

const TT_CASTLE_TOWER_L_SLIT := Vector2i(0, 9)
const TT_CASTLE_TOWER_L_MID := Vector2i(1, 9)
const TT_CASTLE_PORTCULLIS_L := Vector2i(2, 9)
const TT_CASTLE_PORTCULLIS_R := Vector2i(3, 9)
const TT_CASTLE_TOWER_R_MID := Vector2i(4, 9)
const TT_CASTLE_TOWER_R_SLIT := Vector2i(5, 9)

const TT_CASTLE_BASE_L1 := Vector2i(0, 10)
const TT_CASTLE_BASE_L2 := Vector2i(1, 10)
const TT_CASTLE_ARCH_L := Vector2i(2, 10)
const TT_CASTLE_ARCH_R := Vector2i(3, 10)
const TT_CASTLE_BASE_R1 := Vector2i(4, 10)
const TT_CASTLE_BASE_R2 := Vector2i(5, 10)

# Tiny Dungeon Elements (South Gate & Sacred Altar)
const TD_WALL := Vector2i(0, 0)
const TD_BATTLEMENT := Vector2i(0, 1)
const TD_HOLY_FONT := Vector2i(8, 9)
const TD_FIRE_BRAZIER := Vector2i(5, 2)

var ground_layer: TileMapLayer
var objects_layer: TileMapLayer
var roof_layer: TileMapLayer

func _ready() -> void:
	y_sort_enabled = true
	generate_town()

func generate_town() -> void:
	var ts := _create_combined_tileset()

	ground_layer = TileMapLayer.new()
	ground_layer.name = "GroundLayer"
	ground_layer.tile_set = ts
	ground_layer.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	ground_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground_layer.z_index = 0
	add_child(ground_layer)

	objects_layer = TileMapLayer.new()
	objects_layer.name = "ObjectsLayer"
	objects_layer.tile_set = ts
	objects_layer.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	objects_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	objects_layer.z_index = 0
	objects_layer.y_sort_enabled = true
	add_child(objects_layer)

	roof_layer = TileMapLayer.new()
	roof_layer.name = "RoofLayer"
	roof_layer.tile_set = ts
	roof_layer.scale = Vector2(WORLD_SCALE, WORLD_SCALE)
	roof_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	roof_layer.z_index = 10
	roof_layer.y_sort_enabled = false
	add_child(roof_layer)

	# 1. Clean Meadow Base (Vibrant green with authentic flower scatter)
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			ground_layer.set_cell(Vector2i(x, y), SRC_TOWN, TT_GRASS)
			# Only place legitimate flower meadow tiles with seamless grass background
			if (x * 7 + y * 13) % 19 == 0:
				ground_layer.set_cell(Vector2i(x, y), SRC_TOWN, TT_FLOWER_MEADOW)

	# 2. Cobblestone Stepping Stone Roads
	_generate_roads()

	# 3. Fortress Perimeter Walls (Sealing Haven Citadel)
	_generate_perimeter_walls()

	# 4. Castle Cathedral & Village Cottages
	_generate_buildings()

	# 5. Rooted Tree Groves & Landscaping (Matching Kenney reference sample)
	_generate_town_trees()

	# 6. Central Goddess Altar Plaza & South Gate Fortress
	_generate_monuments()

	# 7. Environmental Props (Well, Beehives, Carts, Fences)
	_generate_decorations()

func _create_combined_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(NATIVE_TILE_SIZE, NATIVE_TILE_SIZE)

	var tt_tex: Texture2D = load(TT_ATLAS_PATH)
	var tt_src := TileSetAtlasSource.new()
	tt_src.texture = tt_tex
	tt_src.texture_region_size = Vector2i(NATIVE_TILE_SIZE, NATIVE_TILE_SIZE)
	for c in range(12):
		for r in range(11):
			tt_src.create_tile(Vector2i(c, r))
	ts.add_source(tt_src, SRC_TOWN)

	var td_tex: Texture2D = load(TD_ATLAS_PATH)
	var td_src := TileSetAtlasSource.new()
	td_src.texture = td_tex
	td_src.texture_region_size = Vector2i(NATIVE_TILE_SIZE, NATIVE_TILE_SIZE)
	for c in range(12):
		for r in range(11):
			td_src.create_tile(Vector2i(c, r))
	ts.add_source(td_src, SRC_DUNGEON)

	return ts

func _generate_roads() -> void:
	# North-South Main Highway (Cols 19 & 20, Rows 5 to 35)
	for y in range(5, 36):
		ground_layer.set_cell(Vector2i(19, y), SRC_TOWN, TT_STEPPING_STONES)
		ground_layer.set_cell(Vector2i(20, y), SRC_TOWN, TT_STEPPING_STONES)

	# East-West Main Street (Rows 19 & 20, Cols 5 to 35)
	for x in range(5, 36):
		ground_layer.set_cell(Vector2i(x, 19), SRC_TOWN, TT_STEPPING_STONES)
		ground_layer.set_cell(Vector2i(x, 20), SRC_TOWN, TT_STEPPING_STONES)

	# North Avenue connecting to Forge & Herbalist (Row 11, Cols 8 to 31)
	for x in range(8, 32):
		ground_layer.set_cell(Vector2i(x, 11), SRC_TOWN, TT_STEPPING_STONES)

	# South Avenue connecting residential quarters (Row 26, Cols 8 to 31)
	for x in range(8, 32):
		ground_layer.set_cell(Vector2i(x, 26), SRC_TOWN, TT_STEPPING_STONES)

func _generate_perimeter_walls() -> void:
	# 1. West Curtain Wall (Cols 0-1, Rows 2-34)
	for y in range(2, 35):
		objects_layer.set_cell(Vector2i(0, y), SRC_TOWN, Vector2i(0, 9))
		objects_layer.set_cell(Vector2i(1, y), SRC_TOWN, Vector2i(1, 9))
	# North-West Corner Tower
	objects_layer.set_cell(Vector2i(0, 2), SRC_TOWN, Vector2i(0, 8))
	objects_layer.set_cell(Vector2i(1, 2), SRC_TOWN, Vector2i(1, 8))
	# South-West Corner Tower
	objects_layer.set_cell(Vector2i(0, 34), SRC_TOWN, Vector2i(0, 10))
	objects_layer.set_cell(Vector2i(1, 34), SRC_TOWN, Vector2i(1, 10))

	# 2. East Curtain Wall (Cols 38-39, Rows 2-34)
	for y in range(2, 35):
		objects_layer.set_cell(Vector2i(38, y), SRC_TOWN, Vector2i(4, 9))
		objects_layer.set_cell(Vector2i(39, y), SRC_TOWN, Vector2i(5, 9))
	# North-East Corner Tower
	objects_layer.set_cell(Vector2i(38, 2), SRC_TOWN, Vector2i(4, 8))
	objects_layer.set_cell(Vector2i(39, 2), SRC_TOWN, Vector2i(5, 8))
	# South-East Corner Tower
	objects_layer.set_cell(Vector2i(38, 34), SRC_TOWN, Vector2i(4, 10))
	objects_layer.set_cell(Vector2i(39, 34), SRC_TOWN, Vector2i(5, 10))

	# 3. North Fortress Wall (Rows 2-4)
	# Left curtain wall (Cols 2 to 16)
	for x in range(2, 17):
		objects_layer.set_cell(Vector2i(x, 2), SRC_TOWN, Vector2i(1, 8))
		objects_layer.set_cell(Vector2i(x, 3), SRC_TOWN, Vector2i(1, 9))
		objects_layer.set_cell(Vector2i(x, 4), SRC_TOWN, Vector2i(1, 10))
	# Right curtain wall (Cols 23 to 37)
	for x in range(23, 38):
		objects_layer.set_cell(Vector2i(x, 2), SRC_TOWN, Vector2i(1, 8))
		objects_layer.set_cell(Vector2i(x, 3), SRC_TOWN, Vector2i(1, 9))
		objects_layer.set_cell(Vector2i(x, 4), SRC_TOWN, Vector2i(1, 10))

func _generate_town_trees() -> void:
	# North Churchyard Groves (Full 1x2 trees with canopy and trunks/roots)
	for tx in [4, 7, 10, 13]:
		_place_tree(Vector2i(tx, 6), tx % 6 == 4)
	for tx in [26, 29, 32, 35]:
		_place_tree(Vector2i(tx, 6), tx % 6 == 2)

	# Cottage Yard Trees
	_place_tree(Vector2i(4, 13), true)
	_place_tree(Vector2i(32, 13), false)

	# South Residential Park Groves
	for tx in [4, 7, 10, 13]:
		_place_tree(Vector2i(tx, 28), tx % 6 == 4)
	for tx in [26, 29, 32, 35]:
		_place_tree(Vector2i(tx, 28), tx % 6 == 2)

func _place_tree(pos: Vector2i, is_autumn: bool = false) -> void:
	var top_tile := TT_AUTUMN_TOP if is_autumn else TT_CYPRESS_TOP
	var base_tile := TT_AUTUMN_BASE if is_autumn else TT_CYPRESS_BASE
	objects_layer.set_cell(pos, SRC_TOWN, top_tile)
	objects_layer.set_cell(pos + Vector2i(0, 1), SRC_TOWN, base_tile)

func _generate_buildings() -> void:
	# 1. North Church Sanctuary: Grand 6x3 Stone Castle Citadel (Cols 17 to 22, Rows 2 to 4)
	_place_castle(Vector2i(17, 2))

	# 2. Master Torren's Forge (North-West: Cols 7 to 9, Rows 9 to 10)
	_place_timber_cottage(Vector2i(7, 9), true)

	# 3. Eldrin's Herbalist Sanctuary (North-East: Cols 26 to 28, Rows 9 to 10)
	_place_timber_cottage(Vector2i(26, 9), false)

	# 4. South-West Village Cottage (Cols 7 to 9, Rows 24 to 25)
	_place_timber_cottage(Vector2i(7, 24), false)

	# 5. South-East Village Cottage (Cols 26 to 28, Rows 24 to 25)
	_place_timber_cottage(Vector2i(26, 24), true)

# Fully symmetrical 6-tile wide stone castle fortress
# Left Tower: (0, r), (2, r) | Gate: (3, r), (4, r) | Right Tower: (0, r), (2, r)
func _place_castle(pos: Vector2i) -> void:
	var cols: Array[int] = [0, 2, 3, 4, 0, 2]
	for r_i in range(3):
		var atlas_row: int = 8 + r_i
		for c_i in range(6):
			var atlas_col: int = cols[c_i]
			var cell_pos := pos + Vector2i(c_i, r_i)
			# Overhead archway lintels & battlements (central gateway, rows 0 & 1)
			if c_i in [2, 3] and r_i in [0, 1]:
				roof_layer.set_cell(cell_pos, SRC_TOWN, Vector2i(atlas_col, atlas_row))
			else:
				objects_layer.set_cell(cell_pos, SRC_TOWN, Vector2i(atlas_col, atlas_row))

	# Stepping stone approach through the central archway (Cols 19 & 20)
	ground_layer.set_cell(pos + Vector2i(2, 3), SRC_TOWN, TT_STEPPING_STONES)
	ground_layer.set_cell(pos + Vector2i(3, 3), SRC_TOWN, TT_STEPPING_STONES)

func _place_timber_cottage(pos: Vector2i, has_dormer: bool) -> void:
	# Roof (Row 0): Slate blue shingles with optional dormer window
	objects_layer.set_cell(pos, SRC_TOWN, TT_SLATE_L)
	if has_dormer:
		objects_layer.set_cell(pos + Vector2i(1, 0), SRC_TOWN, TT_SLATE_DORMER)
	else:
		objects_layer.set_cell(pos + Vector2i(1, 0), SRC_TOWN, TT_SLATE_M)
	objects_layer.set_cell(pos + Vector2i(2, 0), SRC_TOWN, TT_SLATE_R)

	# Walls (Row 1): Left glass window, Center solid wooden door, Right wood trim wall
	objects_layer.set_cell(pos + Vector2i(0, 1), SRC_TOWN, TT_WOOD_WINDOW)
	objects_layer.set_cell(pos + Vector2i(1, 1), SRC_TOWN, TT_WOOD_DOOR)
	objects_layer.set_cell(pos + Vector2i(2, 1), SRC_TOWN, TT_WOOD_WALL_R)

	# Stepping stone approach to door
	ground_layer.set_cell(pos + Vector2i(1, 2), SRC_TOWN, TT_STEPPING_STONES)

func _generate_monuments() -> void:
	# 1. Central Goddess Altar Plaza (Rows 17-22, Cols 17-22)
	# Stepping stone plaza that seamlessly connects with the cobblestone highways
	for x in range(17, 23):
		for y in range(17, 23):
			ground_layer.set_cell(Vector2i(x, y), SRC_TOWN, TT_STEPPING_STONES)

	# Cobblestones pave the sacred central plaza (Cols 17-22, Rows 17-22).
	# The Goddess Shrine itself is placed as a custom hand-drawn pixel art sprite in town.tscn.

	# 2. South Fortress Bastion Wall & Castle Gate (Rows 34 to 36)
	# Stone curtain walls to the left (Cols 2 to 16)
	for x in range(2, 17):
		objects_layer.set_cell(Vector2i(x, 34), SRC_TOWN, Vector2i(1, 8))
		objects_layer.set_cell(Vector2i(x, 35), SRC_TOWN, Vector2i(1, 9))
		objects_layer.set_cell(Vector2i(x, 36), SRC_TOWN, Vector2i(1, 10))

	# Grand 6x3 Castle Fortress Gate at Cols 17 to 22, Rows 34 to 36
	_place_castle(Vector2i(17, 34))

	# Stone curtain walls to the right (Cols 23 to 37)
	for x in range(23, 38):
		objects_layer.set_cell(Vector2i(x, 34), SRC_TOWN, Vector2i(1, 8))
		objects_layer.set_cell(Vector2i(x, 35), SRC_TOWN, Vector2i(1, 9))
		objects_layer.set_cell(Vector2i(x, 36), SRC_TOWN, Vector2i(1, 10))

	# Clean open stone gate archway (no wizards!)

func _generate_decorations() -> void:
	# 1. Eldrin's Beehive Garden (Cols 29 to 32, Rows 9 to 10)
	objects_layer.set_cell(Vector2i(29, 9), SRC_TOWN, TT_FENCE_L)
	objects_layer.set_cell(Vector2i(30, 9), SRC_TOWN, TT_FENCE_M)
	objects_layer.set_cell(Vector2i(31, 9), SRC_TOWN, TT_FENCE_R)
	objects_layer.set_cell(Vector2i(29, 10), SRC_TOWN, TT_BEEHIVE_A)
	objects_layer.set_cell(Vector2i(30, 10), SRC_TOWN, TT_BEEHIVE_B)

	# 2. Master Torren's Smithy Yard with Cart (Cols 4 to 6, Rows 9 to 10)
	objects_layer.set_cell(Vector2i(4, 9), SRC_TOWN, TT_FENCE_L)
	objects_layer.set_cell(Vector2i(5, 9), SRC_TOWN, TT_FENCE_M)
	objects_layer.set_cell(Vector2i(6, 9), SRC_TOWN, TT_FENCE_R)
	objects_layer.set_cell(Vector2i(5, 10), SRC_TOWN, TT_CART)


