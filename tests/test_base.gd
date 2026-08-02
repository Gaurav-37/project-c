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
