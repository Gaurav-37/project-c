# res://tests/test_attack_data.gd
#
# AttackData phase helpers and cancel-window boundaries.
# Uses the same startup/active/recovery shape as glaive_l1 (6 / 3 / 12)
# so boundary frames are easy to reason about:
#   startup  : frames 0-5
#   active   : frames 6-8
#   recovery : frames 9-20  (recovery offset 0-11)

extends "res://tests/test_base.gd"


func _make_attack() -> AttackData:
	var a := AttackData.new()
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12
	a.cancel_to_attack_frame = 4
	a.cancel_to_dodge_frame = -1
	a.cancel_to_parry_frame = -1
	a.cancel_to_swap_frame = 4
	return a


func test_phase_boundaries() -> void:
	var a := _make_attack()

	check(a.is_in_startup(0), "frame 0 is startup")
	check(a.is_in_startup(5), "frame 5 (last startup frame) is startup")
	check(not a.is_in_startup(6), "frame 6 is not startup")

	check(not a.is_in_active(5), "frame 5 is not active")
	check(a.is_in_active(6), "frame 6 (first active frame) is active")
	check(a.is_in_active(8), "frame 8 (last active frame) is active")
	check(not a.is_in_active(9), "frame 9 is not active")

	check(not a.is_in_recovery(8), "frame 8 is not recovery")
	check(a.is_in_recovery(9), "frame 9 (first recovery frame) is recovery")
	check(a.is_in_recovery(20), "frame 20 (last recovery frame) is recovery")


func test_total_and_recovery_start() -> void:
	var a := _make_attack()
	check_eq(a.total_frames(), 21, "total_frames sums startup+active+recovery")
	check_eq(a.recovery_start_frame(), 9, "recovery_start_frame = startup+active")


func test_frames_into_recovery() -> void:
	var a := _make_attack()
	check_eq(a.frames_into_recovery(8), -1, "frame 8 (pre-recovery) is -1")
	check_eq(a.frames_into_recovery(9), 0, "frame 9 is recovery offset 0")
	check_eq(a.frames_into_recovery(13), 4, "frame 13 is recovery offset 4")


func test_cancel_to_attack_exact_opening_frame() -> void:
	var a := _make_attack()
	# cancel_to_attack_frame = 4 -> legal at recovery offset >= 4, i.e. frame >= 13
	check(not a.can_cancel_to_attack(12), "frame 12 (offset 3): cancel window not yet open")
	check(a.can_cancel_to_attack(13), "frame 13 (offset 4): cancel window opens exactly here")
	check(a.can_cancel_to_attack(20), "frame 20 (offset 11): still open through end of recovery")


func test_cancel_window_disabled_by_negative_one() -> void:
	var a := _make_attack()
	check(not a.can_cancel_to_dodge(20), "cancel_to_dodge_frame = -1 means never open, even at last frame")
	check(not a.can_cancel_to_parry(20), "cancel_to_parry_frame = -1 means never open, even at last frame")


func test_is_perfect_swap_window() -> void:
	var a := _make_attack()
	# cancel_to_swap_frame = 4, SWAP_CANCEL_WINDOW = 6 -> perfect window is offset [4, 10)
	check(not a.is_perfect_swap(12), "offset 3: before the perfect swap window")
	check(a.is_perfect_swap(13), "offset 4: perfect swap window opens exactly here")
	check(a.is_perfect_swap(18), "offset 9: last frame still inside the perfect swap window")
	check(not a.is_perfect_swap(19), "offset 10: one frame past the perfect swap window")


func test_is_perfect_swap_disabled_by_negative_one() -> void:
	var a := _make_attack()
	a.cancel_to_swap_frame = -1
	check(not a.is_perfect_swap(13), "cancel_to_swap_frame = -1 disables perfect swap entirely")
