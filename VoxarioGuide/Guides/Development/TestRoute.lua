local _, VG = ...

VG:RegisterGuide({
    id = "DEVELOPMENT_TEST_GUIDE",
    name = "Development Test Guide",
    minLevel = 1,
    description = "Location-independent UI and state validation route.",
    steps = {
        { type = "NOTE", text = { enUS = "Voxario Guide development test started.", csCZ = "Spuštěn vývojový test Voxario Guide." } },
        { type = "NOTE", text = { enUS = "Test Previous, Next, and Skip controls.", csCZ = "Otestujte ovládání Předchozí, Další a Přeskočit." } },
        { type = "NOTE", text = { enUS = "Use /reload and verify this step is restored.", csCZ = "Použijte /reload a ověřte obnovení tohoto kroku." } },
        { type = "NOTE", text = { enUS = "Test window position, lock, scale, and minimize state.", csCZ = "Otestujte pozici, zámek, měřítko a minimalizaci okna." } },
        { type = "NOTE", text = { enUS = "Development guide complete.", csCZ = "Vývojový guide je dokončen." } },
    },
})
