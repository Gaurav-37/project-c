# QUARRY — Project Context

Place this file at the root of `D:\Godot Games\project-c`. Claude Code loads it automatically at the start of every session.

---

## What this project is

An isometric 3D action game built around hunting a small number of large, deterministic, learnable enemies. No trash mobs, no random loot, no procedural runs.

**Engine:** Godot 4.x · **Language:** GDScript only · **Platforms:** Windows, macOS, Linux (PC only, no consoles)

**Team:** one non-technical designer, working with AI assistance. Write code that a non-programmer can read. Prefer clarity over cleverness. Comment the *why*, not the *what*.

---

## Non-negotiable design rules

Violating any of these breaks the game's design. If a request appears to require breaking one, **stop and say so** rather than implementing it.

### 1. No cooldowns. Anywhere.

Abilities are gated by **Momentum**, a resource earned through combo execution. Never add a timer, `Timer` node, or elapsed-time gate to any ability.

*Reason: this is a single-enemy game with no macro layer. Cooldown gaps become dead air.*

### 2. Nothing is random

No `randi()`, `randf()`, or `RandomNumberGenerator` in combat, damage, loot, drops, enemy behaviour, or rewards. Every outcome must be reproducible from the same inputs.

*Reason: every death must be legible and the player's own fault.*

### 3. Gameplay logic drives. Animation follows.

Combat runs on an integer frame counter in `_physics_process` at a fixed **60 Hz**. Never read state from `AnimationPlayer`. Never attach gameplay logic (hitbox activation, damage, state changes) to animation keyframes or `call_method` tracks.

Movement is code-driven. **Never use root motion.**

### 4. Data, not code

Attack timings, damage, momentum values, cancel windows and combo links live in `AttackData` and `ComboLink` resources, editable in the Inspector. Adding a combo branch means creating a resource, never editing a script.

### 5. Windows, never timings

Upgrades and passives may modify *windows* — parry width, cancel windows, i-frame duration. They must **never** modify attack startup, active or recovery frames.

*Reason: variable attack timings force combat to be balanced at many frame values simultaneously.*

### 6. The input buffer fills during hit-stop

Hit-stop is a tick-skip that halts gameplay advancement. Input polling must continue. If the buffer stops filling during hit-stop, players lose inputs on impact — the classic "combat feels bad" bug.

### 7. The player's optimal action must never be "wait"

Any system that makes waiting correct is wrong. Test every new mechanic against this sentence.

---

## Architecture

### Tick order — do not reorder

Inside `_physics_process`:

1. **Hit-stop gate** — if frozen, poll input, then return
2. **Input** — poll into the buffer
3. **Advance** — increment `state_frame`
4. **Transitions** — evaluate buffer against open cancel windows
5. **Hitbox** — enable/disable per active frames
6. **Resolve** — collisions, damage, momentum, set hit-stop
7. **Present** — animation, VFX, UI

### Attack phases

`STARTUP` (hitbox off, punishable) → `ACTIVE` (hitbox live) → `RECOVERY` (hitbox off, cancel windows open here)

Cancel windows are stored as **offsets into recovery**, never absolute frames, so retiming an attack cannot silently break its links.

### State machine

`IDLE · MOVING · ATTACK · DODGE · PARRY · HEAL · KNOCKDOWN`

Hit-stop is **not** a state — it is a counter. Modelling it as a state creates transition bugs at every boundary.

---

## File map

```
res://
├── scripts/
│   ├── combat/
│   │   ├── combat_constants.gd   # autoload — all global tuning values
│   │   ├── attack_data.gd        # Resource — one attack, fully as data
│   │   ├── combo_link.gd         # Resource — one combo branch
│   │   ├── input_buffer.gd       # early-input memory
│   │   └── player_combat.gd      # the state machine and tick
│   └── debug/
│       └── debug_overlay.gd      # F1 — frames, windows, buffer, momentum
├── data/attacks/                 # .tres AttackData resources
├── scenes/
├── models/ · materials/ · audio/
└── tests/                        # GUT test suites
```

`CombatConstants` must be registered as an Autoload with exactly that name.

---

## Code conventions

- GDScript only. No C#, no GDExtension, no C++.
- Static typing everywhere: `var x: int = 0`, `func f(a: float) -> void:`
- `snake_case` for files, variables and functions; `PascalCase` for classes
- `StringName` (`&"attack"`) for identifiers compared every frame
- Tabs for indentation (Godot default)
- Prefer signals over direct cross-node calls
- No node lookups by string path in `_physics_process` — cache in `_ready`

---

## Verifying work

Godot must be on PATH as `godot`.

```bash
# Does the project still open and import cleanly?
godot --headless --path . --quit-after 60

# Syntax-check a single script
godot --headless --path . --check-only --script scripts/combat/player_combat.gd

# Run the test suite (GUT)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**Always run at least the first command after changing combat code.** Report the actual output; do not assume success.

---

## What to test

The combat maths is pure logic and should be unit-tested:

- `AttackData` phase helpers — `is_in_startup`, `is_in_active`, `is_in_recovery`
- Cancel-window boundaries, especially the exact opening frame
- `InputBuffer` — expiry by age, newest-first consumption, one-press-one-action
- Momentum arithmetic — gain, spend, clamping, interrupt loss
- Combo resolution — momentum gating, hit-confirm requirements

These tests are the guardrail against AI-written changes silently breaking timing.

---

## What is NOT yours to decide

**Do not change tuning values unless explicitly asked.** Frame counts, hit-stop durations, buffer length, damage figures, momentum rates and snap angles are the designer's, tuned by feel over hundreds of iterations.

You may add new tunable fields. You may not "improve" existing values.

Nobody can reason their way to a good hit-stop duration.

---

## Current position

**Build order steps 1–5 are scaffolded.** Working toward step 6 — a second attack and a cancel window, producing the first real combo.

Remaining order: 6 combo · 7 hit-stop · 8 target snapping · 9 combo tree from data · 10 momentum · 11 dodge · 12 parry · 13 creature parts · 14 enemy moveset · 15 rage · 16 threshold · 17 knockdown.

**Do not build ahead.** Each step must be playable and verified before the next begins.

---

## Reference documents

`QUARRY-design-doc.md` and `QUARRY-combat-tech-spec.md` — keep both in the repo root. The tech spec is authoritative on architecture; the design doc is authoritative on intent.
