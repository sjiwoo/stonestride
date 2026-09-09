# Stonestride

iOS roguelike wave-defense: your base is a walking champion — a stone golem,
a viking longship, or a stubby tank — crewed by Battle-Cats-style cat
gunners. The march is ENDLESS: reaching each checkpoint waystone opens an
upgrade draft, a themed path choice, and the armory, but enemies are never
cleared and the world never resets — you keep marching, a little faster
after every checkpoint, with a boss gating every 10th one.

## Run it (no editor needed)

    godot --path .                      # play (desktop preview)
    godot --headless --path . --import  # first run only: builds class cache
    godot --headless --path . --script tests/run_tests.gd   # property tests

Visual verification without opening the engine (always pass the background
flags so the game window never appears on screen or steals focus):

    STONESTRIDE_SHOTS=/tmp/shots godot --path . --position 10000,80 -- --background

## Layout

    game/autoload/   Settings (user://settings.cfg), Game (run orchestration),
                     Router (radial-wipe scene transitions)
    game/sim/        Pure logic, no nodes: RunState, DraftSystem,
                     PathMap (endless, lazily generated), WaveGen (endless waves)
    game/scenes/     characters/ (sprite-rigged golem/ship/tank), march
                     gameplay, select/menus, draft/path/armory overlays, UiKit
    game/art/        painted backdrops + sprites/ (sliced Nano Banana sheets)
    game/data/       cards.json (17 cards), themes.json (path odds + palettes),
                     weapons.json (weapon tree)
    art/src/         AI art masters (gdignored by the engine)
    tests/           run_tests.gd (19,352 checks), shot_runner.gd

## Design invariants (enforced by tests)

- Drafts are deterministic per seed; theme odds hold within 5% over 6k draws
- Endless path map: generated lazily, deterministic per seed regardless of
  ensure_rows call pattern; boss gate every 10th row (single node), other
  rows triple; every node reachable from start, no dead ends
- WaveGen: goals non-decreasing (capped 220 m), spawn interval non-growing
  (floor 0.4 s), hp compounds forever, boss exactly every 10th wave
- March speed is monotone non-increasing in latched enemies, floored at 20%;
  base speed permanently ramps +2 px/s at every checkpoint
- latch_resist clamps at 0.85

## iOS export notes

- Project is portrait 720x1280, canvas_items stretch/expand, Mobile renderer,
  touch emulation on — ready for Godot's iOS export template
- Settings.vibrate() uses Input.vibrate_handheld (works on device, no-op on desktop)
- No mid-run save yet: closing the app abandons the run (next feature candidate)
- Add App Store icon set + launch screen via export preset when you set up signing

