# res://scripts/combat/combo_link.gd
#
# One branch of the combo tree: "from this attack, if the player presses X,
# and they can afford it, go to attack Y."
#
# Combos are DATA, not code. Adding a new branch means making a resource,
# not editing a script.

class_name ComboLink
extends Resource

## Which input triggers this branch.
## Must match an Input Map action: "attack", "attack_hold", "ability_q",
## "ability_e", "ability_r", "weapon_swap"
@export var input_action: StringName = &"attack"

## The id of the AttackData this leads to.
@export var next_attack_id: StringName

## Momentum required. 0 = a basic chain step. > 0 = an ability route.
@export var required_momentum: float = 0.0

## If true, this branch only opens when the previous attack actually connected.
## Use for finishers that should not be available on a whiff.
@export var requires_hit_confirm: bool = false
