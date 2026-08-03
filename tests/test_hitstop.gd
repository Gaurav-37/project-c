# res://tests/test_hitstop.gd
#
# Hit resolution and the hit-stop counter (build order step 7).
#
# This suite also pins the TARGET CONTRACT that the dummy — and later the
# creature — has to implement:
#
#     func receive_hit(attack: AttackData, source: Node) -> bool
#         return true if the blow BOUNCED off armour, false for a clean hit
#
# Note that PlayerCombat.receive_hit() takes a different shape (damage, knockdown)
# because the player is on the receiving end of a different kind of blow.

extends "res://tests/test_base.gd"


## Stand-in for the dummy target that step 4 still owes us.
class FakeTarget extends Node:
	var bounces: bool = false
	var hits_taken: int = 0
	var seen_attack: AttackData = null
	var seen_source: Node = null

	func receive_hit(attack: AttackData, source: Node) -> bool:
		hits_taken += 1
		seen_attack = attack
		seen_source = source
		return bounces


func _make_attack() -> AttackData:
	var a := AttackData.new()
	a.id = &"test_attack"
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12
	a.momentum_gain = 4.0
	a.hitstop_frames_on_hit = 4
	a.hitstop_frames_on_bounce = 11
	return a


func _make_attacker(atk: AttackData) -> PlayerCombat:
	var pc := PlayerCombat.new()
	pc.current_attack = atk
	pc.state = PlayerCombat.State.ATTACK
	pc.state_frame = atk.startup_frames  # first active frame
	pc.frames_since_contact = 50
	return pc


func test_clean_hit_sets_hitstop_from_the_attack_that_landed() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var target := FakeTarget.new()

	pc._resolve_hit(target)

	check_eq(pc.hitstop_frames, atk.hitstop_frames_on_hit, "a clean hit freezes for the attack's hitstop_frames_on_hit")
	check_approx(pc.momentum, 4.0, "a clean hit banks the attack's momentum_gain")
	check(pc.attack_did_connect, "the hit is recorded for hit-confirm links")
	check_eq(pc.frames_since_contact, 0, "contact resets the momentum-decay grace clock")

	target.free()
	pc.free()


func test_the_target_receives_the_attack_and_the_attacker() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var target := FakeTarget.new()

	pc._resolve_hit(target)

	check_eq(target.hits_taken, 1, "receive_hit is called exactly once")
	check(target.seen_attack == atk, "the target is handed the AttackData that hit it")
	check(target.seen_source == pc, "the target is handed the attacker as source")

	target.free()
	pc.free()


func test_bounce_uses_the_long_freeze_and_costs_momentum() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	pc.momentum = 40.0
	var target := FakeTarget.new()
	target.bounces = true

	pc._resolve_hit(target)

	check_eq(pc.hitstop_frames, atk.hitstop_frames_on_bounce, "an armour bounce freezes for hitstop_frames_on_bounce — it should feel like a wall")
	check_approx(pc.momentum, 34.0, "a bounce burns 15% of banked momentum (40 - 6 = 34)")
	check(pc.hitstop_frames > atk.hitstop_frames_on_hit, "the bounce freeze is longer than a clean hit, so the hand can tell them apart")

	target.free()
	pc.free()


func test_bounce_pays_no_momentum_gain() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	pc.momentum = 0.0
	var target := FakeTarget.new()
	target.bounces = true

	pc._resolve_hit(target)

	check_approx(pc.momentum, 0.0, "a bounce is not a hit: no momentum is earned from it")

	target.free()
	pc.free()


func test_target_without_receive_hit_counts_as_a_clean_hit() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var plain := Node.new()  # e.g. a prop with no combat script

	pc._resolve_hit(plain)

	check_eq(pc.hitstop_frames, atk.hitstop_frames_on_hit, "anything the hitbox overlaps still registers as a hit")
	check_approx(pc.momentum, 4.0, "and still pays momentum")

	plain.free()
	pc.free()


func test_one_hit_per_target_per_swing() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var target := FakeTarget.new()

	pc._resolve_hit(target)
	pc.hitstop_frames = 0  # so a second freeze would be visible
	pc._resolve_hit(target)

	check_eq(target.hits_taken, 1, "the same target cannot be hit twice by one swing")
	check_eq(pc.hitstop_frames, 0, "and no second freeze is triggered")
	check_approx(pc.momentum, 4.0, "and no second momentum payment is made")

	target.free()
	pc.free()


func test_the_next_attack_can_hit_the_same_target_again() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var target := FakeTarget.new()

	pc._resolve_hit(target)
	pc._begin_attack(atk)  # next link in the chain
	pc._resolve_hit(target)

	check_eq(target.hits_taken, 2, "starting a new attack clears the already-hit list")

	target.free()
	pc.free()


func test_the_attacker_cannot_hit_itself() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)

	pc._resolve_hit(pc)

	check_eq(pc.hitstop_frames, 0, "self-overlap resolves to nothing")
	check(not pc.attack_did_connect, "and does not count as a hit-confirm")

	pc.free()


func test_no_attack_means_no_hit() -> void:
	var pc := PlayerCombat.new()
	pc.current_attack = null
	var target := FakeTarget.new()

	pc._resolve_hit(target)

	check_eq(target.hits_taken, 0, "a stray overlap with no attack in progress does nothing")
	check_eq(pc.hitstop_frames, 0, "and cannot freeze the game")

	target.free()
	pc.free()


func test_hit_landed_signal_reports_target_and_attack() -> void:
	var atk := _make_attack()
	var pc := _make_attacker(atk)
	var target := FakeTarget.new()

	var seen := {"target": null, "attack": null, "count": 0}
	pc.hit_landed.connect(func(t: Node, a: AttackData) -> void:
		seen.target = t
		seen.attack = a
		seen.count += 1)

	pc._resolve_hit(target)

	check_eq(seen.count, 1, "hit_landed fires once per connected hit")
	check(seen.target == target, "hit_landed reports what was hit")
	check(seen.attack == atk, "hit_landed reports what hit it")

	target.free()
	pc.free()
