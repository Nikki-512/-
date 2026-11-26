extends CanvasLayer

const FONT = preload("res://assets/IBMPlexMono-Regular.ttf")
const GOLD := Color("#efc676")
const INK := Color("#111b2a")
const PAPER := Color("#f5e8cf")
const MINT := Color("#72dbbf")
var game
var root: Control
var theme := Theme.new()
var first: Button
var hud: Label

func _ready() -> void:
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	theme.default_font = FONT
	theme.default_font_size = 13
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#23334a")
		style.border_color = Color("#4e6881")
		style.set_border_width_all(1)
		match state:
			"hover":
				style.bg_color = Color("#3a5366")
				style.border_color = MINT
			"pressed":
				style.bg_color = Color("#345750")
			"focus":
				style.draw_center = false
				style.border_color = GOLD
				style.set_border_width_all(2)
			"disabled":
				style.bg_color = Color("#1b2737")
				style.border_color = Color("#3b4859")
		theme.set_stylebox(state, "Button", style)
	theme.set_color("font_color", "Button", PAPER)
	theme.set_color("font_disabled_color", "Button", Color("#a1a9b4"))
	root.theme = theme

func w(key: String) -> String:
	return game.word(key)

func panel(box: Rect2, color: Color, edge := Color.TRANSPARENT) -> void:
	var node := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = edge
	style.set_border_width_all(1)
	node.add_theme_stylebox_override("panel", style)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, box)

func place(node: Control, box: Rect2) -> void:
	root.add_child(node)
	node.position = box.position
	node.size = box.size

func label(value: String, box: Rect2, font_size := 14, color := PAPER, wrap := false) -> Label:
	var node := Label.new()
	node.text = value
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if wrap:
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	place(node, box)
	return node

func button(value: String, box: Rect2, callback: Callable, disabled := false) -> Button:
	var node := Button.new()
	node.text = value
	node.disabled = disabled
	node.pressed.connect(callback)
	place(node, box)
	if first == null and not disabled:
		first = node
	return node

func rebuild() -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.queue_free()
	first = null
	hud = null
	match game.mode:
		"menu":
			main_menu()
		"play":
			hud = label("", Rect2(17, 13, 580, 22), 12, MINT)
			button("Ⅱ", Rect2(594, 12, 30, 25), game.show_mode.bind("pause")).focus_mode = Control.FOCUS_NONE
		"levels":
			sheet(w("levels"))
			var names := ["sewer", "lab", "arena"]
			for index in range(3):
				var title := "%02d  %s" % [index + 1, w(names[index])]
				var locked: bool = game.progress.open <= index
				if locked:
					title += "  •  " + w("locked")
				button(title, Rect2(142, 120 + index * 42, 356, 33), game.start.bind(index + 1), locked)
			back_to("menu")
		"reset":
			sheet(w("reset"), w("reset_body"))
			button(w("cancel"), Rect2(142, 225, 168, 34), game.show_mode.bind("menu"))
			button(w("new"), Rect2(330, 225, 168, 34), game.confirm_new)
		"pause":
			sheet(w("pause"))
			button(w("resume"), Rect2(142, 120, 356, 33), game.show_mode.bind("play"))
			button(w("library"), Rect2(142, 164, 356, 33), game.open_library)
			button(w("menu"), Rect2(142, 208, 356, 33), game.show_mode.bind("menu"))
		"library":
			library()
		"dialog":
			var content := w(game.body) if not game.body.is_empty() else missing_items()
			sheet(w(game.heading), content)
			button(w("resume"), Rect2(142, 258, 356, 32), game.show_mode.bind("play"))
		"scene", "final":
			story()
		"defeat":
			sheet(w("defeat"))
			button(w("retry"), Rect2(142, 140, 356, 33), game.start.bind(3, false, false))
			button(w("menu"), Rect2(142, 184, 356, 33), game.show_mode.bind("menu"))
	if first != null and game.mode != "play":
		first.grab_focus()

func missing_items() -> String:
	var missing := PackedStringArray()
	for item in range(5):
		if item not in game.progress.items:
			missing.append(w(game.Words.CARDS[item]))
	return "\n".join(missing)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("accept_game") and first != null and game.mode != "play":
		first.pressed.emit()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if is_instance_valid(hud):
		match game.level:
			1:
				hud.text = w("sewer" if game.pos.y > 470 else ("street" if game.pos.x < 1180 else "roof"))
			2:
				hud.text = "%s %d%%   /   %s %d/5" % [w("gravity"), roundi(game.gravity() / 11.1),
					w("collection"), game.progress.items.size()]
			3:
				hud.text = "%s   /   %s %d/5" % [w("charged" if game.fight.charged else "essence"),
					"♥", game.health]

func main_menu() -> void:
	panel(Rect2(0, 0, 345, 360), Color("#121e2e"))
	panel(Rect2(344, 0, 3, 360), GOLD)
	label(w("tag"), Rect2(31, 36, 306, 20), 12, MINT)
	var title := w("title")
	if game.progress.language == 0:
		title = "Путешествие\nв КФУ"
	label(title, Rect2(29, 58, 306, 87), 32)
	var actions := [
		["new", game.new_game, false],
		["continue", func(): game.start(game.progress.level, true), game.progress.level == 0],
		["levels", game.show_mode.bind("levels"), false],
		["library", game.open_library, false]]
	for index in actions.size():
		var action: Array = actions[index]
		button(w(action[0]), Rect2(31, 151 + index * 36, 285, 30), action[1], action[2])
	for index in range(3):
		var choice := button(["Русский", "Татарча", "English"][index],
			Rect2(31 + index * 97, 309, 91, 26), game.choose_language.bind(index))
		if game.progress.language == index:
			choice.add_theme_color_override("font_color", GOLD)
	if game.progress.won:
		label(w("finished"), Rect2(370, 21, 253, 22), 14, GOLD)
	button(w("quit"), Rect2(435, 318, 179, 23), game.get_tree().quit)

func sheet(title: String, text := "") -> void:
	panel(Rect2(0, 0, 640, 360), Color(0.025, 0.04, 0.07, 0.67))
	panel(Rect2(122, 52, 396, 256), INK, Color("#597486"))
	panel(Rect2(122, 52, 395, 3), GOLD)
	label(title, Rect2(142, 69, 357, 32), 22, GOLD, true)
	if not text.is_empty():
		label(text, Rect2(142, 115, 355, 124), 13, PAPER, true)

func back_to(mode: String) -> void:
	button(w("back"), Rect2(142, 258, 356, 32), game.show_mode.bind(mode))

func library() -> void:
	sheet(w("library"))
	var index: int = game.page
	var key: String = game.Words.CARDS[index]
	var known: bool = index in game.progress.items
	var picture := TextureRect.new()
	picture.texture = game.FOSSIL_IMAGES[index]
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not known:
		picture.modulate = Color("#273448")
	panel(Rect2(142, 110, 83, 87), Color("#1c2b3e"))
	place(picture, Rect2(150, 122, 67, 60))
	label(w(key), Rect2(238, 107, 257, 39), 13, GOLD, true)
	label(w(key + "_body") if known else w("unknown"), Rect2(238, 146, 255, 86), 11, PAPER, true)
	for tab in range(5):
		var entry := button("%d" % (tab + 1), Rect2(142 + tab * 41, 232, 35, 25),
			select_card.bind(tab))
		if tab == index:
			entry.add_theme_color_override("font_color", GOLD)
	back_to(game.library_from)

func select_card(index: int) -> void:
	game.page = index
	rebuild()

func story() -> void:
	var scene: bool = game.mode == "scene"
	var headings := ["lobachevsky", "butlerov", "book", "arena"] if scene else ["arena", "diploma", "student", "credits"]
	var texts := ["scene_one", "scene_two", "", "combat_hint"] if scene else ["return", "graduation", "dream", "credits_body"]
	panel(Rect2(58, 225, 524, 119), INK, Color("#597486"))
	panel(Rect2(58, 225, 524, 2), GOLD)
	label(w(headings[game.page]), Rect2(75, 235, 490, 22), 16, GOLD)
	var key: String = texts[game.page]
	if not key.is_empty():
		label(w(key), Rect2(75, 260, 490, 58), 12, PAPER, true)
	var action := "resume" if scene and game.page == 3 else ("menu" if not scene and game.page == 3 else "next")
	button(w(action), Rect2(422, 315, 144, 23), game.scene_next)
