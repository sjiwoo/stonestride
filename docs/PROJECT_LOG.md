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
  top; forging costs gold. Mockups reviewed in chat before implementation.
- Card/path VFX (asked 2026-09-07): a subtle fiery effect around the upgrade
  cards and the map path choices, plus a better card design. Process: draft
  the design visually first, then implement in code. Upgraded the same day:
  replace the 2D effect with **high-quality 3D flames**; adapting online
  implementations is explicitly allowed.

## Changelog

Newest first. Format: date · commit(s) · summary.

- 2026-09-08 · `docs` · Recorded the weapon tree design ask and prototype
  direction (armory + per-level projectile VFX mockups drafted for owner
  review; implementation pending approval).

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

- Deployed web build: gh-pages `d277655` (3D flames included).
- Flame tuning knobs live in `game/fx/card_fire.gd` (`FLAME_IDLE` /
  `FLAME_SELECTED` in `draft_overlay.gd`, intensities in `path_overlay.gd`);
  owner may request further tuning of intensity, size, or rise height.
- From the design asks, not yet clearly realized: distinct upgrade *trees*
  (beyond card categories), tower *placement*, and the active in-game skill
  element — check current code before assuming, and log progress here.
