# QUARRY
### Design Document — v0.8

*Working title. "Quarry" carries both meanings the game needs: the animal you hunt, and the place you extract material from. You do both, to the same thing.*

---

## 1. The Pitch

An isometric 3D action game built entirely around hunting a small number of enormous, hand-authored creatures. No trash mobs, no random loot, no procedural runs. Every fight is a fixed, learnable, readable problem. You dismantle a creature piece by piece, craft your equipment from the pieces you took, and each kill permanently removes something from the world.

**Shadow of the Colossus** for structure and weight. **Monster Hunter** for the preparation-and-mastery loop. **Nioh** for the depth of the moment-to-moment combat. Rendered in the isometric perspective of **Hades** and **Divinity: Original Sin 2**.

**Platforms:** Windows, macOS, Linux. PC only.
**Engine:** Godot 4.
**Team:** Solo, AI-assisted implementation.

---

## 2. Why This Game

This design was reverse-engineered from a specific set of preferences, and every major decision traces back to one of them.

| Preference | How the design serves it |
|---|---|
| Deep, deliberate character building (Path of Exile, Pathfinder, Monster Hunter, Nioh) | Deterministic crafting and a passive tree. Builds are chosen, never rolled. |
| Kinetic, execution-driven combat (Max Payne, Titanfall 2, Nioh, Dragon's Dogma) | Stance-switching, stamina commitment, and precise part-targeting. High skill ceiling, low input volume. |
| Emotional and moral weight (Shadow of the Colossus, Nier, Spec Ops, To the Moon) | Delivered structurally through permanent loss rather than through written dialogue. |
| Dislike of RNG-driven power | Zero random drops, zero random stats, zero random modifiers. Stated as a hard rule below. |
| Dislike of high-density "ADHD" combat | One enemy on screen. Low actions-per-minute, high consequence per action. |
| Isometric camera (League, Path of Exile, Pathfinder, Divinity, Hades) | Native perspective, and — as it turns out — the correct one for this design. |

---

## 3. Design Pillars

**1. Every fight is a solvable problem, not a dice roll.**
The creature has a fixed moveset. It does not gain random modifiers. When you die, you know exactly what you misread. When you win, you know exactly why.

**2. The creature is terrain, not a health bar.**
You are not reducing a number. You are physically taking a thing apart, and it changes as you do.

**3. Power is chosen, never granted.**
Every point of strength the player gains is the result of a decision they made and an action they executed.

**4. Killing costs something.**
The player should hesitate before the last few hunts. If they don't, the game has failed at its most important job.

### Anti-Pillars — things this game explicitly will not do

- No random stat rolls on equipment. Ever.
- No random drops. If you broke the horn, you have the horn.
- No procedurally generated encounters or random run modifiers.
- No more than one hostile creature on screen at a time.
- No exposition dump explaining why the story is sad.
- No hidden consequences attached to irreversible choices. The player always sees the full cost before committing.

*(Revised in v0.2: damage numbers were previously listed here as an anti-pillar. That was a misdiagnosis — see §5.7.)*

---

## 4. Core Loop

### Phase 1 — Preparation *(quiet, deliberate, ~5 minutes)*

Choose a weapon, choose a stance discipline, craft and equip gear made from previous kills, allocate passive points. Study the creature you're about to hunt — the game gives you real information about its moveset and its breakable parts, because hiding information is not the kind of difficulty this game is interested in.

### Phase 2 — The Hunt *(tense, 8–20 minutes)*

A single creature in a single arena. Fixed moveset. You read telegraphs, manage stamina, and choose which parts of it to attack. Death is instructive and cheap — you restart the hunt immediately, knowing more than you did.

### Phase 3 — The Cost *(short, unavoidable)*

The creature dies. You take what you broke. Something in the world goes away and does not come back.

Return to Phase 1, now stronger and with less world left.

---

## 5. Combat System

### 5.1 The camera is a design advantage, not a compromise

The angled isometric view means **you can see the entire creature at once**. In a third-person game a large boss fills the frame and you fight whichever limb is in front of you. From above, the creature reads as a whole shape — every limb, every breakable part, and the full arc of every telegraph is legible simultaneously.

For a game about dismantling a large animal deliberately, this is the correct camera. It also eliminates the hardest problem in 3D action games, which is the camera itself.

The camera frames player and creature, pulling back proportionally to the creature's size.

**There is no lock-on.** *(Revised in v0.3 — an earlier draft specified always-on lock-on.)* Lock-on is aim assist, and aiming is the primary skill this game asks the player to develop. The camera frames the fight; it never aims for the player. See §5.8.

### 5.2 Part-breaking — the core mechanic

**This is the mechanic the whole game hangs on.**

Every creature is divided into targetable parts, each with its own durability. Damage to a part is tracked separately from overall health. Breaking a part does three things at once:

1. **Changes the fight.** Break a foreleg and it limps — slower repositioning, new stagger animation, a lunge attack it can no longer perform. Break the jaw and the bite is gone. Break the armour plating and a new soft target is exposed. *The creature's moveset shrinks as you take it apart.*
2. **Determines your reward.** Materials come from the parts you actually broke. Want the tail component? Sever the tail before you kill it. This makes moment-to-moment combat decisions directly serve long-term progression, with no lottery in between.
3. **Carries the emotional weight.** You are visibly, progressively wrecking something alive. The game never comments on this. It doesn't need to.

This mechanic simultaneously satisfies build depth, kinetic skill expression, and emotional weight — which is why it is the correct spine for the project.

### 5.3 Controls

Movement follows the MOBA convention the player is already fluent in. Attacks do not.

| Input | Action |
|---|---|
| **Right-click** | Move to point. Held or repeated for continuous movement. |
| **Left-click** | Attack. **Manual, not automatic** — each press is a node in a combo chain. |
| **A + click** | Attack-move, with range indicator, exactly as in League |
| **Left-click (hold)** | Charged attack — branches out of the combo chain |
| **Q / E / R** | Abilities. Cursor-aimed skillshots, Momentum-gated. |
| **F** | Heal. Costs Momentum (§6.6). Committed animation. |
| **Space** | Parry |
| **Shift** | Dodge |
| **1 / 2** | Tools |
| **Alt (hold)** | Inspect — part durability, wounds, rage and Threshold timers |

There is no dedicated heavy-attack key — **hold left-click** charges instead, which keeps the hand small and makes charging a commitment rather than a separate button.

**Cast options:** quickcast, quickcast with range indicator, and normal cast, configurable per ability, plus self-cast. This is pure UX, cheap to build, and its absence is the first thing a MOBA player notices.

**No lock-on and no auto-targeting on abilities.** *(Revised in v0.3 — an earlier draft specified always-on lock-on.)* Aiming is the primary skill the game asks the player to develop; assisting it removes the thing that makes the combat theirs. The camera frames the fight, it never aims.

**Attacks are manual.** This is the one place the design deliberately departs from League. Auto-attack would create dead time (see §5.4), so left-click drives a real combo chain — closer to Hades than to a MOBA.

### 5.4 Momentum — why there are no cooldowns

**The problem this solves.** League's cooldown economy works because League is not a boss fight. When abilities are down, the player is still last-hitting, warding, rotating and reading the map. That macro layer fills the gap. A single creature in a single arena has no macro layer, so cooldown gaps become literal dead air — right-clicking while waiting for a number to reach zero.

**Therefore: no ability in this game is on a timer.** Abilities are gated by a resource earned through execution.

#### The economy

| Event | Momentum |
|---|---|
| Basic attack lands | Gain — scaling upward through the chain, so completing strings pays |
| Perfect parry | Large gain |
| Combo interrupted by the creature | **Accumulated Momentum lost** |
| Ability used | Spend |

**The consequence is the point: a better player casts more often.** Ability frequency stops being a property of the game and becomes a property of the player's hands. That is a skill expression with no ceiling, and unlike a timing input it does not decay with mastery — there is always a tighter route that generates faster.

#### Abilities as combo routes, not separate buttons

Abilities are not a parallel system sitting outside basic attacks on their own timers. Basic chains contain **branch points**, and spending Momentum at a branch routes the chain somewhere it could not otherwise go — a part-breaking heavy, a repositioning strike, a launcher.

There is consequently no "ability phase" and no "auto-attack phase." There is one continuous activity with decisions inside it. The player is always mid-combo, always at risk of interruption, always able to try again.

This also makes combo *routing* a first-class theorycraft object, in the same way Monster Hunter weapon combo trees are.

#### The rule

> **The player's optimal action must never be "wait."**

Every system added to this game gets tested against that sentence. If waiting is ever correct, the fight has dead air and the system is wrong.

#### What this means for creature design

The creature's job is **not** to reduce the player's health bar. Its job is to **break the player's rhythm and take their Momentum.**

This is a more useful design lens than damage: a good creature attack is not one that hits hard, it is one that punishes greed at precisely the moment the player is tempted to extend the chain one hit further.

### 5.4a Stances — cut

*(Revised in v0.3.)* Nioh's three-stance system assumed the player drives every swing in a commitment-based melee game. Under a Momentum-and-combo-routing model, stances would duplicate what combo branches already do.

**Replaced by:** mode-switching as the *identity of one or two specific weapons* rather than a universal system — the approach Monster Hunter takes with Charge Blade and Switch Axe. Small depth loss, meaningful scope saving.

### 5.5 Feel checklist

Combat feel is not a system, it is a hundred small tuning decisions. This list is the actual work:

- Hit-stop scaled to blow weight (heavier blows freeze longer)
- Directional camera shake on part-breaks only, never on regular hits
- Input buffering window of roughly 150–200ms so combos feel responsive without feeling automatic
- Animation-cancel windows defined explicitly per attack, not globally
- Distinct audio layer per part-break — the sound of something structural failing
- A wind-up frame count long enough to read, short enough to punish hesitation
- Creature telegraphs must be readable from the isometric distance — silhouette change, not a subtle facial cue

### 5.6 Rage

Rage exists to solve a specific flaw: without it, part-breaking has no downside, so players break every part in the same order every time. That is a checklist, not a decision.

**Breaking a part is one of the rage triggers.** Every break therefore becomes a real question — weaken the creature permanently and accept a far more dangerous animal for the next ninety seconds, or leave the part intact and fight it whole a while longer?

**Triggers — all deterministic, all visible:**

| Trigger | Notes |
|---|---|
| Cumulative damage threshold | Fixed percentages of total health |
| Part broken | The primary risk/reward lever |
| Time floor | Guarantees the state appears even in a defensive fight |

No random rolls. An experienced player should be able to predict enrage to within a few seconds.

**Behaviour during rage:**

- **New moves, not bigger numbers.** Rage adds attacks to the moveset. Simply increasing damage and speed is the lazy version and players feel it immediately.
- **Rage is also an opportunity.** The creature over-commits, over-extends, and exposes something it otherwise protects — a soft part, a longer recovery window, higher stagger vulnerability. A skilled player should *want* the enrage window and learn to trigger it on purpose. This converts escalation from a punishment into a resource.
- **Readable state change.** Posture, breathing, colour, audio. Legible instantly at isometric distance.
- **Fixed duration with a visible decay**, then a return to base state with a short vulnerable cooldown.

Rage is the cheapest content in the project: substantially more moveset per creature, with no new model, rig, or arena.

### 5.8 Parry and Interrupt

These two mechanics carry the execution ceiling that the Momentum system alone does not provide.

**Parry** exists on every weapon, but behaves differently on each — a large component of weapon identity:

| Weapon class | Parry behaviour |
|---|---|
| Heavy | Absorbs anything, staggers the creature hard, slow recovery |
| Fast | Narrow window, negates and repositions the player behind the creature |
| Reach | Parries at distance, creates spacing rather than an opening |

**A perfect parry opens a guaranteed part-strike window.** This is the connection that makes defence feed the core loop rather than sitting beside it — the player is not parrying to survive, they are parrying to earn a break.

**Interrupt via part-break.** Striking a limb during the creature's wind-up cancels the attack outright. This makes part-targeting a real-time defensive tool rather than only a progression system, and it gives skilled players a third answer to every telegraph.

**Three answers, never all three.** Each creature attack should be parryable, dodgeable, *or* interruptible — but not all of them, and never obviously. Learning which answer each move wants is the mastery curve, and it costs nothing but design attention.

**Rage-gated parries.** The creature's enraged moveset contains its most parryable attacks, so enrage becomes the window where a confident player *gains* tempo. Escalation rewards mastery rather than punishing it.

### 5.9 Wounds

Damage dealt to a specific part persists and decays slowly rather than resetting. This rewards focused targeting over spreading damage, and makes "which limb am I committing to" a strategic question spanning the whole hunt. Fully deterministic.

### 5.10 Thresholds — conditional escalation

Reference: Alatreon's Escaton Judgment and Fatalis's flame breath in Monster Hunter World.

**A Threshold is a scheduled catastrophic attack whose severity is determined by what the player has broken before it arrives.** The event is not avoidable. Only its magnitude is negotiable.

**Why this is the most valuable encounter mechanic available to this design:** every other system here permits a patient player to turtle and wait for perfect openings. A Threshold does not. Waiting is losing. **It makes greed mandatory**, which is the cleanest possible solution to a single-boss fight going stale.

#### Rules

**1. Gate on parts broken, never on raw damage.**
This is the critical design decision. Alatreon drew significant criticism for functioning as a gear check disguised as a skill check — it soft-required specific elemental builds, collapsing the viable roster. For a game whose central pillar is build diversity, a damage-number Threshold would destroy the build space.

Breaking a part is a **precision and commitment achievement**, available to any build whose player aims well. A damage number is a gear score. One rewards skill; the other rewards farming.

**2. Gradient, not binary.**

| Parts broken | Outcome |
|---|---|
| All required | A scratch. Fight continues cleanly. |
| Partial | Survivable, expensive, changes the rest of the fight |
| None | Death |

**3. Fully visible from the first second of the fight.**
The required parts and the countdown appear in the UI immediately. Never discovered on death. This upholds the no-hidden-consequences anti-pillar and converts every failure into information instead of a feel-bad.

#### The Threshold–Rage–Momentum knot

This is the mastery curve of the entire game, and it costs no additional content:

1. The player **must** break parts to survive the Threshold.
2. Breaking parts **triggers Rage** (§5.6).
3. Rage makes the creature more dangerous **and accelerates the Threshold clock**.

Break too slowly and the check fails. Break too fast and you fight an enraged creature under a compressed timer. There is an optimal line and it is a knife edge.

Momentum sits underneath, pulling in a fourth direction: the burst that breaks a part costs Momentum, Momentum only accrues in melee range, melee range is where interruptions happen, and interruption costs the Momentum the player needed. Every axis fights every other. Nothing is random and every failure is legible.

### 5.10a Enemy Types and Reactivity

**Two enemy categories, both fully reactive.**

| Category | Description |
|---|---|
| **Great creatures** | Large, non-humanoid, closer to terrain than to opponent. Carry the scale and the mournful register. Procedurally animated per §9.3. |
| **Humanoid adversaries** | Bipedal, roughly 1.5–2× human scale. Standard rigs, retargetable animation, dramatically cheaper to produce. |

Humanoid opponents are the single largest cost saving available to this project — bipedal rigs, licensed animation libraries and retargeting are mature, and they substantially reduce the animation risk identified in §13.

**Creature intelligence is a lore problem, not a design problem.** Establishing *why* these things reason is a writing task, and a cheap one.

#### Reactive rules, never adaptive AI

> **The opponent responds to what the player is doing right now. It never adapts to what the player tends to do.**

This distinction is load-bearing. Genuinely adaptive AI is non-deterministic, which would break the pillar that every death is legible and every fight is learnable.

Sekiro's bosses are not intelligent. They feel intelligent because of **conditional rules**:

- Whiff a heavy inside my punish range → I counter
- Back off to heal → I close the distance
- Approach from above → I have an anti-air
- Repeat an option → I have a specific answer to it

Rule-based reactivity is fully deterministic, entirely learnable, and achievable by a solo developer. It produces the sensation of intelligence without any of the problems.

#### Disarming

Available only against humanoid adversaries, and one of the strongest mechanics in the design: **break the opponent's weapon and they switch to an entirely different moveset.**

It functions simultaneously as a part-break, a Threshold gate, and a dramatic mid-fight reversal. It exists purely because the opponent is humanoid.

### 5.11 Knockdown and Wake-up

Creature attacks knock the player down. Rising is a choice:

| Option | Trade |
|---|---|
| **Quick-rise** | Fast recovery, minimal invulnerability |
| **Slow-rise** | Longer on the floor, meaningful i-frames |

The creature carries follow-up attacks that punish the predictable option. Against a fixed moveset this is fully learnable — which is exactly the point. It is a mixup that can be *solved*, and solving it registers as mastery rather than luck.

### 5.12 Phase Gating

Reference: Shara Ishvalda, Safi'jiiva.

**What the player accomplishes in an early phase permanently alters later phases.** Armour left unbroken in phase one becomes a mechanic in phase two. A part severed early removes an entire phase-three attack.

Implementation cost is close to zero — a state flag swapping a moveset — and the knowledge-reward is enormous. A veteran's fight is structurally different from a newcomer's, which is depth that costs no art.

### 5.13 Damage Philosophy

**Three to five hits kill the player. Not twenty.**

Stated explicitly because it must be defended during balancing. High per-hit damage makes every parry consequential, gives the knockdown layer real stakes, sharpens the risk/reward on greed, and is the mechanical opposite of the chip-damage texture this project is defined against.

Few mistakes, each expensive.

### 5.7 Damage Numbers

**Included.** An earlier draft excluded them, which was a misdiagnosis — the objection to bullet-heaven games was about *density*, not *information*. Monster Hunter World has damage numbers and is not a chaotic game, because there is one monster and a handful of numbers on screen rather than four hundred.

More importantly, a game built on theorycraft **requires** damage feedback. A build that cannot be measured cannot be optimised, and cutting numbers would quietly gut the entire build-depth pillar.

**Rules that keep them signal rather than noise:**

- Colour-coded by hit quality — weak point, normal, and bounced-off-armour are visually distinct
- One number per hit, never per damage tick
- Number appearance shifts as a part approaches breaking, so it doubles as durability feedback
- Positioned at the part struck, reinforcing the part-targeting system
- Toggle available in options

---

### 5.8 Input Scheme — mouse and keyboard

**The foundational separation: WASD moves your body, the mouse decides what you are trying to hit, and the two are fully independent.**

This is the thing a controller physically cannot do. A stick offers roughly eight directions of usable precision, which is why Monster Hunter and Nioh ask you to position your whole body and hope the swing lands on the right limb. A cursor offers absolute, analog, pixel-precise targeting — so the player can aim at a **specific part of the creature**.

That converts part-breaking from a positioning approximation into a precision skill, and it is the primary reason this design belongs on PC.

#### Bindings

| Input | Action | Notes |
|---|---|---|
| **WASD** | Movement | Camera-relative. Not click-to-move. |
| **Mouse position** | Aim / facing | Independent of movement at all times |
| **RMB** | Primary attack | Seeks the part under the cursor, steps into range if needed. The League right-click. |
| **LMB** | Heavy attack | Pure aim, no target snapping, full commitment. The skillshot. |
| **A + click** | Attack-move | Displays weapon reach ring, snaps to nearest part in that direction |
| **Q / E / F** | Stance — high / mid / low | Instant, usable mid-combo |
| **1–4** | Weapon arts | Stamina cost, aimed with the cursor |
| **Shift** | Dodge | Directional, stamina cost |
| **Space** | **Recovery pulse / Parry** | Context-dependent — see §5.9 |
| **Scroll** | Alternate stance switch | Bind alongside Q/E/F and let playtesting decide |

*Ergonomics note: Q/E/F versus scroll for stances is a hands question, not a reasoning question. Bind both in the prototype and choose after fifty hunts.*

#### Attack-move, adapted

League's attack-move exists to prevent misclicks while managing many units, and "nearest target" means nearest champion or minion. With one creature on screen that would be meaningless — **unless the targets are parts.** Press A, see your weapon's reach ring, click near the foreleg, and the character closes and strikes that part.

The same muscle memory, repurposed into the part-targeting system. The reach ring is real information rather than clutter, because weapon reach varies enormously and every attack commits.

RMB and attack-move are the comfortable, readable inputs. **LMB deliberately offers no assistance**, so players who aim manually are rewarded with better part damage. These are different tools for different moments, not a better and worse option.

#### Aim-commitment — the skillshot translation

**The cursor position at the frame of input locks the strike vector.** A heavy has roughly a 400ms wind-up, during which the creature moves. The player has to lead it.

| Outcome | Result |
|---|---|
| Lands on exposed part | Heavy part damage, the break you were aiming for |
| Lands on armour | Weapon bounces, self-stagger, stamina lost |
| Misses entirely | Full recovery animation with a large animal on top of you |

Identical tension to a MOBA skillshot, except the target is a body with internal structure rather than a point. League gives the player *hit or miss*; this gives them *which part did I hit*. A strictly higher-dimensional aiming problem.

#### The six axes of the skill ceiling

All execution, none random:

1. **Reading the telegraph** — what is it about to do
2. **Leading the aim** — where will that limb be in 400ms
3. **Stance selection** — which of three movesets fits this exact opening
4. **Recovery-pulse timing** — the Space input that refunds stamina
5. **Rage management** — break this part now and accept escalation, or wait
6. **Spacing** — positioning against the creature's turn rate

A new player runs two of these. A great player runs all six at once. Very deep ceiling, very little content.

#### Stance-cancelling — the mastery layer

Switching stance during an attack's recovery frames cancels into the new stance's opener, allowing chains the game never teaches. High-stance heavy cancelled into low-stance flurry at the right frame is the sort of thing players discover, record, and post.

Implementation cost is near zero — it is animation-cancel windows defined per attack. Payoff is the entire high-level metagame.

---

### 5.9 Parry — and the Timing Key

**Parry exists on every weapon.** It is bound to **Space**, the same key as the recovery pulse, resolved by context:

- Pressed after your own attack → **recovery pulse**, refunding stamina
- Pressed as an incoming blow lands within its window → **parry**

One button, one underlying skill — *perfect timing* — with two applications. This keeps the keybind load low and makes Space **the Timing Key**: the single input that separates competent players from great ones.

*Resolution rule: if an incoming attack is inside its parry window, Space parries; otherwise it pulses. Overlapping-window behaviour must be verified in the prototype.*

#### Rules that stop parry becoming press-to-win

1. **Success exposes a part.** Parrying feeds the part-breaking system rather than sitting beside it as pure defence.
2. **Failure costs real stamina** and leaves the player in recovery. Parry is a bet, like everything else in this game.
3. **Some attacks are unparryable**, flagged with a distinct colour and audio cue — Sekiro's perilous-attack visual language. This forces a live parry-or-dodge read instead of one dominant answer.
4. **Parry character varies by weapon, not power level.** Heavy weapons get a forgiving window and a slow, enormous counter. Fast weapons get a tight window, a modest payoff, and the ability to chain directly into pressure.

---

### 5.10 Additional Mechanics — evaluated

Every mechanic multiplies the tuning surface. These are ranked by value against cost, and **no more than two should enter the prototype.**

| Mechanic | Verdict | Rationale |
|---|---|---|
| **Stagger meter** | **Take** | A visible second bar filled by heavy hits and successful parries, decaying if the player backs off. Fill it and the creature topples for a free window. Sekiro's posture system. The best adrenaline engine in the genre — it rewards pressing forward when instinct says retreat — and it costs one number and one animation. |
| **Damage types (cut / blunt)** | **Take** | Cutting severs tails and thin parts; blunt breaks heads and builds stagger. Pure Monster Hunter. Near-zero cost, and it instantly makes weapon choice a genuine build decision rather than a preference. |
| **Arena hazards** | **Defer** | Two or three lure-able features per arena. Gives arenas a purpose beyond backdrop and adds a spatial layer. Moderate cost — wait until the core fight is proven fun. |
| **Charged precision strike** | **Defer** | Hold heavy to tighten a precision reticle, trading time for accuracy. Fits the skillshot theme well, but overlaps with existing systems. |
| **Mounting / climbing the creature** | **Cut** | Shadow of the Colossus's signature, and it requires an entire traversal system plus animation set. Also poor readability at isometric distance. |
| **Adaptive AI that learns player habits** | **Cut** | Directly violates Pillar 1 — the fight stops being a fixed, learnable problem. Also a balancing nightmare and non-deterministic by nature. Refuse this one even though it sounds impressive. |

**Recommended for prototype: stagger meter and damage types.**

---

## 6. Build System

### 6.1 Hard rule: nothing is random

Materials are awarded for parts broken. Crafting outcomes are fixed and known in advance. Equipment has no rolled affixes. The passive tree is fully visible from hour one.

The variance that keeps the game fresh comes from **the player making different decisions**, not from the game rolling different numbers. This is the central design correction against the bullet-heaven genre.

### 6.2 Three layers of build depth

**Layer 1 — Weapon identity.** Four to five weapons, each with a genuinely different moveset and a different relationship to part-breaking. A heavy weapon breaks armoured parts efficiently but struggles to sever thin ones; a fast weapon is the reverse. Weapon choice is the largest single build decision.

**Layer 2 — Crafted equipment.** Gear built from specific creature parts. Each piece grants a defined, non-random property, usually thematically tied to the creature it came from. Building a set requires targeting specific parts across multiple hunts — this is what makes you fight the same creature again with a different plan.

**Layer 3 — The Atlas.** The passive tree, the world map, and the hunt-selection screen are the same object. See §6.4 — this is the structural spine of the game's progression.

### 6.3 Why you fight the same creature more than once

Monster Hunter's answer, adopted directly. The creature does not change. **You** change. A hunt you first survived in eighteen desperate minutes becomes a six-minute clinic once your build and your hands have caught up. Higher difficulty tiers add moveset extensions rather than stat inflation.

This is how a game with ten enemies supports sixty hours.

### 6.4 The Atlas — map, skill tree and hunt selection as one object

**The single most important structural decision in the project.**

There is no separate skill tree screen, no separate world map, and no separate mission select. There is one screen: a map of the world, where each creature is a node, and the routes between nodes are the progression paths. Choosing what to hunt *is* choosing your build.

**Why this is the right structure:**

- It collapses three systems and three interfaces into one. For a solo developer that is months of saved work, and it removes an entire category of UI design.
- It makes the game's theme *mechanical* rather than decorative. Loss stops being atmosphere and becomes the progression system itself.
- It produces enormous build variety from very little content, entirely through player decision rather than randomness.
- It eliminates the class-selection screen (see §6.5).

#### The Hunt and the Claim are separate acts

This separation is load-bearing. Without it, permanent creature removal would destroy the repeat-hunting loop that gives the game its length.

| | **The Hunt** | **The Claim** |
|---|---|---|
| What it gives | Materials, mastery, crafting components | The creature's power; a permanent Atlas node |
| Repeatable? | **Yes, forever** | **No. Irreversible.** |
| Cost | None | Closes adjacent Atlas routes. The region dies. |

You may hunt a creature a dozen times and never claim it. Claiming is a deliberate, separate decision made at the Atlas, not something that happens automatically when the creature dies.

This preserves the Monster Hunter farming loop in full, while converting the game's central tragedy from a consequence into a **choice** — which is dramatically stronger. The player is not mourning something that happened to them. They are choosing what to destroy in exchange for what they want to become.

#### Rules

1. **Full disclosure before commitment.** The Atlas shows exactly which routes and powers will close before the player confirms a Claim. Hidden consequences on irreversible decisions read as a gotcha, not as tragedy. Show the cost, let them pay it anyway — that is what makes it land.
2. **Claims are permanent within a playthrough.** No respec. The weight depends on it. *(Minor path nodes respec freely — see §6.4a.)*
3. **Not every creature can be claimed in one run.** Target roughly 6 claims available out of 10 creatures. Some routes are mutually exclusive by design.
4. **The first hunt is fixed.** The opening choice carries the most weight at the moment the player understands least. Make hunt one a fixed tutorial and begin real branching at the second or third node.
5. **The Atlas is the save-file summary.** At a glance it shows what you became and what you unmade.

### 6.4a How the Tree Scales in a Combo-Driven Loop

**A Path of Exile-style percentage tree would break this game.** The reasoning matters, because it determines what every node in the Atlas is allowed to do.

PoE scales numbers because it is a stat-check game against thousands of enemies. QUARRY has ten creatures, and its central encounter mechanic is a Threshold gated on **parts broken**. A tree handing out large damage multipliers silently converts Thresholds into gear checks — reintroducing precisely the failure identified in §5.10. There is also not enough content here to absorb that much power inflation.

> **Nodes change what the player can do. They do not change how big the numbers are.**

#### The power fantasy is Momentum throughput

In a combo-driven game, "stronger" means *doing the interesting thing more often*. A late-game build does not hit harder — it generates Momentum faster, bleeds less on interruption, and routes into Rend twice as often as a starting build can.

That is the same sensation the player gets from genuinely improving at the game. The tree therefore **amplifies mastery rather than substituting for it**, which is the correct relationship for this project.

#### The three axes

Every node moves one of these, and nothing else:

| Axis | Examples |
|---|---|
| **Momentum throughput** | Gain rates, interrupt loss reduction, decay, conditional refunds |
| **Break efficiency** | Wound application, armour penetration, interrupt strength |
| **Recovery** | I-frame duration, parry window width, heal cost |

#### Two tiers, falling naturally out of the Atlas

**Claims — major, ~10 exist, ~6 taken per run.** Each is a **verb, not a number**, and each meaningfully defines a build:

- *Deflect also interrupts wind-ups*
- *Breaking a part refunds 25 Momentum*
- *Charged attacks apply Wound to adjacent parts*
- *Rend may fire at 30 Momentum, but leaves the player at zero*
- *Light attacks pierce armour thresholds; Momentum gain halved*

**Path nodes — minor, ~50.** The connective tissue between Claims. Modest economy tuning, small conditional triggers, narrow numeric bumps.

**Total: roughly 60 nodes.** Path of Exile has over thirteen hundred. Sixty is sufficient here because the *combinations* carry the weight, and sixty is a scope a solo developer can actually design, balance and test.

#### Technical constraint — windows, never timings

**Nodes may modify windows. Nodes may never modify attack timings.**

Widening a parry window or extending a cancel window is a single value, easy to reason about and easy to test. Reducing an attack's startup frames ripples through every feel-tuning decision in the combat tech spec, forcing combat to be balanced at many different frame values simultaneously. That is a testing burden a solo developer cannot carry.

#### Nodes must grant toys, not only modifiers

*(Revised in v0.7 — the previous draft was almost entirely modifiers, and read as dry.)*

Players feel power from **things they can newly do**, not from invisible percentage adjustments. "+8% Momentum gain" is not felt. "Your Glaive L2 now links directly into your off-hand finisher" is felt immediately.

Target roughly **half of all Claims and a third of path nodes granting new combo branches, new abilities, or new routes** rather than adjusting existing ones.

Support this with **visual escalation** — attacks visibly gaining weight, trails and impact effects as investment increases. This is inexpensive VFX layering and does disproportionate work for the sensation of growth.

#### Numeric budget

*(Revised upward in v0.7. The earlier figure of +40–60% was too flat to perceive.)*

**Target: 3–4× effective throughput across a fully allocated tree**, built from compounding components rather than one multiplier:

| Component | Growth |
|---|---|
| Raw damage | +60–80% |
| Momentum generation rate | +50–70% |
| Break efficiency | +40–60% |
| New routes and abilities | Unquantified — the largest felt component |

#### Why this does not break Thresholds

**Each creature's Threshold is tuned individually, against the build the player is expected to hold when they first meet it.** It is not a global constraint and it never rescales.

Consequently, returning to creature one at endgame with three times the throughput means obliterating a check that was calibrated for a starting build. **This produces the "old content is easy now" fantasy automatically — with no enemy debuff, no level scaling, and no additional system.** The player simply walks in genuinely stronger against a bar that stayed where it was.

Current-tier creatures remain tense because their Thresholds assume the corresponding investment.

### 6.4b Two Weapons and the Swap

**The player carries two weapons and swaps freely between them.**

**This costs zero additional art.** The project still builds four or five weapons total; players merely access more of them per hunt. Depth with no content cost is the rarest trade available in game development, and it should be taken.

Build diversity multiplies accordingly: five weapons choosing two yields ten loadouts, each with two combo trees, two parry behaviours, and a reason to carry both precision and reach into the same fight.

#### Swap is a combo branch, not a cooldown

Per §5.4, no system in this game uses a timer. Swap is therefore integrated into the combo system rather than gated beside it:

| Rule | Detail |
|---|---|
| **When** | Only at cancel windows — swap is a branch input, not a panic button |
| **Continuity** | Swapping mid-chain **continues** the combo into the other weapon's tree; it does not reset it |
| **Cost** | Small Momentum cost |
| **Swap-cancel** | A precisely timed swap inside a tight window **refunds the cost** and carries the chain through |

This is the weapon-weaving of Devil May Cry, Bayonetta and Nier Automata. It converts two separate movesets into a single much larger shared tree, using animations already authored — **the interesting content is the transitions, which cost nothing to make.**

It also introduces a genuine execution-skill window in swap-cancel timing, which is the category of depth that does not decay with mastery.

#### The tree nodes this unlocks

These are the antidote to a dry tree — visible, playable, immediately felt:

- *The swap-cancel window is widened*
- *The first attack after a swap deals bonus part damage*
- *Swapping mid-combo refunds Momentum rather than costing it*
- *New route: Glaive L2 links directly into the off-hand weapon's finisher*

A node that adds a **new route between the player's two weapons** changes how a fight is played the moment it is taken. That is what the tree should mostly be made of.

#### Respec

*(Refines §6.4 rule 2.)* **Claims are permanent. Path nodes respec freely.**

The weight belongs on the Claims, where it is dramatic and meaningful. Making a 4% Momentum node irreversible punishes experimentation without adding anything.

### 6.5 Classes — there are none

Deliberately. The reference games make the case: Path of Exile's classes are only starting positions on a shared tree, Monster Hunter has no classes at all because the weapon *is* the class, and Nioh and Divinity both let you build in any direction.

Identity here comes from two independent axes:

- **Weapon = your verbs.** How you move, what your combos are, which parts you can break efficiently. Four to five genuinely distinct options.
- **Atlas path = your nouns.** What you are capable of, which powers you took, and which you closed off forever.

Four weapons crossed with a branching Atlas produces far more genuine build identity than a class list would, at a fraction of the content cost.

**Your first hunt is your class selection** — chosen by fighting something rather than by reading a menu at hour zero, when you know least about the game.

### 6.6 Consumables and Tools

**There are no healing items. There is no consumable grind.**

#### Healing costs Momentum

Healing is a Momentum spend, not an inventory slot. This uses the existing economy rather than adding a parallel one, and it produces the game's sharpest decision:

At low health under a running Threshold clock, healing costs the Momentum needed for the burst that breaks the part that stops the catastrophe from killing you. Heal too much and you survive the next thirty seconds, then die to the clock.

A separate healing resource would give healing no opportunity cost — which is precisely what the three-to-five-hits damage philosophy exists to prevent. Potions would flatten the entire risk structure.

#### No gathering, no crafting of consumables

The pre-hunt preparation ritual common to the genre — gathering herbs, crafting potions, buffing up — is a time tax that generates no decisions. Nobody has ever agonised over whether to bring healing items. It is familiar rather than good, and it will not be imported.

#### Tools — the exception that earns its place

**Two tool slots. Fixed charges per hunt. Refilled free between hunts.** No gathering, no crafting, no inventory screen.

Tools exist for one reason: they let the player **manufacture a window** rather than wait for one. That is directly aligned with the rule that waiting must never be optimal. Which two tools are brought is a loadout decision sitting alongside weapon and Atlas path — closer to Path of Exile flask setup than to an item pouch. Build depth, not bookkeeping.

**Hard rule: no tool may reduce, delay, or bypass a Threshold.** The moment a consumable solves conditional escalation, the entire encounter design collapses into "bring the correct item."

**Scope note:** tools are a v1 system, not a prototype system. The prototype needs Momentum-healing, because it changes how the fight feels. Tools can be designed on paper and built in month eight.

---

## 6.7 Reference Weapon — The Glaive

A complete specification for one weapon, so the shape of the commitment is concrete. The other three or four weapons follow this template.

### Identity

Mid-weight polearm. **Reach is its defining property.** Its central decision axis is **thrust versus sweep** — precision on a single part, or width across several at reduced damage each. It parries at distance, creating spacing rather than an opening.

### Bindings

| Input | Action | Momentum |
|---|---|---|
| **Right-click** | Move to point | — |
| **A + Left-click** | Attack-move, with range indicator | — |
| **Left-click (tap)** | Light attack — advances the combo chain | Gain |
| **Left-click (hold)** | Charged attack — branches out of the chain | Gain |
| **Shift** | Dodge — i-frames, direction of travel | — |
| **Space** | **Deflect** (parry) | Gain on success |
| **Q** | **Pin** — aimed thrust, applies heavy Wound, **interrupts a wind-up** | −20 |
| **E** | **Vault** — pole-vault reposition with i-frames | −15 |
| **R** | **Rend** — multi-hit burst into one part. The mega-combo. | −40 |
| **F** | **Mend** — heal. Committed animation, fully vulnerable. | −25 |
| **Tab** | **Weapon swap** — only at cancel windows, continues the chain | Small cost; refunded on a perfect swap-cancel |
| **1 / 2** | Tools | — |
| **Alt (hold)** | Inspect — part durability, wounds, rage and Threshold timers | — |

**Aiming:** the character faces the cursor. The part beneath the cursor is the focus target and is highlighted. All abilities aim at the cursor. No auto-targeting, no lock-on.

### Combo Tree

```
                    ┌─ hold LMB ─> CHARGED THRUST
                    │              single part, heavy part damage
   L1 THRUST ── LMB ─> L2 SWEEP ── LMB ─> L3 RISING CUT
   fast, narrow        wide arc,          finisher, staggers
   single part         adjacent parts     large Momentum payout
                            │
                            └─ hold LMB (−20) ─> IMPALE
                                                  part-break route
```

### Frame and Economy Values

| Attack | Startup | Active | Recovery | Cancel→atk | Momentum |
|---|---|---|---|---|---|
| L1 Thrust | 6 | 3 | 12 | 4 | **+4** |
| L2 Sweep | 7 | 4 | 13 | 4 | **+6** |
| L3 Rising Cut | 10 | 4 | 20 | 8 | **+10** |
| Charged Thrust | 18 | 4 | 24 | 8 | **+12** |
| Impale | 14 | 5 | 26 | — | **−20** |
| Deflect (parry) | 3 | 6 | 19 | — | **+25** on perfect |
| Interrupted mid-combo | — | — | — | — | **−50% of current** |

**Economy check:** a full L1→L2→L3 chain yields 20 Momentum — exactly one Pin. Rend at 40 requires two clean chains, or one chain plus a perfect Deflect. The mega-combo is *earned*, and a player who keeps getting interrupted never reaches it.

### Deflect — weapon identity

Per §5.8, parry behaviour is weapon-specific. The Glaive's parries **at reach**: it does not stagger the creature, it pushes it back and creates spacing.

**A perfect Deflect grants a guaranteed free Charged Thrust window** — the part-strike opportunity that makes defence feed the core loop.

### The intended fantasy

Chain thrusts and sweeps to build. Read the wind-up. Either **Pin** it to interrupt outright, or **Deflect** for +25 and a free Charged Thrust. Bank toward 40. Wait for a stagger or a broken-limb stumble, then dump **Rend** into the head to break it before the Threshold clock expires.

Every one of those is a decision. None of them is random. All of them are the player's fault.

---

## 7. The Cost — narrative through subtraction

The narrative budget for this project is close to zero, and that is a feature. Shadow of the Colossus carries enormous emotional weight on a few hundred lines of dialogue, because its weight is structural.

**Each creature *claimed* — not merely killed — permanently removes something.** Rotate across these categories so the player cannot predict which lever gets pulled:

- **World.** A region falls silent. An ambient track loses an instrument layer. Weather in an area stops changing.
- **Mechanical.** A convenience the player had come to rely on stops working. Something that made the world feel alive stops.
- **Personal.** An NPC who spoke to you at the hub stops speaking, or leaves. No explanation given.
- **Self.** Gear crafted from a creature grants real power at a real cost — the game states this plainly and lets the player choose.

**Design target:** by the seventh hunt, the player should pause on the selection screen. Nothing in the game should ever tell them to feel bad. The music going quiet is the whole argument.

**Ending:** the player must be able to stop hunting. A player who walks away from the last two creatures should get an ending that acknowledges it. This single feature converts the game's theme from decoration into a real choice, and it costs almost nothing to build.

---

## 8. Content Scope

| Element | Target | Notes |
|---|---|---|
| Creatures | 8–10 | The single largest cost. Each is a full boss with parts, states, and unique animation. |
| Weapons | 4–5 | Each needs 3 stances × full moveset. |
| Arenas | 8–10 | One per creature. Small, hand-built, no streaming, no open world. |
| Hub | 1 | Crafting, tree, creature selection, NPCs. |
| First playthrough | 15–20 hours | |
| Full mastery | 50–70 hours | Via build variety and difficulty tiers |
| Spoken/written dialogue | Minimal | Under 5,000 words total is a reasonable ceiling |

**What is explicitly out of scope:** open world, trash enemies, multiplayer, procedural generation, crafting trees beyond the creature-part system, romance/companion systems, voice acting, and any form of live service.

---

## 9. Technical Plan

### 9.1 Engine — Godot 4

Given PC-only across Windows, macOS and Linux, with no console ambitions, Godot 4 is straightforwardly correct:

- MIT licensed. No royalty at any revenue level, ever.
- Roughly 100 MB editor plus ~1.2 GB export templates. Fits comfortably alongside everything else.
- Exports to all three target operating systems from a single Windows machine, from one project, without a build farm.
- Vulkan renderer with PBR and modern lighting — far more than a stylized isometric game requires.
- Editor launches in seconds and iteration is near-instant, which matters enormously on a 4-core CPU.

Godot's known weaknesses — large-world streaming, occlusion culling at scale, console export — are all things this design does not use.

### 9.2 Art direction — stylized low-poly

Not a budget compromise, a proven commercial style. PEAK and R.E.P.O. were both stylized low-poly from tiny teams and both were enormous in 2025. Players read it as intent.

Practical rules:
- Baked lighting for arenas. Real-time lighting only where it must react.
- Strong silhouette-first creature design — readability at isometric distance beats detail.
- Limited palette per arena, so that a region "going quiet" can be expressed visually.
- Environments can be built from asset packs. Creatures cannot — they are the product.

### 9.3 Procedural animation — the key technical decision

**Hand-animating ten enormous non-humanoid creatures is the thing most likely to kill this project.** The mitigation is to drive creature limbs with inverse kinematics and physics rather than authored clips.

- Legs plant procedurally against terrain via IK, so movement adapts to arena geometry for free
- Body mass follows limbs with spring dynamics, producing weight without keyframes
- Broken limbs are handled by disabling an IK chain — *the damage state is nearly free*, which is what makes part-breaking affordable at all
- Attacks remain hand-authored, since telegraph readability is the product; locomotion and reaction are procedural

This trades animator-months for mathematics. Mathematics is precisely the category of code that AI assistance handles reliably and that can be verified by playing. It also produces a distinctive, weighty look that hand-keyframed animation on a solo budget will not match.

For the humanoid player character, licensed animation sets (Mixamo and similar) are entirely appropriate and standard practice.

### 9.4 Working on the target hardware

Machine: ASUS TUF FX505DD — Ryzen 5 3550H (4C/8T), 16 GB RAM, GTX 1050, C: 237 GB with ~40 GB free, D: 931 GB with ~320 GB free.

- **Install Godot and all project files on D:.** The C: drive is too close to full for Windows to stay healthy.
- Free RAM was measured at 4.58 GB with background applications running. Close browsers and chat clients during development sessions — this is the real bottleneck, not the CPU.
- Target 60fps at 1080p on this exact machine. If it runs well here, it runs on nearly every machine a customer owns. **Developing on modest hardware is a scope-discipline mechanism — treat it as an asset.**
- Git with Git LFS for 3D assets, from day one, with an off-machine backup.

---

## 10. The Prototype — and the test that decides everything

### Build exactly this, and nothing else

**One creature. One weapon. Three stances. Two breakable parts. Grey-box arena. Programmer art. No hub, no tree, no crafting, no story.**

Required in the slice:
- Right-click movement and attack-move
- **One basic combo chain** with at least one Momentum branch point
- **The Momentum economy** — gain on chain, loss on interruption, spend on ability
- **Two cursor-aimed abilities**, no auto-targeting
- **Parry**, with the perfect-parry part-strike window
- Two independently breakable parts, each visibly altering the creature's moveset
- **One rage state**, triggered by a part-break, adding at least two new attacks and one exploitable opening
- Damage numbers with weak-point colour coding
- One complete, readable, learnable creature moveset with clean telegraphs
- Hit-stop, screen shake, and part-break audio

*Not in the slice: the Atlas, crafting, the Claim system, wounds, interrupts, weapon modes, or any second creature or weapon.* Those are systems, and systems can be designed on paper. Combat feel cannot.

**Watch for feature creep specifically.** This design gained rage, damage numbers, the Atlas, the Claim system, parry, an ability suite, quickcast, attack-move, inspection, Momentum, wounds and interrupts across four conversations. Every one is a good idea. That is exactly the problem — good ideas are what kill solo projects, because none of them ever feel like the one to cut.

### The kill test

**Fight your own grey-box creature twenty times. If hunts fifteen through twenty are still enjoyable with no art, no story, no progression and no reward — the project is real. If they are not, stop.**

This test is honest, it is cheap, and it arrives early. A game whose combat is not fun with programmer art will not be rescued by art, story, or systems. Spending three months to find this out is a good trade against spending two years.

---

## 11. Timeline

Ranges assume solo development with AI-assisted implementation. The spread is mostly a function of hours per week.

| Phase | Duration | Output |
|---|---|---|
| Learning Godot + grey-box prototype | 2–3 months | The kill test above |
| Vertical slice | 4–6 months | One creature, finished art, real feel, trailer-ready |
| **Decision point** | — | Announce, open the Steam page, start accumulating wishlists |
| Full production | 12–18 months | Remaining creatures, hub, tree, crafting, Cost system |
| Polish, balance, ports, launch | 3–4 months | macOS and Linux builds, difficulty tiers, release |
| **Total** | **21–31 months** | |

Two things worth internalising: the first creature will take three to four times longer than the fourth, and the last 10% of the project will take about 30% of the time. Both are normal.

---

## 12. Commercial Plan

### Positioning

Deterministic skill-based action is a smaller market than roguelites, but far less crowded and with dramatically better word-of-mouth persistence. Publishers reviewed roughly 250 roguelike deckbuilders in a single year and are now actively avoiding the genre. Meanwhile Nine Sols — hand-drawn, deterministic, parry-based, no RNG — sold over 800,000 copies in its first year, and Another Crab's Treasure passed 250,000 in under a month with a small team.

These games get streamed as challenge content, discussed for years, and sold repeatedly on discount. That is a much better long-tail profile than a bullet-heaven title with a six-week spike.

### Price

**$19.99–24.99.** Do not go below this. It signals seriousness in the action genre, and a low price on a skill-based game attracts exactly the audience most likely to refund it.

### Wishlist targets

Current benchmarks: roughly 7,000 wishlists is the threshold for Steam's Popular Upcoming visibility. Common tiers cited for 2026 are 5,000 (minimum viable), 8,000 (solid), 50,000 (strong), 90,000+ (major). Wishlist-to-sale conversion has compressed to roughly 10–25% in launch week, and 20–40% lifetime.

**Target: 15,000 wishlists before launch, minimum 8,000.**

### How wishlists actually get earned

Open the Steam page the moment the vertical slice looks good — roughly month six, not month twenty. Wishlists compound, and a page that exists for eighteen months massively outperforms one that exists for three.

The most valuable marketing asset this game has is **the part-break moment**. A ten-second clip of a creature's leg failing and its movement visibly changing is a self-explaining hook that needs no voiceover. Build the game so that clip exists early, then use it everywhere.

Capsule art matters more than almost anything else on this list. Budget real money for it.

---

## 13. Risks and Kill Criteria

| Risk | Severity | Mitigation |
|---|---|---|
| **Boss fights are the hardest thing in games to make feel good** | Critical | The month-3 kill test exists specifically to surface this before real money is spent |
| **Threshold tuning** | High | The hardest balancing problem in the design. Too tight and the game feels unfair and build-hostile; too loose and the mechanic is decorative. Gate on parts rather than damage, keep the gradient wide, and display the requirement from second one |
| Creature animation cost overruns | High | Procedural IK-driven locomotion; hand-author only attacks |
| Finite content, short playtime | High | Build variety and difficulty tiers designed in from day one, not bolted on |
| Solo developer burnout over 2+ years | High | Ship the vertical slice publicly at month 6. External response is the fuel that gets you to month 24 |
| AI-generated code becoming unmaintainable | Medium | Deterministic systems are testable and specifiable. Keep systems small and separable. Do not accept code you cannot describe in one sentence |
| Combat feel cannot be delegated | Certain | This is your job, not the AI's. Budget months for it and expect to enjoy it |

### Explicit stop conditions

Decide these now, while it is cheap to be honest:

1. **Month 3** — if the grey-box hunt is not fun on the twentieth attempt, stop.
2. **Month 6** — if the vertical slice trailer does not earn 1,000 wishlists in its first month, the hook is not legible. Fix the hook before building more content.
3. **Month 12** — if creature four is still taking as long as creature one, the pipeline has failed. Cut the creature count from ten to six rather than extending the schedule.

---

## Appendix — Immediate Next Steps

1. Install Godot 4 on the **D: drive**.
2. Complete one full Godot 3D tutorial end to end. Do not skip this; you need to know what the engine feels like before directing anyone, human or otherwise, to build in it.
3. Grey-box a flat arena with a capsule player and a static cube creature.
4. Build stance-switching and committed attacks against the cube.
5. Give the cube two breakable faces and one telegraphed attack.
6. Play it twenty times.

Step 6 is the entire decision.

---

*Prepared August 2026. Everything above is a starting position, not a commitment — expect the design to change once the prototype tells you what it actually wants to be.*
