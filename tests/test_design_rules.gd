# res://tests/test_design_rules.gd
#
# Guardrails for the non-negotiable rules in CLAUDE.md. These do not test
# behaviour — they read the combat scripts as text and fail if a banned
# construct has appeared.
#
# The point is that these rules are easy to break by accident, especially by
# an assistant writing "helpful" code: one randf() for damage variance, one
# Timer for a cooldown, one delta multiply for smoothness, and the game's
# determinism is gone with no test failing anywhere else.
#
# Comments are stripped before scanning, so the rules can still be DISCUSSED
# in comments. (The stripper cuts at the first '#' on a line, so avoid '#'
# inside string literals in combat scripts.)

extends "res://tests/test_base.gd"

const COMBAT_SCRIPTS: Array[String] = [
	"res://scripts/combat/attack_data.gd",
	"res://scripts/combat/combat_constants.gd",
	"res://scripts/combat/combo_link.gd",
	"res://scripts/combat/input_buffer.gd",
	"res://scripts/combat/player_combat.gd",
]


## Source with comments removed, so a rule can be named in a comment
## without tripping the test that enforces it.
func _code_of(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var out := ""
	for line in f.get_as_text().split("\n"):
		var hash_at := line.find("#")
		out += (line if hash_at < 0 else line.substr(0, hash_at)) + "\n"
	return out


func _check_absent(token: String, reason: String) -> void:
	for path in COMBAT_SCRIPTS:
		var code := _code_of(path)
		check(not code.contains(token), "%s must not contain '%s' — %s" % [path.get_file(), token, reason])


# ---------------------------------------------------------------------------
# RULE 2 — NOTHING IS RANDOM
# ---------------------------------------------------------------------------

func test_no_randomness_in_combat() -> void:
	_check_absent("randi", "every outcome must be reproducible from the same inputs")
	_check_absent("randf", "every outcome must be reproducible from the same inputs")
	_check_absent("randomize", "every outcome must be reproducible from the same inputs")
	_check_absent("RandomNumberGenerator", "every outcome must be reproducible from the same inputs")


# ---------------------------------------------------------------------------
# RULE 1 — NO COOLDOWNS, AND NO WALL CLOCK ANYWHERE
# ---------------------------------------------------------------------------

func test_no_timers_in_combat() -> void:
	_check_absent("Timer", "abilities are gated by Momentum, never by elapsed time")
	_check_absent("create_timer", "abilities are gated by Momentum, never by elapsed time")


func test_no_wall_clock_in_combat() -> void:
	_check_absent("get_ticks_msec", "combat counts frames, not milliseconds")
	_check_absent("get_ticks_usec", "combat counts frames, not milliseconds")
	_check_absent("Time.", "combat counts frames, not milliseconds")


func test_no_awaits_in_combat() -> void:
	_check_absent("await", "an awaited coroutine resumes outside the tick order, which is how frame-exact logic goes soft")


# ---------------------------------------------------------------------------
# RULE 3 — GAMEPLAY LOGIC DRIVES, ANIMATION FOLLOWS
# ---------------------------------------------------------------------------

func test_combat_never_reads_the_animation_player() -> void:
	_check_absent("AnimationPlayer", "gameplay state is never read back out of animation")
	_check_absent("root_motion", "movement is code-driven; root motion is banned")


func test_combat_maths_does_not_use_delta() -> void:
	for path in COMBAT_SCRIPTS:
		# The tick signature's own `_delta` parameter is allowed; using the
		# value is not, because frame-rate-dependent maths is not reproducible.
		var code := _code_of(path).replace("_delta", "")
		check(not code.contains("delta"), "%s must not use delta — combat advances in whole frames at a fixed 60Hz" % path.get_file())


func test_combat_runs_in_physics_process_not_process() -> void:
	var code := _code_of("res://scripts/combat/player_combat.gd")
	check(code.contains("func _physics_process"), "the tick lives in _physics_process, which runs at a fixed rate")
	check(not code.contains("func _process"), "and not in _process, which runs at whatever the frame rate happens to be")


# ---------------------------------------------------------------------------
# RULE 4 — DATA, NOT CODE
# ---------------------------------------------------------------------------

func test_no_attack_timings_are_hardcoded_in_the_state_machine() -> void:
	var code := _code_of("res://scripts/combat/player_combat.gd")
	# Timings must be read off the AttackData resource, never written inline.
	check(code.contains("current_attack.total_frames()"), "the attack's length is read from its resource")
	check(code.contains("current_attack.can_cancel_to_attack"), "cancel windows are read from the resource, not hardcoded")


# ---------------------------------------------------------------------------
# RULE 5 — WINDOWS, NEVER TIMINGS
# ---------------------------------------------------------------------------

func test_cancel_windows_are_offsets_into_recovery() -> void:
	var code := _code_of("res://scripts/combat/attack_data.gd")
	check(code.contains("frames_into_recovery"), "cancel legality is computed from an offset into recovery")
	# If a cancel check ever compared against an absolute frame, retiming an
	# attack would silently move its windows.
	for fn in ["can_cancel_to_attack", "can_cancel_to_dodge", "can_cancel_to_parry", "can_cancel_to_swap"]:
		var at := code.find("func " + fn)
		check(at >= 0, "%s exists" % fn)
		if at < 0:
			continue
		var body := code.substr(at, 220)
		check(body.contains("frames_into_recovery"), "%s measures from the start of recovery, not from the start of the attack" % fn)
