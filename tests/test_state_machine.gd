# res://tests/test_state_machine.gd
#
# The state machine itself: entering actions from neutral, action lengths,
# and the guarantee that hit-stop was never modelled as a state.
#
# These call _evaluate_transitions() directly rather than ticking, so each
# test names the exact frame it cares about.

extends "res://tests/test_base.gd"


func _make_attack(id: StringName) -> AttackData:
	var a := AttackData.new()
	a.id = id
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12  # total 21
	return a


func _make_player() -> PlayerCombat:
	var atk := _make_attack(&"l1")
	var pc := PlayerCombat.new()
	pc.starting_attack = atk
	pc.attack_library = [atk] as Array[AttackData]
	pc._ready()
	pc.global_frame = 100
	return pc


func _buffer(pc: PlayerCombat, action: StringName) -> void:
	pc._buffer._entries.append({"action": action, "frame": pc.global_frame})


# ---------------------------------------------------------------------------
# THE STATE LIST
# ---------------------------------------------------------------------------

func test_states_are_exactly_the_documented_seven() -> void:
	var expected := ["IDLE", "MOVING", "ATTACK", "DODGE", "PARRY", "HEAL", "KNOCKDOWN"]
	check_eq(PlayerCombat.State.keys(), expected, "the state list matches the design doc — in particular there is NO hit-stop state, because hit-stop is a counter")


# ---------------------------------------------------------------------------
# ENTERING ACTIONS FROM NEUTRAL
# ---------------------------------------------------------------------------

func test_buffered_attack_starts_the_starting_attack() -> void:
	var pc := _make_player()
	_buffer(pc, &"attack")

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.ATTACK, "a buffered attack press leaves neutral")
	check(pc.current_attack == pc.starting_attack, "a chain always opens with starting_attack")
	check_eq(pc.state_frame, 0, "the new action starts on frame 0")
	check(not pc.attack_did_connect, "hit-confirm starts clean on every new attack")

	pc.free()


func test_attack_can_be_started_out_of_moving() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.MOVING
	_buffer(pc, &"attack")

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.ATTACK, "attacking interrupts a walk")
	check(not pc.has_move_target, "starting an attack drops the move order — attacks commit")

	pc.free()


func test_attack_wins_over_a_simultaneous_dodge() -> void:
	var pc := _make_player()
	_buffer(pc, &"dodge")
	_buffer(pc, &"attack")

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.ATTACK, "attack is checked first from neutral")
	check(pc._buffer.has(&"dodge", pc.global_frame), "the unused dodge press stays buffered rather than being thrown away")

	pc.free()


func test_dodge_and_parry_start_from_neutral() -> void:
	var pc := _make_player()
	_buffer(pc, &"dodge")
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.DODGE, "a buffered dodge press starts a dodge")
	pc.free()

	var pc2 := _make_player()
	_buffer(pc2, &"parry")
	pc2._evaluate_transitions()
	check_eq(pc2.state, PlayerCombat.State.PARRY, "a buffered parry press starts a parry")
	pc2.free()


# ---------------------------------------------------------------------------
# ACTION LENGTHS
# ---------------------------------------------------------------------------

func test_attack_ends_on_the_frame_after_its_last() -> void:
	var pc := _make_player()
	pc.current_attack = pc.starting_attack
	pc.state = PlayerCombat.State.ATTACK

	pc.state_frame = pc.starting_attack.total_frames() - 1
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.ATTACK, "frame 20 (last recovery frame): still committed")

	pc.state_frame = pc.starting_attack.total_frames()
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.IDLE, "frame 21: the attack is over")
	check(pc.current_attack == null, "and the attack is cleared")

	pc.free()


func test_attack_state_with_no_attack_falls_back_to_idle() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = null

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.IDLE, "an ATTACK state with nothing to swing recovers to IDLE instead of hanging")

	pc.free()


func test_dodge_lasts_its_constant() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.DODGE

	pc.state_frame = CombatConstants.DODGE_TOTAL_FRAMES - 1
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.DODGE, "still dodging one frame before the end")

	pc.state_frame = CombatConstants.DODGE_TOTAL_FRAMES
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.IDLE, "the dodge ends after DODGE_TOTAL_FRAMES")

	pc.free()


func test_parry_lasts_startup_plus_active_plus_recovery() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.PARRY
	var total := CombatConstants.PARRY_STARTUP + CombatConstants.PARRY_ACTIVE + CombatConstants.PARRY_RECOVERY

	pc.state_frame = total - 1
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.PARRY, "still parrying one frame before the end")

	pc.state_frame = total
	pc._evaluate_transitions()
	check_eq(pc.state, PlayerCombat.State.IDLE, "the parry ends after its three phases")

	pc.free()


# ---------------------------------------------------------------------------
# HEAL — a momentum spend, not an item
# ---------------------------------------------------------------------------

func test_heal_is_refused_without_the_momentum_to_pay_for_it() -> void:
	var pc := _make_player()
	pc.momentum = CombatConstants.HEAL_COST - 1.0
	_buffer(pc, &"heal")

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.IDLE, "healing you cannot afford does not start")
	check_approx(pc.momentum, CombatConstants.HEAL_COST - 1.0, "and costs nothing")

	pc.free()


func test_heal_spends_momentum_up_front() -> void:
	var pc := _make_player()
	pc.momentum = 40.0
	_buffer(pc, &"heal")

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.HEAL, "an affordable heal starts")
	check_approx(pc.momentum, 40.0 - CombatConstants.HEAL_COST, "the cost is paid when the heal begins, not when it lands")

	pc.free()


func test_heal_restores_health_at_the_end_of_its_animation() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.HEAL
	pc.health = 40.0

	pc.state_frame = 39
	pc._evaluate_transitions()
	check_approx(pc.health, 40.0, "no health arrives early — the heal is committed and punishable")

	pc.state_frame = 40
	pc._evaluate_transitions()
	check_approx(pc.health, 40.0 + CombatConstants.HEAL_AMOUNT, "the heal lands on its last frame")
	check_eq(pc.state, PlayerCombat.State.IDLE, "and returns to neutral")

	pc.free()


func test_heal_cannot_overfill_health() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.HEAL
	pc.health = CombatConstants.PLAYER_MAX_HEALTH - 5.0
	pc.state_frame = 40

	pc._evaluate_transitions()

	check_approx(pc.health, CombatConstants.PLAYER_MAX_HEALTH, "healing clamps at max health")

	pc.free()


# ---------------------------------------------------------------------------
# KNOCKDOWN
# ---------------------------------------------------------------------------

func test_a_knockdown_hit_puts_the_player_on_the_floor() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = pc.starting_attack

	pc.receive_hit(10.0, true)

	check_eq(pc.state, PlayerCombat.State.KNOCKDOWN, "a knockdown blow ends in KNOCKDOWN, not IDLE")
	check(pc.current_attack == null, "the interrupted attack is dropped")

	pc.free()


func test_knockdown_has_no_exit_yet() -> void:
	var pc := _make_player()
	pc.state = PlayerCombat.State.KNOCKDOWN
	pc.state_frame = 600

	pc._evaluate_transitions()

	check_eq(pc.state, PlayerCombat.State.KNOCKDOWN, "rise options are build-order step 17 — this test flips when that lands")

	pc.free()
