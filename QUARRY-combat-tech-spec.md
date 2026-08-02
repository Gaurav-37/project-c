# QUARRY — Combat Technical Specification
### v1.0 · Companion to the QUARRY Design Document

**Who this is for:** whoever implements the combat system, human or AI. Every section opens with a plain-English summary, so the document is readable end to end without a programming background.

---

## 0. Language and Engine Decision

**Engine:** Godot 4.x
**Language:** **GDScript.** Not C++, not C#.

| Option | Verdict |
|---|---|
| **GDScript** | **Chosen.** Python-like and readable by a non-programmer. Hot-reloads, so tuning a number is instant. Vast majority of Godot documentation and community answers use it. |
| C# | Adds a build step and toolchain complexity for performance this project does not need. |
| C++ (GDExtension) | Full native speed, but requires recompiling on every change — fatal on a 4-core laptop when the core work is hundreds of tuning iterations. |

**Performance reality check:** GDScript becomes a bottleneck in the thousands-of-entities range. This game has one creature and one player. It is nowhere near the ceiling.

**Escape hatch:** if profiling later identifies a genuine hot path — most likely the procedural IK solver on a large creature — port *that single module* to C++ via GDExtension and leave everything else in GDScript. Do not pre-optimise.

---

## 1. The Governing Principle

> **Gameplay logic drives. Animation follows. Never the reverse.**

**Plain English:** the game decides what is happening; the animation is a picture of it. The animation never decides anything.

The tempting Godot approach is to attach hitbox activation to animation keyframes and let the `AnimationPlayer` own timing. It works for roughly three weeks, then becomes impossible to debug, impossible to buffer correctly, and impossible to tune without re-exporting art assets.

**Instead:**

- Combat runs on an integer frame counter inside `_physics_process`, at a **fixed 60 Hz**.
- The state machine owns all timing: which frame we are on, whether the hitbox is live, whether the cancel window is open.
- `AnimationTree` is told what to play. It never reports back.

**Set this in project settings and never change it:**
```
Engine.physics_ticks_per_second = 60
```

All frame values in this document assume that tick rate.

### Movement: code-driven, not root motion

Character position is set by code. Animation is cosmetic.

Root motion looks more natural and is far less predictable. For a game where exact reach and exact timing *are* the product, predictability wins outright.

### Why determinism matters here

A fixed tick with integer frame counts and no reliance on `delta` for combat logic means the same inputs always produce the same result. That gives you reproducible bug reports, automated testing, and consistency with the design document's no-randomness pillar.

---

## 2. Tick Order

**Plain English:** the exact sequence of operations every frame. Getting this order wrong causes the "my input didn't register" class of bug, which is miserable to diagnose after the fact.

Execute in this order inside `_physics_process`:

```
1. HIT-STOP GATE
   if hitstop_frames > 0:
       hitstop_frames -= 1
       poll input → push to buffer      # buffer still fills during freeze
       return                            # skip all gameplay advancement

2. INPUT
   poll raw input → push actions into the input buffer with current frame stamp

3. ADVANCE
   state_frame += 1

4. TRANSITIONS
   evaluate the buffer against the current state's open windows
   if a valid transition exists → consume the buffered input, change state, reset state_frame

5. HITBOX
   enable or disable the hitbox based on the current attack's active window

6. RESOLVE
   process collisions → apply damage, part damage, wounds, momentum
   on a confirmed hit → set hitstop_frames

7. PRESENT
   update AnimationTree, VFX, camera, UI to match state
```

**Critical rule:** hit-stop freezes gameplay advancement but **must not** block input buffering. If the buffer stops filling during hit-stop, players lose inputs at exactly the moment they are most likely to press — on impact. This is the single most common source of "the combos feel bad" in homemade action games.

---

## 3. Player State Machine

**Plain English:** the player is always in exactly one of these states. Each has rules about what it can become next.

```
IDLE
MOVING
ATTACK_STARTUP     → ATTACK_ACTIVE
ATTACK_ACTIVE      → ATTACK_RECOVERY
ATTACK_RECOVERY    → IDLE | next attack | dodge | parry
DODGE
PARRY_STARTUP      → PARRY_ACTIVE
PARRY_ACTIVE       → PARRY_SUCCESS | PARRY_RECOVERY
PARRY_SUCCESS
KNOCKDOWN          → RISING_FAST | RISING_SLOW
RISING_FAST / RISING_SLOW → IDLE
```

**Hit-stop is not a state.** It is a global counter that pauses frame advancement. Modelling it as a state creates transition bugs at every boundary.

### Attack phase structure

Every attack has three phases measured in frames:

| Phase | Meaning |
|---|---|
| **Startup** | Wind-up. Hitbox inactive. The creature's opportunity to punish. |
| **Active** | Hitbox live. Contact is possible. |
| **Recovery** | Follow-through. Hitbox inactive. **Cancel windows open here.** |

---

## 4. Frame Data Schema

**Plain English:** every tuning number lives in a data file you can edit with sliders, not buried in code. This is the most important structural decision in the document — it is the difference between tuning thirty times and tuning three hundred times.

Create as a Godot `Resource` so instances are editable in the Inspector and hot-reload without a restart.

```gdscript
class_name AttackData extends Resource

# --- identity ---
@export var id: StringName
@export var animation_name: StringName
@export var display_name: String

# --- timing (frames @ 60Hz) ---
@export var startup_frames: int = 7
@export var active_frames: int = 3
@export var recovery_frames: int = 14

# --- cancel windows (frame offset INTO recovery; -1 = never) ---
@export var cancel_to_attack_frame: int = 4
@export var cancel_to_dodge_frame: int = -1
@export var cancel_to_parry_frame: int = -1

# --- damage ---
@export var damage: float = 10.0
@export var part_damage_multiplier: float = 1.0
@export var wound_application: float = 1.0
@export var poise_damage: float = 5.0

# --- momentum ---
@export var momentum_gain: float = 4.0
@export var momentum_cost: float = 0.0        # > 0 makes this an ability

# --- feel ---
@export var hitstop_frames_on_hit: int = 4
@export var hitstop_frames_on_bounce: int = 8   # armour deflection
@export var snap_max_angle_deg: float = 30.0
@export var snap_max_distance: float = 0.5
@export var camera_shake: float = 0.0

# --- hitbox ---
@export var hitbox_offset: Vector3
@export var hitbox_size: Vector3

# --- chaining ---
@export var links: Array[ComboLink] = []
```

```gdscript
class_name ComboLink extends Resource

@export var input_action: StringName        # "light", "heavy", "ability_q" ...
@export var next_attack_id: StringName
@export var required_momentum: float = 0.0
@export var requires_hit_confirm: bool = false   # only chains if the previous hit landed
```

**Total attack duration** = `startup + active + recovery`.
**Cancel windows are offsets into recovery**, not absolute frames — so retiming an attack does not silently break its links.

### Starting values

Tuned starting points, not final answers. Beginning from sensible numbers rather than zero saves weeks.

| Attack | Startup | Active | Recovery | Cancel → attack |
|---|---|---|---|---|
| Light 1 | 6 | 3 | 12 | 4 |
| Light 2 | 7 | 3 | 13 | 4 |
| Light 3 (finisher) | 10 | 4 | 20 | 8 |
| Heavy | 16 | 4 | 26 | 8 |
| Ability | 12 | 5 | 22 | 10 |

| Global | Value |
|---|---|
| Input buffer window | 12 frames (200 ms) |
| Hit-stop, light | 3–4 frames |
| Hit-stop, heavy | 6–10 frames |
| Hit-stop, armour bounce | 8–12 frames |
| Animation blend time | 0.06–0.10 s |
| Dodge i-frames | 8–12, beginning frame 2 |
| Dodge total | 24 frames |
| Parry active window | 6 frames, beginning frame 3 |
| Parry total | 28 frames |

**Responsiveness budget:** time from button press to visible response should stay under ~100 ms (6 frames). If an attack's startup exceeds that, the *animation* must show anticipation within 6 frames even if the hitbox comes later.

---

## 5. Input Buffer

**Plain English:** if the player presses a button slightly too early, remember it and use it as soon as it becomes legal. Without this, the game feels like it is ignoring them. This is the highest-impact single mechanism in the document.

```gdscript
class_name InputBuffer

const WINDOW_FRAMES := 12

var _entries: Array = []   # [{action: StringName, frame: int}]

func push(action: StringName, frame: int) -> void:
    _entries.append({ "action": action, "frame": frame })

func consume(action: StringName, current_frame: int) -> bool:
    for i in range(_entries.size() - 1, -1, -1):
        var e = _entries[i]
        if e.action == action and current_frame - e.frame <= WINDOW_FRAMES:
            _entries.remove_at(i)
            return true
    return false

func expire(current_frame: int) -> void:
    _entries = _entries.filter(
        func(e): return current_frame - e.frame <= WINDOW_FRAMES
    )
```

**Rules:**

1. The buffer fills **during hit-stop**. Non-negotiable.
2. A consumed input is removed immediately — one press, one action.
3. Entries expire by age, never by state change.
4. Scan newest-first, so the most recent intent wins.
5. Buffer window is per-project, not per-attack. Keep it uniform or inputs feel inconsistent.

---

## 6. Cancel Windows and the Commitment Rule

**Plain English:** offence should flow freely. Defence should cost something. This preserves the greed tension the design depends on while keeping chains fluid.

| Cancel into | Availability |
|---|---|
| **Another attack** | Freely, from `cancel_to_attack_frame` onward |
| **Dodge** | Only on attacks that explicitly permit it (`cancel_to_dodge_frame >= 0`) |
| **Parry** | Rarely. Reserved as weapon identity for defensive weapons |

Heavy and finisher attacks should generally set `cancel_to_dodge_frame = -1`. That is what makes committing to them a real decision, and what gives the creature a genuine punish window.

---

## 7. Hit-Stop

**Plain English:** freezing the picture for a few frames on impact makes the hit feel heavier and, counterintuitively, makes the whole exchange feel faster.

- Freeze **both** attacker and target.
- Scale duration to attack weight — heavier blows freeze longer.
- Armour bounces freeze **longest**. The deflection should feel like hitting a wall.
- Implement as a tick-skip (see §2), not as a state.
- Do not freeze the camera, UI, or particle systems — freeze the actors only.

---

## 8. Target Snapping

**Plain English:** nudge the character toward what they are aiming at during wind-up so attacks connect. Every action game does this. Nobody notices it, but its absence makes near-misses feel like the game cheated.

During `ATTACK_STARTUP` only:

1. Find the aim target — the creature part under the cursor, or nearest part within reach.
2. Rotate toward it, capped at `snap_max_angle_deg`, distributed across startup frames.
3. Translate toward it, capped at `snap_max_distance`.
4. **Never snap during active or recovery.** Snapping after the hitbox goes live produces attacks that visibly bend around the target.

---

## 9. Combo Tree

**Plain English:** combos are a branching map, not a fixed list. Each attack knows which attacks it can flow into and what each transition requires.

The tree is defined entirely by `AttackData.links` — no combo logic in code.

```
light_1 ──light──> light_2 ──light──> light_3_finisher
   │                  │
   │heavy             │heavy (needs 20 momentum)
   ▼                  ▼
heavy_slam         rising_break        ← part-breaking route
```

**Resolution order on input:**

1. Is the cancel window open for this input type?
2. Does a `ComboLink` exist for this action from the current attack?
3. Is `required_momentum` satisfied?
4. Is `requires_hit_confirm` satisfied, if set?
5. → Transition, spend momentum, reset `state_frame`.

Otherwise the input stays in the buffer and is re-tested next frame.

---

## 10. Momentum Integration

Per the design document, there are no cooldowns anywhere. Abilities are gated by a resource earned through execution.

```gdscript
var momentum: float = 0.0
const MOMENTUM_MAX := 100.0
const DECAY_PER_FRAME := 0.15        # only while out of combat contact
const INTERRUPT_LOSS_RATIO := 0.5    # fraction lost when a combo is broken
```

| Event | Effect |
|---|---|
| Attack lands | `+ momentum_gain` (rises through the chain — later hits pay more) |
| Perfect parry | Large flat gain |
| Ability used | `- momentum_cost` |
| **Player struck mid-combo** | **Lose `INTERRUPT_LOSS_RATIO` of current momentum** |
| No contact for N frames | Slow decay |

The interrupt loss is the stake. It should hurt enough that the player feels it and adjusts their greed accordingly.

---

## 11. Part Damage and Hitbox Model

**Plain English:** the creature is not one target with one health bar. It is a set of parts, each tracked separately.

Each creature part is an `Area3D` with:

```gdscript
class_name CreaturePart extends Area3D

@export var part_id: StringName
@export var durability_max: float
@export var armoured: bool = false       # bounces weak attacks
@export var armour_threshold: float      # damage below this deflects
@export var breaks_into_state: StringName

var durability: float
var wound: float = 0.0                   # persistent, slow decay
var is_broken: bool = false
```

**On hit resolution:**

1. Identify which part was struck.
2. If `armoured` and incoming damage `< armour_threshold` → **bounce**: no damage, long hit-stop, player self-stagger, momentum penalty.
3. Otherwise apply `damage × part_damage_multiplier` to durability, and `wound_application` to wound.
4. If `durability <= 0` → break: swap mesh, disable the relevant IK chain, remove the associated attacks from the creature's moveset, emit `part_broken`.
5. `part_broken` is consumed by the Rage system and the Threshold system.

**Wounds** decay slowly and independently, rewarding sustained focus on one part rather than spreading damage evenly.

---

## 12. Debug Overlay

**Plain English:** you cannot tune what you cannot see. Build this before building the combos. It looks like a detour and it is not — it is probably the highest-value day of work in the whole prototype.

On-screen, toggleable, showing:

- Current state and `state_frame`
- Current attack id and phase (startup / active / recovery)
- **Cancel window status** — open or closed, and for which inputs
- **Input buffer contents** with age in frames
- Hit-stop counter
- Hitbox wireframes, coloured by active state
- Momentum value and last change
- Per-part durability and wound values
- Threshold clock and required parts
- Frame-step mode: advance one frame at a time

"Why didn't my input register" is unanswerable without this overlay and trivial with it.

---

## 13. Build Order

Strictly sequential. Each step is playable and verifiable before the next begins.

| # | Step | Done when |
|---|---|---|
| 1 | Fixed 60 Hz tick + debug overlay skeleton | Frame counter visible and advancing |
| 2 | Player state machine, IDLE and MOVING only | Right-click movement works |
| 3 | One attack with startup/active/recovery from `AttackData` | Phases visible in overlay |
| 4 | Hitbox activation + a static dummy target | Dummy takes damage during active frames only |
| 5 | **Input buffer** | Early presses register correctly |
| 6 | Second attack + cancel window | **First real combo chains** |
| 7 | Hit-stop | Impacts feel weighty |
| 8 | Target snapping | Near-misses connect |
| 9 | Combo tree from data, 3-hit chain with one branch | Branch routing works |
| 10 | Momentum: gain, spend, interrupt loss | Ability gated by execution |
| 11 | Dodge with i-frames | |
| 12 | Parry with active window and success state | |
| 13 | Creature parts, durability, armour bounce | Parts break, mesh swaps |
| 14 | Creature moveset with telegraphs | |
| 15 | Rage triggered by part break | |
| 16 | Threshold clock and gradient outcome | |
| 17 | Knockdown and rise options | |

**Steps 1–9 are the feel core.** If those nine do not feel good, no later step rescues them.

---

## 14. Feel Verification Checklist

Test these by hand before declaring combat done. Each targets a specific known failure mode.

- [ ] Press attack the instant before recovery ends — **the input must register**
- [ ] Mash attack during hit-stop — **no inputs lost**
- [ ] Full 3-hit chain with no visible pause between hits
- [ ] Attack that misses feels different from one that lands, without reading the numbers
- [ ] Armour bounce is unmistakable — the hand should feel it
- [ ] Dodge cancel is available on light attacks, unavailable on heavies
- [ ] Attack slightly off-centre still connects (snapping working)
- [ ] Attack far off-centre clearly misses (snapping not overreaching)
- [ ] Camera never obscures the creature's wind-up
- [ ] Combo interrupted by the creature — momentum loss is *felt*, not just displayed
- [ ] Fifty consecutive hunts without the inputs feeling inconsistent

---

## 15. Division of Labour

**Machinery — specifiable, testable, safe to delegate to AI:**
state machine, tick order, input buffer, cancel-window logic, frame counters, hitbox resolution, part damage, momentum accounting, data schema, debug overlay.

**Values — yours, and not delegable:**
every number in §4. Startup frames, hit-stop durations, buffer length, snap angles, damage figures, momentum rates.

Nobody can prompt their way to a good hit-stop duration. That is a hand judgement made three hundred times, and it is the part of this project that no tool can do for you.

---

*Companion to the QUARRY Design Document v0.4. All frame values assume a fixed 60 Hz tick and are starting points for tuning, not final figures.*
