# res://tests/test_target_dummy.gd
#
# The dummy target, and — more importantly — the round trip: player swings,
# hitbox overlaps, dummy takes damage, player freezes and banks momentum.
#
# Everything above the physics layer is covered here. What these tests CANNOT
# cover is the overlap itself: whether Godot reports the collision on the
# frame the hitbox switches on. That needs a stepping physics world and a
# hand at the controls, so it stays on the manual checklist.

extends "res://tests/test_base.gd"


func _make_attack(dmg: float = 10.0) -> AttackData:
	var a := AttackData.new()
	a.id = &"test_attack"
	a.startup_frames = 6
	a.active_frames = 3
	a.recovery_frames = 12
	a.damage = dmg
	a.momentum_gain = 4.0
	a.hitstop_frames_on_hit = 4
	a.hitstop_frames_on_bounce = 11
	return a


func _make_dummy(health: float = 100.0) -> TargetDummy:
	var d := TargetDummy.new()
	d.max_health = health
	d._ready()
	return d


func _make_attacker(atk: AttackData) -> PlayerCombat:
	var pc := PlayerCombat.new()
	pc.current_attack = atk
	pc.state = PlayerCombat.State.ATTACK
	pc.state_frame = atk.startup_frames
	return pc


# ---------------------------------------------------------------------------
# DAMAGE
# ---------------------------------------------------------------------------

func test_a_dummy_starts_at_full_health() -> void:
	var d := _make_dummy(250.0)
	check_approx(d.health, 250.0, "the dummy starts at max_health")
	check_eq(d.hits_taken, 0, "and has taken nothing")
	d.free()


func test_a_hit_takes_the_attacks_damage() -> void:
	var d := _make_dummy(100.0)
	var atk := _make_attack(10.0)

	var bounced := d.receive_hit(atk, null)

	check(not bounced, "a clean hit reports no bounce")
	check_approx(d.health, 90.0, "damage comes off the attack resource, not the dummy")
	check_eq(d.hits_taken, 1, "the hit is counted")
	check_approx(d.last_damage, 10.0, "and its size recorded for the readout")
	d.free()


func test_damage_accumulates_across_a_chain() -> void:
	var d := _make_dummy(100.0)
	d.receive_hit(_make_attack(10.0), null)
	d.receive_hit(_make_attack(8.0), null)

	check_approx(d.health, 82.0, "two hits of a chain both land")
	check_approx(d.total_damage, 18.0, "total damage is the sum of the chain")
	check_eq(d.hits_taken, 2, "both hits counted")
	d.free()


func test_health_clamps_at_zero() -> void:
	var d := _make_dummy(15.0)
	d.receive_hit(_make_attack(10.0), null)
	d.receive_hit(_make_attack(10.0), null)

	check_approx(d.health, 0.0, "health never goes negative")
	d.free()


func test_a_dead_dummy_still_registers_hits() -> void:
	var d := _make_dummy(10.0)
	d.receive_hit(_make_attack(10.0), null)
	check_approx(d.health, 0.0, "precondition: the dummy is at zero")

	var bounced := d.receive_hit(_make_attack(10.0), null)

	check(not bounced, "hits keep resolving at 0 health")
	check_eq(d.hits_taken, 2, "and keep counting — a dummy that stops responding stops being useful")
	d.free()


func test_a_null_attack_does_nothing() -> void:
	var d := _make_dummy(100.0)

	var bounced := d.receive_hit(null, null)

	check(not bounced, "a hit with no attack behind it resolves to nothing")
	check_approx(d.health, 100.0, "and costs no health")
	check_eq(d.hits_taken, 0, "and is not counted")
	d.free()


func test_reset_restores_everything() -> void:
	var d := _make_dummy(100.0)
	d.receive_hit(_make_attack(10.0), null)

	d.reset()

	check_approx(d.health, 100.0, "reset returns the dummy to full")
	check_eq(d.hits_taken, 0, "and clears the counters")
	check_approx(d.total_damage, 0.0, "including total damage")
	d.free()


func test_was_hit_signal_reports_damage_and_bounce() -> void:
	var d := _make_dummy(100.0)
	var seen := {"damage": -1.0, "bounced": true, "count": 0}
	d.was_hit.connect(func(dmg: float, bounced: bool) -> void:
		seen.damage = dmg
		seen.bounced = bounced
		seen.count += 1)

	d.receive_hit(_make_attack(10.0), null)

	check_eq(seen.count, 1, "was_hit fires once per hit")
	check_approx(seen.damage, 10.0, "carrying the damage dealt")
	check(not seen.bounced, "and whether it bounced")
	d.free()


# ---------------------------------------------------------------------------
# THE BOUNCE TEST SWITCH
# ---------------------------------------------------------------------------

func test_always_bounces_deflects_every_blow() -> void:
	var d := _make_dummy(100.0)
	d.always_bounces = true

	var bounced := d.receive_hit(_make_attack(10.0), null)

	check(bounced, "the test switch reports a bounce")
	check_approx(d.health, 100.0, "a bounce does no damage")
	check_eq(d.hits_taken, 1, "but still counts as contact")
	d.free()


# ---------------------------------------------------------------------------
# THE ROUND TRIP — player into dummy
# ---------------------------------------------------------------------------

func test_a_swing_that_connects_damages_freezes_and_pays() -> void:
	var atk := _make_attack(10.0)
	var pc := _make_attacker(atk)
	var d := _make_dummy(100.0)

	pc._resolve_hit(d)

	check_approx(d.health, 90.0, "the dummy takes the damage")
	check_eq(pc.hitstop_frames, atk.hitstop_frames_on_hit, "the player freezes on impact")
	check_approx(pc.momentum, 4.0, "and banks the attack's momentum")
	check(pc.attack_did_connect, "and the hit is confirmed for links that need it")

	d.free()
	pc.free()


func test_a_bounced_swing_costs_momentum_and_freezes_longer() -> void:
	var atk := _make_attack(10.0)
	var pc := _make_attacker(atk)
	pc.momentum = 40.0
	var d := _make_dummy(100.0)
	d.always_bounces = true

	pc._resolve_hit(d)

	check_approx(d.health, 100.0, "a bounce leaves the target untouched")
	check_eq(pc.hitstop_frames, atk.hitstop_frames_on_bounce, "and freezes the attacker for the longer count")
	check_approx(pc.momentum, 34.0, "and takes 15% of the bank with it")

	d.free()
	pc.free()


func test_one_swing_cannot_hit_the_dummy_twice() -> void:
	var atk := _make_attack(10.0)
	var pc := _make_attacker(atk)
	var d := _make_dummy(100.0)

	pc._resolve_hit(d)
	pc._resolve_hit(d)  # e.g. body_entered and area_entered both firing

	check_eq(d.hits_taken, 1, "a single swing lands once however many overlaps are reported")
	check_approx(d.health, 90.0, "so damage is paid once")

	d.free()
	pc.free()


func test_the_next_attack_in_a_chain_hits_it_again() -> void:
	var l1 := _make_attack(10.0)
	var l2 := _make_attack(8.0)
	var pc := _make_attacker(l1)
	var d := _make_dummy(100.0)

	pc._resolve_hit(d)
	pc._begin_attack(l2)
	pc._resolve_hit(d)

	check_eq(d.hits_taken, 2, "the second attack of a chain lands too")
	check_approx(d.health, 82.0, "each for its own damage")

	d.free()
	pc.free()


# ---------------------------------------------------------------------------
# THE DUMMY SHARES THE FREEZE
# ---------------------------------------------------------------------------

func test_the_dummy_freezes_while_the_attacker_is_in_hitstop() -> void:
	var atk := _make_attack(10.0)
	var pc := _make_attacker(atk)
	var d := _make_dummy(100.0)

	pc._resolve_hit(d)
	check(d.is_frozen(), "the moment the hit lands, both sides are frozen")
	var flash_at_impact := d._flash_frames

	d._physics_process(1.0 / 60.0)
	check_eq(d._flash_frames, flash_at_impact, "the dummy's flash does not tick down during the freeze")

	pc.hitstop_frames = 0
	check(not d.is_frozen(), "when the attacker unfreezes, so does the dummy")
	d._physics_process(1.0 / 60.0)
	check_eq(d._flash_frames, flash_at_impact - 1, "and the flash resumes")

	d.free()
	pc.free()


func test_an_untouched_dummy_is_never_frozen() -> void:
	var d := _make_dummy(100.0)
	check(not d.is_frozen(), "a dummy that has never been hit has no attacker to freeze with")
	d.free()
