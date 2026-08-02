# res://tests/test_combo_resolution.gd
#
# Combo resolution: a ComboLink should only fire when its momentum
# requirement is met and, if set, the previous attack actually connected.
# This is the guardrail for build-order step 6 (the first real combo).

extends "res://tests/test_base.gd"


func _make_attack(id: StringName) -> AttackData:
	var a := AttackData.new()
	a.id = id
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12
	a.cancel_to_attack_frame = 4  # cancel window opens at recovery offset 4 = frame 13
	return a


func _make_player_mid_cancel_window(atk1: AttackData, atk2: AttackData, link: ComboLink) -> PlayerCombat:
	atk1.links = [link]
	var pc := PlayerCombat.new()
	pc.attack_library = [atk1, atk2]
	pc._ready()
	pc.current_attack = atk1
	pc.state = PlayerCombat.State.ATTACK
	pc.state_frame = 13  # exactly when can_cancel_to_attack opens
	pc.global_frame = 100
	pc._buffer._entries.append({"action": &"attack", "frame": 100})
	return pc


func test_link_fires_with_no_requirements() -> void:
	var atk1 := _make_attack(&"l1")
	var atk2 := _make_attack(&"l2")
	var link := ComboLink.new()
	link.input_action = &"attack"
	link.next_attack_id = &"l2"
	link.required_momentum = 0.0
	link.requires_hit_confirm = false

	var pc := _make_player_mid_cancel_window(atk1, atk2, link)
	pc._update_attack_state()

	check(pc.current_attack == atk2, "a plain link with no gates fires as soon as the cancel window opens")
	check_eq(pc.state, PlayerCombat.State.ATTACK, "chaining stays in the ATTACK state")
	check_eq(pc.state_frame, 0, "starting the next attack resets state_frame")
	pc.free()


func test_hit_confirm_blocks_link_when_previous_attack_whiffed() -> void:
	var atk1 := _make_attack(&"l1")
	var atk2 := _make_attack(&"l2")
	var link := ComboLink.new()
	link.input_action = &"attack"
	link.next_attack_id = &"l2"
	link.requires_hit_confirm = true

	var pc := _make_player_mid_cancel_window(atk1, atk2, link)
	pc.attack_did_connect = false
	pc._update_attack_state()

	check(pc.current_attack == atk1, "a hit-confirm finisher does not open on a whiff")
	pc.free()


func test_hit_confirm_allows_link_when_previous_attack_connected() -> void:
	var atk1 := _make_attack(&"l1")
	var atk2 := _make_attack(&"l2")
	var link := ComboLink.new()
	link.input_action = &"attack"
	link.next_attack_id = &"l2"
	link.requires_hit_confirm = true

	var pc := _make_player_mid_cancel_window(atk1, atk2, link)
	pc.attack_did_connect = true
	pc._update_attack_state()

	check(pc.current_attack == atk2, "a hit-confirm finisher opens once the previous attack connected")
	pc.free()


func test_momentum_gate_blocks_link_when_underfunded() -> void:
	var atk1 := _make_attack(&"l1")
	var atk2 := _make_attack(&"l2")
	var link := ComboLink.new()
	link.input_action = &"attack"
	link.next_attack_id = &"l2"
	link.required_momentum = 20.0

	var pc := _make_player_mid_cancel_window(atk1, atk2, link)
	pc.momentum = 10.0
	pc._update_attack_state()

	check(pc.current_attack == atk1, "an ability route does not fire without enough momentum")
	check_eq(pc.momentum, 10.0, "momentum is untouched when the gate blocks the link")
	pc.free()


func test_momentum_gate_allows_and_spends_when_funded() -> void:
	var atk1 := _make_attack(&"l1")
	var atk2 := _make_attack(&"l2")
	var link := ComboLink.new()
	link.input_action = &"attack"
	link.next_attack_id = &"l2"
	link.required_momentum = 20.0

	var pc := _make_player_mid_cancel_window(atk1, atk2, link)
	pc.momentum = 25.0
	pc._update_attack_state()

	check(pc.current_attack == atk2, "an ability route fires once momentum covers the cost")
	check_eq(pc.momentum, 5.0, "the link's momentum cost is spent on use (25 - 20 = 5)")
	pc.free()
