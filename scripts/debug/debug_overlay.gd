# res://scripts/debug/debug_overlay.gd
#
# Build this BEFORE the combos. It looks like a detour and it is not —
# it is probably the highest-value day of work in the whole prototype.
#
# "Why didn't my input register" is unanswerable without it and obvious with it.
#
# SETUP:
#   CanvasLayer -> Control (name it DebugOverlay) -> attach this script
#   Set player_path in the Inspector to your Player node
#   F1 toggles

extends Control

@export var player_path: NodePath
@export var enabled_at_start: bool = true

var _player: PlayerCombat
var _font: Font
var _visible: bool

const LINE_H := 18
const MARGIN := Vector2(16, 16)

const COL_TEXT := Color(0.92, 0.92, 0.88)
const COL_DIM := Color(0.60, 0.60, 0.56)
const COL_HOT := Color(0.98, 0.55, 0.30)
const COL_GOOD := Color(0.55, 0.85, 0.55)
const COL_BG := Color(0.05, 0.05, 0.06, 0.78)


func _ready() -> void:
	_visible = enabled_at_start
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as PlayerCombat


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			_visible = not _visible
			queue_redraw()


func _process(_delta: float) -> void:
	if _visible:
		queue_redraw()


func _draw() -> void:
	if not _visible or _player == null:
		return

	var lines: Array = []

	lines.append(["── STATE ──", COL_DIM])
	lines.append(["state        %s" % _player.debug_state_name(), COL_TEXT])
	lines.append(["state_frame  %d" % _player.state_frame, COL_TEXT])
	lines.append(["global_frame %d" % _player.global_frame, COL_DIM])

	if _player.hitstop_frames > 0:
		lines.append(["HITSTOP      %d" % _player.hitstop_frames, COL_HOT])
	else:
		lines.append(["hitstop      -", COL_DIM])

	lines.append(["", COL_DIM])
	lines.append(["── ATTACK ──", COL_DIM])

	var atk: AttackData = _player.current_attack
	if atk != null:
		lines.append(["attack       %s" % atk.display_name, COL_TEXT])
		var phase := _player.debug_phase_name()
		var phase_col := COL_TEXT
		if phase == "ACTIVE":
			phase_col = COL_HOT
		lines.append(["phase        %s" % phase, phase_col])
		lines.append(["frames       %d / %d" % [_player.state_frame, atk.total_frames()], COL_DIM])
		lines.append(["  startup    %d" % atk.startup_frames, COL_DIM])
		lines.append(["  active     %d" % atk.active_frames, COL_DIM])
		lines.append(["  recovery   %d" % atk.recovery_frames, COL_DIM])

		var into_rec := atk.frames_into_recovery(_player.state_frame)
		if into_rec >= 0:
			lines.append(["into_recov   %d" % into_rec, COL_DIM])

		var can_atk := atk.can_cancel_to_attack(_player.state_frame)
		lines.append([
			"CANCEL>ATK   %s" % ("OPEN" if can_atk else "closed"),
			COL_GOOD if can_atk else COL_DIM
		])

		var can_dodge := atk.can_cancel_to_dodge(_player.state_frame)
		lines.append([
			"CANCEL>DODGE %s" % ("OPEN" if can_dodge else "closed"),
			COL_GOOD if can_dodge else COL_DIM
		])

		lines.append(["connected    %s" % str(_player.attack_did_connect), COL_DIM])
	else:
		lines.append(["attack       -", COL_DIM])

	lines.append(["", COL_DIM])
	lines.append(["── MOMENTUM ──", COL_DIM])
	var m := _player.momentum
	var m_col := COL_TEXT
	if m >= 40.0:
		m_col = COL_GOOD
	lines.append(["momentum     %.1f / %.0f" % [m, CombatConstants.MOMENTUM_MAX], m_col])
	lines.append([_momentum_bar(m), m_col])
	lines.append(["health       %.0f" % _player.health, COL_TEXT])

	lines.append(["", COL_DIM])
	lines.append(["── INPUT BUFFER ──", COL_DIM])
	var buf := _player.debug_buffer()
	if buf.is_empty():
		lines.append(["(empty)", COL_DIM])
	else:
		for entry in buf:
			lines.append(["  %s" % entry, COL_HOT])

	lines.append(["", COL_DIM])
	lines.append(["F1 toggle", COL_DIM])

	# background panel
	var h := lines.size() * LINE_H + MARGIN.y * 2
	draw_rect(Rect2(Vector2.ZERO, Vector2(320, h)), COL_BG)

	var y := MARGIN.y + LINE_H
	for entry in lines:
		draw_string(_font, Vector2(MARGIN.x, y), entry[0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, entry[1])
		y += LINE_H


func _momentum_bar(value: float) -> String:
	var filled := int((value / CombatConstants.MOMENTUM_MAX) * 20.0)
	var s := ""
	for i in range(20):
		s += "█" if i < filled else "·"
	return s
