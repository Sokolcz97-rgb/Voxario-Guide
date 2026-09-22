local _, VG = ...
VG.StepTypes = {
    ACCEPT_QUEST = true, COMPLETE_QUEST = true, TURNIN_QUEST = true, GO_TO = true,
    KILL = true, COLLECT = true, TALK_TO = true, USE_ITEM = true, SET_HEARTH = true,
    USE_HEARTH = true, FLIGHT_PATH = true, TRAIN = true, BUY = true, NOTE = true,
}
VG.Factions = { Alliance = true, Horde = true }
VG.NavigationConstants = { ARRIVAL_DISTANCE = 15 } -- TODO VERIFY FOREVER API unit before enabling auto-complete.
