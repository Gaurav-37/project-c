# res://tests/test_base.gd
#
# Minimal test-suite base. No GUT dependency — run headless via:
#   godot --headless --path . --script res://tests/run_tests.gd
#
# A suite is a script that extends this one and defines test_*() methods.
# Each is called automatically and failures are collected rather than
# thrown, so one bad assertion doesn't stop the rest of the suite.

extends RefCounted

var suite_name: String = ""
var passed: int = 0
var failed: int = 0
var failures: Array[String] = []


func run() -> void:
	suite_name = get_script().resource_path.get_file()
	var methods: Array[Dictionary] = get_script().get_script_method_list()
	for m in methods:
		var mname: String = m.name
		if mname.begins_with("test_"):
			call(mname)


func check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		failures.append(description)


func check_eq(actual, expected, description: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [description, expected, actual])


func check_approx(actual: float, expected: float, description: String) -> void:
	check(is_equal_approx(actual, expected), "%s (expected %s, got %s)" % [description, expected, actual])


# ---------------------------------------------------------------------------
# TREE HELPERS
#
# Most combat logic is pure and runs on a node that was never added to the
# scene. A few things — move_and_slide(), Area3D monitoring — are only legal
# inside the tree, so those suites park the node under the runner's root.
# No physics frames tick during a headless script run, so _physics_process is
# never called behind our backs: the test drives every tick by hand.
# ---------------------------------------------------------------------------

func add_to_tree(node: Node) -> void:
	var loop := Engine.get_main_loop() as SceneTree
	loop.root.add_child(node)


## Pull a node back out of the tree and release it. Paired with add_to_tree.
func discard(node: Node) -> void:
	if node.is_inside_tree():
		node.get_parent().remove_child(node)
	node.free()
