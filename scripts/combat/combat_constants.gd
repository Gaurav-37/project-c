# res://scripts/combat/combat_constants.gd
#
# Every global tuning value in one place.
# You will change these numbers hundreds of times. That is the point.
#
# Register as an Autoload:
#   Project -> Project Settings -> Autoload -> add this file, name it "CombatConstants"

extends Node

# ---------------------------------------------------------------------------
# TIMING  (all values in frames, at 60 physics ticks per second)
# ---------------------------------------------------------------------------

## How long an input is remembered if pressed too early.
## THE most important feel value in the project. 12 frames = 200ms.
## Too low and inputs feel dropped. Too high and the character feels autonomous.
const INPUT_BUFFER_FRAMES: int = 12

## Freeze duration on impact, by weight of blow.
const HITSTOP_LIGHT: int = 4
const HITSTOP_HEAVY: int = 8
const HITSTOP_BOUNCE: int = 11   # armour deflection — should feel like a wall

## Dodge
const DODGE_TOTAL_FRAMES: int = 24
const DODGE_IFRAME_START: int = 2
const DODGE_IFRAME_END: int = 14

## Parry
const PARRY_STARTUP: int = 3
const PARRY_ACTIVE: int = 6
const PARRY_RECOVERY: int = 19

## Weapon swap — only valid inside a cancel window (see design doc 6.4b)
const SWAP_COST: float = 8.0
const SWAP_CANCEL_WINDOW: int = 6   # a swap this precise refunds its cost


# ---------------------------------------------------------------------------
# MOMENTUM  (see design doc 5.4 — there are no cooldowns in this game)
# ---------------------------------------------------------------------------

const MOMENTUM_MAX: float = 100.0

## Fraction of banked Momentum lost when a combo is interrupted by the enemy.
## This is the stake. It should hurt.
const MOMENTUM_INTERRUPT_LOSS: float = 0.5

## Slow bleed while not in contact, so turtling is never free.
const MOMENTUM_DECAY_PER_FRAME: float = 0.15
const MOMENTUM_DECAY_GRACE_FRAMES: int = 90   # 1.5s of no contact before decay

## Healing is a Momentum spend, not an item (design doc 6.6)
const HEAL_COST: float = 25.0
const HEAL_AMOUNT: float = 35.0


# ---------------------------------------------------------------------------
# MOVEMENT
# ---------------------------------------------------------------------------

const MOVE_SPEED: float = 6.0
const ROTATION_SPEED: float = 12.0
const ARRIVAL_THRESHOLD: float = 0.25


# ---------------------------------------------------------------------------
# TARGET SNAPPING  (design doc / tech spec section 8)
# Applied during STARTUP frames only. Never during active or recovery.
# ---------------------------------------------------------------------------

const SNAP_MAX_ANGLE_DEG: float = 30.0
const SNAP_MAX_DISTANCE: float = 0.5


# ---------------------------------------------------------------------------
# HEALTH  (design doc 5.13 — three to five hits should kill)
# ---------------------------------------------------------------------------

const PLAYER_MAX_HEALTH: float = 100.0
