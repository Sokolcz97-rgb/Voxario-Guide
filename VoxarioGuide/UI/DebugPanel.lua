local _, VG = ...
function VG:ShowDebugStatus()
    local step, guide = self:GetCurrentStep()
    local currentStep = guide and self:NormalizeCurrentStep(guide) or "?"
    local total = self:GetGuideStepCount(guide)
    local recorder = self.Recorder or {}
    local compatibility, reason = "none", "no guide"
    if guide then compatibility, reason = self:GetGuideCompatibility(guide, self.Player) end
    self:Info(string.format("Voxario Guide %s | Guide: %s [%s/%s: %s] | Step: %s/%s (%s) | Player Faction: %s | Guide Faction: %s | Player: L%s %s %s | Map: %s | DevMode: %s | Recorder: %s (%s steps)", self.Version, guide and guide.name or "none", guide and guide.category or "none", compatibility, reason, currentStep, total, step and step.type or "complete", self.Player.faction or "?", guide and guide.faction or "none", self.Player.level or "?", self.Player.race or "?", self.Player.class or "?", self.Player.mapID or "?", self.db.settings.devMode and "ON" or "OFF", recorder.active and "ON" or "OFF", type(recorder.steps) == "table" and #recorder.steps or 0))
end
