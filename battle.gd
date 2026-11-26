extends RefCounted

const GATES := [75, 50, 25, 0]

static func hit(state: Dictionary, damage: int) -> void:
	if not state.charged or state.hp <= 0:
		return
	var gate: int = GATES[state.phase]
	state.hp = maxi(gate, state.hp - damage)
	if state.hp == gate and gate > 0:
		state.charged = false
		state.essence = state.phase

static func recharge(state: Dictionary) -> void:
	if state.essence < 0:
		return
	state.essence = -1
	state.phase += 1
	state.charged = true
