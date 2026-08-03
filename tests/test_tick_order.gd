# res://tests/test_tick_order.gd
#
# The tick itself: hit-stop as a tick-skip, and the non-negotiable rule that
# the input buffer keeps filling while gameplay is frozen (design rule 6).
#
# These tests drive _physics_process() by hand, one tick at a time. Nothing
# ticks on its own during a headless script run, so the frame counts below
# are exact, not approximate.

extends "res://tests/test_base.gd"

const DT: float = 1.0 / 60.0


func _make_attack() -> AttackData:
	var a := AttackData.new()
	a.id = &"test_attack"
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12  # total 21
	a.cancel_to_attack_frame = -1  # no chaining: this suite measures one attack
	return a


## A player parked in the tree so move_and_slide() is legal.
func _make_player(atk: AttackData) -> PlayerCombat:
	var pc := PlayerCombat.new()
	pc.starting_attack = atk
	pc.attack_library = [atk] as Array[AttackData]
	var shape := CollisionShape3D.new()
	shape.shape = CapsuleShape3D.new()
	pc.add_child(shape)
	add_to_tree(pc)  # fires _ready() exactly once
	return pc


func _tick(pc: PlayerCombat, times: int = 1) -> void:
	for i in times:
		pc._physics_process(DT)


# ---------------------------------------------------------------------------
# HIT-STOP IS A TICK-SKIP
# ---------------------------------------------------------------------------

func test_frozen_tick_burns_one_hitstop_frame_and_nothing_else() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 7
	pc.hitstop_frames = 3
	var before := pc.global_frame

	_tick(pc)

	check_eq(pc.hitstop_frames, 2, "one frozen tick burns exactly one hit-stop frame")
	check_eq(pc.state_frame, 7, "gameplay does not advance while frozen")
	check_eq(pc.global_frame, before + 1, "the global frame counter keeps running regardless")

	discard(pc)


func test_freeze_lasts_exactly_the_frames_it_was_given() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 7
	pc.hitstop_frames = 4

	_tick(pc, 4)
	check_eq(pc.state_frame, 7, "still frozen through the 4th tick")
	check_eq(pc.hitstop_frames, 0, "the counter has run out")

	_tick(pc)
	check_eq(pc.state_frame, 8, "the 5th tick advances gameplay again")

	discard(pc)


func test_hitstop_is_a_counter_not_a_state() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 7
	pc.hitstop_frames = 3

	_tick(pc)

	check_eq(pc.state, PlayerCombat.State.ATTACK, "freezing does not change the state — the attack is still mid-swing")

	discard(pc)


# ---------------------------------------------------------------------------
# DESIGN RULE 6 — THE BUFFER FILLS DURING HIT-STOP
# ---------------------------------------------------------------------------

func test_the_buffer_is_still_polled_while_frozen() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.hitstop_frames = 60  # a freeze far longer than the buffer window
	pc._buffer._entries.append({"action": &"attack", "frame": pc.global_frame})

	# poll() runs the expiry pass. If the entry ages out while we are frozen,
	# poll() must have been called — which is the whole point of the rule.
	_tick(pc, CombatConstants.INPUT_BUFFER_FRAMES + 2)

	check_eq(pc._buffer._entries.size(), 0, "the buffer keeps ticking during hit-stop (stale entry expired)")

	discard(pc)


func test_an_input_pressed_on_impact_survives_the_freeze() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.hitstop_frames = 4  # a normal light-hit freeze
	pc._buffer._entries.append({"action": &"attack", "frame": pc.global_frame})

	_tick(pc, 4)

	check(pc._buffer.has(&"attack", pc.global_frame), "a press made on the impact frame is still buffered when the freeze ends")

	discard(pc)


# ---------------------------------------------------------------------------
# HIT-STOP MUST NOT RETIME AN ATTACK
# ---------------------------------------------------------------------------

## Ticks until the player returns to IDLE, optionally injecting a freeze the
## moment the attack reaches `freeze_at`. Returns the number of real ticks.
func _run_attack(pc: PlayerCombat, freeze_at: int, freeze_frames: int) -> int:
	pc._buffer._entries.append({"action": &"attack", "frame": pc.global_frame})
	var ticks := 0
	var injected := false
	while ticks < 400:
		pc._physics_process(DT)
		ticks += 1
		if not injected and freeze_frames > 0 \
				and pc.state == PlayerCombat.State.ATTACK \
				and pc.state_frame == freeze_at:
			pc.hitstop_frames = freeze_frames
			injected = true
		if ticks > 1 and pc.state == PlayerCombat.State.IDLE:
			break
	return ticks


func test_an_attack_runs_for_exactly_its_frame_count() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)

	var ticks := _run_attack(pc, 0, 0)

	# 1 tick to consume the buffered press and enter ATTACK, then total_frames() more.
	check_eq(ticks, atk.total_frames() + 1, "an unfrozen attack takes exactly startup+active+recovery gameplay frames")
	check_eq(pc.state, PlayerCombat.State.IDLE, "and lands back in IDLE")

	discard(pc)


func test_hitstop_adds_real_time_but_not_gameplay_frames() -> void:
	var atk := _make_attack()
	var clean := _make_player(atk)
	var frozen := _make_player(atk)

	var clean_ticks := _run_attack(clean, 0, 0)
	var frozen_ticks := _run_attack(frozen, 8, 5)  # freeze 5 frames on the active frames

	check_eq(frozen_ticks, clean_ticks + 5, "a 5-frame freeze costs 5 extra real ticks")
	check_eq(frozen.state, PlayerCombat.State.IDLE, "the attack still completes")

	discard(clean)
	discard(frozen)
