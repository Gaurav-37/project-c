# res://scripts/combat/input_buffer.gd
#
# Remembers inputs pressed slightly too early and replays them the moment
# they become legal.
#
# This is the single highest-impact piece of game feel in the project.
# Without it, players feel the game is ignoring them. With it, the same
# combat feels responsive and forgiving.
#
# CRITICAL: this buffer must keep filling during hit-stop. If it stops,
# players lose inputs at exactly the moment they are most likely to press —
# on impact. That is the classic "my combos feel bad" bug.

class_name InputBuffer
extends RefCounted

const TRACKED_ACTIONS: Array[StringName] = [
	&"attack",
	&"attack_hold",
	&"dodge",
	&"parry",
	&"ability_q",
	&"ability_e",
	&"ability_r",
	&"heal",
	&"weapon_swap",
]

var _entries: Array[Dictionary] = []


## Call every tick, INCLUDING during hit-stop.
func poll(current_frame: int) -> void:
	for action in TRACKED_ACTIONS:
		if InputMap.has_action(action) and Input.is_action_just_pressed(action):
			_entries.append({ "action": action, "frame": current_frame })
	_expire(current_frame)


## Is this action waiting in the buffer? Does not remove it.
func has(action: StringName, current_frame: int) -> bool:
	for e in _entries:
		if e.action == action and _age(e, current_frame) <= CombatConstants.INPUT_BUFFER_FRAMES:
			return true
	return false


## Take this action out of the buffer if present. One press, one action.
## Scans newest-first so the most recent intent wins.
func consume(action: StringName, current_frame: int) -> bool:
	for i in range(_entries.size() - 1, -1, -1):
		var e := _entries[i]
		if e.action == action and _age(e, current_frame) <= CombatConstants.INPUT_BUFFER_FRAMES:
			_entries.remove_at(i)
			return true
	return false


## Clear everything. Use on death or scene change — NOT on state change.
func clear() -> void:
	_entries.clear()


## For the debug overlay.
func debug_contents(current_frame: int) -> Array[String]:
	var out: Array[String] = []
	for e in _entries:
		out.append("%s (%df)" % [e.action, _age(e, current_frame)])
	return out


func _age(entry: Dictionary, current_frame: int) -> int:
	return current_frame - int(entry.frame)


## Entries expire by AGE only, never by state change.
func _expire(current_frame: int) -> void:
	var kept: Array[Dictionary] = []
	for e in _entries:
		if _age(e, current_frame) <= CombatConstants.INPUT_BUFFER_FRAMES:
			kept.append(e)
	_entries = kept
