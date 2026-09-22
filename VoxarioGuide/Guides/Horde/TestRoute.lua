local _, VG = ...

VG:RegisterGuide({
    id = "HORDE_DEVELOPMENT_STARTER", name = "Horde Starter Development", category = "development", faction = "Horde", minLevel = 1, maxLevel = 10,
    description = "Safe development route without unverified Forever quest IDs.",
    steps = {
        { type = "NOTE", important = true, text = { enUS = "Development route: use this guide to verify Voxario's UI and controls.", csCZ = "Vývojová trasa: ověřte zde UI a ovládání Voxario." } },
        { type = "GO_TO", text = { enUS = "Travel to a known starter-area landmark. Coordinates can be added after Forever map IDs are verified.", csCZ = "Vydejte se ke známému místu ve startovní oblasti. Souřadnice doplňte po ověření map ID Forever." } },
        { type = "ACCEPT_QUEST", text = { enUS = "Accept a verified Forever quest here once its quest ID is documented.", csCZ = "Přijměte zde ověřený Forever quest, až bude zdokumentováno jeho quest ID." } },
        { type = "COMPLETE_QUEST", text = { enUS = "Complete that quest, then advance manually during this data-free development route.", csCZ = "Dokončete tento quest a v této vývojové trase pokračujte ručně." } },
        { type = "TURNIN_QUEST", text = { enUS = "Turn in the quest. This confirms the guide flow without inventing data.", csCZ = "Odevzdejte quest. Tím ověříte průchod guide bez vymyšlených dat." } },
    },
})
