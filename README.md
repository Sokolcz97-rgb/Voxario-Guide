# Voxario Guide

**Voxario Guide** is a free, open-source, step-by-step leveling and quest-guide addon for **World of Warcraft: Forever**. It advises the player and reacts only to legitimate game state. It never moves a character, selects targets, casts abilities, or performs protected actions.

Status: **0.2.1-alpha — early development / Forever Beta validation required.**

## Features

- Data-driven, extensible guide registry, conditions, and step engine.
- Saved guide selection, normalized step recovery, completed internal steps, UI settings, and debug state.
- Event-driven updates for login, quests, level, and zone changes; no per-frame quest polling.
- Compact draggable UI, guide selector, navigation fallback, debug status, and English/Czech UI strings.
- Development-only Horde and Alliance guides with no invented Forever quest IDs or map coordinates.
- Developer-only Guide Recorder that captures legitimate quest events, manual waypoints, and notes in a reload-safe temporary route.
- Location-independent Development Test Guide for testing UI, controls, reload recovery, and completion state.

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

## Development Test Guide

`Development Test Guide` has five `NOTE` steps and is available to every faction from any location. It contains no quest IDs, map IDs, or live leveling content. Use it to verify Previous/Next/Skip boundaries, reload recovery, frame settings, and the Guide Complete state.

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
