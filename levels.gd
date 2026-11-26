extends RefCounted

static func slab(x: int, y: int, width: int, tone := "", hz := 1, group := 0, target := Vector2.ZERO) -> Dictionary:
	return {"x": x, "y": y, "base": width, "width": width, "tone": tone, "hz": hz,
		"group": group, "target": target, "flash": 0.0}

static func stage(level: int) -> Dictionary:
	match level:
		1:
			return {
				"bounds": Rect2(0, -220, 2290, 900),
				"spawn": Vector2(43, 619),
				"points": [Vector2(668, 389), Vector2(1190, 329), Vector2(1790, 233)],
				"ladder": Rect2(645, 390, 28, 231),
				"exit": Vector2(2214, 173),
				"slabs": [
					slab(0, 620, 156), slab(208, 605, 97), slab(351, 580, 87),
					slab(490, 603, 74), slab(607, 620, 124),
					slab(604, 390, 188), slab(792, 390, 54, "cyan", 2, 1),
					slab(856, 390, 56, "cyan", 3, 1), slab(916, 390, 46, "amber", 3, 1),
					slab(784, 450, 235), slab(966, 421, 56), slab(991, 374, 94), slab(1110, 351, 73),
					slab(1183, 330, 122), slab(1305, 330, 62, "amber", 2, 2),
					slab(1544, 319, 70, "amber", 4, 2), slab(1658, 281, 69),
					slab(1753, 234, 111), slab(1891, 202, 99), slab(2021, 174, 269)]}
		2:
			return {
				"bounds": Rect2(0, -390, 1120, 960),
				"spawn": Vector2(56, 519),
				"points": [Vector2(472, 453), Vector2(617, 311), Vector2(781, 191)],
				"exit": Vector2(1035, 96),
				"items": [Vector2(275, 446), Vector2(797, 365), Vector2(967, 265),
					Vector2(436, 263), Vector2(226, 196)],
				"slabs": [
					slab(0, 520, 1120), slab(170, 491, 61), slab(239, 466, 103),
					slab(358, 454, 52), slab(410, 454, 122, "warp", 1, 0, Vector2(613, 291)),
					slab(540, 488, 66), slab(609, 432, 90), slab(752, 385, 110), slab(891, 337, 102),
					slab(934, 285, 116), slab(789, 272, 131), slab(561, 312, 140),
					slab(450, 304, 88), slab(335, 283, 117), slab(265, 249, 67),
					slab(175, 216, 100), slab(80, 269, 90), slab(716, 192, 136),
					slab(848, 159, 77), slab(932, 97, 153)]}
		_:
			return {
				"bounds": Rect2(0, 0, 640, 360),
				"spawn": Vector2(89, 321),
				"exit": Vector2.ZERO,
				"points": [],
				"slabs": [slab(0, 322, 640), slab(58, 273, 131), slab(247, 259, 145),
					slab(450, 272, 131), slab(149, 208, 109), slab(356, 213, 119)]}

static func tune(slabs: Array, changed: Dictionary) -> void:
	var totals := {}
	for platform in slabs:
		if platform.group == changed.group and not platform.tone.is_empty():
			var key := "%s/%s" % [platform.tone, platform.hz]
			totals[key] = totals.get(key, 0) + platform.base
	var changed_key := "%s/%s" % [changed.tone, changed.hz]
	for platform in slabs:
		if platform.group != changed.group or platform.tone.is_empty():
			continue
		var key := "%s/%s" % [platform.tone, platform.hz]
		platform.width = totals[key]
		if key == changed_key and platform.width > platform.base:
			platform.flash = 0.45
