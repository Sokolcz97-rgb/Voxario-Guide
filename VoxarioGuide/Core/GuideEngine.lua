local _, VG = ...

function VG:SelectGuide(guideID)
    local guide = self:GetGuide(guideID)
    if not guide then return false end
    self.db.selectedGuide = guideID
    self.db.currentStep = math.max(1, self.db.currentStep or 1)
    self:EvaluateCurrentStep()
    return true
end

function VG:GetCurrentGuide() return self.db and self:GetGuide(self.db.selectedGuide) end
function VG:GetCurrentStep()
    local guide = self:GetCurrentGuide()
    return guide and guide.steps[self.db.currentStep], guide
end

function VG:EvaluateCurrentStep()
    if not self.db then return end
    local step, guide = self:GetCurrentStep()
    while step and (not self:AreConditionsMet(step, guide) or self:IsStepComplete(step)) do
        self:MarkStepCompleted(guide.id, self.db.currentStep)
        self.db.currentStep = self.db.currentStep + 1
        step = guide.steps[self.db.currentStep]
    end
    self:SetWaypoint(step)
    if self.UI.GuideFrame then self.UI.GuideFrame:Refresh() end
end

function VG:AdvanceStep(manual)
    local step, guide = self:GetCurrentStep()
    if not step then return end
    self:MarkStepCompleted(guide.id, self.db.currentStep)
    if manual then self.db.manualSkipHistory[#self.db.manualSkipHistory + 1] = { guideID = guide.id, step = self.db.currentStep, time = time() } end
    self.db.currentStep = math.min(self.db.currentStep + 1, #guide.steps + 1)
    self:EvaluateCurrentStep()
end

function VG:PreviousStep()
    if self.db.currentStep > 1 then self.db.currentStep = self.db.currentStep - 1; self:EvaluateCurrentStep() end
end

function VG:ResetCurrentGuide()
    local guide = self:GetCurrentGuide()
    if not guide then return end
    self.db.currentStep, self.db.completedSteps[guide.id] = 1, {}
    self:EvaluateCurrentStep()
end
