local _, VG = ...
VG:RegisterGuide({ id = "DEV_DYNAMIC_TEST_1", name = "Dynamic Test Part 1", category = "development", minLevel = 1, maxLevel = 99, priority = 100, nextGuide = "DEV_DYNAMIC_TEST_2", sections = { INTRO = "Dynamic Conditions", FLOW = "Optional and Completion" }, steps = {
    { type = "NOTE", section = "INTRO", text = { enUS = "Dynamic engine test started.", csCZ = "Spusten test dynamickeho enginu." } },
    { type = "NOTE", section = "INTRO", conditions = { faction = "Alliance" }, text = { enUS = "Alliance-only step. Horde automatically skips it.", csCZ = "Pouze Alliance. Horde tento krok preskoci." } },
    { type = "NOTE", section = "INTRO", conditions = { anyOf = { { class = "WARRIOR" }, { class = "PALADIN" } } }, text = { enUS = "Warrior/Paladin conditional step.", csCZ = "Podminkovy krok pro Warrior/Paladin." } },
    { type = "NOTE", section = "FLOW", optional = true, text = { enUS = "Optional step: perform it or use Skip.", csCZ = "Volitelny krok: provedte nebo preskocte." } },
    { type = "NOTE", section = "FLOW", text = { enUS = "Complete this guide to test next-guide chaining.", csCZ = "Dokoncete guide pro test navazujiciho guide." } },
} })
