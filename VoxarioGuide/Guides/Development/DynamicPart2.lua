local _, VG = ...
VG:RegisterGuide({ id = "DEV_DYNAMIC_TEST_2", name = "Dynamic Test Part 2", category = "development", minLevel = 1, maxLevel = 99, priority = 90, previousGuide = "DEV_DYNAMIC_TEST_1", sections = { VERIFY = "State Recovery" }, steps = {
    { type = "NOTE", section = "VERIFY", text = { enUS = "Dynamic guide chaining succeeded.", csCZ = "Dynamicke navazani guide probehlo." } },
    { type = "NOTE", section = "VERIFY", conditions = { not = { maxLevel = 0 } }, text = { enUS = "Nested not condition resolved safely.", csCZ = "Vnorena podminka not se bezpecne vyresila." } },
    { type = "NOTE", section = "VERIFY", text = { enUS = "Dynamic Test Part 2 complete.", csCZ = "Dynamic Test Part 2 dokoncen." } },
} })
