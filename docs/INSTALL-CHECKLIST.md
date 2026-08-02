# Install Checklist

Godot lives at `C:\Godot`. The project lives at `D:\Godot Games\project-c`.

**Done for you:** the project folder and its full directory tree.

**Left for you:** four steps below. Roughly fifteen minutes. Tick them off in order.

---

## ☐ 1. Save the starter files into the project

These live in the chat above. Download each one and put it exactly here:

| File | Destination |
|---|---|
| `combat_constants.gd` | `project-c\scripts\combat\` |
| `attack_data.gd` | `project-c\scripts\combat\` |
| `combo_link.gd` | `project-c\scripts\combat\` |
| `input_buffer.gd` | `project-c\scripts\combat\` |
| `player_combat.gd` | `project-c\scripts\combat\` |
| `debug_overlay.gd` | `project-c\scripts\debug\` |
| `CLAUDE.md` | `project-c\` |
| `QUARRY-design-doc.md` | `project-c\` |
| `QUARRY-combat-tech-spec.md` | `project-c\` |
| `project.godot` | see step 2 — **not yet** |

---

## ☐ 2. Create the Godot project, then swap in the settings file

**Do it in this order.** It gives you a working fallback if anything goes wrong.

1. Run `C:\Godot\godot.exe`
2. **New Project** → Project Path: `D:\Godot Games\project-c` → Renderer: **Forward+** → **Create & Edit**
3. Godot will warn the folder isn't empty. That's expected — continue.
4. **Close Godot completely.**
5. Copy `project.godot` from the chat into `D:\Godot Games\project-c`, **overwriting** the one Godot just made.
6. Reopen the project.

That single file sets the 60 Hz physics tick, the window size, the `CombatConstants` autoload, and all fifteen input actions — the part that would otherwise be an hour of clicking.

**If Godot complains about the version:** let it upgrade the file. Everything important survives.

**If the project refuses to open:** delete `project.godot`, repeat steps 1–3 to regenerate a clean one, and set the physics tick manually under *Project Settings → Physics → Common → Physics Ticks Per Second → 60*. Then bring the input actions in by hand from the table in `SETUP.md`.

**Verify it worked** — open *Project → Project Settings → Input Map*. You should see all fifteen actions listed.

---

## ☐ 3. Put Godot on PATH

This is what lets Claude Code actually run and test the game. Skip it and you lose most of the benefit.

1. Make sure the executable is named **`godot.exe`** — rename it if it's still `Godot_v4.x-stable_win64.exe`
2. Windows key → search **environment variables** → *Edit the system environment variables*
3. **Environment Variables…** button
4. Under **User variables**, select **Path** → **Edit** → **New**
5. Add: `C:\Godot`
6. **OK** through every dialog
7. **Open a brand-new terminal** — existing ones won't pick it up

Check:

```
godot --version
```

A version number means you're done. "Not recognized" means the terminal was open before the change, or the exe isn't named `godot.exe`.

---

## ☐ 4. Git

Five seconds per commit, and it makes every future change reversible.

1. Install Git from `git-scm.com` if you don't have it (you appear to already)
2. In a terminal:

```
cd "D:\Godot Games\project-c"
git init
git add .
git commit -m "initial scaffold"
```

Create a **private** repo on GitHub and push to it within the week. A backup that only exists on this laptop is not a backup.

---

## Then start

```
cd "D:\Godot Games\project-c"
claude
```

First prompt:

> Read CLAUDE.md and QUARRY-combat-tech-spec.md. The starter scripts are in
> scripts/combat/ and scripts/debug/. Build the arena scene: orthogonal camera
> at roughly (0, 14, 10) rotated -50° on X, a CSGBox3D floor 20x1x20, a
> CharacterBody3D player named Player with a capsule mesh, a CollisionShape3D,
> and an Area3D child named Hitbox with a BoxShape3D. Attach player_combat.gd
> to the Player and wire hitbox_path. Add a CanvasLayer with a Control running
> debug_overlay.gd, and set its player_path to the Player.
> Then run `godot --headless --path . --quit-after 60` and show me the output.

That takes you to build-order step 3 with proof it runs.

---

## Current state

```
D:\Godot Games\project-c\
├── scripts\
│   ├── combat\        ← 5 .gd files go here
│   └── debug\         ← 1 .gd file goes here
├── data\
│   └── attacks\       ← .tres attack resources, created later
├── scenes\
├── models\
├── materials\
├── audio\
└── tests\             ← GUT test suites
```
