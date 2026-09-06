# Stonestride

iOS roguelike wave-defense: your base is a walking stone golem. March each wave's
distance while tiny monsters latch on and slow you, draft an upgrade card after
every wave, then choose a themed path that biases your next draft — all routes
converge on the wave-10 boss.

## Run it (no editor needed)

    godot --path .                      # play (desktop preview)
    godot --headless --path . --import  # first run only: builds class cache
    godot --headless --path . --script tests/run_tests.gd   # property tests

Visual verification without opening the engine:

    STONESTRIDE_SHOTS=/tmp/shots godot --path .   # captures menu/march/draft/path PNGs

## Layout

    game/autoload/   Settings (user://settings.cfg), Game (run orchestration),
                     Router (radial-wipe scene transitions)
    game/sim/        Pure logic, no nodes: RunState, DraftSystem, PathMap
    game/data/       cards.json (17 cards), themes.json (path odds + palettes),
                     waves.json (10 waves)
    game/scenes/     Golem (procedural articulated walk), march gameplay,
                     menus, draft/path/pause overlays, UiKit helpers
    tests/           run_tests.gd (4,992 checks), shot_runner.gd

## Design invariants (enforced by tests)

- Drafts are deterministic per seed; theme odds hold within 5% over 6k draws
- Path maps: rows == waves, start and boss rows single, every node reachable
  from start, no dead ends, boss reachable on all 50 tested seeds
- March speed is monotone non-increasing in latched enemies, floored at 20%
- latch_resist clamps at 0.85; wave goals strictly increase; final wave is boss

## iOS export notes

- Project is portrait 720x1280, canvas_items stretch/expand, Mobile renderer,
  touch emulation on — ready for Godot's iOS export template
- Settings.vibrate() uses Input.vibrate_handheld (works on device, no-op on desktop)
- No mid-run save yet: closing the app abandons the run (next feature candidate)
- Add App Store icon set + launch screen via export preset when you set up signing

