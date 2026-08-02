# res://tests/test_momentum.gd
#
# Momentum arithmetic: gain, spend, clamping, and the interrupt-loss stake
# applied by receive_hit() when the player is caught mid-attack.
#
# PlayerCombat is a CharacterBody3D but works fine unadded to any tree for
# pure-logic calls like these — no physics or node lookups are triggered.

extends "res://tests/test_base.gd"


func _make_player() -> PlayerCombat:
	return PlayerCombat.new()


func test_gain_increases_momentum() -> void:
	var pc := _make_player()
	pc._gain_momentum(30.0)
	check_eq(pc.momentum, 30.0, "gaining 30 from 0 sets momentum to 30")
	pc.free()


func test_gain_clamps_to_max() -> void:
	var pc := _make_player()
	pc.momentum = 90.0
	pc._gain_momentum(50.0)
	check_eq(pc.momentum, CombatConstants.MOMENTUM_MAX, "gain beyond MOMENTUM_MAX clamps instead of overflowing")
	pc.free()


func test_spend_clamps_to_zero() -> void:
	var pc := _make_player()
	pc.momentum = 10.0
	pc._spend_momentum(30.0)
	check_eq(pc.momentum, 0.0, "spending more than available clamps to 0, never negative")
	pc.free()


func test_interrupt_loss_applies_only_mid_attack() -> void:
	var pc := _make_player()
	pc.momentum = 80.0
	pc.state = PlayerCombat.State.ATTACK

	var lost_signal := {"value": -1.0}
	pc.combo_interrupted.connect(func(lost: float): lost_signal.value = lost)

	pc.receive_hit(10.0)

	check_eq(pc.health, 90.0, "receive_hit still applies raw damage")
	check_eq(pc.momentum, 40.0, "interrupted mid-attack loses MOMENTUM_INTERRUPT_LOSS fraction (80 * 0.5 = 40 lost)")
	check_eq(lost_signal.value, 40.0, "combo_interrupted signal reports the exact amount lost")
	check(pc.current_attack == null, "the in-progress attack is cleared on interrupt")
	pc.free()


func test_no_interrupt_loss_outside_attack_state() -> void:
	var pc := _make_player()
	pc.momentum = 50.0
	pc.state = PlayerCombat.State.IDLE

	var signal_fired := {"value": false}
	pc.combo_interrupted.connect(func(_lost: float): signal_fired.value = true)

	pc.receive_hit(5.0)

	check_eq(pc.health, 95.0, "damage still applies while idle")
	check_eq(pc.momentum, 50.0, "momentum is untouched when the hit lands outside ATTACK state")
	check(not signal_fired.value, "combo_interrupted does not fire when there was no combo to interrupt")
	pc.free()
