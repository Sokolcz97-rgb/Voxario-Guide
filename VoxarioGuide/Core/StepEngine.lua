local _, VG = ...

local atomicKeys = { minLevel = true, maxLevel = true, faction = true, race = true, class = true, questCompleted = true, questActive = true, questNotCompleted = true, previousStep = true }

function VG:EvaluateConditions(conditions, guide)
    if type(conditions) ~= "table" then return true end
    local player = self.Player or {}
    if conditions.allOf then for _, child in ipairs(conditions.allOf) do if not self:EvaluateConditions(child, guide) then return false end end end
    if conditions.anyOf then local match = false; for _, child in ipairs(conditions.anyOf) do if self:EvaluateConditions(child, guide) then match = true; break end end; if not match then return false end end
    if conditions["not"] and self:EvaluateConditions(conditions["not"], guide) then return false end
    if conditions.minLevel and (tonumber(player.level) or 1) < conditions.minLevel then return false end
    if conditions.maxLevel and (tonumber(player.level) or 1) > conditions.maxLevel then return false end
    if conditions.faction and player.faction ~= conditions.faction then return false end
    if conditions.race and not self:ValueMatches(conditions.race, player.race) then return false end
    if conditions.class and not self:ValueMatches(conditions.class, player.class) then return false end
    if conditions.questCompleted and not self:IsQuestCompleted(conditions.questCompleted) then return false end
    if conditions.questActive and not self:IsQuestActive(conditions.questActive) then return false end
    if conditions.questNotCompleted and self:IsQuestCompleted(conditions.questNotCompleted) then return false end
    if conditions.previousStep and (not guide or not self:IsStepCompleted(guide.id, conditions.previousStep)) then return false end
    return true
end

function VG:AreConditionsMet(step, guide)
    return type(step) == "table" and self:EvaluateConditions(step.conditions, guide)
end

function VG:ValueMatches(expected, actual)
    if type(expected) == "table" then for _, value in ipairs(expected) do if value == actual then return true end end return false end
    return expected == actual
end

function VG:IsStepCompleted(guideID, index)
    local completed = self.db and self.db.completedSteps and self.db.completedSteps[guideID]
    return type(completed) == "table" and completed[index] == true or false
end

function VG:MarkStepCompleted(guideID, index)
    if not self.db or not guideID or type(index) ~= "number" then return end
    if type(self.db.completedSteps[guideID]) ~= "table" then self.db.completedSteps[guideID] = {} end
    self.db.completedSteps[guideID][index] = true
end

function VG:IsStepComplete(step)
    if type(step) ~= "table" then return false end
    if step.type == "ACCEPT_QUEST" then return self:IsQuestActive(step.questID) or self:IsQuestCompleted(step.questID) end
    if step.type == "COMPLETE_QUEST" or step.type == "TURNIN_QUEST" then return self:IsQuestCompleted(step.questID) end
    return false
end
