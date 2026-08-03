# res://tests/run_tests.gd
#
# Headless test runner. No GUT dependency.
#
#   godot --headless --path . --script res://tests/run_tests.gd
#
# Exits 0 if every suite passed, 1 otherwise — safe to wire into CI.

extends SceneTree

const SUITE_PATHS: Array[String] = [
	# Pure logic
	"res://tests/test_attack_data.gd",
	"res://tests/test_input_buffer.gd",
	"res://tests/test_momentum.gd",
	"res://tests/test_combo_resolution.gd",
	# The state machine and the tick
	"res://tests/test_state_machine.gd",
	"res://tests/test_hitbox.gd",
	"res://tests/test_hitstop.gd",
	"res://tests/test_tick_order.gd",
	# Data and wiring
	"res://tests/test_attack_resources.gd",
	"res://tests/test_scene_wiring.gd",
	# The non-negotiables
	"res://tests/test_design_rules.gd",
]


## Suites run on the first frame rather than in _initialize(), because the
## scene tree's root is not live until the loop starts iterating — and the
## suites that exercise the real tick need to park a node in the tree.
func _process(_delta: float) -> bool:
	_run_all()
	return true


func _run_all() -> void:
	var total_passed := 0
	var total_failed := 0

	for path in SUITE_PATHS:
		var suite: RefCounted = load(path).new()
		suite.run()
		total_passed += suite.passed
		total_failed += suite.failed

		var status := "PASS" if suite.failed == 0 else "FAIL"
		print("[%s] %s — %d passed, %d failed" % [status, suite.suite_name, suite.passed, suite.failed])
		for f in suite.failures:
			print("    FAIL: ", f)

	print("---")
	print("%d passed, %d failed" % [total_passed, total_failed])
	quit(1 if total_failed > 0 else 0)
