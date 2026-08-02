# res://scripts/combat/attack_data.gd
#
# One attack, entirely as data. Every number you will tune lives here,
# editable in the Inspector with no code changes and no restart.
#
# To create one: right-click in the FileSystem panel ->
#   New Resource -> AttackData -> save into res://data/attacks/
#
# Defaults below are the "L1 Thrust" starting values from the tech spec.

class_name AttackData
extends Resource

# ---------------------------------------------------------------------------
# IDENTITY
# ---------------------------------------------------------------------------

## Unique. ComboLinks refer to attacks by this id.
@export var id: StringName = &"glaive_l1"

## Shown in the debug overlay.
@export var display_name: String = "L1 Thrust"

## Name of the clip in the AnimationPlayer. Leave blank while grey-boxing.
@export var animation_name: StringName = &""


# ---------------------------------------------------------------------------
# TIMING — frames at 60Hz
#
#   STARTUP  : wind-up. Hitbox off. This is when the enemy can punish you.
#   ACTIVE   : hitbox live.
#   RECOVERY : follow-through. Hitbox off. Cancel windows open in here.
# ---------------------------------------------------------------------------

@export_group("Timing")
@export var startup_frames: int = 6
@export var active_frames: int = 3
@export var recovery_frames: int = 12


# ---------------------------------------------------------------------------
# CANCEL WINDOWS
#
# Frame OFFSET INTO RECOVERY at which each cancel becomes legal.
# -1 means never.
#
# Offsets rather than absolute frames, so retiming an attack does not
# silently break its links.
#
# Design rule (doc 6): cancelling into another ATTACK should be generous;
# cancelling into DODGE or PARRY should be rare. Offence flows, defence costs.
# ---------------------------------------------------------------------------

@export_group("Cancel Windows")
@export var cancel_to_attack_frame: int = 4
@export var cancel_to_dodge_frame: int = -1
@export var cancel_to_parry_frame: int = -1
@export var cancel_to_swap_frame: int = 4


# ---------------------------------------------------------------------------
# DAMAGE
# ---------------------------------------------------------------------------

@export_group("Damage")
@export var damage: float = 10.0

## Multiplier applied to part durability specifically.
## Heavy/blunt attacks should exceed 1.0 here.
@export var part_damage_multiplier: float = 1.0

## Persistent wound applied to the struck part (design doc 5.9).
@export var wound_application: float = 1.0

## Ability to stagger. Compared against enemy poise.
@export var poise_damage: float = 5.0

## If enemy part armour exceeds this, the hit BOUNCES:
## no damage, long hitstop, self-stagger, Momentum penalty.
@export var armour_pierce: float = 0.0


# ---------------------------------------------------------------------------
# MOMENTUM  (design doc 5.4)
# ---------------------------------------------------------------------------

@export_group("Momentum")

## Gained on hit. Should RISE through a chain so finishing strings pays.
@export var momentum_gain: float = 4.0

## Cost to use. Greater than 0 makes this an ability rather than a basic.
@export var momentum_cost: float = 0.0


# ---------------------------------------------------------------------------
# FEEL
# ---------------------------------------------------------------------------

@export_group("Feel")
@export var hitstop_frames_on_hit: int = 4
@export var hitstop_frames_on_bounce: int = 11
@export var snap_max_angle_deg: float = 30.0
@export var snap_max_distance: float = 0.5
@export var camera_shake: float = 0.0

## Forward motion driven by CODE, not root motion (tech spec section 1).
@export var lunge_distance: float = 0.0


# ---------------------------------------------------------------------------
# HITBOX — offset and size relative to the player
# ---------------------------------------------------------------------------

@export_group("Hitbox")
@export var hitbox_offset: Vector3 = Vector3(0, 1, -1.5)
@export var hitbox_size: Vector3 = Vector3(1.0, 1.0, 2.0)


# ---------------------------------------------------------------------------
# CHAINING
# ---------------------------------------------------------------------------

@export_group("Combo")
@export var links: Array[ComboLink] = []


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

func total_frames() -> int:
	return startup_frames + active_frames + recovery_frames

func recovery_start_frame() -> int:
	return startup_frames + active_frames

func is_in_startup(frame: int) -> bool:
	return frame < startup_frames

func is_in_active(frame: int) -> bool:
	return frame >= startup_frames and frame < recovery_start_frame()

func is_in_recovery(frame: int) -> bool:
	return frame >= recovery_start_frame()

## Frames elapsed since recovery began. -1 if not yet in recovery.
func frames_into_recovery(frame: int) -> int:
	if not is_in_recovery(frame):
		return -1
	return frame - recovery_start_frame()

func can_cancel_to_attack(frame: int) -> bool:
	var r := frames_into_recovery(frame)
	return cancel_to_attack_frame >= 0 and r >= cancel_to_attack_frame

func can_cancel_to_dodge(frame: int) -> bool:
	var r := frames_into_recovery(frame)
	return cancel_to_dodge_frame >= 0 and r >= cancel_to_dodge_frame

func can_cancel_to_parry(frame: int) -> bool:
	var r := frames_into_recovery(frame)
	return cancel_to_parry_frame >= 0 and r >= cancel_to_parry_frame

func can_cancel_to_swap(frame: int) -> bool:
	var r := frames_into_recovery(frame)
	return cancel_to_swap_frame >= 0 and r >= cancel_to_swap_frame

## True if this swap counts as a "perfect" swap-cancel (refunds its cost).
func is_perfect_swap(frame: int) -> bool:
	var r := frames_into_recovery(frame)
	if r < 0 or cancel_to_swap_frame < 0:
		return false
	return r >= cancel_to_swap_frame \
		and r < cancel_to_swap_frame + CombatConstants.SWAP_CANCEL_WINDOW
