local _, VG = ...
function VG:ShowDebugStatus()
    local step, guide = self:GetCurrentStep()
    local currentStep = guide and self:NormalizeCurrentStep(guide) or "?"
    self:Info(string.format("v%s | Interface %d | level %s | %s/%s | map %s | guide %s | step %s (%s) | quest %s | waypoint %s", self.Version, self.Interface, self.Player.level or "?", self.Player.race or "?", self.Player.class or "?", self.Player.mapID or "?", guide and guide.id or "none", currentStep, step and step.type or "none", step and step.questID or "none", self:GetWaypointText() or "none"))
end
