local _, VG = ...

function VG:AreConditionsMet(step, guide)
    local c, player = step.conditions, self.Player
    if not c then return true end
    if c.minLevel and player.level < c.minLevel then return false end
    if c.maxLevel and player.level > c.maxLevel then return false end
    if c.faction and player.faction ~= c.faction then return false end
    if c.race and not self:ValueMatches(c.race, player.race) then return false end
    if c.class and not self:ValueMatches(c.class, player.class) then return false end
    if c.questCompleted and not self:IsQuestCompleted(c.questCompleted) then return false end
    if c.questActive and not self:IsQuestActive(c.questActive) then return false end
    if c.questNotCompleted and self:IsQuestCompleted(c.questNotCompleted) then return false end
    if c.previousStep and not self:IsStepCompleted(guide.id, c.previousStep) then return false end
    return true
end

function VG:ValueMatches(expected, actual)
    if type(expected) == "table" then for _, value in ipairs(expected) do if value == actual then return true end end return false end
    return expected == actual
end

function VG:IsStepCompleted(guideID, index)
    return self.db.completedSteps[guideID] and self.db.completedSteps[guideID][index] or false
end

function VG:MarkStepCompleted(guideID, index)
    self.db.completedSteps[guideID] = self.db.completedSteps[guideID] or {}
    self.db.completedSteps[guideID][index] = true
end

function VG:IsStepComplete(step)
    if step.type == "ACCEPT_QUEST" then return self:IsQuestActive(step.questID) or self:IsQuestCompleted(step.questID) end
    if step.type == "COMPLETE_QUEST" then return self:IsQuestCompleted(step.questID) end
    if step.type == "TURNIN_QUEST" then return self:IsQuestCompleted(step.questID) end
    -- GO_TO, NOTE and action-advice steps are intentionally manual in this alpha.
    return false
end
