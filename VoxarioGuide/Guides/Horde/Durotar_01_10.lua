local _, VG = ...

VG:RegisterGuide({
    id = "HORDE_DUROTAR_01_10", name = "Durotar 1-10", category = "leveling", faction = "Horde", minLevel = 1, maxLevel = 10,
    zone = "Durotar", status = "alpha", priority = 200,
    description = "Work in progress. Gameplay data pending Forever Beta verification.",
    sections = { DATA = "Route data verification" },
    steps = {
        { type = "NOTE", section = "DATA", verification = "pending", text = { enUS = "TODO DATA VERIFICATION: verified Forever Durotar route data has not been collected yet.", csCZ = "TODO DATA VERIFICATION: overena Forever Durotar data zatim nejsou k dispozici." } },
        { type = "NOTE", section = "DATA", verification = "pending", text = { enUS = "Add verified quest and NPC records through the static data workflow; the recorder is optional for in-game confirmation.", csCZ = "Overene quest a NPC zaznamy pridejte pres staticky datovy postup; recorder je volitelny pro potvrzeni ve hre." } },
    },
})
