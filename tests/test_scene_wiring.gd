# res://tests/test_scene_wiring.gd
#
# Project and scene setup. None of this is logic — it is the wiring that makes
# the logic reachable, and every one of these has broken silently at least once
# in some project somewhere: an autoload renamed, a hitbox left on the wrong
# collision mask, an attack resource dropped from the library.

extends "res://tests/test_base.gd"

const ARENA_PATH := "res://scenes/arena.tscn"


func _arena() -> Node:
	return (load(ARENA_PATH) as PackedScene).instantiate()


# ---------------------------------------------------------------------------
# PROJECT SETTINGS
# ---------------------------------------------------------------------------

func test_physics_runs_at_sixty_hertz() -> void:
	check_eq(Engine.physics_ticks_per_second, 60, "combat is written in whole frames at 60Hz — changing this retimes every attack in the game")


func test_combat_constants_is_an_autoload_under_that_exact_name() -> void:
	check(ProjectSettings.has_setting("autoload/CombatConstants"), "CombatConstants is registered as an autoload — every script refers to it by that name")
	var path := str(ProjectSettings.get_setting("autoload/CombatConstants", ""))
	check(path.ends_with("scripts/combat/combat_constants.gd"), "and points at combat_constants.gd")


func test_the_arena_is_the_main_scene() -> void:
	check_eq(str(ProjectSettings.get_setting("application/run/main_scene", "")), ARENA_PATH, "pressing F5 opens the arena")


func test_the_inputs_the_combat_code_consumes_are_all_bound() -> void:
	for action in [&"attack", &"dodge", &"parry", &"heal", &"move_to"] as Array[StringName]:
		check(InputMap.has_action(action), "'%s' is bound in the Input Map — the combat code consumes it by name" % action)


# ---------------------------------------------------------------------------
# THE PLAYER IN THE ARENA
# ---------------------------------------------------------------------------

func test_the_arena_has_a_player_running_player_combat() -> void:
	var arena := _arena()
	var player := arena.get_node_or_null("Player")
	check(player != null, "the arena has a Player node")
	check(player is PlayerCombat, "and it runs player_combat.gd")
	arena.free()


func test_the_player_opens_chains_with_l1() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	check(player.starting_attack != null, "starting_attack is assigned — without it, left-click does nothing")
	check_eq(player.starting_attack.id, &"glaive_l1", "chains open with the L1 Thrust")
	arena.free()


func test_both_attacks_are_in_the_library() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	var ids: Array[StringName] = []
	for a in player.attack_library:
		if a != null:
			ids.append(a.id)
	check(&"glaive_l1" in ids, "L1 is in the attack library")
	check(&"glaive_l2" in ids, "L2 is in the attack library — a link cannot resolve to an attack that is not there")
	arena.free()


func test_every_link_in_the_library_resolves_within_the_library() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	var ids: Array[StringName] = []
	for a in player.attack_library:
		if a != null:
			ids.append(a.id)
	for a in player.attack_library:
		if a == null:
			continue
		for link in a.links:
			if link == null:
				continue
			check(link.next_attack_id in ids,
				"%s links to '%s', which must also be in the Player's library or the chain dead-ends at runtime" % [a.id, link.next_attack_id])
	arena.free()


# ---------------------------------------------------------------------------
# THE HITBOX
# ---------------------------------------------------------------------------

func test_the_hitbox_path_resolves_to_an_area_with_a_shape() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	check(player.hitbox_path != NodePath(), "hitbox_path is assigned")
	var hitbox := player.get_node_or_null(player.hitbox_path)
	check(hitbox is Area3D, "hitbox_path points at an Area3D")
	if hitbox != null:
		check(hitbox.get_child_count() > 0 and hitbox.get_child(0) is CollisionShape3D,
			"the Area3D's first child is a CollisionShape3D — _ready() caches it by index")
	arena.free()


func test_the_hitbox_only_looks_for_enemies() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	var hitbox := player.get_node(player.hitbox_path) as Area3D
	check_eq(hitbox.collision_layer, 0, "the hitbox is on no layer — nothing should ever detect IT")
	check_eq(hitbox.collision_mask, 2, "the hitbox watches layer 2 only, so the floor never registers as a hit")
	arena.free()


func test_the_hitbox_ships_switched_off() -> void:
	var arena := _arena()
	var player := arena.get_node("Player") as PlayerCombat
	var hitbox := player.get_node(player.hitbox_path) as Area3D
	check(not hitbox.monitoring, "the hitbox starts disabled — it is switched on for active frames only")
	check((hitbox.get_child(0) as CollisionShape3D).disabled, "and its shape starts disabled too")
	arena.free()


# ---------------------------------------------------------------------------
# THE DUMMY — something for the hitbox to find
# ---------------------------------------------------------------------------

func test_the_arena_has_a_dummy_to_hit() -> void:
	var arena := _arena()
	var dummy := arena.get_node_or_null("Dummy")
	check(dummy != null, "the arena has a Dummy node")
	check(dummy is TargetDummy, "and it runs target_dummy.gd — without this the hitbox sweeps empty air")
	arena.free()


func test_the_dummy_sits_on_the_layer_the_hitbox_scans() -> void:
	var arena := _arena()
	var dummy := arena.get_node("Dummy") as TargetDummy
	var player := arena.get_node("Player") as PlayerCombat
	var hitbox := player.get_node(player.hitbox_path) as Area3D

	check(dummy.collision_layer & hitbox.collision_mask != 0,
		"the dummy is on a layer the player's hitbox actually scans — mismatch here means every swing silently misses")
	check(dummy.collision_layer & 1 != 0,
		"and on layer 1 as well, so the player's body collides with it instead of walking through")
	arena.free()


func test_the_dummy_is_in_front_of_the_player() -> void:
	var arena := _arena()
	var dummy := arena.get_node("Dummy") as TargetDummy
	var player := arena.get_node("Player") as PlayerCombat
	var attack := player.starting_attack

	# The player does not turn yet — rotation is step 8 — so forward is -Z,
	# and the hitbox only ever sweeps that way.
	check(dummy.position.z < player.position.z,
		"the dummy is on the player's -Z side, which is the only direction the hitbox reaches")

	var reach: float = absf(attack.hitbox_offset.z) + attack.hitbox_size.z * 0.5
	check(absf(dummy.position.z - player.position.z) < reach,
		"and close enough that the first swing of a session connects without moving first (reach %.1f)" % reach)
	arena.free()


func test_the_debug_overlay_is_pointed_at_the_player() -> void:
	var arena := _arena()
	var overlay := arena.get_node_or_null("UI/DebugOverlay")
	check(overlay != null, "the debug overlay is in the arena")
	if overlay == null:
		arena.free()
		return
	var target := overlay.get_node_or_null(overlay.player_path)
	check(target is PlayerCombat, "the overlay's player_path resolves to the Player — otherwise F1 shows nothing")
	arena.free()
