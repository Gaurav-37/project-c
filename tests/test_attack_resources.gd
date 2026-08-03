# res://tests/test_attack_resources.gd
#
# The real .tres files on disk, not hand-built stand-ins.
#
# Two kinds of test live here:
#
#   STRUCTURAL — invariants that must hold no matter how the attack is tuned
#                (a cancel window that opens after recovery ends can never
#                fire; a link pointing at a missing id can never resolve).
#                These should never need editing.
#
#   FRAME TABLE — the exact numbers from design doc 6.7. These are the
#                designer's to change. WHEN YOU RETUNE AN ATTACK, UPDATE THE
#                NUMBERS HERE TOO — a failure in this section means the data
#                and the design doc have drifted apart, not that code broke.

extends "res://tests/test_base.gd"

const L1_PATH := "res://data/attacks/glaive_l1.tres"
const L2_PATH := "res://data/attacks/glaive_l2.tres"


func _all_attacks() -> Array[AttackData]:
	return [load(L1_PATH) as AttackData, load(L2_PATH) as AttackData]


func _lookup() -> Dictionary:
	var d := {}
	for a in _all_attacks():
		d[a.id] = a
	return d


# ---------------------------------------------------------------------------
# STRUCTURAL
# ---------------------------------------------------------------------------

func test_both_attack_resources_load_as_attack_data() -> void:
	var l1 := load(L1_PATH)
	var l2 := load(L2_PATH)
	check(l1 is AttackData, "glaive_l1.tres loads as an AttackData")
	check(l2 is AttackData, "glaive_l2.tres loads as an AttackData")


func test_ids_are_present_and_unique() -> void:
	var seen: Array[StringName] = []
	for a in _all_attacks():
		check(a.id != &"", "%s has an id" % a.resource_path.get_file())
		check(not a.id in seen, "%s has a unique id — links resolve by id, so duplicates would be ambiguous" % a.id)
		seen.append(a.id)


func test_every_phase_has_at_least_one_frame() -> void:
	for a in _all_attacks():
		check(a.startup_frames > 0, "%s has startup frames — an instant attack cannot be punished" % a.id)
		check(a.active_frames > 0, "%s has active frames — otherwise it can never connect" % a.id)
		check(a.recovery_frames > 0, "%s has recovery frames — otherwise it has no commitment" % a.id)


func test_cancel_windows_open_inside_recovery() -> void:
	for a in _all_attacks():
		if a.cancel_to_attack_frame >= 0:
			check(a.cancel_to_attack_frame < a.recovery_frames,
				"%s: the attack cancel window opens before recovery ends (offset %d into %d frames)" % [a.id, a.cancel_to_attack_frame, a.recovery_frames])
		if a.cancel_to_swap_frame >= 0:
			check(a.cancel_to_swap_frame < a.recovery_frames,
				"%s: the swap cancel window opens before recovery ends" % a.id)


func test_hitstop_values_are_sane() -> void:
	for a in _all_attacks():
		check(a.hitstop_frames_on_hit > 0, "%s freezes on a clean hit — a hit with no freeze reads as a whiff" % a.id)
		check(a.hitstop_frames_on_bounce > a.hitstop_frames_on_hit,
			"%s: an armour bounce freezes longer than a clean hit, so the hand can tell them apart" % a.id)


func test_hitboxes_have_volume() -> void:
	for a in _all_attacks():
		check(a.hitbox_size.x > 0.0 and a.hitbox_size.y > 0.0 and a.hitbox_size.z > 0.0,
			"%s has a hitbox with real volume" % a.id)


func test_every_link_points_at_an_attack_that_exists() -> void:
	var known := _lookup()
	for a in _all_attacks():
		for link in a.links:
			check(link != null, "%s has no empty slots in its links array" % a.id)
			if link == null:
				continue
			check(known.has(link.next_attack_id),
				"%s links to '%s', which must exist as an AttackData or the branch is dead" % [a.id, link.next_attack_id])


func test_every_link_uses_an_input_that_actually_exists() -> void:
	for a in _all_attacks():
		for link in a.links:
			if link == null:
				continue
			check(InputMap.has_action(link.input_action),
				"%s links on '%s', which must be bound in the Input Map or the branch can never fire" % [a.id, link.input_action])


func test_momentum_rises_through_the_chain() -> void:
	var known := _lookup()
	var l1 := known[&"glaive_l1"] as AttackData
	var l2 := known[&"glaive_l2"] as AttackData
	check(l2.momentum_gain > l1.momentum_gain,
		"L2 pays more momentum than L1 — finishing a string has to be worth more than opening one")


# ---------------------------------------------------------------------------
# FRAME TABLE — design doc 6.7. Update alongside the doc when retuning.
# ---------------------------------------------------------------------------

func test_l1_matches_the_design_table() -> void:
	var a := load(L1_PATH) as AttackData
	check_eq(a.id, &"glaive_l1", "L1 id")
	check_eq(a.startup_frames, 6, "L1 startup")
	check_eq(a.active_frames, 3, "L1 active")
	check_eq(a.recovery_frames, 12, "L1 recovery")
	check_eq(a.cancel_to_attack_frame, 4, "L1 cancel into attack at recovery offset 4")
	check_approx(a.momentum_gain, 4.0, "L1 momentum gain")


func test_l2_matches_the_design_table() -> void:
	var a := load(L2_PATH) as AttackData
	check_eq(a.id, &"glaive_l2", "L2 id")
	check_eq(a.startup_frames, 7, "L2 startup")
	check_eq(a.active_frames, 4, "L2 active")
	check_eq(a.recovery_frames, 13, "L2 recovery")
	check_eq(a.cancel_to_attack_frame, 4, "L2 cancel into attack at recovery offset 4")
	check_approx(a.momentum_gain, 6.0, "L2 momentum gain")


func test_l1_chains_into_l2_on_attack() -> void:
	var a := load(L1_PATH) as AttackData
	check_eq(a.links.size(), 1, "L1 has exactly one branch so far")
	if a.links.size() != 1:
		return
	var link := a.links[0] as ComboLink
	check_eq(link.input_action, &"attack", "the L1 branch is taken by pressing attack again")
	check_eq(link.next_attack_id, &"glaive_l2", "and leads to L2")
	check_approx(link.required_momentum, 0.0, "the opening chain step is free — momentum gating starts at step 10")
	check(not link.requires_hit_confirm, "L1 into L2 is available on a whiff, so a missed opener can still be finished")


func test_l2_is_the_end_of_the_chain_for_now() -> void:
	var a := load(L2_PATH) as AttackData
	check_eq(a.links.size(), 0, "L2 has no branches yet — L3 is build-order step 9")
