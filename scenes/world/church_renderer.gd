extends Node2D

# 1:1 Color Palette ported directly from Haven Town RPG (CGG_Pythongame constants.py)
const INK := Color(0.08, 0.08, 0.10, 1.0)
const STONE_DARK := Color(0.18, 0.18, 0.20, 1.0)
const STONE_LIGHT := Color(0.24, 0.24, 0.26, 1.0)
const WALL_STONE := Color(0.28, 0.28, 0.30, 1.0)
const WALL_TRIM := Color(0.36, 0.36, 0.38, 1.0)

const CARPET_RED := Color(0.72, 0.18, 0.20, 1.0)
const CARPET_GOLD := Color(0.96, 0.84, 0.35, 1.0)

const PEW_DARK := Color(0.28, 0.15, 0.08, 1.0)
const PEW_WOOD := Color(0.48, 0.26, 0.12, 1.0)
const PEW_LIGHT := Color(0.62, 0.36, 0.18, 1.0)

const ALTAR_BASE := Color(0.32, 0.32, 0.34, 1.0)
const ALTAR_CLOTH := Color(0.94, 0.92, 0.88, 1.0)
const ALTAR_GOLD := Color(0.98, 0.85, 0.28, 1.0)

const GLASS_BLUE := Color(0.15, 0.32, 0.65, 1.0)
const GLASS_RUBY := Color(0.68, 0.12, 0.22, 1.0)
const GLASS_GOLD := Color(0.95, 0.78, 0.25, 1.0)
const LIGHT_RAY := Color(1.0, 0.96, 0.75, 0.11)
const LIGHT_CORE := Color(1.0, 0.98, 0.82, 0.18)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var center_x := 640.0
	var carpet_w := 96.0
	var room_left := 160.0
	var room_right := 1120.0
	var room_top := 80.0
	var room_bottom := 860.0
	var wall_h := 140.0
	var floor_top := room_top + wall_h

	# 1. Outer Void / Border Fill (Completely blocks out Godot background)
	draw_rect(Rect2(-200, -200, 1680, 1200), Color(0.04, 0.04, 0.05))

	# 2. Checkered Cathedral Flagstone Floor
	var tile_sz := 48.0
	var cols := int((room_right - room_left) / tile_sz) + 1
	var rows := int((room_bottom - floor_top) / tile_sz) + 1

	for c in range(cols):
		var tx: float = room_left + float(c) * tile_sz
		for r in range(rows):
			var ty: float = floor_top + float(r) * tile_sz
			var is_even := ((c + r) % 2) == 0
			var col := STONE_LIGHT if is_even else STONE_DARK
			draw_rect(Rect2(tx, ty, tile_sz, tile_sz), col)
			draw_rect(Rect2(tx, ty, tile_sz, tile_sz), Color(0, 0, 0, 0.25), false, 1.0)

	# 3. North Sanctuary Wall (Gothic Ashlar Masonry)
	draw_rect(Rect2(room_left, room_top, room_right - room_left, wall_h), WALL_STONE)
	# Wall architectural moulding lines
	draw_line(Vector2(room_left, room_top), Vector2(room_right, room_top), INK, 3.0)
	draw_line(Vector2(room_left, room_top + 45.0), Vector2(room_right, room_top + 45.0), WALL_TRIM, 2.0)
	draw_line(Vector2(room_left, floor_top), Vector2(room_right, floor_top), INK, 3.0)

	# Left & Right Sanctuary Wall Columns
	draw_rect(Rect2(room_left - 24, room_top, 24, room_bottom - room_top), WALL_TRIM)
	draw_line(Vector2(room_left, room_top), Vector2(room_left, room_bottom), INK, 3.0)
	draw_rect(Rect2(room_right, room_top, 24, room_bottom - room_top), WALL_TRIM)
	draw_line(Vector2(room_right, room_top), Vector2(room_right, room_bottom), INK, 3.0)

	# 4. Central Velvet Runner Carpet with Golden Piping
	var carpet_left := center_x - carpet_w * 0.5
	var carpet_top := floor_top + 16.0
	var carpet_bottom := room_bottom
	draw_rect(Rect2(carpet_left, carpet_top, carpet_w, carpet_bottom - carpet_top), CARPET_RED)
	# Gold braided borders
	draw_line(Vector2(carpet_left, carpet_top), Vector2(carpet_left, carpet_bottom), CARPET_GOLD, 3.0)
	draw_line(Vector2(carpet_left + carpet_w, carpet_top), Vector2(carpet_left + carpet_w, carpet_bottom), CARPET_GOLD, 3.0)
	draw_line(Vector2(carpet_left, carpet_top), Vector2(carpet_left + carpet_w, carpet_top), CARPET_GOLD, 3.0)

	# 5. Rose Stained Glass Window (Centered on North Wall)
	var win_center := Vector2(center_x, room_top + 60.0)
	var win_radius := 36.0
	draw_circle(win_center, win_radius + 4.0, INK)
	draw_circle(win_center, win_radius, WALL_TRIM)
	draw_circle(win_center, win_radius - 4.0, GLASS_BLUE)
	# Stained glass quatrefoil petals
	var petal_dist := 14.0
	var petal_r := 10.0
	for angle_deg: float in [0.0, 90.0, 180.0, 270.0]:
		var rad := deg_to_rad(angle_deg)
		var p_pos := win_center + Vector2(cos(rad), sin(rad)) * petal_dist
		draw_circle(p_pos, petal_r, GLASS_RUBY)
		draw_arc(p_pos, petal_r, 0, TAU, 16, INK, 1.5)
	# Central Golden Core & Cross Tracery
	draw_circle(win_center, 9.0, GLASS_GOLD)
	draw_line(Vector2(win_center.x - win_radius + 4, win_center.y), Vector2(win_center.x + win_radius - 4, win_center.y), INK, 2.0)
	draw_line(Vector2(win_center.x, win_center.y - win_radius + 4), Vector2(win_center.x, win_center.y + win_radius - 4), INK, 2.0)

	# 6. High Altar Dais
	var dais_w := 220.0
	var dais_h := 70.0
	var dais_rect := Rect2(center_x - dais_w * 0.5, floor_top - 20.0, dais_w, dais_h)
	draw_rect(dais_rect, ALTAR_BASE)
	draw_rect(dais_rect, INK, false, 2.0)

	var cloth_w := 170.0
	var cloth_h := 45.0
	var cloth_rect := Rect2(center_x - cloth_w * 0.5, floor_top - 5.0, cloth_w, cloth_h)
	draw_rect(cloth_rect, ALTAR_CLOTH)
	draw_rect(cloth_rect, ALTAR_GOLD, false, 2.0)

	# 7. Church Wooden Pews (Rowed Benches)
	var pew_w := 140.0
	var pew_h := 28.0
	var pew_rows: Array[float] = [360.0, 480.0, 600.0, 720.0]
	for py in pew_rows:
		var left_px := center_x - carpet_w * 0.5 - pew_w - 40.0
		_draw_pew(left_px, py, pew_w, pew_h)

		var right_px := center_x + carpet_w * 0.5 + 40.0
		_draw_pew(right_px, py, pew_w, pew_h)

	# 8. Volumetric Cathedral Light Shafts (Casting down from Rose Window onto Altar & Carpet)
	var light_poly: PackedVector2Array = [
		Vector2(win_center.x - 24.0, win_center.y + 20.0),
		Vector2(win_center.x + 24.0, win_center.y + 20.0),
		Vector2(center_x + carpet_w * 0.9, room_bottom - 100.0),
		Vector2(center_x - carpet_w * 0.9, room_bottom - 100.0)
	]
	draw_colored_polygon(light_poly, LIGHT_RAY)

	var inner_light_poly: PackedVector2Array = [
		Vector2(win_center.x - 12.0, win_center.y + 24.0),
		Vector2(win_center.x + 12.0, win_center.y + 24.0),
		Vector2(center_x + carpet_w * 0.45, room_bottom - 220.0),
		Vector2(center_x - carpet_w * 0.45, room_bottom - 220.0)
	]
	draw_colored_polygon(inner_light_poly, LIGHT_CORE)

func _draw_pew(px: float, py: float, pw: float, ph: float) -> void:
	# Pew Shadow
	draw_rect(Rect2(px + 4, py + ph, pw, 6), Color(0, 0, 0, 0.35))
	# Main Seat Bench
	draw_rect(Rect2(px, py + ph * 0.35, pw, ph * 0.65), PEW_WOOD)
	# Upper Backrest with Highlight Trim
	draw_rect(Rect2(px, py, pw, ph * 0.35), PEW_LIGHT)
	draw_line(Vector2(px, py), Vector2(px + pw, py), Color(0.78, 0.50, 0.28), 2.0)
	# Dark Wood End Panels (Left & Right Armrests)
	draw_rect(Rect2(px - 6, py - 3, 8, ph + 6), PEW_DARK)
	draw_rect(Rect2(px - 6, py - 3, 8, ph + 6), INK, false, 1.5)
	draw_rect(Rect2(px + pw - 2, py - 3, 8, ph + 6), PEW_DARK)
	draw_rect(Rect2(px + pw - 2, py - 3, 8, ph + 6), INK, false, 1.5)
	# Bench outline
	draw_rect(Rect2(px, py, pw, ph), INK, false, 1.5)
