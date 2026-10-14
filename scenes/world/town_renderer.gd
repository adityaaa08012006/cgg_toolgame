extends Node2D

# Kenney RPG Base (art/tiles/rpg_base/PNG/) - 64x64 Real Pixel Art Tiles!
const TILE_GRASS = preload("res://art/tiles/rpg_base/PNG/rpgTile015.png")
const TILE_DIRT_ROAD = preload("res://art/tiles/rpg_base/PNG/rpgTile016.png")
const TILE_STONE_ROAD = preload("res://art/tiles/rpg_base/PNG/rpgTile017.png")
const TILE_WALL_STONE = preload("res://art/tiles/rpg_base/PNG/rpgTile040.png")
const TILE_WALL_RIM = preload("res://art/tiles/rpg_base/PNG/rpgTile018.png")
const TILE_WINDOW = preload("res://art/tiles/rpg_base/PNG/rpgTile044.png")
const TILE_DOOR = preload("res://art/tiles/rpg_base/PNG/rpgTile105.png")

# Roof Tiles
const TILE_ROOF_RED_L = preload("res://art/tiles/rpg_base/PNG/rpgTile155.png")
const TILE_ROOF_RED_M = preload("res://art/tiles/rpg_base/PNG/rpgTile156.png")
const TILE_ROOF_RED_R = preload("res://art/tiles/rpg_base/PNG/rpgTile157.png")

const TILE_ROOF_BLUE_L = preload("res://art/tiles/rpg_base/PNG/rpgTile175.png")
const TILE_ROOF_BLUE_M = preload("res://art/tiles/rpg_base/PNG/rpgTile176.png")
const TILE_ROOF_BLUE_R = preload("res://art/tiles/rpg_base/PNG/rpgTile177.png")

# Props, Carpets & Nature
const TILE_TREE_ROUND = preload("res://art/tiles/rpg_base/PNG/rpgTile217.png")
const TILE_TREE_PINE = preload("res://art/tiles/rpg_base/PNG/rpgTile218.png")
const TILE_BUSH = preload("res://art/tiles/rpg_base/PNG/rpgTile203.png")
const TILE_FLOWERS = preload("res://art/tiles/rpg_base/PNG/rpgTile204.png")
const TILE_ANVIL = preload("res://art/tiles/rpg_base/PNG/rpgTile194.png")
const TILE_WOOD_FENCE = preload("res://art/tiles/rpg_base/PNG/rpgTile183.png")
const TILE_CARPET_HEAD = preload("res://art/tiles/rpg_base/PNG/rpgTile111.png")
const TILE_CARPET_MID = preload("res://art/tiles/rpg_base/PNG/rpgTile112.png")
const TILE_CARPET_TAIL = preload("res://art/tiles/rpg_base/PNG/rpgTile113.png")

const TILE_SZ: float = 64.0
const COLS: int = 20
const ROWS: int = 20

var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	# 1. Base Meadow (Lush 64x64 grass pixel tiles across entire 1280x1280 map)
	for c in range(COLS):
		var x: float = float(c) * TILE_SZ
		for r in range(ROWS):
			var y: float = float(r) * TILE_SZ
			draw_texture(TILE_GRASS, Vector2(x, y))

	# 2. Cobblestone Highways & Intersections
	# North-South Main Highway (Columns 9 & 10 from church y=192 down to gate y=1152)
	for r in range(3, ROWS):
		var y: float = float(r) * TILE_SZ
		draw_texture(TILE_STONE_ROAD, Vector2(9.0 * TILE_SZ, y))
		draw_texture(TILE_STONE_ROAD, Vector2(10.0 * TILE_SZ, y))

	# East-West Market Street (Rows 8 & 9 from Forge x=192 to Cottage x=1088)
	for c in range(3, 17):
		var x: float = float(c) * TILE_SZ
		draw_texture(TILE_STONE_ROAD, Vector2(x, 8.0 * TILE_SZ))
		draw_texture(TILE_STONE_ROAD, Vector2(x, 9.0 * TILE_SZ))

	# Connecting pathway to Forge (Cols 2-3, Row 8)
	draw_texture(TILE_STONE_ROAD, Vector2(2.0 * TILE_SZ, 8.0 * TILE_SZ))
	draw_texture(TILE_STONE_ROAD, Vector2(3.0 * TILE_SZ, 8.0 * TILE_SZ))

	# Connecting pathway to Cottage (Cols 16-17, Row 8)
	draw_texture(TILE_STONE_ROAD, Vector2(16.0 * TILE_SZ, 8.0 * TILE_SZ))
	draw_texture(TILE_STONE_ROAD, Vector2(17.0 * TILE_SZ, 8.0 * TILE_SZ))

	# 3. North Cathedral Exterior (Cols 7 to 12, Rows 0 to 4)
	# Blue Slate Roof (2 Rows)
	draw_texture(TILE_ROOF_BLUE_L, Vector2(7.0 * TILE_SZ, 0.0))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(8.0 * TILE_SZ, 0.0))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(9.0 * TILE_SZ, 0.0))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(10.0 * TILE_SZ, 0.0))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(11.0 * TILE_SZ, 0.0))
	draw_texture(TILE_ROOF_BLUE_R, Vector2(12.0 * TILE_SZ, 0.0))

	draw_texture(TILE_ROOF_BLUE_L, Vector2(7.0 * TILE_SZ, 1.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(8.0 * TILE_SZ, 1.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(9.0 * TILE_SZ, 1.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(10.0 * TILE_SZ, 1.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(11.0 * TILE_SZ, 1.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_R, Vector2(12.0 * TILE_SZ, 1.0 * TILE_SZ))

	# Cathedral Stone Wall (Rows 2 & 3)
	for c in range(7, 13):
		var x: float = float(c) * TILE_SZ
		# Row 2: Windows and stone
		if c == 8 or c == 11:
			draw_texture(TILE_WINDOW, Vector2(x, 2.0 * TILE_SZ))
		else:
			draw_texture(TILE_WALL_STONE, Vector2(x, 2.0 * TILE_SZ))

		# Row 3: Double entrance door and stone
		if c == 9 or c == 10:
			draw_texture(TILE_DOOR, Vector2(x, 3.0 * TILE_SZ))
		else:
			draw_texture(TILE_WALL_STONE, Vector2(x, 3.0 * TILE_SZ))

	# Cathedral Entrance carpet runner leading out
	draw_texture(TILE_CARPET_HEAD, Vector2(9.5 * TILE_SZ - 32.0, 4.0 * TILE_SZ))
	draw_texture(TILE_CARPET_TAIL, Vector2(9.5 * TILE_SZ - 32.0, 4.8 * TILE_SZ))

	# 4. Master Torren's Blacksmith Forge (West: Cols 2 to 5, Rows 5 to 7)
	# Red Tiled Roof (Row 5)
	draw_texture(TILE_ROOF_RED_L, Vector2(2.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_RED_M, Vector2(3.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_RED_M, Vector2(4.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_RED_R, Vector2(5.0 * TILE_SZ, 5.0 * TILE_SZ))

	# Forge Stone Walls (Row 6)
	draw_texture(TILE_WALL_STONE, Vector2(2.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_WINDOW, Vector2(3.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_DOOR, Vector2(4.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_WALL_STONE, Vector2(5.0 * TILE_SZ, 6.0 * TILE_SZ))

	# Outdoor Workshop Equipment (Row 7.5)
	draw_texture(TILE_ANVIL, Vector2(2.8 * TILE_SZ, 7.3 * TILE_SZ))
	draw_texture(TILE_WOOD_FENCE, Vector2(1.5 * TILE_SZ, 7.0 * TILE_SZ))
	draw_texture(TILE_WOOD_FENCE, Vector2(1.5 * TILE_SZ, 8.0 * TILE_SZ))

	# Forge Hearth Glow (Flickering firelight)
	var hearth_pos := Vector2(4.8 * TILE_SZ, 7.5 * TILE_SZ)
	draw_texture(TILE_ANVIL, hearth_pos - Vector2(16.0, 16.0))
	var f_glow := sin(anim_time * 9.0) * 2.5 + 10.0
	draw_circle(hearth_pos, f_glow, Color(1.0, 0.45, 0.1, 0.8))
	draw_circle(hearth_pos, f_glow * 0.5, Color(1.0, 0.9, 0.3, 0.95))

	# 5. Eldrin's Herbalist Cottage (East: Cols 14 to 17, Rows 5 to 7)
	# Blue Tiled Roof (Row 5)
	draw_texture(TILE_ROOF_BLUE_L, Vector2(14.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(15.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_M, Vector2(16.0 * TILE_SZ, 5.0 * TILE_SZ))
	draw_texture(TILE_ROOF_BLUE_R, Vector2(17.0 * TILE_SZ, 5.0 * TILE_SZ))

	# Cottage Walls (Row 6)
	draw_texture(TILE_WALL_STONE, Vector2(14.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_DOOR, Vector2(15.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_WINDOW, Vector2(16.0 * TILE_SZ, 6.0 * TILE_SZ))
	draw_texture(TILE_WALL_STONE, Vector2(17.0 * TILE_SZ, 6.0 * TILE_SZ))

	# Herb & Flower Garden Beds (Row 7 & 8)
	draw_texture(TILE_WOOD_FENCE, Vector2(18.0 * TILE_SZ, 6.5 * TILE_SZ))
	draw_texture(TILE_WOOD_FENCE, Vector2(18.0 * TILE_SZ, 7.5 * TILE_SZ))
	draw_texture(TILE_FLOWERS, Vector2(14.2 * TILE_SZ, 7.3 * TILE_SZ))
	draw_texture(TILE_FLOWERS, Vector2(15.4 * TILE_SZ, 7.3 * TILE_SZ))
	draw_texture(TILE_BUSH, Vector2(16.8 * TILE_SZ, 7.3 * TILE_SZ))

	# 6. Central Goddess Altar Plaza (Intersection of main roads)
	var altar_pos := Vector2(9.5 * TILE_SZ, 8.5 * TILE_SZ)
	draw_texture(TILE_CARPET_HEAD, Vector2(9.0 * TILE_SZ, 8.0 * TILE_SZ))
	draw_texture(TILE_CARPET_HEAD, Vector2(10.0 * TILE_SZ, 8.0 * TILE_SZ))
	draw_texture(TILE_ANVIL, Vector2(9.5 * TILE_SZ, 8.2 * TILE_SZ))

	# Divine Holy Radiance
	var aura := sin(anim_time * 4.0) * 4.0 + 38.0
	draw_circle(Vector2(10.0 * TILE_SZ, 8.7 * TILE_SZ), aura, Color(1.0, 0.95, 0.40, 0.18))

	# 7. South Fortified Gate & Perimeter Palisade (Row 18, y=1152)
	# Wooden palisade wall left and right
	for c in range(0, 9):
		draw_texture(TILE_WOOD_FENCE, Vector2(float(c) * TILE_SZ, 18.0 * TILE_SZ))
	for c in range(11, 20):
		draw_texture(TILE_WOOD_FENCE, Vector2(float(c) * TILE_SZ, 18.0 * TILE_SZ))

	# Fortified Stone Gate Towers
	draw_texture(TILE_WALL_STONE, Vector2(8.0 * TILE_SZ, 17.5 * TILE_SZ))
	draw_texture(TILE_WALL_RIM, Vector2(8.0 * TILE_SZ, 16.5 * TILE_SZ))
	draw_texture(TILE_WALL_STONE, Vector2(11.0 * TILE_SZ, 17.5 * TILE_SZ))
	draw_texture(TILE_WALL_RIM, Vector2(11.0 * TILE_SZ, 16.5 * TILE_SZ))

	# Magical Barrier across South Gate road if quest is not complete
	if not QuestManager.quest_complete:
		var bar_rect := Rect2(9.0 * TILE_SZ, 17.8 * TILE_SZ, 2.0 * TILE_SZ, 28.0)
		var b_pulse := sin(anim_time * 6.0) * 0.15 + 0.60
		draw_rect(bar_rect, Color(0.70, 0.12, 0.95, b_pulse))
		draw_line(Vector2(bar_rect.position.x, bar_rect.position.y + 14), Vector2(bar_rect.end.x, bar_rect.position.y + 14), Color(1.0, 0.5, 1.0, 0.95), 3.0)

	# 8. Trees & Natural Foliage (Real Kenney pixel art trees!)
	# West forest edge
	var tree_coords: Array[Vector2] = [
		Vector2(0.5, 1.0), Vector2(2.0, 1.5), Vector2(4.0, 1.0),
		Vector2(0.5, 3.5), Vector2(1.5, 4.0),
		Vector2(0.5, 9.5), Vector2(1.5, 11.0), Vector2(0.5, 13.0), Vector2(1.5, 15.0),
		# East forest edge
		Vector2(14.0, 1.0), Vector2(16.0, 1.5), Vector2(18.0, 1.0),
		Vector2(18.0, 3.5), Vector2(17.5, 9.5), Vector2(18.5, 11.5),
		Vector2(17.5, 13.5), Vector2(18.5, 15.5),
		# Park groves near town square
		Vector2(5.5, 10.5), Vector2(6.5, 12.5), Vector2(5.5, 14.5),
		Vector2(13.5, 10.5), Vector2(12.5, 12.5), Vector2(13.5, 14.5),
		# Gate sentry trees
		Vector2(7.0, 16.5), Vector2(12.5, 16.5)
	]

	for idx in range(tree_coords.size()):
		var tp: Vector2 = tree_coords[idx]
		var tex := TILE_TREE_ROUND if (idx % 2 == 0) else TILE_TREE_PINE
		draw_texture(tex, tp * TILE_SZ)

	# Scatter bushes and flowers across grasslands
	var bush_coords: Array[Vector2] = [
		Vector2(3.0, 3.0), Vector2(5.5, 4.0), Vector2(14.0, 3.5), Vector2(16.5, 4.0),
		Vector2(3.5, 10.5), Vector2(4.5, 13.0), Vector2(15.0, 10.5), Vector2(15.5, 13.0)
	]
	for bp in bush_coords:
		draw_texture(TILE_BUSH, bp * TILE_SZ)

	var flower_coords: Array[Vector2] = [
		Vector2(4.5, 9.5), Vector2(2.5, 12.0), Vector2(14.5, 12.0), Vector2(16.0, 11.0),
		Vector2(7.5, 7.5), Vector2(12.0, 7.5)
	]
	for fp in flower_coords:
		draw_texture(TILE_FLOWERS, fp * TILE_SZ)
