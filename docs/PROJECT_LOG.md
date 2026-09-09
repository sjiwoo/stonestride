# Stonestride project log

> **MANDATORY FOR ALL AGENTS (Claude sessions and any other AI/automation):**
> This document is the single source of truth for the owner's design directions
> and the history of work done. Every session that changes code, assets, data,
> or the deployed web build MUST update this document in the same push:
> append a changelog entry, and record any new owner ask or design direction
> in the sections below. If a direction supersedes an older one, mark the old
> one as superseded rather than deleting it. Do not let this file go stale.

Owner: Gandalf (repo: sjiwoo/stonestride). Multiple agent sessions work on
this repo in parallel — pull/rebase before pushing, and keep entries factual.

## Workflow directions (standing)

- **Fully hands-free development.** The owner does not touch the Godot editor.
  Agents deliver everything as complete files (code, scenes, data, tests) and
  never give instructions to perform in the editor. Validate without the
  editor: headless parse checks, script-driven smoke tests, and offscreen
  renders (xvfb + `--rendering-driver opengl3`) for visual work.
- **Keep the web preview current.** The repo was made public to enable GitHub
  Pages. `gh-pages` holds a manually exported web build (no CI). After visual
  or gameplay changes, export the Web preset headless and push the build to
  `gh-pages` so the owner can see the latest state in the browser.
- **Maintain this document** (see banner above).
- **Licensing care.** Adapting open-source implementations found online is
  fine when the license permits (e.g. MIT, with attribution in the file
  header). Never ship non-commercial-licensed assets (e.g. CC-BY-NC) in the
  game; generate textures/assets procedurally instead.

## Game design directions (owner asks)

- iOS wave-defense roguelike built in Godot 4.4, separate from the owner's
  other game (Hatchline).
- Original concept: waves of enemies attack; the player upgrades a base to
  defend. **Pivoted:** the base is a large walking stone golem. Upgrades
  (size, econ structures, shooting towers) mount onto the golem while tiny
  monsters swarm it.
- Golem look: humanlike, small torso, long thick arms, articulating elbows
  and knees, hunched over, walks like a neanderthal.
- Waves are passed by the golem walking a set distance.
- Upgrades are roguelike drafts via a popup card selection, with a chance of
  econ, speed, or attack upgrades. Owner wants multiple upgrade trees with
  different focuses (wave AoE, single target, pierce, etc.), placement of
  multiple towers including an econ building, and an additional in-game
  skill element (e.g. a wave clear).
- After each draft, a themed path choice biases the next draft's category
  odds; routes converge on a boss.
- Enemy interaction redesign: enemies must NOT jump onto or latch the golem.
  They collide with its front, stay there, and apply a slow that stacks per
  enemy; they can't pass through, get behind, or go under it. The golem
  shoots the closest enemy.
- Weapon tree system (asked 2026-09-07): multiple weapon types the player
  selects between, each with levels/upgrades that bring new visual effects.
  Prototyped as three lines — cannon (single target), mortar (wave AoE),
  javelin (pierce) — two levels each plus a pick-one exclusive branch at the
  top; forging costs gold. Mockups reviewed in chat; owner approved ("Go"),
  including the between-waves armory screen (opens after the path choice).
- Card/path VFX (asked 2026-09-07): a subtle fiery effect around the upgrade
  cards and the map path choices, plus a better card design. Process: draft
  the design visually first, then implement in code. Upgraded the same day:
  replace the 2D effect with **high-quality 3D flames**; adapting online
  implementations is explicitly allowed.
- Visual path map (asked 2026-09-07): a beautiful map for the designed paths,
  drafted visually first, still procedurally generated. Choosing the next
  path must be **purely visual selection on the map with no text**, with good
  visual effects and animation.

- Graphics revamp with Nano Banana (asked 2026-09-09): revamp the graphics
  toward a consistent, modern, artsy, beautiful theme using AI-generated
  raster art. Art direction ("Moonlit Megalith") + prompts: `docs/ART_PROMPTS.md`.
- **Superseded** (same day): the browser-only generation workflow. New
  standing rule: agents MAY call the Gemini API (owner's key) but must be
  cost-efficient — combine assets into one sprite-sheet generation where
  slicing is safe, default to 1K resolution, use the cheapest model that
  meets quality (`gemini-3.1-flash-lite-image` for emblems/icons,
  `gemini-3.1-flash-image` for hero scenery), and state the estimated cost
  before running a batch.

- Big update (asked 2026-09-09): THREE selectable characters — the golem
  (now sprites, not vectors), a cartoony viking ship, and a tank — with
  Battle-Cats-style animations. All towers become cat-themed sprites in the
  Battle Cats look, line thickness matching the art (reasonably thick).
  Architecture: levels are ENDLESS and procedurally generated; reaching a
  waystone is a checkpoint (draft + path + armory as before) but enemies
  are NOT deleted and nothing resets — the march continues to the next
  checkpoint, and pace speeds up for clear progression.

- Visual refresh via ComfyUI (asked 2026-09-10): more sprite updates —
  enemies, UI elements, towers (checkpoint waystone), buttons — generated on
  the LOCAL ComfyUI/Flux install instead of Nano Banana. **Standing rule:
  for simple asset updates like these, use local ComfyUI (free); reserve
  the Gemini API for hero/painterly art.**
- Path screen (asked 2026-09-10): entering the map hung for a second — fix
  the error and make the flow more seamless; owner suggested ditching the
  map. Done: the full-screen journey map was removed in favor of a compact
  instant route picker (the hitch was the map's 3D flame SubViewport shader
  compiles).

## Changelog

Newest first. Format: date · commit(s) · summary.

- 2026-09-10 · `(this commit)` · HUD bars, widescreen pop-in, faster pace
  (owner asks). Distance/HP bars are carved-stone groove tracks (one free
  ComfyUI texture, `ui_bar_track.png`) with rounded fills; flat fallback
  kept. Widescreen glitch fixed: the waystone had a hardcoded 860px
  visibility cull (popped into view mid-screen on wide displays) — now
  always visible and glides in; enemy/boss spawns likewise moved from fixed
  800/820px to just past the actual canvas right edge (`_offscreen_x`).
  Pace: base speed 70 → 90 px/s, checkpoint ramp +2 → +3, goals 55+10n
  (cap 220) → 90+14n (cap 320) — longer marches that finish sooner in
  wall-clock, with stronger backdrop parallax (0.12 → 0.16). Tests updated
  (19,352 pass); web build deployed.

- 2026-09-10 · `(this commit)` · ComfyUI visual refresh + seamless route
  picker. Nine assets generated FREE on the local Flux-schnell install
  (magenta-key pipeline v2: sample the real bg color — Flux renders
  "magenta" as crimson — flood-fill from borders, strip baked drop-shadows
  by hue band, largest blob): enemy sprites (grunt/runner/tank imps + boss
  ogre, code fallback kept), checkpoint waystone tower sprite (goal
  marker; texture must be loaded in _build_world, NOT inside the draw
  callback — load() there rendered a white placeholder), gold coin sprite,
  and carved-stone UI (gold + dark slate 9-patch button plates, stone
  panel plate) wired through UiKit primary/ghost/panel with flat
  fallbacks. Path map RETIRED: `path_overlay.gd` deleted (its FlameFrame
  SubViewport shader compiles caused the ~1 s hang on open); replaced by
  `path_picker.gd` — an instant bottom-sheet with pulsing waystone glyphs,
  theme names, draft-bias hints, elite spikes, and the map-backdrop art as
  a strip. Same chosen(map_index) contract. Tests 19,352 pass; shot suite
  verified; web build deployed.

- 2026-09-09 · `(this commit)` · Characters + cat towers + endless runs.
  Three Nano Banana sprite sheets ($0.20 API total; magenta chroma-key +
  connected-component slicing into `game/art/sprites/`). New
  `game/scenes/characters/`: BaseCharacter (factory, sprite/pivot helpers)
  with sprite-rigged GolemChar (same sine gait as the old vector rig, now
  parts + squash), ShipChar (viking longship, bob/rock/sail sway), TankChar
  (tread-bounce). Old vector `golem.gd` deleted; march/menu use
  BaseCharacter. New character-select screen (`select_menu`) after Start
  run; choice persisted in settings. Turrets are Battle-Cats-style cat
  sprites (cannon/mortar/javelin) that lean toward targets and recoil with
  squash; branch = glow disc, level 2 = bigger cat. ENDLESS architecture:
  `wave_gen.gd` (formula waves: goal cap 220 m, interval floor 0.4 s, hp
  compounds, boss every 10th), `path_map.gd` rewritten as an endless lazy
  act-based map (setup/ensure_rows, deterministic per seed), waves.json
  deleted. Checkpoints do NOT clear enemies or reset the world — coins
  magnet in, a 0.45 s beat, then draft/path/armory over paused combat, then
  the same swarm resumes. Pace: +2 px/s base speed per checkpoint.
  path_overlay flames only the next boss gate (endless maps would pile up
  SubViewports); embers localized to the focus area. End screen reworded
  for endless runs. Tests rewritten for the new invariants: 19,352 checks
  pass. Shot suite: 04 is now the checkpoint (enemies alive), 09_select
  added; repo screenshots refreshed (+05_select). Web build deployed.

- 2026-09-09 · `(this commit)` · Background QA launches (owner ask: never
  switch/steal the owner's window). `settings.gd` now honors a `--background`
  user arg: NO_FOCUS window flag + park past the rightmost monitor edge.
  Launch windowed QA runs with `--position 10000,80 -- --background`
  (documented in README + CLAUDE.md). Never minimize — it throttles the
  swapchain and hangs shot runs.
- 2026-09-09 · `(this commit)` · Art revamp round 1 integrated. Nine
  Nano Banana images generated via the Gemini API (~$0.54: 7x
  `gemini-3.1-flash-image`, 2x lite; masters in `art/src/`, game copies in
  `game/art/`). Main menu: painted key art background (golem under the moon)
  with slow ken-burns drift, buttons moved to the bottom; procedural
  golem/ground kept as fallback when art is absent. March: per-theme painted
  backdrops (wastes/fire/forest/water/boss) drawn mirror-tiled with slow
  parallax in `_draw_bg`; procedural sky/hills remain as fallback; ground
  rocks still code-drawn. Path map: painted mountain-journey backdrop under
  the `map_terrain` shader, which now respects modulate (was hardcoded
  opaque) and blends at 0.25 as a haze/vignette/ridge pass. Draft cards:
  carved-stone category emblems (attack/econ/speed) on a dark plaque.
  Armory: weapon emblems (cannon/mortar/javelin) beside line names. App
  icon replaced (`ios_icon_1024.png`, `game/art/icon_512.png`, project
  icon). Emblems sliced from one generated sprite sheet; scenery stored as
  JPEG (game/art ~1.4 MB). Tests 5,098 pass; 8-shot suite verified; repo
  screenshots refreshed. Web build deployed to gh-pages.
- 2026-09-09 · `83ff197` · Graphics-revamp ask recorded. Added
  `docs/ART_PROMPTS.md`: "Moonlit Megalith" art direction, 14 Nano Banana
  prompts (menu key art, 5 themed march backdrops, path-map backdrop, 6
  emblems, app icon) with exact filenames/ratios, owner browser workflow,
  and the integration plan. Created `art/src/` drop folder. No code changes;
  integration follows once the owner generates round 1.
- 2026-09-08 · (this commit) · Weapon tree system implemented. New
  `game/data/weapons.json` + `game/sim/armory.gd` (level gating, branch
  exclusivity, gold costs; fully unit-tested). `ArmoryOverlay` opens between
  waves after the path choice. Turrets/projectiles rewritten mode-driven:
  cannon shell/tracer/magma-burn or twin barrels; mortar splash/bloom with
  ash-field (`ash_field.gd`) or cluster bomblets; javelin pierce bolts with
  storm chain lightning (`zap_fx.gd`) or impaler blocked-bonus. Enemies
  support burn DoT. Mount cards removed from the draft pool (replaced by
  overclocked_loaders / war_core); RunState.turrets -> weapons dict, mount
  op removed. Tests 4,992 -> 5,098 checks. Shot suite now captures the
  armory (07) and a maxed triple-branch build in combat (08). Web build
  deployed to gh-pages.
- 2026-09-08 · `docs` · Recorded the weapon tree design ask and prototype
  direction (armory + per-level projectile VFX mockups drafted for owner
  review; implementation pending approval).
- 2026-09-07 · `(this commit)` · Visual path map: `path_overlay.gd` rewritten
  as a full-screen, text-free journey map (bottom-to-top). Procedural per run:
  node jitter and trail bends seeded from the run seed. Terrain backdrop is a
  new `game/fx/map_terrain.gdshader` (fbm ridge silhouettes, drifting haze,
  vignette, parallax on scroll). Glyph-only waystones (flame/tree/droplet,
  cairn start, skull boss with a FlameFrame 3D fire ring, spiked elites);
  traveled path drawn gold from new `Game.path_history`; current choices pulse
  with animated dashed trails; tap to pick (drag scrolls the taller-than-screen
  map); selection triggers an expanding ring burst and the golem marker walks
  the trail before `chosen` fires; ambient ember particles throughout.
  `FlameFrame` gained a `_ready` layout pass so manually positioned frames
  work. Public overlay API unchanged; `march.gd` untouched; `game.gd` only
  gained `path_history`. Verified with offscreen renders (idle, mid-travel,
  boss summit).

- 2026-09-07 · `docs` · Added this project log and CLAUDE.md agent
  instructions (owner ask: write and maintain a document of all changes,
  design directions, and asks; all agents must keep it updated).
- 2026-09-07 · gh-pages `d277655` · Web build re-exported and deployed with
  the 3D flame VFX (verified Pages build succeeded).
- 2026-09-07 · `6f6769e` · Replaced the 2D flame aura with 3D GPU particle
  flames. `game/fx/flame_billboard.gdshader` is a stylized fire billboard
  shader (threshold alpha erosion over procedural noise), adapted from
  GDQuest's MIT-licensed `stylized_fire` — attribution in the file header;
  all textures (noise, mask, color ramp, scale curve) are generated in code,
  no GDQuest art assets used (theirs are CC-BY-NC). `FlameFrame`
  (`game/fx/card_fire.gd`) renders `GPUParticles3D` in a transparent
  per-frame `SubViewport` (ortho camera, glow environment), emitting along
  the card's rounded-rect border; selection tweens `amount_ratio` and
  emission for a flare. Tuned over five offscreen render iterations.
- 2026-09-07 · `19b160a` · Card and path redesign (per VFX ask): category
  pill, rarity pips, full-width stat strip, category-tinted card bodies in
  `draft_overlay.gd`; path gates wrapped in auras tinted by route theme
  (elite brighter, boss red) in `path_overlay.gd`. Overlay public APIs
  unchanged; `march.gd` and `UiKit` untouched. (Its 2D shader was
  superseded by `6f6769e` the same day.)
- 2026-09-07 · `03197aa` · World depth, goal waystone, walk sync, wave-end
  rout. Web build of this state deployed as gh-pages `8f0da77`.
- 2026-09-07 · `731af88` · Enemies mob the golem's front instead of latching
  (implements the enemy interaction redesign above).
- (earlier) · `b560af4` · Initial scaffold: golem wave-defense roguelike —
  menus, march scene, golem/enemy/turret/projectile scripts, draft and path
  overlays, sim (path map, run state, draft system), data (cards, waves,
  themes), UiKit, tests, iOS + Web export presets.

## Current state / open threads

- Deployed web build: gh-pages (3D flames + visual path map).
- Flame tuning knobs live in `game/fx/card_fire.gd` (`FLAME_IDLE` /
  `FLAME_SELECTED` in `draft_overlay.gd`, intensities in `path_overlay.gd`);
  owner may request further tuning of intensity, size, or rise height.
- From the design asks, not yet clearly realized: distinct upgrade *trees*
  (beyond card categories), tower *placement*, and the active in-game skill
  element — check current code before assuming, and log progress here.
