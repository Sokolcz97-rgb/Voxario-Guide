local _, VG = ...

function VG:RefreshQuestState()
    self.QuestState.active = {}
    -- TODO VERIFY FOREVER API: C_QuestLog.IsQuestFlaggedCompleted is guarded below.
end

function VG:IsQuestCompleted(questID)
    if not questID or not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then return false end
    local ok, completed = pcall(C_QuestLog.IsQuestFlaggedCompleted, questID)
    return ok and completed == true
end

function VG:IsQuestActive(questID)
    if not questID or not C_QuestLog or not C_QuestLog.GetLogIndexForQuestID then return false end
    local ok, index = pcall(C_QuestLog.GetLogIndexForQuestID, questID)
    return ok and index and index > 0 or false
end

function VG:GetQuestStatus(questID)
    if not questID then return "unknown" end
    if self:IsQuestCompleted(questID) then return "completed" end
    if self:IsQuestActive(questID) then return "active" end
    return "unavailable"
end
