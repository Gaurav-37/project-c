# res://scripts/combat/player_combat.gd
#
# The heart of the game. Attach to a CharacterBody3D named "Player".
#
# GOVERNING PRINCIPLE (tech spec section 1):
#   Gameplay logic drives. Animation follows. Never the reverse.
#   Nothing here reads from the AnimationPlayer. It only tells it what to play.
#
# Everything runs on an integer frame counter at a fixed 60Hz, so the same
# inputs always produce the same result.

class_name PlayerCombat
extends CharacterBody3D

# ---------------------------------------------------------------------------
# SETUP — assign in the Inspector
# ---------------------------------------------------------------------------

## The attack that left-click starts a chain with.
@export var starting_attack: AttackData

## Every AttackData the player can reach. Looked up by id.
@export var attack_library: Array[AttackData] = []

@export var hitbox_path: NodePath
@export var mesh_path: NodePath


# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

enum State {
	IDLE,
	MOVING,
	ATTACK,
	DODGE,
	PARRY,
	HEAL,
	KNOCKDOWN,
}

var state: State = State.IDLE
var state_frame: int = 0
var global_frame: int = 0

## Hit-stop is a TICK-SKIP, not a state. Modelling it as a state
## creates transition bugs at every boundary.
var hitstop_frames: int = 0

var momentum: float = 0.0
var health: float = CombatConstants.PLAYER_MAX_HEALTH

var current_attack: AttackData = null
var attack_did_connect: bool = false
var frames_since_contact: int = 0

var move_target: Vector3
var has_move_target: bool = false

var _buffer := InputBuffer.new()
var _attack_lookup: Dictionary = {}
var _hitbox: Area3D
var _hitbox_shape: CollisionShape3D
var _already_hit: Array = []

signal momentum_changed(value: float)
signal attack_started(attack: AttackData)
signal hit_landed(target: Node, attack: AttackData)
signal combo_interrupted(lost: float)


# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	for a in attack_library:
		if a != null:
			_attack_lookup[a.id] = a
	if starting_attack != null and not _attack_lookup.has(starting_attack.id):
		_attack_lookup[starting_attack.id] = starting_attack

	if hitbox_path != NodePath():
		_hitbox = get_node_or_null(hitbox_path) as Area3D
		if _hitbox:
			_hitbox_shape = _hitbox.get_child(0) as CollisionShape3D
			_hitbox.body_entered.connect(_on_hitbox_body_entered)
			_hitbox.area_entered.connect(_on_hitbox_area_entered)
			_set_hitbox_active(false)


# ---------------------------------------------------------------------------
# MAIN TICK — order matters enormously. See tech spec section 2.
# ---------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	global_frame += 1

	# 1. HIT-STOP GATE ------------------------------------------------------
	# Buffer still fills. Gameplay does not advance.
	if hitstop_frames > 0:
		hitstop_frames -= 1
		_buffer.poll(global_frame)
		return

	# 2. INPUT --------------------------------------------------------------
	_buffer.poll(global_frame)
	_poll_move_command()

	# 3. ADVANCE ------------------------------------------------------------
	state_frame += 1
	frames_since_contact += 1

	# 4. TRANSITIONS --------------------------------------------------------
	_evaluate_transitions()

	# 5. HITBOX -------------------------------------------------------------
	_update_hitbox()

	# 6. RESOLVE ------------------------------------------------------------
	_update_movement()
	_update_momentum_decay()

	# 7. PRESENT ------------------------------------------------------------
	# Animation, VFX and UI go here. Deliberately empty while grey-boxing.
	move_and_slide()


# ---------------------------------------------------------------------------
# TRANSITIONS
# ---------------------------------------------------------------------------

func _evaluate_transitions() -> void:
	match state:
		State.IDLE, State.MOVING:
			_try_start_action_from_neutral()
		State.ATTACK:
			_update_attack_state()
		State.DODGE:
			if state_frame >= CombatConstants.DODGE_TOTAL_FRAMES:
				_change_state(State.IDLE)
		State.PARRY:
			var total := CombatConstants.PARRY_STARTUP \
				+ CombatConstants.PARRY_ACTIVE \
				+ CombatConstants.PARRY_RECOVERY
			if state_frame >= total:
				_change_state(State.IDLE)
		State.HEAL:
			if state_frame >= 40:
				health = minf(health + CombatConstants.HEAL_AMOUNT,
					CombatConstants.PLAYER_MAX_HEALTH)
				_change_state(State.IDLE)
		State.KNOCKDOWN:
			pass  # rise options — build order step 17


func _try_start_action_from_neutral() -> void:
	if _buffer.consume(&"attack", global_frame):
		_begin_attack(starting_attack)
		return
	if _buffer.consume(&"dodge", global_frame):
		_change_state(State.DODGE)
		return
	if _buffer.consume(&"parry", global_frame):
		_change_state(State.PARRY)
		return
	if _buffer.consume(&"heal", global_frame):
		if momentum >= CombatConstants.HEAL_COST:
			_spend_momentum(CombatConstants.HEAL_COST)
			_change_state(State.HEAL)
		return


func _update_attack_state() -> void:
	if current_attack == null:
		_change_state(State.IDLE)
		return

	# Cancel into another attack via a ComboLink
	if current_attack.can_cancel_to_attack(state_frame):
		for link in current_attack.links:
			if link == null:
				continue
			if link.requires_hit_confirm and not attack_did_connect:
				continue
			if momentum < link.required_momentum:
				continue
			if _buffer.consume(link.input_action, global_frame):
				var next: AttackData = _attack_lookup.get(link.next_attack_id)
				if next != null:
					if link.required_momentum > 0.0:
						_spend_momentum(link.required_momentum)
					_begin_attack(next)
					return

	# Defensive cancels — deliberately rarer than offensive ones
	if current_attack.can_cancel_to_dodge(state_frame):
		if _buffer.consume(&"dodge", global_frame):
			_change_state(State.DODGE)
			return

	if current_attack.can_cancel_to_parry(state_frame):
		if _buffer.consume(&"parry", global_frame):
			_change_state(State.PARRY)
			return

	# Attack finished
	if state_frame >= current_attack.total_frames():
		current_attack = null
		_change_state(State.IDLE)


func _begin_attack(attack: AttackData) -> void:
	if attack == null:
		return
	current_attack = attack
	attack_did_connect = false
	_already_hit.clear()
	_change_state(State.ATTACK)
	has_move_target = false
	attack_started.emit(attack)


func _change_state(new_state: State) -> void:
	state = new_state
	state_frame = 0
	if new_state != State.ATTACK:
		_set_hitbox_active(false)


# ---------------------------------------------------------------------------
# HITBOX
# ---------------------------------------------------------------------------

func _update_hitbox() -> void:
	if state != State.ATTACK or current_attack == null:
		_set_hitbox_active(false)
		return

	var active := current_attack.is_in_active(state_frame)
	_set_hitbox_active(active)

	if active and _hitbox:
		_hitbox.position = current_attack.hitbox_offset
		if _hitbox_shape and _hitbox_shape.shape is BoxShape3D:
			(_hitbox_shape.shape as BoxShape3D).size = current_attack.hitbox_size


func _set_hitbox_active(active: bool) -> void:
	if _hitbox_shape:
		_hitbox_shape.disabled = not active
	if _hitbox:
		_hitbox.monitoring = active


func _on_hitbox_body_entered(body: Node) -> void:
	_resolve_hit(body)

func _on_hitbox_area_entered(area: Node) -> void:
	_resolve_hit(area)


func _resolve_hit(target: Node) -> void:
	if current_attack == null or target == self:
		return
	if target in _already_hit:
		return
	_already_hit.append(target)

	attack_did_connect = true
	frames_since_contact = 0

	var bounced := false
	if target.has_method("receive_hit"):
		bounced = bool(target.receive_hit(current_attack, self))

	if bounced:
		hitstop_frames = current_attack.hitstop_frames_on_bounce
		_spend_momentum(momentum * 0.15)
	else:
		hitstop_frames = current_attack.hitstop_frames_on_hit
		_gain_momentum(current_attack.momentum_gain)

	hit_landed.emit(target, current_attack)


# ---------------------------------------------------------------------------
# TAKING DAMAGE — this is where combos get broken
# ---------------------------------------------------------------------------

func receive_hit(damage: float, causes_knockdown: bool = false) -> void:
	health -= damage

	# Interrupted mid-combo: lose half the bank. This is the stake.
	if state == State.ATTACK:
		var lost := momentum * CombatConstants.MOMENTUM_INTERRUPT_LOSS
		_spend_momentum(lost)
		combo_interrupted.emit(lost)
		current_attack = null

	if causes_knockdown:
		_change_state(State.KNOCKDOWN)
	else:
		_change_state(State.IDLE)


# ---------------------------------------------------------------------------
# MOMENTUM
# ---------------------------------------------------------------------------

func _gain_momentum(amount: float) -> void:
	momentum = clampf(momentum + amount, 0.0, CombatConstants.MOMENTUM_MAX)
	momentum_changed.emit(momentum)

func _spend_momentum(amount: float) -> void:
	momentum = clampf(momentum - amount, 0.0, CombatConstants.MOMENTUM_MAX)
	momentum_changed.emit(momentum)

func _update_momentum_decay() -> void:
	if frames_since_contact > CombatConstants.MOMENTUM_DECAY_GRACE_FRAMES:
		if momentum > 0.0:
			_spend_momentum(CombatConstants.MOMENTUM_DECAY_PER_FRAME)


# ---------------------------------------------------------------------------
# MOVEMENT — right-click to move, MOBA style
# ---------------------------------------------------------------------------

func _poll_move_command() -> void:
	if not InputMap.has_action(&"move_to"):
		return
	if Input.is_action_pressed(&"move_to"):
		var point := _mouse_ground_position()
		if point != Vector3.INF:
			move_target = point
			has_move_target = true


func _update_movement() -> void:
	# Attacks commit. You do not walk out of them.
	if state == State.ATTACK or state == State.HEAL or state == State.KNOCKDOWN:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if not has_move_target:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var to_target := move_target - global_position
	to_target.y = 0.0

	if to_target.length() < CombatConstants.ARRIVAL_THRESHOLD:
		has_move_target = false
		velocity.x = 0.0
		velocity.z = 0.0
		_change_state(State.IDLE)
		return

	var dir := to_target.normalized()
	velocity.x = dir.x * CombatConstants.MOVE_SPEED
	velocity.z = dir.z * CombatConstants.MOVE_SPEED

	if state == State.IDLE:
		_change_state(State.MOVING)


## Where the mouse is pointing, projected onto the ground plane (y = 0).
func _mouse_ground_position() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.INF
	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t := -origin.y / dir.y
	if t < 0.0:
		return Vector3.INF
	return origin + dir * t


# ---------------------------------------------------------------------------
# DEBUG ACCESS
# ---------------------------------------------------------------------------

func debug_state_name() -> String:
	return State.keys()[state]

func debug_phase_name() -> String:
	if state != State.ATTACK or current_attack == null:
		return "-"
	if current_attack.is_in_startup(state_frame):
		return "STARTUP"
	if current_attack.is_in_active(state_frame):
		return "ACTIVE"
	return "RECOVERY"

func debug_buffer() -> Array[String]:
	return _buffer.debug_contents(global_frame)
