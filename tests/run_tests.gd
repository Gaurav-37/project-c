# res://tests/run_tests.gd
#
# Headless test runner. No GUT dependency.
#
#   godot --headless --path . --script res://tests/run_tests.gd
#
# Exits 0 if every suite passed, 1 otherwise — safe to wire into CI.

extends SceneTree

const SUITE_PATHS: Array[String] = [
	"res://tests/test_attack_data.gd",
	"res://tests/test_input_buffer.gd",
	"res://tests/test_momentum.gd",
	"res://tests/test_combo_resolution.gd",
]


func _initialize() -> void:
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
