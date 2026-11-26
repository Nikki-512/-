extends SceneTree

const GAME = preload("res://main.tscn")
const Levels = preload("res://levels.gd")
const Battle = preload("res://battle.gd")
const Progress = preload("res://progress.gd")
const FONT = preload("res://assets/IBMPlexMono-Regular.ttf")
const DT := 1.0 / 60
var game
var failures := 0
var save_file := "user://qa_journey.cfg"

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if ok:
		print("OK: ", message)
	else:
		failures += 1
		push_error("%s | level %d pos %s mode %s" % [message, game.level, game.pos, game.mode])

func install() -> void:
	game = GAME.instantiate()
	if game.get_script() == null:
		quit(1)
		return
	game.save_path = save_file
	root.add_child(game)
	game.set_physics_process(false)

func accept() -> void:
	if game.ui.first != null:
		game.ui.first.pressed.emit()

func tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	game._unhandled_input(event)

func frame(count := 1) -> void:
	for _i in range(count):
		game._physics_process(DT)

func walk(x: float) -> void:
	var action := "left" if x < game.pos.x else "right"
	Input.action_press(action)
	for _i in range(360):
		if absf(game.pos.x - x) < 3 or game.mode != "play":
			break
		frame()
	Input.action_release(action)

func leap(x: float) -> void:
	tap("jump")
	frame()
	walk(x)
	frame(75)

func on_floor() -> bool:
	return game.floor_index >= 0

func door() -> void:
	tap("up")

func run() -> void:
	if OS.get_environment("KFU_QA_CHECKPOINT") == "1":
		save_file = Progress.PATH
		if FileAccess.file_exists(save_file):
			push_error("Street checkpoint test requires an isolated user directory.")
			quit(2)
			return
	for suffix in ["", ".previous", ".tmp"]:
		if FileAccess.file_exists(save_file + suffix):
			DirAccess.remove_absolute(save_file + suffix)
	install()
	var platforms := [
		Levels.slab(20, 0, 80, "cyan", 2, 1),
		Levels.slab(250, 0, 120, "cyan", 3, 1),
		Levels.slab(500, 0, 60, "cyan", 4, 1),
		Levels.slab(700, 0, 40, "amber", 3, 1)]
	platforms[0].hz = 3
	Levels.tune(platforms, platforms[0])
	check(platforms.map(func(p): return p.width) == [200, 200, 60, 40], "two-platform match")
	platforms[2].hz = 3
	Levels.tune(platforms, platforms[2])
	check(platforms.map(func(p): return p.width) == [260, 260, 260, 40], "three-platform match")
	for i in range(8):
		platforms[0].hz = 2 if i % 2 == 0 else 3
		Levels.tune(platforms, platforms[0])
		check(platforms[0].width == (80 if i % 2 == 0 else 260), "group recalculated without growth")
	var fight := {"hp":100, "phase":0, "charged":true, "essence":-1}
	for gate in [75, 50, 25, 0]:
		Battle.hit(fight, 1000)
		check(fight.hp == gate, "oversized shot stops exactly at %d" % gate)
		if gate > 0:
			Battle.hit(fight, 1000)
			check(fight.hp == gate and not fight.charged, "empty book cannot skip gate")
			Battle.recharge(fight)
	for glyph in "ӘӨҮҖҢҺәөүҗңһ":
		check(FONT.has_char(glyph.unicode_at(0)), "font includes " + glyph)

	accept()
	check(game.mode == "dialog", "main menu starts new game")
	accept()
	frame(2)
	walk(145)
	leap(238)
	check(game.pos.y == 605, "first sewer gap")
	walk(295)
	leap(379)
	walk(427)
	leap(523)
	walk(558)
	leap(658)
	Input.action_press("up")
	frame(150)
	Input.action_release("up")
	check(game.mode == "dialog" and game.heading == "frequencies", "climbed to frequency tutorial")
	accept()
	frame(4)
	check(game.progress.point == 0, "street checkpoint")
	game.choose_language(1)
	if OS.get_environment("KFU_QA_CHECKPOINT") == "1":
		quit(1 if failures else 0)
		return
	game.free()
	install()
	check(game.progress.language == 1 and game.progress.point == 0, "reload saves checkpoint and Tatar")
	game.start(game.progress.level, true)
	frame(3)
	check(game.pos.distance_to(Vector2(668, 390)) < 2.0, "continue returns to checkpoint")
	if game.mode == "dialog":
		accept()
	frame(20)
	walk(811)
	tap("raise")
	check(game.stage.slabs[6].width == 110 and game.stage.slabs[7].width == 110, "in-game safe resonance")
	walk(925)
	leap(1045)
	walk(1080)
	leap(1140)
	walk(1178)
	leap(1210)
	if game.mode == "dialog":
		accept()
	frame(42)
	walk(1240)
	if game.mode == "dialog":
		accept()
	walk(1359)
	leap(1551)
	check(game.pos.x < 1400, "full untuned rooftop jump falls short")
	walk(1325)
	tap("raise")
	tap("raise")
	walk(1430)
	check(on_floor() and game.pos.y == 330, "standing on extension of tuned rooftop")
	leap(1555)
	check(game.pos.y == 319 and on_floor(), "tuned rooftop jump lands")
	walk(1648)
	leap(1685)
	walk(1719)
	leap(1790)
	walk(1858)
	leap(1930)
	walk(1985)
	leap(2050)
	walk(2212)
	door()
	check(game.level == 2 and game.progress.open == 2, "KFU entrance opens level two")
	accept()
	frame(4)
	walk(164)
	leap(208)
	leap(266)
	check(0 in game.progress.items, "geometry picked up on lower floor")
	walk(337)
	leap(390)
	leap(472)
	if game.mode == "dialog":
		accept()
	frame(50)
	check(game.pos.y == 454 and game.pos.x < 500, "walking onto warp stays in place")
	walk(546)
	frame(30)
	check(game.pos.y == 488, "walking off warp does not teleport")
	walk(546)
	leap(557)
	leap(508)
	if game.mode == "dialog":
		accept()
	frame(60)
	tap("jump")
	check(game.pos.distance_to(Vector2(613, 291)) < 1.0, "jump triggers transfer")
	frame(60)
	check(game.pos.y == 312, "transfer lands on safe platform")
	walk(568)
	leap(480)
	leap(432)
	check(3 in game.progress.items, "trilobite picked up on west floor")
	walk(342)
	leap(298)
	leap(226)
	check(4 in game.progress.items, "belemnite picked up on west floor")
	walk(271)
	leap(403)
	leap(490)
	leap(608)
	walk(695)
	leap(811)
	walk(902)
	leap(968)
	check(2 in game.progress.items, "ammonite picked up on east floor")
	walk(939)
	leap(870)
	walk(798)
	leap(783)
	walk(847)
	leap(896)
	walk(920)
	leap(1016)
	walk(1034)
	door()
	check(game.level == 2 and game.heading == "missing" and 1 not in game.progress.items, "door locked with four and missing report named")
	if game.mode == "dialog":
		accept()
	walk(782)
	frame(60)
	walk(863)
	frame(60)
	walk(754)
	frame(65)
	walk(797)
	check(1 in game.progress.items and game.progress.items.size() == 5, "returned for missed report at minimum gravity")
	# Reascend the east floor after deliberately dropping to the report.
	walk(853)
	leap(944)
	leap(968)
	walk(938)
	leap(867)
	walk(797)
	leap(781)
	walk(847)
	leap(894)
	walk(921)
	leap(1005)
	walk(1036)
	door()
	check(game.level == 3 and game.progress.open == 3, "five items unlock final hall")
	if game.level != 3:
		quit(1)
		return
	for _i in range(4):
		accept()
	check(game.mode == "play", "finished all four story panels")
	frame(2)
	Input.action_press("fire")
	frame(80)
	Input.action_release("fire")
	check(game.fight.hp == 75 and game.fight.essence == 0, "beam hits first threshold")
	for _i in range(5):
		game.invincible = 0
		game.hurt()
	check(game.mode == "defeat", "defeat during first recharge")
	accept()
	check(game.fight.hp == 100 and game.fight.essence == -1 and game.health == 5 and game.progress.items.size() == 5, "retry resets only battle")
	finish_battle()
	check(game.mode == "final" and game.progress.won, "last ray starts diploma sequence")
	if game.mode == "final":
		for _i in range(4):
			accept()
	check(game.mode == "menu", "credits return to menu")
	game.free()
	install()
	check(game.progress.open == 3 and game.progress.items.size() == 5 and game.progress.won and game.progress.language == 1,
		"victory, every level, five exhibits and language reload together")
	game.start(1)
	check(game.progress.open == 3 and game.progress.items.size() == 5, "replaying level one preserves unlocks and collection")
	if FileAccess.file_exists(save_file):
		DirAccess.remove_absolute(save_file)
	quit(1 if failures else 0)

func shoot_until(next_essence: int) -> void:
	Input.action_press("fire")
	for _i in range(2200):
		if game.fight.essence == next_essence and next_essence >= 0 or game.mode != "play":
			break
		var desired := 1.0 if game.boss.x > game.pos.x else -1.0
		if game.facing != int(desired):
			var action := "right" if desired > 0 else "left"
			Input.action_press(action)
			frame()
			Input.action_release(action)
		else:
			frame()
	Input.action_release("fire")

func finish_battle() -> void:
	frame(5)
	shoot_until(0)
	check(game.fight.essence == 0, "essence 1 materializes")
	leap(115)
	check(game.fight.phase == 1, "essence 1 collected with a jump")
	walk(204)
	frame(25)
	shoot_until(1)
	check(game.fight.essence == 1, "essence 2 materializes")
	leap(174)
	leap(269)
	walk(380)
	leap(420)
	check(game.fight.phase == 2, "essence 2 collected from upper tier")
	walk(482)
	frame(35)
	shoot_until(2)
	check(game.fight.essence == 2, "essence 3 materializes")
	walk(548)
	check(game.fight.phase == 3, "essence 3 collected from east tier")
	walk(594)
	frame(36)
	shoot_until(-1)
