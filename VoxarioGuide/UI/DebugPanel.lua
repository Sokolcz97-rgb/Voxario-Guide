local _, VG = ...
function VG:ShowDebugStatus()
    local step, guide = self:GetCurrentStep()
    local currentStep = guide and self:NormalizeCurrentStep(guide) or "?"
    local total = self:GetGuideStepCount(guide)
    local recorder = self.Recorder or {}
    self:Info(string.format("Voxario Guide %s | Guide: %s | Step: %s/%s (%s) | Player: L%s %s %s %s | Map: %s | Recorder: %s (%s steps)", self.Version, guide and guide.name or "none", currentStep, total, step and step.type or "complete", self.Player.level or "?", self.Player.faction or "?", self.Player.race or "?", self.Player.class or "?", self.Player.mapID or "?", recorder.active and "ON" or "OFF", type(recorder.steps) == "table" and #recorder.steps or 0))
end
