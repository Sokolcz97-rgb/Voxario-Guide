# Voxario Guide

**Voxario Guide** is a free, open-source, step-by-step leveling and quest-guide addon for **World of Warcraft: Forever**. It advises the player and reacts only to legitimate game state. It never moves a character, selects targets, casts abilities, or performs protected actions.

Status: **0.5.5-alpha — early development / Forever Beta validation required.**

## Features

- Data-driven, extensible guide registry, conditions, and step engine.
- Saved guide selection, normalized step recovery, completed internal steps, UI settings, and debug state.
- Event-driven updates for login, quests, level, and zone changes; no per-frame quest polling.
- Compact draggable UI, guide selector, navigation fallback, debug status, and English/Czech UI strings.
- Development-only Horde and Alliance guides with no invented Forever quest IDs or map coordinates.
- Zone hierarchy bootstrap tooling that can scan descendants from a verified map root and export static/runtime data separately.
- Developer-only Guide Recorder that captures legitimate quest events, manual waypoints, and notes in a reload-safe temporary route. It is optional and inactive until explicitly started.
- Location-independent Development Test Guide for testing UI, controls, reload recovery, and completion state.
- Dynamic Guide Engine with nested conditions, sections, optional steps, pause/resume, recommendations, and manual guide chaining.
- Development-category guides are selectable on any character while real incompatible guides remain disabled.
- Centralized waypoint navigation with normalized coordinates and safe coordinate fallback.
- First Horde-first real-content framework: `Durotar 1-10` is registered as an alpha route with no fabricated gameplay data.
- Zone Database Scanner for collecting map hierarchy directly from guarded Forever client APIs.

## Installation

1. Copy the `VoxarioGuide` directory into your World of Warcraft: Forever `Interface/AddOns` folder.
2. Enable **Voxario Guide** at character select.
3. Log in and choose a faction-compatible guide, or start the route recorder.

The target TOC interface is `16001`. Update [VoxarioGuide.toc](VoxarioGuide/VoxarioGuide.toc) only after validating a new Forever client build.

## Slash commands

| Command | Action |
| --- | --- |
| `/vg` or `/voxarioguide` | Toggle the primary guide window. |
| `/vg guides` | Open the compatible guide selector. |
| `/vg reset` | Reset the selected guide. |
| `/vg debug` | Toggle debug logging. |
| `/vg status` | Print current player/guide/quest/waypoint state. |
| `/vg version` | Print addon version. |
| `/vg help` | Print the available commands. |
| `/vg pause` | Pause automatic guide resolution. |
| `/vg resume` | Resume automatic guide resolution. |
| `/vg devmode` | Toggle persisted development diagnostics; it never enables incompatible real guides. |
| `/vg nav` | Print active waypoint state. |
| `/vg nav clear` | Clear the temporary active waypoint. |
| `/vg navhere` | Create a temporary waypoint at the current verified map position. |
| `/vg location` | Print current map ID and coordinates when available. |
| `/vg zones ancestors` | Print the verified parent chain for the current map. |
| `/vg zones scan current` | Scan the current map only. |
| `/vg zones scan tree <mapID>` | Scan a verified root and its exposed descendants. |
| `/vg zones scan hierarchy` | Scan a safe verified ancestor of the current map. |
| `/vg zones status` | Print static, runtime, merged, and last-scan counts. |
| `/vg zones find <name>` | Search static and runtime zone records. |
| `/vg zones export` | Export runtime scanned records as deterministic Lua. |
| `/vg zones export merged` | Export merged static and runtime records as deterministic Lua. |
| `/vg zones validate` | Validate static and runtime zone record structure. |
| `/vg step <number>` | Development-safe jump to a valid step in the active guide. |
| `/vg validate` | Validate registered guide data structure and pending-verification counts. |
| `/vg record start` | Start recording a temporary development route. |
| `/vg record stop` | Stop recording while preserving its steps. |
| `/vg record status` | Print recorder state and step count. |
| `/vg record clear` | Clear the temporary recorded route. |
| `/vg record export` | Open copyable Lua guide data for the recorded route. |
| `/vg mark [note]` | Add a `GO_TO` step at the current player position. |
| `/vg note <text>` | Add a `NOTE` step to the recording. |

## Guide Recorder

The development-only recorder observes normal player activity and never performs a game action. While `/vg record start` is active, it records quest acceptance, completions found during the guarded `QUEST_LOG_UPDATE` event, and quest turn-ins. Every recorded event stores available map coordinates, level, faction, race, class, timestamp, and order. A small `REC <count>` indicator is visible only while recording.

Recorder data survives reloads, but recording itself is switched **off** on login/reload. Starting it always requires an explicit `/vg record start`; normal guide use never records route data.

## Zone hierarchy database

The Zone Scanner is a **development tool**, not a normal-player requirement. It uses the verified Forever `C_Map.GetMapInfo(uiMapID)` API and, when supported by the client, guarded `C_Map.GetMapChildrenInfo(uiMapID, nil, true)` to discover descendants from a chosen root. If the all-descendants form is unavailable or does not return a table, the addon uses guarded direct-child recursion with duplicate protection, cycle protection, and a 1,000-map safety limit.

`/vg zones ancestors` prints the actual parent chain of the current map. `/vg zones scan hierarchy` chooses the highest non-world ancestor it can verify; when only an overly broad world root is exposed, it stops and asks for an explicit `/vg zones scan tree <mapID>` command.

Runtime discoveries persist in `VoxarioGuideDB.zoneScanner.maps`. Bundled `Data/Zones.lua` remains separate. `/vg zones export` exports runtime records; `/vg zones export merged` produces deterministic map-ID-sorted Lua for developer review before verified data is deliberately copied into `Data/Zones.lua`. The addon has no runtime Wowhead or HTTP dependency.

Normal guide selection, guide progression, navigation, zone lookup, SavedVariables, and UI do not require recorder data. The Guide Selector now uses a bounded scrollable viewport so large guide lists remain contained at supported UI scales.

## Quest and NPC data foundation

`Data/Quests.lua` and `Data/NPCs.lua` are static numeric-ID databases intended for verified Forever route data. Quest records can include level, faction, authoritative `zoneMapID`, objectives, start/end NPC IDs, chain metadata, source/build provenance, and verification state. NPC records support multiple map locations. Unknown fields remain absent rather than guessed.

Use `/vg quest <id|name>`, `/vg npc <id|name>`, `/vg database status`, and `/vg database validate` while developing data. The importer design is documented in [tools/README.md](tools/README.md): external JSON/CSV or generated Lua must be normalized and reviewed outside the addon, then committed as static Lua. Public databases are development inputs only; the addon has no runtime network dependency.

## Development Test Guide

`Development Test Guide` has five `NOTE` steps and is available to every faction from any location. It contains no quest IDs, map IDs, or live leveling content. Use it to verify Previous/Next/Skip boundaries, reload recovery, frame settings, and the Guide Complete state.

`Dynamic Test Part 1` and `Dynamic Test Part 2` validate nested conditions, automatic skipping, optional steps, sections, pause/resume, and explicit next-guide chaining. They are location-independent and contain no live quest data.

## Dynamic guide metadata

Guides may declare `category`, `priority`, `previousGuide`, `nextGuide`, and `sections`. Steps may declare `section`, `optional = true`, and `conditions`. Conditions combine ordinary fields (`minLevel`, `maxLevel`, `faction`, `race`, `class`, quest state, and `previousStep`) with readable nested `allOf`, `anyOf`, and `not` groups. Invalid or already-completed steps resolve forward through one bounded resolver path; automatic skips never enter manual skip history.

Guides with `category = "development"` remain selectable regardless of guide metadata compatibility. This does not change the player's real faction, race, class, or level, so all internal step conditions continue to test actual player state. Non-development guides remain unavailable and disabled when their faction, level, race, or class metadata does not match.

## Navigation and waypoints

Any step may contain `mapID`, normalized `x`/`y` coordinates, and optional `targetName`. When active, it creates the shared waypoint used by the guide window and navigation element. Coordinates are stored internally as `0.0–1.0`; explicit percentage values such as `52.4, 37.8` are normalized to `0.524, 0.378`. Invalid values clear the waypoint safely.

Forever distance and player-facing APIs have not yet been verified for reliable yard/direction calculations. Therefore 0.5.3-alpha displays target labels and coordinates only; it does not fabricate a direction arrow, yard distance, or GO_TO arrival completion. The settings defaults are persisted for future verified implementations, with GO_TO auto-complete disabled.

## Content status

`Durotar 1-10` is Horde-only, `category = "leveling"`, and `status = "alpha"`. It is a real route framework, not a claimed complete 1–10 guide: its current two notes are explicitly marked `verification = "pending"` until Forever Beta quest, NPC, coordinate, and prerequisite data are recorded and tested. No Alliance production route data is included. Use `/vg validate` to find structural errors, suspicious duplicate quest steps, and pending data markers.

Use `/vg mark Enter the cave` to create a waypoint while building a route. Use `/vg note Sell junk and repair` for a note. `/vg record export` opens valid Lua guide data in a scrollable copyable box. It intentionally omits unavailable titles and positions rather than inventing values.

## Creating a guide

Create a Lua file under `VoxarioGuide/Guides/<Faction>/`, add it to the TOC **before** `Core/Events.lua`, and register it:

```lua
local _, VG = ...

VG:RegisterGuide({
    id = "MY_ROUTE_01",
    name = "My Route",
    faction = "Horde",
    minLevel = 1,
    maxLevel = 10,
    steps = {
        {
            type = "GO_TO",
            mapID = 123, -- verified Forever map ID only
            x = 0.523,
            y = 0.378,
            text = { enUS = "Travel to the meeting point." },
        },
    },
})
```

Supported types are `ACCEPT_QUEST`, `COMPLETE_QUEST`, `TURNIN_QUEST`, `GO_TO`, `KILL`, `COLLECT`, `TALK_TO`, `USE_ITEM`, `SET_HEARTH`, `USE_HEARTH`, `FLIGHT_PATH`, `TRAIN`, `BUY`, and `NOTE`. `conditions` accepts `minLevel`, `maxLevel`, `race`, `class`, `faction`, `questCompleted`, `questActive`, `questNotCompleted`, `previousStep`, and `optional`.

## Compatibility and limitations

The addon uses guarded Mainline-style APIs, principally `C_QuestLog` and `C_Map`. Forever-specific areas are marked `TODO VERIFY FOREVER API`. Missing or unsupported API data degrades safely: the recorder skips unavailable data and navigation falls back to textual coordinates.

The recorder does not invent quest, NPC, map, or coordinate data. It is a development tool, not a route editor or automated guide authoring system. Verify every exported route on the Forever Beta client before publishing it.

See [the manual test checklist](VoxarioGuide/Tests/README.md) before claiming in-game compatibility.

## License

MIT. See [LICENSE](LICENSE).
