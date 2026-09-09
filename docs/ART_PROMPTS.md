# Stonestride art revamp — Nano Banana prompt sheet

Owner workflow (standing rule): the owner generates all AI art in the Gemini
web app (their Google AI subscription); agents write the prompts and integrate
the results. **Never call the Gemini API from this project.**

## Art direction: "Moonlit Megalith"

Modern painterly flat-shape illustration in the Alto's Odyssey / Monument
Valley lineage: large simplified landforms, soft layered gradients, subtle
film-grain texture, thin warm rim light, tiny ember/firefly accents. Night
palette anchored to the game's existing colors:

- deep indigo night `#1b2440`, dusk violet `#3d3154`, ground slate `#2e2a3d`
- warm amber accent `#ffb74d`, pale moon `#e8ddb0`, mint glow `#9ee7c8`
- theme tints — fire `#e05a4e`/`#5c2a2e`, forest `#5aa06b`/`#2c4a34`,
  water `#5b9bd5`/`#27455e`, boss violet `#c79bf0`/`#45295e`

The procedurally animated golem, enemies, projectiles and 3D flame VFX stay
code-drawn; raster art supplies backdrops, emblems and key art around them.

## How to generate (owner)

1. Go to gemini.google.com, start ONE new chat, and keep every prompt in that
   same chat (it keeps the style consistent). Use the model that generates
   images (Nano Banana / "Create image").
2. Run prompt 1 first and download it. For every later prompt, ATTACH the
   prompt-1 image and start the message with:
   "Match the exact painting style, palette, grain and lighting of the
   attached image."
3. Download each result as PNG and save it into `art/src/` with the exact
   filename given. If a result has text, watermarks, people, or ignores the
   composition notes, just regenerate.
4. Tell the agent when the files are in `art/src/` — integration is code work.

## Round 1 — core scenery (7 images, biggest impact)

| # | file | ratio | used for |
|---|------|-------|----------|
| 1 | `key_art_menu.png` | 9:16 | main menu background + style anchor |
| 2 | `march_wastes.png` | 16:9 | march backdrop, neutral theme |
| 3 | `march_fire.png` | 16:9 | march backdrop, fiery path |
| 4 | `march_forest.png` | 16:9 | march backdrop, forest path |
| 5 | `march_water.png` | 16:9 | march backdrop, water path |
| 6 | `march_boss.png` | 16:9 | march backdrop, boss wave |
| 7 | `map_backdrop.png` | 9:16 | path-map journey backdrop |

Full prompt text lives in the chat handoff and is duplicated here so any
agent can reissue it.

### 1 · key_art_menu.png (9:16)

> A 9:16 portrait game key art illustration, modern flat-shape painterly
> style like Alto's Odyssey and Monument Valley, subtle film grain, no
> outlines. A massive hunched stone golem with long thick arms and short
> legs walks left to right across a dark moorland at night, knuckle-dragging
> like a neanderthal, moss on its shoulder, one warm amber rune glowing in
> its chest. A handful of tiny glowing red imp silhouettes scurry at its
> feet. Deep indigo night sky #1b2440 fading to dusk violet #3d3154 at the
> horizon, large pale cream moon #e8ddb0, sparse stars, faint amber
> fireflies. The upper third of the image is calm open sky with no clouds or
> details (title space). Muted, elegant, atmospheric. No text, no words, no
> watermark, no humans.

### 2 · march_wastes.png (16:9)

> Match the exact painting style, palette, grain and lighting of the attached
> image. A 16:9 wide seamless side-scrolling game background of desolate
> night moorland: rolling dark hills in two or three flat parallax layers,
> scattered weathered standing stones and dead shrubs, deep indigo sky
> #1b2440 to dusk violet #3d3154, pale moon high right, sparse stars, faint
> mist between hill layers. Horizon line at two-thirds down; the bottom third
> is a nearly flat, plain dark slate ground band #2e2a3d with almost no
> detail. Keep shapes generic and evenly distributed with no single centered
> landmark, so the image tiles horizontally. No creatures, no figures, no
> text, no watermark.

### 3 · march_fire.png (16:9)

> Same as 2 but: smoldering volcanic badlands, ember-red sky #2e1626 to
> #5c2a2e, cracked ridges with thin glowing lava seams #e05a4e, drifting
> sparks, dark smoke plumes on the horizon, ground band #38222a.

### 4 · march_forest.png (16:9)

> Same as 2 but: ancient pine forest at night, layered flat pine silhouettes,
> sky #16261e to #2c4a34, moss-green moonlight rim #5aa06b on the treetops,
> faint green fireflies, low fog between tree layers, ground band #223326.

### 5 · march_water.png (16:9)

> Same as 2 but: a moonlit lakeshore, calm water with a long soft moon
> reflection, distant blue cliffs, sky #14202e to #27455e, cool blue accents
> #5b9bd5, gentle mist over the water, ground band #1e2b3a (the golem walks
> on a dark shore strip in front of the lake).

### 6 · march_boss.png (16:9)

> Same as 2 but: an ominous violet summit approach, jagged black spires,
> sky #241633 to #45295e, eerie violet glow #c79bf0 behind the tallest
> central-right spire, floating dust motes, ground band #2c1f3d.

### 7 · map_backdrop.png (9:16)

> Match the exact painting style, palette, grain and lighting of the attached
> image. A 9:16 tall vertical painted overview of a night journey for a game
> map screen, viewed from a high vantage: dark layered mountain ridges
> stacked bottom to top, a faint pale winding trail suggestion rising from
> the bottom edge to a distant violet-lit summit at the top, thin mist bands
> between ridges, deep indigo #1b2440 and dusk violet #3d3154, sparse stars
> near the top. VERY dark, low contrast and muted overall — glowing UI
> markers will be drawn on top and must stay readable. No icons, no
> creatures, no text, no watermark.

## Round 2 — emblems, icon (7 images, after round 1 is in)

All emblems: 1:1, a single carved stone medallion centered on a near-black
`#12101c` background (no transparency needed — integrated with additive/
vignette blending), thin warm amber rim light, same painterly style, no text.

| # | file | subject |
|---|------|---------|
| 8 | `emblem_attack.png` | clenched stone fist wreathed in embers (attack cards) |
| 9 | `emblem_econ.png` | stack of glowing amber coins on stone (econ cards) |
| 10 | `emblem_speed.png` | stone boot with wind-swirl lines (speed cards) |
| 11 | `emblem_cannon.png` | stout cannon barrel, single amber muzzle glow |
| 12 | `emblem_mortar.png` | mortar tube with a high arcing spark trail |
| 13 | `emblem_javelin.png` | slender javelin bolt piercing three rings |
| 14 | `app_icon.png` | 1:1 app icon: bold hunched golem silhouette against the moon, deep indigo, amber chest rune, readable at small size, flat background, no text |

## Integration plan (agent, after images land in art/src/)

- Downscale/crop masters into `game/art/` (menu 720x1280; march layers sliced
  from the 16:9 masters — sky band + ridge band, mirror-tiled horizontally
  for scroll; map backdrop under the existing shader haze at low opacity).
- `march.gd`: swap flat sky/hill polygons for the sliced painted layers with
  parallax factors; keep code-drawn ground strip, footprints, shadows.
- `path_overlay.gd`: draw `map_backdrop.png` beneath (or blended with)
  `map_terrain.gdshader`.
- `draft_overlay.gd` / `armory_overlay.gd`: emblem thumbnails on cards/nodes.
- Re-run the shot suite, compare before/after, export Web preset, deploy
  gh-pages, changelog in PROJECT_LOG.md.
