# res://tests/test_input_buffer.gd
#
# InputBuffer expiry, newest-first consumption, one-press-one-action.
#
# poll() reads real Input state, which we can't drive headlessly, so these
# tests seed _entries directly (GDScript has no real access control — this
# is the same trick used to confirm the mechanism works at all) and then
# exercise the public has()/consume() surface, plus poll()'s expiry pass.

extends "res://tests/test_base.gd"


func test_consume_within_window_succeeds_and_removes() -> void:
	var buf := InputBuffer.new()
	buf._entries.append({"action": &"attack", "frame": 0})

	check(buf.consume(&"attack", CombatConstants.INPUT_BUFFER_FRAMES), "consume succeeds at exactly the buffer's age limit")
	check_eq(buf._entries.size(), 0, "consumed entry is removed from the buffer")


func test_consume_beyond_window_fails_expiry_by_age() -> void:
	var buf := InputBuffer.new()
	buf._entries.append({"action": &"attack", "frame": 0})

	var too_old_frame := CombatConstants.INPUT_BUFFER_FRAMES + 1
	check(not buf.consume(&"attack", too_old_frame), "consume fails one frame past the buffer window")


func test_has_does_not_remove_entry() -> void:
	var buf := InputBuffer.new()
	buf._entries.append({"action": &"dodge", "frame": 0})

	check(buf.has(&"dodge", 1), "has() reports the entry present")
	check(buf.has(&"dodge", 1), "has() called twice does not consume it")
	check(buf.consume(&"dodge", 1), "the entry is still consumable afterwards")


func test_consume_is_newest_first() -> void:
	var buf := InputBuffer.new()
	# Chronological order, oldest appended first — same order poll() would produce.
	buf._entries.append({"action": &"attack", "frame": 0})
	buf._entries.append({"action": &"attack", "frame": 3})

	check(buf.consume(&"attack", 4), "consume removes one of the two matching entries")
	check_eq(buf._entries.size(), 1, "exactly one entry remains")
	check_eq(buf._entries[0].frame, 0, "the OLDER entry (frame 0) is the one left behind")


func test_one_press_one_action() -> void:
	var buf := InputBuffer.new()
	buf._entries.append({"action": &"parry", "frame": 0})

	check(buf.consume(&"parry", 1), "first consume of a single entry succeeds")
	check(not buf.consume(&"parry", 1), "second consume finds nothing left — one press, one action")


func test_poll_expires_stale_entries_by_age_alone() -> void:
	var buf := InputBuffer.new()
	buf._entries.append({"action": &"heal", "frame": 0})

	# poll() with no real input just runs its expiry pass at this frame count.
	buf.poll(CombatConstants.INPUT_BUFFER_FRAMES + 1)

	check_eq(buf._entries.size(), 0, "poll() expires an entry once its age exceeds the buffer window")
