local _, VG = ...

VG:RegisterGuide({
    id = "HORDE_DUROTAR_01_10", name = "Durotar 1-10", category = "leveling", faction = "Horde", minLevel = 1, maxLevel = 10,
    zone = "Durotar", status = "alpha", priority = 200,
    description = "Work in progress. Gameplay data pending Forever Beta verification.",
    sections = { DATA = "Route data verification" },
    steps = {
        { type = "NOTE", section = "DATA", verification = "pending", text = { enUS = "TODO DATA VERIFICATION: verified Forever Durotar route data has not been collected yet.", csCZ = "TODO DATA VERIFICATION: overena Forever Durotar data zatim nejsou k dispozici." } },
        { type = "NOTE", section = "DATA", verification = "pending", text = { enUS = "Use the recorder and /vg location while playing to collect verified quest and coordinate data.", csCZ = "Pro sber overenych quest a souradnic pouzijte recorder a /vg location." } },
    },
})
