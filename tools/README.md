# Voxario data import workflow

The addon consumes only static Lua data in `VoxarioGuide/Data/Quests.lua` and `VoxarioGuide/Data/NPCs.lua`. It performs no HTTP requests and does not scrape websites.

Prepare verified external exports in a normalized intermediate JSON or CSV file, review their provenance, then generate deterministic Lua keyed by numeric `questID` or `npcID`. Preserve `source`, `sourceBuild` where known, and `verification` on every record. Accepted objective types are `KILL`, `COLLECT`, `INTERACT`, `TALK`, `REACH`, `USE_ITEM`, and `CUSTOM`.

Do not import unlabelled Classic references as Forever facts. Use `source = "classic_reference"` with `verification = "needs_ingame_check"` until tested in the Forever client. `forever_client` and `verified` records may be used for route authoring after review.
