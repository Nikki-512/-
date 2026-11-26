extends RefCounted

const FONT = preload("res://assets/IBMPlexMono-Regular.ttf")
const STUDENT = preload("res://assets/student.png")
const LOB = preload("res://assets/lobachevsky.png")
const BUT = preload("res://assets/butlerov.png")
const DRAGON = preload("res://assets/dragon.png")
const GOLD := Color("#f4cb7c")
const MINT := Color("#77e9cc")
const MILK := Color("#f5e8cf")
const VIOLET := Color("#cea3ff")
const ALARM := Color("#ff806a")
const INK := Color("#111a29")

static func block(c: Node2D, x: float, y: float, width: float, height: float, tint: Color) -> void:
	c.draw_rect(Rect2(floorf(x), floorf(y), width, height), tint)

static func poly(c: Node2D, points: Array, tint: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array(points), tint)

static func text(c: Node2D, point: Vector2, value: String, size := 12, tint := MILK) -> void:
	c.draw_string(FONT, point.floor(), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)

static func sprite(c: Node2D, image: Texture2D, foot: Vector2, scale: int, face := 1, tint := Color.WHITE) -> void:
	var size := image.get_size() * scale
	var origin := (foot - Vector2(size.x / 2, size.y)).floor()
	c.draw_set_transform(origin + (Vector2(size.x, 0) if face < 0 else Vector2.ZERO),
		0, Vector2(face, 1))
	c.draw_texture_rect(image, Rect2(Vector2.ZERO, size), false, tint)
	c.draw_set_transform(Vector2.ZERO)

static func sky(c: Node2D, scroll: Vector2, dark := false) -> void:
	var top := Color("#222b47") if dark else Color("#263a58")
	var bottom := Color("#71485e") if dark else Color("#b67a64")
	for row in range(18):
		block(c, 0, row * 20, 640, 20, top.lerp(bottom, row / 17.0))
	for index in range(74):
		var x := fposmod(index * 173.0 - scroll.x * 0.12, 640)
		var y := fposmod(index * index * 29.0 - scroll.y * 0.07, 250)
		block(c, x, y, 2 if index % 9 == 0 else 1, 1, Color("#d9b7a4"))
	var moon := Vector2(530 - fposmod(scroll.x * 0.055, 160), 102 - scroll.y * 0.04)
	c.draw_circle(moon.floor(), 47, Color("#d7a27a"))
	for stripe in range(4):
		block(c, moon.x - 45 + stripe * 6, moon.y + stripe * 8, 91 - stripe * 12, 3, bottom)
	for layer in range(2):
		var offset := fposmod(scroll.x * (0.19 + layer * 0.12), 79)
		var wall_y := 278.0 - scroll.y * 0.25 + layer * 21
		var wall := Color("#3c3952") if layer == 0 else Color("#2c314a")
		for index in range(-1, 10):
			var x := index * 79.0 - offset
			var y := wall_y - ((index * index + layer * 3) % 5) * 13
			block(c, x + 4, y, 73, 370 - y, wall)
			poly(c, [Vector2(x, y), Vector2(x + 30, y - 27), Vector2(x + 47, y - 27), Vector2(x + 79, y)], wall.darkened(0.16))
			for window in range(3):
				block(c, x + 13 + window * 19, y + 11, 5, 9,
					Color("#a16f65") if (index + window) % 3 == 0 else wall.darkened(0.23))
		var tower_x := 436.0 - fposmod(scroll.x * 0.12, 240)
		if layer == 0:
			block(c, tower_x, wall_y - 92, 20, 94, wall)
			block(c, tower_x + 6, wall_y - 115, 8, 26, wall)
			poly(c, [Vector2(tower_x - 4, wall_y - 91), Vector2(tower_x + 10, wall_y - 121),
				Vector2(tower_x + 24, wall_y - 91)], wall)

static func campus(c: Node2D, base: Vector2, scale: float) -> void:
	var x := base.x
	var y := base.y
	block(c, x, y - 74 * scale, 224 * scale, 74 * scale, Color("#a29189"))
	block(c, x + 56 * scale, y - 99 * scale, 112 * scale, 99 * scale, Color("#edc7a0"))
	poly(c, [Vector2(x + 46 * scale, y - 99 * scale), Vector2(x + 112 * scale, y - 131 * scale),
		Vector2(x + 178 * scale, y - 99 * scale)], Color("#6e4c56"))
	poly(c, [Vector2(x + 62 * scale, y - 100 * scale), Vector2(x + 112 * scale, y - 123 * scale),
		Vector2(x + 162 * scale, y - 100 * scale)], Color("#f3d8aa"))
	block(c, x, y - 77 * scale, 224 * scale, 5 * scale, GOLD)
	block(c, x + 57 * scale, y - 96 * scale, 111 * scale, 4 * scale, MILK)
	for col in [62, 83, 135, 156]:
		block(c, x + col * scale, y - 91 * scale, 8 * scale, 87 * scale, MILK)
		block(c, x + (col - 3) * scale, y - 91 * scale, 14 * scale, 4 * scale, GOLD)
		block(c, x + (col - 2) * scale, y - 8 * scale, 12 * scale, 5 * scale, Color("#fff2d5"))
	for col in [12, 32, 184, 204]:
		for row in [22, 51]:
			block(c, x + col * scale, y - row * scale, 9 * scale, 15 * scale, INK)
			block(c, x + (col + 2) * scale, y - (row - 2) * scale, 5 * scale, 8 * scale, Color("#c29363"))
	block(c, x + 104 * scale, y - 42 * scale, 17 * scale, 42 * scale, INK)
	block(c, x - 4 * scale, y - 3 * scale, 232 * scale, 6 * scale, Color("#675a62"))

static func sewer(c: Node2D, camera: Vector2, clock: float) -> void:
	var top := 403 - camera.y
	block(c, 0, top, 640, 390, Color("#141d2b"))
	for y in range(407, 670, 16):
		for x in range(0, 810, 35):
			var p := Vector2(x + (y % 32) * 0.8, y) - camera
			block(c, p.x, p.y, 33, 14, Color("#202c3c") if (x + y) % 4 == 0 else Color("#1a2636"))
	for x in [77, 279, 458, 657]:
		var p := Vector2(x, 475) - camera
		block(c, p.x - 6, top, 12, 89, Color("#283848"))
		poly(c, [p + Vector2(-12, 0), p + Vector2(12, 0), p + Vector2(52, 109), p + Vector2(-52, 109)], Color(0.96, 0.65, 0.26, 0.075))
		block(c, p.x - 11, p.y - 4, 22, 7, GOLD)
		block(c, p.x - 8, p.y + 3, 16, 2, MILK)
	for x in [158, 316, 526]:
		var p := Vector2(x, 580) - camera
		block(c, p.x, p.y, 12, 76, Color("#314e57"))
		block(c, p.x - 2, p.y, 16, 5, Color("#557077"))
	var water_y := 653 - camera.y
	block(c, 0, water_y, 640, 60, Color("#183f4a"))
	for x in range(0, 640, 24):
		var step := int(clock * 14) % 24
		block(c, (x + step) % 640, water_y + (x % 3) * 3, 10, 2, MINT.darkened(0.4))

static func laboratory(c: Node2D, camera: Vector2) -> void:
	block(c, 0, 0, 640, 360, Color("#182639"))
	for y in range(-400, 560, 24):
		var screen_y := y - camera.y
		if screen_y < -24 or screen_y > 360:
			continue
		block(c, 0, screen_y, 640, 2, Color("#22354a"))
	for x in range(30, 1150, 148):
		var screen_x := x - camera.x
		block(c, screen_x, 0, 12, 360, Color("#2d4256"))
		block(c, screen_x + 1, 0, 2, 360, Color("#3a5867"))
		for y in range(-150, 525, 97):
			var screen_y := y - camera.y
			block(c, screen_x + 31, screen_y, 66, 54, Color("#30475d"))
			block(c, screen_x + 34, screen_y + 3, 60, 48, Color("#172d43"))
			block(c, screen_x + 36, screen_y + 5, 26, 45, Color("#214157"))
			block(c, screen_x + 35, screen_y + 23, 58, 3, Color("#335268"))
			block(c, screen_x + 62, screen_y + 4, 3, 47, Color("#335268"))
	for x in [90, 520, 1005]:
		var point := Vector2(x, 507) - camera
		block(c, point.x - 29, point.y - 55, 58, 60, Color("#273e54"))
		block(c, point.x - 19, point.y - 46, 38, 19, Color("#0d1727"))
		for index in range(5):
			block(c, point.x - 15 + index * 6, point.y - 34 - (index * 3 % 8), 3, 5 + index % 3, MINT)

static func shield(c: Node2D, pos: Vector2, filled: bool) -> void:
	var piece := [Vector2(-42, -36), Vector2(42, -36), Vector2(42, 19), Vector2(0, 47), Vector2(-42, 19)]
	var shape := PackedVector2Array()
	for point in piece:
		shape.append(pos + point)
	c.draw_colored_polygon(shape, GOLD)
	for index in range(shape.size()):
		shape[index] = pos + piece[index] * 0.92
	c.draw_colored_polygon(shape, Color("#f1dcc0"))
	block(c, pos.x - 28, pos.y + 17, 56, 5, Color("#58846c"))
	if filled:
		sprite(c, DRAGON, pos + Vector2(0, 18), 2, 1, Color("#937567"))

static func render(c) -> void:
	var view: Vector2 = c.camera
	if c.mode in ["menu", "levels", "reset"] or (c.mode == "library" and c.library_from == "menu"):
		sky(c, Vector2(150, -20), true)
		campus(c, Vector2(365, 276), 1.13)
		sprite(c, DRAGON, Vector2(511, 137), 3)
		sprite(c, STUDENT, Vector2(466, 308), 3, -1)
		return
	if c.mode in ["scene", "final"]:
		story_art(c)
		return
	if c.level == 2:
		laboratory(c, view)
	else:
		sky(c, view, c.level == 3)
	if c.level == 1:
		if view.y + 360 > 400:
			sewer(c, view, c.clock)
		var ladder: Rect2 = c.stage.ladder
		for x in [ladder.position.x + 4, ladder.end.x - 6]:
			block(c, x - view.x, ladder.position.y - view.y, 4, ladder.size.y, GOLD.darkened(0.34))
		for y in range(int(ladder.position.y) + 5, int(ladder.end.y), 12):
			block(c, ladder.position.x + 4 - view.x, y - view.y, 21, 3, GOLD)
		campus(c, Vector2(2037, 174) - view, 1.38)
	elif c.level == 3:
		campus(c, Vector2(64, 320), 2.28)
		shield(c, Vector2(322, 159), false)
	for platform in c.stage.slabs:
		platform_art(c, platform, view)
	for point in c.stage.points:
		var p: Vector2 = point - view
		block(c, p.x - 1, p.y - 28, 3, 28, MILK)
		block(c, p.x + 2, p.y - 27, 13, 8, MINT if c.stage.points.find(point) == c.progress.point else GOLD)
	if c.level == 2:
		for index in c.stage.items.size():
			if index not in c.progress.items:
				var point: Vector2 = c.stage.items[index] - view
				var lift := sin(c.clock * 4 + index) * 3
				c.draw_circle(point, 15, Color(0.35, 0.9, 0.78, 0.16))
				sprite(c, c.FOSSIL_IMAGES[index], point + Vector2(0, 8 + lift), 2)
		if c.floor_index >= 0:
			var platform: Dictionary = c.stage.slabs[c.floor_index]
			if platform.tone == "warp":
				var goal: Vector2 = platform.target - view
				c.draw_dashed_line(c.pos - view, goal, VIOLET, 2, 6)
				gem(c, goal, VIOLET)
	if c.level <= 2:
		var door: Vector2 = c.stage.exit - view
		block(c, door.x - 15, door.y - 47, 30, 47, GOLD)
		block(c, door.x - 12, door.y - 44, 24, 44, INK)
		block(c, door.x + 6, door.y - 21, 3, 3, MINT if c.level == 1 or c.progress.items.size() == 5 else ALARM)
		if c.pos.distance_to(c.stage.exit) < 49:
			text(c, door + Vector2(-49, -53), c.word("door"))
	var foot: Vector2 = c.pos - view
	var walking: bool = Input.get_axis("left", "right") != 0 and c.floor_index >= 0 and c.mode == "play"
	if c.invincible <= 0 or int(c.clock * 16) % 2 == 0:
		sprite(c, STUDENT, foot - Vector2(0, 2 if walking and int(c.clock * 14) % 2 == 0 else 0), 2, -c.facing)
	if c.level == 3:
		battle_art(c)
	block(c, 11, 10, 315 if c.level > 1 else 248, 24, Color(0.04, 0.07, 0.11, 0.90))
	if c.notice_time > 0:
		block(c, 11, 329, 330, 23, INK)
		text(c, Vector2(19, 345), c.word(c.notice), 12, GOLD)

static func platform_art(c, p: Dictionary, view: Vector2) -> void:
	var x: float = p.x - view.x
	var y: float = p.y - view.y
	var width: int = p.width
	var color := Color("#c0bec0")
	var thickness := 10
	match p.tone:
		"cyan": color = MINT
		"amber": color = GOLD
		"warp": color = VIOLET
	if p.group > 0:
		thickness = 11 + p.hz * 4
	block(c, x, y, width, thickness + 3, INK)
	block(c, x, y, width, 3, color.lerp(Color.WHITE, p.flash))
	block(c, x + 2, y + 4, width - 4, thickness - 4, color.darkened(0.73))
	for mark in range(5, width - 4, 13):
		block(c, x + mark, y + thickness - 3, 6, 1, color.darkened(0.43))
	if p.group > 0:
		var icon := "◆" if p.tone == "cyan" else "▲"
		text(c, Vector2(x + 5, y + 14), "%s %d %s" % [icon, p.hz, c.word("hz")], 10, color)
	elif p.tone == "warp":
		for mark in range(12, width - 8, 16):
			gem(c, Vector2(x + mark, y + 5), VIOLET, 3)

static func gem(c: Node2D, p: Vector2, color: Color, radius := 8) -> void:
	poly(c, [p + Vector2(0, -radius), p + Vector2(radius, 0), p + Vector2(0, radius), p + Vector2(-radius, 0)], color)
	block(c, p.x - 1, p.y - 2, 3, 3, MILK)

static func battle_art(c) -> void:
	if c.attack_time >= 2.05 and c.attack_time < 3.0:
		var dive: bool = c.attack_cycle % 2 == 0
		if dive:
			c.draw_dashed_line(Vector2(0, c.dive_lane), Vector2(640, c.dive_lane), ALARM, 2, 9)
		else:
			c.draw_arc(c.boss, 35 + sin(c.clock * 20) * 5, 0, TAU, 24, ALARM, 3)
		block(c, 190, 99, 260, 20, INK)
		text(c, Vector2(199, 113), c.word("dash" if dive else "volley"), 12, ALARM)
	sprite(c, DRAGON, c.boss + Vector2(0, 23), 3, c.boss_facing,
		Color("#ffc597") if c.attack_time >= 2.05 and c.attack_time < 3.0 else Color.WHITE)
	for projectile in c.shots:
		gem(c, projectile.point, ALARM, 6)
	if c.fight.essence >= 0:
		var point: Vector2 = c.ESSENCES[c.fight.essence]
		c.draw_circle(point, 18 + sin(c.clock * 6) * 3, Color(0.35, 0.9, 0.78, 0.23))
		gem(c, point, MINT)
		text(c, point + Vector2(-3, -21), "▼", 12, MINT)
	if c.beam_time > 0:
		c.draw_line(c.beam_from, c.beam_to, MINT, 6)
		c.draw_line(c.beam_from, c.beam_to, MILK, 2)
	block(c, 15, 45, 610, 24, INK)
	text(c, Vector2(24, 61), c.word("arena"), 12, MILK)
	block(c, 108, 50, 470, 13, Color("#433445"))
	block(c, 108, 50, 470 * c.fight.hp / 100.0, 13, ALARM)
	for part in range(1, 4):
		block(c, 108 + part * 117.5, 50, 2, 13, MILK)
	text(c, Vector2(587, 61), str(c.fight.hp), 11, MILK)

static func story_art(c) -> void:
	sky(c, Vector2.ZERO, c.mode == "scene")
	campus(c, Vector2(78, 238), 2.1)
	var elapsed := (Time.get_ticks_msec() - int(c.page_started)) / 1000.0
	shield(c, Vector2(474, 122), c.mode == "final" and (c.page > 0 or elapsed >= 1.35))
	if c.mode == "final" and c.page == 0 and elapsed < 1.35:
		var flight := smoothstep(0, 1.35, elapsed)
		var origin := Vector2(125, 112).lerp(Vector2(474, 140), flight)
		sprite(c, DRAGON, origin - Vector2(0, sin(flight * PI) * 65), 3 if flight < 0.55 else 2)
	block(c, 0, 221, 640, 139, Color("#262e42"))
	block(c, 0, 219, 640, 2, Color("#796c65"))
	sprite(c, LOB, Vector2(215, 220), 3)
	sprite(c, BUT, Vector2(305, 220), 3)
	sprite(c, STUDENT, Vector2(394, 220), 3)
	var time := Time.get_ticks_msec() / 1000.0
	if c.mode == "scene" and c.page in [2, 3]:
		var center := Vector2(342, 153)
		for index in range(5):
			var orbit := Vector2.from_angle(index * TAU / 5 + time * 1.6) * (66 * (1 - smoothstep(0, 1.6, elapsed)) + 3)
			sprite(c, c.FOSSIL_IMAGES[index], center + orbit, 2, 1, Color(1, 1, 1, 0.63))
		c.draw_circle(center, 26 + sin(time * 4) * 4, Color(0.6, 0.9, 0.55, 0.23))
		sprite(c, c.BOOK, center + Vector2(0, 12), 3, 1, Color(1, 1, 1, smoothstep(0.55, 1.6, elapsed)))
	if c.mode == "final" and c.page in [1, 2]:
		var diploma_x := 353 + sin(time * 2.0) * 8
		block(c, diploma_x, 188, 22, 13, MILK)
		block(c, diploma_x + 9, 188, 4, 13, ALARM)
		for index in range(26):
			var x := (index * 139) % 640
			var y := fposmod(index * 33.0 + time * (21 + index % 6), 217)
			block(c, x, y, 3, 5, GOLD if index % 2 == 0 else MINT)
