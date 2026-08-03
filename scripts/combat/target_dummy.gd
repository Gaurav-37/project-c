# res://scripts/combat/target_dummy.gd
#
# A stationary thing to hit. Build order step 4 owed us this: the hitbox has
# been sweeping through empty air since it was written, so nothing downstream
# of a connected hit — hit-stop, momentum gain, hit-confirm links — has ever
# actually run in the game.
#
# This is NOT the creature. It has no parts, no durability, no poise, no
# behaviour. Those are steps 13 and 14. This exists to answer one question:
# did the blow land, and on which frame.
#
# THE CONTRACT: PlayerCombat calls receive_hit(attack, source) on whatever its
# hitbox overlaps, and reads the return value as "did this bounce off armour".
# Anything that wants to be hittable implements exactly this.

class_name TargetDummy
extends StaticBody3D

# ---------------------------------------------------------------------------
# SETUP
# ---------------------------------------------------------------------------

@export var max_health: float = 1000.0

## Grey-box switch for feeling the armour-bounce hit-stop, which PlayerCombat
## already implements but nothing has ever been able to trigger. This is a
## test toggle, not the armour system — real armour is part durability and
## armour_pierce, which is build order step 13.
@export var always_bounces: bool = false

## How long the dummy flashes on impact. Frames, like everything else.
@export var flash_frames_on_hit: int = 6

@export var mesh_path: NodePath
@export var label_path: NodePath


# ---------------------------------------------------------------------------
# STATE
# ---------------------------------------------------------------------------

var health: float = 0.0
var hits_taken: int = 0
var last_damage: float = 0.0
var total_damage: float = 0.0

var _flash_frames: int = 0
var _bounced_last: bool = false
var _mesh: MeshInstance3D
var _label: Label3D
var _material: StandardMaterial3D

## Remembered from the last hit so the dummy can share the attacker's freeze.
var _attacker: Node = null

const COL_IDLE := Color(0.45, 0.47, 0.52)
const COL_HIT := Color(0.95, 0.95, 0.90)
const COL_BOUNCE := Color(0.98, 0.55, 0.30)

signal was_hit(damage: float, bounced: bool)


# ---------------------------------------------------------------------------
# READY
# ---------------------------------------------------------------------------

func _ready() -> void:
	health = max_health

	if mesh_path != NodePath():
		_mesh = get_node_or_null(mesh_path) as MeshInstance3D
	if label_path != NodePath():
		_label = get_node_or_null(label_path) as Label3D

	# Built in code so the scene file stays readable — one less thing to
	# hunt through the Inspector for when the colours look wrong.
	if _mesh != null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = COL_IDLE
		_mesh.material_override = _material

	_refresh_label()


# ---------------------------------------------------------------------------
# TAKING A HIT — the contract PlayerCombat calls
# ---------------------------------------------------------------------------

## Returns true if the blow BOUNCED (no damage, long hit-stop, momentum
## penalty). Returns false for a clean hit.
func receive_hit(attack: AttackData, source: Node) -> bool:
	if attack == null:
		return false

	_attacker = source
	hits_taken += 1
	_flash_frames = flash_frames_on_hit

	if always_bounces:
		_bounced_last = true
		last_damage = 0.0
		_refresh_label()
		was_hit.emit(0.0, true)
		return true

	_bounced_last = false
	last_damage = attack.damage
	total_damage += attack.damage
	# Clamped, not killed. A dummy that stops responding stops being useful —
	# hits must keep registering so hit-stop can still be felt at 0 health.
	health = maxf(health - attack.damage, 0.0)

	_refresh_label()
	was_hit.emit(attack.damage, false)
	return false


## Back to full. Nothing calls this yet; it is here so a debug key or a
## training-mode reset has something to call.
func reset() -> void:
	health = max_health
	hits_taken = 0
	last_damage = 0.0
	total_damage = 0.0
	_flash_frames = 0
	_bounced_last = false
	_refresh_label()


# ---------------------------------------------------------------------------
# PRESENTATION — frame-counted, never timed
# ---------------------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if is_frozen():
		return
	if _flash_frames > 0:
		_flash_frames -= 1
		_apply_colour()


## Share the attacker's freeze. If the dummy kept animating through hit-stop,
## the impact would read as softer than it is — the point of the freeze is
## that the picture stops.
func is_frozen() -> bool:
	var player := _attacker as PlayerCombat
	return player != null and player.hitstop_frames > 0


func _apply_colour() -> void:
	if _material == null:
		return
	if _flash_frames > 0:
		_material.albedo_color = COL_BOUNCE if _bounced_last else COL_HIT
	else:
		_material.albedo_color = COL_IDLE


func _refresh_label() -> void:
	_apply_colour()
	if _label == null:
		return
	_label.text = "HP %d / %d\nhits %d   last %.0f" % [
		roundi(health), roundi(max_health), hits_taken, last_damage,
	]
