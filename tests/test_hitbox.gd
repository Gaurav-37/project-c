# res://tests/test_hitbox.gd
#
# Hitbox activation (build order step 4). The hitbox must be live during the
# ACTIVE frames and at no other time — that is what makes a whiff a whiff.
#
# The shape and offset are pushed from AttackData every active frame, so two
# attacks with different reach share one Area3D node.

extends "res://tests/test_base.gd"


func _make_attack() -> AttackData:
	var a := AttackData.new()
	a.id = &"test_attack"
	a.startup_frames = 6   # frames 0-5
	a.active_frames = 3    # frames 6-8
	a.recovery_frames = 12 # frames 9-20
	a.hitbox_offset = Vector3(0, 1, -1.5)
	a.hitbox_size = Vector3(1, 1, 2)
	return a


func _make_player(atk: AttackData) -> PlayerCombat:
	var pc := PlayerCombat.new()
	pc.starting_attack = atk
	pc.attack_library = [atk] as Array[AttackData]

	var hitbox := Area3D.new()
	hitbox.name = "Hitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	hitbox.add_child(shape)
	pc.add_child(hitbox)

	pc.hitbox_path = NodePath("Hitbox")
	add_to_tree(pc)  # fires _ready() exactly once, which caches and disables the hitbox
	return pc


func _shape_of(pc: PlayerCombat) -> CollisionShape3D:
	return pc.get_node("Hitbox").get_child(0) as CollisionShape3D


func _is_live(pc: PlayerCombat) -> bool:
	var area := pc.get_node("Hitbox") as Area3D
	return area.monitoring and not _shape_of(pc).disabled


func test_hitbox_starts_disabled() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)

	check(not _is_live(pc), "the hitbox is off before anything happens")

	discard(pc)


func test_hitbox_is_off_during_startup() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk

	pc.state_frame = 0
	pc._update_hitbox()
	check(not _is_live(pc), "frame 0 (first startup frame): hitbox off — this is when you are punishable")

	pc.state_frame = 5
	pc._update_hitbox()
	check(not _is_live(pc), "frame 5 (last startup frame): still off")

	discard(pc)


func test_hitbox_is_live_for_exactly_the_active_frames() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk

	pc.state_frame = 6
	pc._update_hitbox()
	check(_is_live(pc), "frame 6 (first active frame): hitbox live")

	pc.state_frame = 8
	pc._update_hitbox()
	check(_is_live(pc), "frame 8 (last active frame): still live")

	pc.state_frame = 9
	pc._update_hitbox()
	check(not _is_live(pc), "frame 9 (first recovery frame): off again")

	discard(pc)


func test_hitbox_takes_its_shape_from_the_attack_data() -> void:
	var atk := _make_attack()
	atk.hitbox_offset = Vector3(0, 1, -2.5)
	atk.hitbox_size = Vector3(2, 1, 1.8)
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 6

	pc._update_hitbox()

	var area := pc.get_node("Hitbox") as Area3D
	check_eq(area.position, atk.hitbox_offset, "reach comes from AttackData.hitbox_offset, not the scene")
	check_eq((_shape_of(pc).shape as BoxShape3D).size, atk.hitbox_size, "size comes from AttackData.hitbox_size")

	discard(pc)


func test_hitbox_is_off_outside_the_attack_state() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 6
	pc._update_hitbox()

	pc.state = PlayerCombat.State.DODGE
	pc._update_hitbox()

	check(not _is_live(pc), "dodging out of an attack takes the hitbox with it")

	discard(pc)


func test_leaving_the_attack_state_kills_the_hitbox_immediately() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk
	pc.state_frame = 6
	pc._update_hitbox()
	check(_is_live(pc), "precondition: hitbox is live on an active frame")

	pc._change_state(PlayerCombat.State.IDLE)

	check(not _is_live(pc), "_change_state disables the hitbox without waiting for the next tick")

	discard(pc)


func test_hitbox_follows_the_active_frames_across_a_full_swing() -> void:
	var atk := _make_attack()
	var pc := _make_player(atk)
	pc.state = PlayerCombat.State.ATTACK
	pc.current_attack = atk

	var live_frames: Array[int] = []
	for f in atk.total_frames():
		pc.state_frame = f
		pc._update_hitbox()
		if _is_live(pc):
			live_frames.append(f)

	check_eq(live_frames, [6, 7, 8] as Array[int], "across a whole swing the hitbox is live on exactly the active frames")

	discard(pc)
