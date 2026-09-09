# Agent instructions for Stonestride

Read `docs/PROJECT_LOG.md` before starting work. It holds the owner's design
directions, standing workflow rules, and the changelog.

Non-negotiables for every agent session (Claude or otherwise):

1. **Maintain `docs/PROJECT_LOG.md`.** Any push that changes code, assets,
   data, or the gh-pages build must include a changelog entry there, and any
   new owner ask or design direction must be recorded in its sections.
2. **Hands-free only.** The owner never opens the Godot editor. Ship complete
   files and validate headless (parse checks, scripted smoke tests, xvfb
   offscreen renders for visuals). When a windowed run is unavoidable (e.g.
   the screenshot suite), ALWAYS launch with `--position 10000,80 -- --background`
   — the Settings autoload then parks the window off-screen with NO_FOCUS so
   the owner's active window is never disturbed. Never minimize instead.
3. **Keep the web preview current.** After visual or gameplay changes, export
   the Web preset headless and push the build to `gh-pages` (manual deploy,
   no CI).
4. **Parallel sessions.** Others may push to `main` concurrently — fetch and
   rebase before pushing; keep changes scoped to minimize conflicts.
5. **Licensing.** Permissively licensed code may be adapted with attribution;
   never ship non-commercial-licensed assets — generate assets procedurally
   instead.
