# QUARRY — Setup and First Week

Written for someone who has not used Godot before. Follow it in order. Nothing here requires programming knowledge.

---

## Part 1 — Install (about 30 minutes)

### 1. Godot 4 — on the D: drive

Download **Godot 4.x, Standard version** (not .NET/C#) from `godotengine.org`.

Godot does not have an installer. It is a single `.exe` you run directly.

Create this folder and put it there:

```
D:\Godot\
```

**On D:, not C:.** Your C: drive has about 40 GB free and Windows needs that headroom. Everything for this project lives on D:.

Run the .exe once. Right-click the taskbar icon → **Pin to taskbar**.

### 2. Project folders

```
D:\Godot\                        ← the Godot executable
D:\Godot Games\project-c\        ← the game project  (already created)
D:\Godot Games\_backups\         ← manual backups until git is set up
```

### 3. Create the project

Open Godot → **New Project**
- Project Path: `D:\Godot Games\project-c`
- Renderer: **Forward+**
- Version Control: **Git** (if offered)

Godot will warn that the folder is not empty only if something is already in it — an empty `project-c` is exactly what it wants.

### 4. Project settings — do this before anything else

**Project → Project Settings**

| Setting | Value | Why |
|---|---|---|
| Physics → Common → **Physics Ticks Per Second** | **60** | Every frame number in the tech spec assumes this. |
| Physics → Common → **Max Physics Steps Per Frame** | 8 | Prevents spiral-of-death on frame drops. |
| Display → Window → Size → Viewport Width | 1920 | |
| Display → Window → Size → Viewport Height | 1080 | |
| Display → Window → Stretch → Mode | `canvas_items` | |
| Rendering → Textures → Default Texture Filter | **Nearest** | Only if you go stylized/low-res. Skip otherwise. |

**Do not change the physics tick again, ever.** All tuning depends on it.

### 5. Input map

**Project → Project Settings → Input Map.** Add each action, then bind it.

| Action name | Bind to |
|---|---|
| `move_to` | Right mouse button |
| `attack` | Left mouse button |
| `attack_move` | A |
| `dodge` | Shift |
| `parry` | Space |
| `ability_q` | Q |
| `ability_e` | E |
| `ability_r` | R |
| `heal` | F |
| `weapon_swap` | Tab |
| `tool_1` | 1 |
| `tool_2` | 2 |
| `inspect` | Alt |
| `debug_toggle` | F1 |
| `debug_step` | F2 |

Type the name exactly — the scripts look for these strings.

---

## Part 2 — Folder structure

Inside `D:\Godot Games\project-c`, create:

```
res://
├── scripts/
│   ├── combat/
│   └── debug/
├── data/
│   └── attacks/          ← AttackData resources live here
├── scenes/
├── models/
├── materials/
└── audio/
```

Copy the `.gd` files from this starter kit into `scripts/combat/` and `scripts/debug/` as indicated by their headers.

---

## Part 3 — Backups (do not skip)

Two hours of work lost is annoying. Two months is fatal.

**Minimum viable, today:** copy the whole `project-c` folder into `D:\Godot Games\_backups\project-c-YYYY-MM-DD` at the end of every working session.

**Proper, within the first week:** install Git (`git-scm.com`), create a **private** repository on GitHub, and commit at the end of each session. Add Git LFS later, when you start adding 3D models.

A backup that lives only on this laptop is not a backup. Get it off the machine.

---

## Part 4 — The first week

Steps 1–5 of the build order in the tech spec. The goal is **not** a fun game. The goal is a capsule that swings at a cube, with numbers on screen proving the machinery works.

### Day 1 — Learn the editor

Do **one** complete Godot 3D tutorial, start to finish, without skipping. Any beginner 3D one on the official site.

You are not learning to program. You are learning what nodes and scenes are, so that the rest of this stops looking like noise. Skipping this makes everything after it harder.

### Day 2 — Empty scene, camera, floor

- New 3D scene, save as `scenes/arena.tscn`
- Add a `CSGBox3D` floor, scale to about 20 × 1 × 20
- Add a `Camera3D`, position around `(0, 14, 10)`, rotate X to about `-50°`
- **Projection: Orthogonal**, Size around 14

That's your isometric view. Press Play and confirm you see a floor from above at an angle.

### Day 3 — Player and debug overlay

- Add a `CharacterBody3D` named `Player` with a capsule mesh and matching collision shape
- Attach `player_combat.gd`
- Add a `CanvasLayer` → `Control` named `DebugOverlay`, attach `debug_overlay.gd`
- Set the overlay's `player_path` in the Inspector to point at your Player

Press Play, press **F1**. Numbers should appear.

**Milestone: build order step 1 complete.** The frame counter is advancing.

### Day 4 — Movement

Right-click should move the capsule to the clicked point.

**Milestone: step 2.**

### Day 5 — One attack

Create your first `AttackData` resource in `data/attacks/`:
- Right-click in the FileSystem panel → **New Resource** → `AttackData`
- Name it `glaive_l1.tres`
- Set `startup_frames = 6`, `active_frames = 3`, `recovery_frames = 12`

Assign it to the player's `starting_attack`. Left-click should now run through the three phases, visible in the overlay.

**Milestone: step 3.**

### Day 6 — Hitbox and dummy

- Add an `Area3D` child of Player named `Hitbox`, with a box collision shape, disabled by default
- Add a static box in the arena as a dummy target

The hitbox should activate only during the active frames. Watch it in the overlay.

**Milestone: step 4.**

### Day 7 — Buffer, and the first real test

The input buffer is already in the code. Test it:

Press attack during recovery, slightly before the cancel window opens. **The input must register.** If it does, buffering works, and you have the single most important piece of game feel in the project.

**Milestone: step 5.**

---

## What "done" looks like after week one

A capsule that moves on right-click and swings at a cube, with a debug overlay showing state, frame count, cancel windows and buffer contents.

It will not be fun. It is not supposed to be. It is the machinery that everything else is built on, and it is the part that has to be correct before feel-tuning means anything.

**Next up is step 6 — a second attack and a cancel window — which is when you get your first real combo, and the first moment this starts to feel like a game.**

---

## When you get stuck

You will. Everyone does. In order:

1. Read the error in Godot's Output panel — it names the file and line
2. Search the exact error text; Godot's community is large and GDScript answers dominate
3. Bring the error text and the relevant script back here

Errors are information, not failure. The Output panel is telling you exactly what it wants.
