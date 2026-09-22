# Voxario Guide

**Voxario Guide** is a free, open-source, step-by-step leveling and quest-guide addon for **World of Warcraft: Forever**. It gives advice and reacts to legally available game state; it never moves a character, selects targets, casts abilities, or performs protected actions.

Status: **0.1.0-alpha — early development / Forever Beta validation required.**

## Features

- Data-driven, extensible guide registry and step engine.
- Conditions for level, race, class, faction, quest state, preceding steps, and optional route logic.
- Saved selection, step recovery, completed internal steps, manual skip history, frame position, scale, lock state, and debug state.
- Event-driven updates for login, quest, level, and zone changes — no per-frame quest polling.
- Compact draggable UI, guide selector, settings, safe navigation fallback, slash commands, debug status, and English/Czech UI strings.
- Development-only Horde and Alliance guides with no invented Forever quest IDs or map coordinates.

## Installation

1. Copy the `VoxarioGuide` directory into your World of Warcraft: Forever `Interface/AddOns` folder.
2. At character select, enable **Voxario Guide**.
3. Log in and choose the faction-compatible development guide.

The target TOC interface is `16001`. Keep that value in [VoxarioGuide.toc](VoxarioGuide/VoxarioGuide.toc) isolated and update it only after validating a new Forever client build.

## Slash commands

| Command | Action |
| --- | --- |
| `/vg` or `/voxarioguide` | Toggle the primary guide window. |
| `/vg guides` | Open the compatible guide selector. |
| `/vg reset` | Reset the selected guide. |
| `/vg debug` | Toggle debug logging. |
| `/vg status` | Print current player/guide/quest/waypoint state. |
| `/vg version` | Print addon version. |

## Project layout

`Core` contains state, registry, conditions, events, navigation, and guide flow. `UI` contains native Blizzard-frame UI. `Guides` contains only route data. `Data` is reserved for verified public Forever references. `Localization` stores UI text. This separation means a new route can be added without changing the engine.

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
            text = {
                enUS = "Travel to the meeting point.",
                csCZ = "Vydejte se na místo setkání.",
            },
            conditions = { faction = "Horde", minLevel = 1 },
        },
    },
})
```

Supported types are `ACCEPT_QUEST`, `COMPLETE_QUEST`, `TURNIN_QUEST`, `GO_TO`, `KILL`, `COLLECT`, `TALK_TO`, `USE_ITEM`, `SET_HEARTH`, `USE_HEARTH`, `FLIGHT_PATH`, `TRAIN`, `BUY`, and `NOTE`. Automatic completion in this alpha is deliberately limited to quest-state steps whose `questID` has been verified. Advice and travel steps remain manual.

`conditions` accepts `minLevel`, `maxLevel`, `race`, `class` (a string or list), `faction`, `questCompleted`, `questActive`, `questNotCompleted`, `previousStep`, and `optional`. Optional route policy is intentionally left to future route-selection work.

## Forever API compatibility and limitations

The addon uses guarded Mainline-style APIs, principally `C_QuestLog` and `C_Map`. Areas that require Forever Beta confirmation are marked `TODO VERIFY FOREVER API`; unavailable APIs degrade to no quest auto-completion or a textual coordinate waypoint rather than a Lua error. The custom arrow currently displays a safe coordinate/distance estimate only; it does not rotate toward a target until the necessary Forever position/facing APIs are validated.

There are no real quest IDs, NPC IDs, map IDs, copied guide text, databases, or third-party route assets in this alpha. Populate data only from independently verified Forever Beta testing.

See [the manual test checklist](VoxarioGuide/Tests/README.md) before claiming in-game compatibility.

## License

MIT. See [LICENSE](LICENSE).
