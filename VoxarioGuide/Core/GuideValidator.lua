local _, VG = ...

function VG:ValidateGuide(guide)
    local errors, warnings, pending = 0, 0, 0
    if type(guide) ~= "table" or not guide.id or not guide.name or type(guide.steps) ~= "table" then return 1, 0, 0 end
    if guide.minLevel and guide.maxLevel and guide.minLevel > guide.maxLevel then errors = errors + 1 end
    if guide.faction and (self:NormalizeFaction(guide.faction) ~= "Horde" and self:NormalizeFaction(guide.faction) ~= "Alliance") then errors = errors + 1 end
    local seen = {}
    for index, step in ipairs(guide.steps) do
        if type(step) ~= "table" or not VG.StepTypes[step.type] then errors = errors + 1
        else
            if (step.type == "ACCEPT_QUEST" or step.type == "COMPLETE_QUEST" or step.type == "TURNIN_QUEST") and not tonumber(step.questID) then warnings = warnings + 1 end
            if (step.x or step.y) and (not step.mapID or not self:NormalizeCoordinates(step.x, step.y)) then errors = errors + 1 end
            if step.verification == "pending" then pending = pending + 1 end
            local key = step.type .. ":" .. tostring(step.questID); if seen[key] and step.questID then warnings = warnings + 1 end; seen[key] = true
        end
    end
    return errors, warnings, pending
end

function VG:ValidateRegisteredGuides()
    local count, errors, warnings, pending = 0, 0, 0, 0
    for _, guide in pairs(self.Guides) do
        local e, w, p = self:ValidateGuide(guide); count, errors, warnings, pending = count + 1, errors + e, warnings + w, pending + p
        self:Info(string.format("%s: %d steps | %d errors | %d warnings | %d pending", guide.name or "Invalid guide", self:GetGuideStepCount(guide), e, w, p))
    end
    self:Info(string.format("Validation: %d guides | %d errors | %d warnings | %d pending", count, errors, warnings, pending))
end
