extends Node2D

const Levels = preload("res://levels.gd")
const Progress = preload("res://progress.gd")
const Battle = preload("res://battle.gd")
const Words = preload("res://words.gd")
const Art = preload("res://art.gd")
const Interface = preload("res://interface.gd")
const SPEED := 176.0
const JUMP := 310.0
const ESSENCES := [Vector2(116, 251), Vector2(420, 193), Vector2(547, 251)]
const BOOK = preload("res://assets/book.png")
const FOSSIL_IMAGES = [preload("res://assets/geometry.png"), preload("res://assets/report.png"),
	preload("res://assets/ammonite.png"), preload("res://assets/trilobite.png"), preload("res://assets/belemnite.png")]

var save_path := Progress.PATH
var progress: Dictionary
var ui: CanvasLayer
var level := 0
var stage: Dictionary
var pos := Vector2.ZERO
var camera := Vector2.ZERO
var vertical := 0.0
var facing := 1
var floor_index := -1
var coyote := 0.0
var jump_buffer := 0.0
var climbing := false
var clock := 0.0
var gravity_time := 0.0
var seen := {}
var mode := "menu"
var heading := ""
var body := ""
var page := 0
var page_started := 0
var library_from := "menu"
var notice := ""
var notice_time := 0.0

var fight := {}
var boss := Vector2(484, 301)
var boss_facing := -1
var attack_time := 0.0
var attack_cycle := 0
var dive_lane := 0.0
var dive_start := Vector2.ZERO
var dive_end := Vector2.ZERO
var shots: Array[Dictionary] = []
var health := 5
var invincible := 0.0
var beam_time := 0.0
var beam_delay := 0.0
var beam_from := Vector2.ZERO
var beam_to := Vector2.ZERO
var shot_fired := false

func _ready() -> void:
	bind("left", [KEY_A, KEY_LEFT])
	bind("right", [KEY_D, KEY_RIGHT])
	bind("up", [KEY_W, KEY_UP])
	bind("jump", [KEY_SPACE])
	bind("lower", [KEY_Q])
	bind("raise", [KEY_E])
	bind("fire", [KEY_F])
	bind("pause_game", [KEY_ESCAPE])
	bind("accept_game", [KEY_ENTER, KEY_KP_ENTER])
	progress = Progress.load_game(save_path)
	update_title.call_deferred()
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	show_mode("menu")

func bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func word(key: String) -> String:
	return Words.get_text(key, progress.language)

func save() -> void:
	if Progress.save_game(progress, save_path) != OK:
		notice = "save_error"
		notice_time = 4.0

func update_title() -> void:
	get_window().title = word("title")

func choose_language(language: int) -> void:
	progress.language = language
	update_title.call_deferred()
	save()
	ui.rebuild()

func show_mode(next: String) -> void:
	mode = next
	page_started = Time.get_ticks_msec()
	ui.rebuild()
	queue_redraw()

func new_game() -> void:
	if progress.level > 0:
		show_mode("reset")
	else:
		confirm_new()

func confirm_new() -> void:
	progress = Progress.empty(progress.language)
	start(1)

func start(next: int, resume := false, show_intro := true) -> void:
	level = next
	stage = Levels.stage(level)
	invincible = 0.0
	seen.clear()
	clock = 0.0
	notice_time = 0.0
	var point: int = progress.point if resume else -1
	if level == 1 and point >= 0:
		seen.street = true
	gravity_time = float(progress.gravity_time) if resume and level == 2 else 0.0
	progress.level = level
	progress.open = maxi(progress.open, level)
	progress.point = point
	progress.gravity_time = gravity_time
	spawn(point)
	save()
	if level == 3:
		reset_battle()
		page = 0
		show_mode("scene" if show_intro else "play")
	elif resume and point >= 0:
		show_mode("play")
	else:
		dialog("sewer" if level == 1 else "lab", "start_hint" if level == 1 else "lab_hint")

func spawn(point: int) -> void:
	pos = stage.points[point] if point >= 0 else stage.spawn
	facing = 1
	floor_index = -1
	vertical = 0.0
	coyote = 0.0
	jump_buffer = 0.0
	climbing = false
	center_camera()

func center_camera() -> void:
	var bounds: Rect2 = stage.bounds
	camera = (pos - Vector2(300, 217)).clamp(bounds.position, bounds.end - Vector2(640, 360)).floor()

func dialog(title: String, text: String) -> void:
	heading = title
	body = text
	show_mode("dialog")

func open_library() -> void:
	library_from = mode
	page = 0
	show_mode("library")

func scene_next() -> void:
	page += 1
	page_started = Time.get_ticks_msec()
	if mode == "scene" and page == 4:
		show_mode("play")
	elif mode == "final" and page == 4:
		show_mode("menu")
	else:
		ui.rebuild()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		match mode:
			"play": show_mode("pause")
			"pause": show_mode("play")
			"library": show_mode(library_from)
			"levels", "reset": show_mode("menu")
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if mode != "play":
		return
	if event.is_action_pressed("up"):
		try_door()
	elif event.is_action_pressed("jump"):
		jump_buffer = 0.115
		if floor_index >= 0 and stage.slabs[floor_index].tone == "warp":
			var platform: Dictionary = stage.slabs[floor_index]
			if supports(platform, pos.x):
				warp(platform.target)
	elif floor_index >= 0 and (event.is_action_pressed("lower") or event.is_action_pressed("raise")):
		var platform: Dictionary = stage.slabs[floor_index]
		if platform.group > 0 and supports(platform, pos.x):
			var adjustment := 1 if event.is_action_pressed("raise") else -1
			var frequency := clampi(platform.hz + adjustment, 1, 5)
			if frequency != platform.hz:
				platform.hz = frequency
				Levels.tune(stage.slabs, platform)

func _physics_process(delta: float) -> void:
	if mode != "play":
		queue_redraw()
		return
	clock += delta
	notice_time = maxf(0.0, notice_time - delta)
	for platform in stage.slabs:
		platform.flash = maxf(0.0, platform.flash - delta)
	if level == 2:
		gravity_time = minf(23.0, gravity_time + delta)
	move_student(delta)
	center_camera()
	if level == 3:
		tick_battle(delta)
	else:
		tick_route()
	queue_redraw()

func gravity() -> float:
	return lerpf(1110.0, 490.0, gravity_time / 23.0) if level == 2 else 870.0

func supports(platform: Dictionary, x: float) -> bool:
	return x >= platform.x - 3 and x <= platform.x + platform.width + 3

func warp(target: Vector2) -> void:
	pos = target
	vertical = 0.0
	floor_index = -1
	jump_buffer = 0.0
	coyote = 0.0

func move_student(delta: float) -> void:
	var axis := Input.get_axis("left", "right")
	if axis != 0:
		facing = 1 if axis > 0 else -1
	if level == 1:
		var ladder: Rect2 = stage.ladder
		if Input.is_action_pressed("up") and ladder.grow(5).has_point(pos):
			pos.x = move_toward(pos.x, ladder.get_center().x, 95 * delta)
			pos.y = maxf(ladder.position.y, pos.y - 115 * delta)
			floor_index = -1
			climbing = true
			vertical = 0
			if pos.y == ladder.position.y:
				pos.x = ladder.get_center().x + 8
				climbing = false
			return
		if climbing and axis == 0 and jump_buffer <= 0:
			return
		climbing = false
	var bounds: Rect2 = stage.bounds
	pos.x = clampf(pos.x + axis * SPEED * delta, 10, bounds.end.x - 10)
	if floor_index >= 0 and not supports(stage.slabs[floor_index], pos.x):
		floor_index = -1
	coyote = 0.100 if floor_index >= 0 else maxf(0.0, coyote - delta)
	if jump_buffer > 0 and coyote > 0:
		vertical = -JUMP
		floor_index = -1
		coyote = 0.0
		jump_buffer = 0.0
	jump_buffer = maxf(0.0, jump_buffer - delta)
	if floor_index >= 0:
		return
	vertical = minf(560.0, vertical + gravity() * delta)
	var next_y := pos.y + vertical * delta
	if vertical >= 0:
		for index in stage.slabs.size():
			var platform: Dictionary = stage.slabs[index]
			if supports(platform, pos.x) and pos.y <= platform.y and next_y >= platform.y:
				next_y = platform.y
				floor_index = index
		if floor_index >= 0:
			vertical = 0
	pos.y = next_y

func tick_route() -> void:
	if pos.y > stage.bounds.end.y + 35:
		spawn(progress.point)
		return
	for index in stage.points.size():
		var point: Vector2 = stage.points[index]
		if floor_index >= 0 and pos.distance_to(point) < 22 and index != progress.point:
			progress.point = index
			progress.gravity_time = gravity_time
			notice = "checkpoint"
			notice_time = 2.0
			save()
	if level == 1:
		if pos.y <= 393 and pos.x > 665 and pos.x < 790 and not seen.has("street"):
			seen.street = true
			dialog("frequencies", "tune_hint")
		elif pos.x >= 1225 and pos.x < 1360 and pos.y < 334 and not seen.has("roof"):
			seen.roof = true
			dialog("roof", "roof_hint")
	else:
		if pos.x > 395 and pos.x < 500 and pos.y < 463 and pos.y > 400 and not seen.has("warp"):
			seen.warp = true
			dialog("warp", "warp_hint")
		for index in stage.items.size():
			var item: Vector2 = stage.items[index]
			if index not in progress.items and (pos - Vector2(0, 12)).distance_to(item) < 24:
				progress.items.append(index)
				progress.gravity_time = gravity_time
				notice = Words.CARDS[index]
				notice_time = 2.5
				save()

func try_door() -> void:
	if level < 3 and pos.distance_to(stage.exit) < 29:
		if level == 1 or progress.items.size() == 5:
			start(level + 1)
		else:
			dialog("missing", "")

func reset_battle() -> void:
	fight = {"hp": 100, "phase": 0, "charged": true, "essence": -1}
	boss = Vector2(474, 298)
	boss_facing = -1
	attack_time = 0
	attack_cycle = 0
	dive_lane = 298
	shots.clear()
	health = 5
	invincible = 0
	beam_delay = 0
	beam_time = 0
	shot_fired = false

func finish() -> void:
	progress.won = true
	save()
	page = 0
	show_mode("final")

func tick_battle(delta: float) -> void:
	invincible = maxf(0, invincible - delta)
	beam_time = maxf(0, beam_time - delta)
	beam_delay = maxf(0, beam_delay - delta)
	attack_time += delta
	var lane := 300.0 if attack_cycle % 3 == 0 else (252.0 if attack_cycle % 3 == 1 else 186.0)
	if attack_time < 2.05:
		boss.x = 320 + (165 if attack_cycle % 2 == 0 else -165) + sin(clock * 2) * 25
		boss.y = move_toward(boss.y, lane, 100 * delta)
		boss_facing = -1 if boss.x > pos.x else 1
	elif attack_time < 3.0:
		if not shot_fired:
			dive_lane = clampf(pos.y - 13, 170, 303)
			dive_start = boss
			dive_end = Vector2(58 if boss.x > 320 else 582, dive_lane)
			shot_fired = true
		if attack_cycle % 2 == 0:
			boss.y = move_toward(boss.y, dive_lane, 210 * delta)
	elif attack_time < 4.08:
		if attack_cycle % 2 == 0:
			boss = dive_start.lerp(dive_end, clampf((attack_time - 3.0) / 0.86, 0.0, 1.0))
			boss.y = dive_lane
			if boss.distance_to(pos - Vector2(0, 14)) < 30:
				hurt()
		elif shot_fired:
			shot_fired = false
			var direction := boss.direction_to(pos - Vector2(0, 12))
			for spread in [-0.23, 0.0, 0.23]:
				shots.append({"point": boss, "speed": direction.rotated(spread) * (153 + 13 * fight.phase)})
	else:
		attack_cycle += 1
		attack_time = 0
		shot_fired = false
	for index in range(shots.size() - 1, -1, -1):
		var projectile := shots[index]
		projectile.point += projectile.speed * delta
		if projectile.point.distance_to(pos - Vector2(0, 13)) < 15:
			hurt()
			shots.remove_at(index)
		elif not Rect2(-25, -25, 690, 410).has_point(projectile.point):
			shots.remove_at(index)
	if mode != "play":
		return
	if fight.essence >= 0 and ESSENCES[fight.essence].distance_to(pos - Vector2(0, 15)) < 26:
		Battle.recharge(fight)
	if fight.charged and beam_delay <= 0 and Input.is_action_pressed("fire"):
		beam_delay = 0.26
		beam_time = 0.12
		beam_from = pos + Vector2(facing * 9, -15)
		beam_to = Vector2(640 if facing > 0 else 0, beam_from.y)
		if (boss.x - beam_from.x) * facing >= -8 and absf(boss.y - beam_from.y) < 27:
			beam_to.x = boss.x
			Battle.hit(fight, 9)
			if fight.hp == 0:
				finish()

func hurt() -> void:
	if invincible > 0:
		return
	invincible = 1.25
	health -= 1
	if health <= 0:
		show_mode("defeat")

func _draw() -> void:
	if progress.is_empty():
		return
	Art.render(self)
