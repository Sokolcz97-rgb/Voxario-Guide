# Manual test checklist — WoW Forever Beta

- Install the `VoxarioGuide` folder in the Forever AddOns directory and enable it at character select.
- Confirm login produces no Lua errors and `Development Test Guide` is available from any location.
- Test `/vg`, `/vg help`, `/vg guides`, `/vg reset`, `/vg debug`, `/vg status`, and `/vg version`.
- Select `Development Test Guide`; test Previous on step 1, Next, Skip, final-step completion, Restart Guide, and Choose Guide.
- Confirm Recorder is OFF after `/reload`, then test `/vg record status`, `/vg record start`, `/vg record stop`, and `/vg record clear` without recording live route data.
- Select a guide, use Previous, Next, and Skip, then `/reload` and verify the current step recovers.
- Move and scale the main frame; reload and verify both settings persist.
- Add a **verified** quest ID to a local development copy and confirm `ACCEPT_QUEST` advances when accepted and `COMPLETE_QUEST` / `TURNIN_QUEST` react correctly.
- Add verified `mapID`, `x`, and `y` to a `GO_TO` step and verify the waypoint fallback/arrow in open world, indoors, and an instance.
- Test zone changes, level-up, abandoning a quest, logout/login, and missing map-position data.

Do not add live route data until it has been tested on the Forever Beta client.
