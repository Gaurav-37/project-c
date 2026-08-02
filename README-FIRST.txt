QUARRY / project-c  —  drop-in project files
============================================

WHERE THIS GOES
---------------
Everything in this zip belongs directly inside:

    D:\Godot Games\project-c\

Extract so that CLAUDE.md and project.godot end up in the ROOT of project-c,
NOT inside an extra nested folder.

If Windows creates a nested folder when you extract, just move the contents
up one level — or let Claude Code sort it out (see the prompt below).


WHAT'S INSIDE
-------------
  CLAUDE.md                     project context, loaded by Claude Code each session
  project.godot                 60Hz tick, autoload, all 15 input actions preset
  QUARRY-design-doc.md          the design, v0.8
  QUARRY-combat-tech-spec.md    architecture, frame data, build order

  scripts/combat/               the 5 core combat scripts
  scripts/debug/                the debug overlay
  data/attacks/                 attack .tres resources go here (empty for now)
  scenes/ models/ materials/ audio/ tests/     empty, ready

  docs/                         setup guides, reference only


ORDER OF OPERATIONS
-------------------
1. Open Godot once, create the project at D:\Godot Games\project-c
   (Renderer: Forward+). Let it create its own project.godot.
2. CLOSE Godot completely.
3. Extract this zip into project-c, overwriting project.godot when asked.
4. Reopen the project in Godot. Check Project Settings > Input Map —
   you should see 15 actions.
5. Delete the .gdignore-placeholder files, or leave them; they're harmless.

If Godot refuses to open the project, delete project.godot, let Godot
regenerate a clean one, and set Physics Ticks Per Second to 60 by hand.


THEN, IN CLAUDE CODE
--------------------
Paste the prompt from the chat. It will verify placement, fix the PATH,
build the arena scene, and run a headless test.
