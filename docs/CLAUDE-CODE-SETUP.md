# Running Claude Code on QUARRY

How to set up Claude Code so it can write, verify and iterate on the project largely on its own.

---

## 1. Install Claude Code

**Requires a Claude Pro, Max, Team or Enterprise subscription.** Not available on the free plan.

The **native installer** is now the recommended method and needs no Node.js. The npm route also works and you already have Node installed.

**Native (recommended)** — follow the current instructions at `docs.claude.com`.

**npm alternative:**

```bash
npm install -g @anthropic-ai/claude-code
```

Then authenticate:

```bash
claude login
```

A browser window opens for sign-in.

---

## 2. Put Godot on PATH

This is the step that makes autonomous work possible. Without it, Claude Code cannot run or verify anything.

1. Rename your Godot executable to **`godot.exe`** (from something like `Godot_v4.4-stable_win64.exe`)
2. Windows key → search **"environment variables"** → *Edit the system environment variables*
3. **Environment Variables…** → under *User variables*, select **Path** → **Edit** → **New**
4. Add `D:\Godot`
5. **OK** through all dialogs, then **open a new terminal**

Verify:

```bash
godot --version
```

If that prints a version number, Claude Code can now drive the engine.

---

## 3. Start a session

Open a terminal in the project folder:

```bash
cd "D:\Godot Games\project-c"
claude
```

`CLAUDE.md` in the project root loads automatically as context — it contains the design rules, architecture and conventions, so you don't have to re-explain the project each session.

---

## 4. Install the test framework

**GUT (Godot Unit Test)** — the most established option, runs headless from the command line.

Install through Godot's **AssetLib** tab (search "GUT"), or clone from `github.com/bitwes/Gut` into `addons/gut/`. Enable it in **Project → Project Settings → Plugins**.

Create a `tests/` folder in the project root.

*(GdUnit4 is a reasonable alternative with slightly better structured CLI output.)*

---

## 5. The verification loop

These are the commands Claude Code should run after changing code. They are also in `CLAUDE.md`.

```bash
# Project opens and imports cleanly, runs 60 frames, exits
godot --headless --path . --quit-after 60

# Syntax-check one script
godot --headless --path . --check-only --script scripts/combat/player_combat.gd

# Run the test suite
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

**Caveat:** `--check-only` can report false failures on scripts that depend on autoloads, because autoloads aren't loaded before the script compiles. If a check fails oddly, fall back to the full `--quit-after 60` run, which is the more reliable signal.

---

## 6. What this loop can and cannot do

**It can, on its own:**

- Write GDScript and verify it parses
- Confirm the project still opens and imports
- Run unit tests on combat maths and report real pass/fail
- Catch regressions in cancel windows, buffer expiry, momentum arithmetic
- Read Godot's error output and fix its own mistakes

**It cannot, ever:**

- Tell you whether hit-stop feels good
- Tell you whether the input buffer is too long or too short
- Tell you whether a combo is satisfying
- Tell you whether an enemy telegraph is readable

**The loop closes on correctness, not on feel.** Everything in the first list is delegable. Everything in the second is yours, and no amount of tooling changes that.

Which is why the debug overlay and the tunable-values-in-resources structure matter so much: they make *your* iteration fast, since it's the only iteration that can't be automated.

---

## 7. Working effectively

**Give it one build-order step at a time.** "Implement step 6 — a second attack and a cancel window" produces far better work than "build the combat system."

**Make it run the verification command and show you the output.** Not "it should work." Actual terminal output.

**Play after every step.** The loop can't tell you the thing you most need to know.

**Commit before each step.** `git commit -am "before step 6"` costs five seconds and means any change is reversible.

**When it violates a design rule, point at `CLAUDE.md`.** The rules are written down precisely so you don't have to re-argue them — "that adds a cooldown, see rule 1" is a complete correction.

---

## 8. First session

```
cd "D:\Godot Games\project-c"
claude
```

Then, roughly:

> Read CLAUDE.md and QUARRY-combat-tech-spec.md. The starter scripts are in
> scripts/combat/ and scripts/debug/. Set up the Godot project so it runs:
> an arena scene with an orthogonal camera, a CharacterBody3D player with
> the capsule mesh and hitbox, and the debug overlay wired up. Then run
> `godot --headless --path . --quit-after 60` and show me the output.

That gets you to build-order step 3 in one go, with proof it runs.

---

## Sources

- [Claude Code installation](https://docs.claude.com)
- [Godot command line tutorial](https://docs.godotengine.org/en/4.4/tutorials/editor/command_line_tutorial.html)
- [GUT — Godot Unit Test](https://github.com/bitwes/Gut)
