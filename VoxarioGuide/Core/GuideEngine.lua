local _, VG = ...

function VG:GetGuideStepCount(guide)
    if type(guide) ~= "table" or type(guide.steps) ~= "table" then return 0 end
    return #guide.steps
end

-- This is the only place that normalizes the persisted current-step value.
-- It writes the result back, so UI and engine share one source of truth.
function VG:NormalizeCurrentStep(guide)
    if not self.db then return 1, false end
    local count = self:GetGuideStepCount(guide)
    local currentStep = tonumber(self.db.currentStep) or 1
    if currentStep ~= currentStep or currentStep == math.huge or currentStep == -math.huge then currentStep = 1 end
    currentStep = math.floor(currentStep)
    if currentStep < 1 then currentStep = 1 end
    if count > 0 and currentStep > count then currentStep = count end
    self.db.currentStep = currentStep
    return currentStep, count > 0
end

function VG:ClearInvalidGuide(guide)
    if not self.db then return end
    self:Warn("Guide has no valid steps: " .. tostring(guide and guide.id or self.db.selectedGuide))
    self.db.selectedGuide = nil
    self.db.currentStep = 1
    self:SetWaypoint(nil)
    if self.ShowGuideSelector then self:ShowGuideSelector() end
end

function VG:SelectGuide(guideID)
    local guide = self:GetGuide(guideID)
    if not guide or self:GetGuideStepCount(guide) == 0 then
        self:ClearInvalidGuide(guide)
        return false
    end
    local isNewSelection = self.db.selectedGuide ~= guideID
    if isNewSelection then self.db.currentStep = 1 end
    self.db.selectedGuide = guideID
    if isNewSelection then self.db.guideComplete[guideID] = false end
    self:NormalizeCurrentStep(guide)
    self:EvaluateCurrentStep()
    return true
end

function VG:GetCurrentGuide()
    return self.db and self:GetGuide(self.db.selectedGuide) or nil
end

function VG:GetCurrentStep()
    local guide = self:GetCurrentGuide()
    if self:GetGuideStepCount(guide) == 0 then return nil, guide end
    local currentStep = self:NormalizeCurrentStep(guide)
    return guide.steps[currentStep], guide
end

function VG:IsGuideComplete(guide)
    return self.db and guide and self.db.guideComplete and self.db.guideComplete[guide.id] == true or false
end

function VG:RefreshCurrentStepUI()
    local step, guide = self:GetCurrentStep()
    if self:IsGuideComplete(guide) then step = nil end
    self:SetWaypoint(step)
    if self.UI.GuideFrame then self.UI.GuideFrame:Refresh() end
end

function VG:EvaluateCurrentStep()
    if not self.db then return end
    local guide = self:GetCurrentGuide()
    local count = self:GetGuideStepCount(guide)
    if count == 0 then
        if guide or self.db.selectedGuide then self:ClearInvalidGuide(guide) else self:RefreshCurrentStepUI() end
        return
    end

    local currentStep = self:NormalizeCurrentStep(guide)
    if self:IsGuideComplete(guide) then self:RefreshCurrentStepUI(); return end

    local step = guide.steps[currentStep]
    while step and (not self:AreConditionsMet(step, guide) or self:IsStepComplete(step)) do
        self:MarkStepCompleted(guide.id, currentStep)
        if currentStep >= count then
            self.db.guideComplete[guide.id] = true
            break
        end
        currentStep = currentStep + 1
        self.db.currentStep = currentStep
        step = guide.steps[currentStep]
    end
    self:RefreshCurrentStepUI()
end

function VG:AdvanceStep(isSkip)
    local step, guide = self:GetCurrentStep()
    local count = self:GetGuideStepCount(guide)
    if not guide or count == 0 or not step or self:IsGuideComplete(guide) then return false end

    local currentStep = self:NormalizeCurrentStep(guide)
    self:MarkStepCompleted(guide.id, currentStep)
    if isSkip then
        self.db.manualSkipHistory[#self.db.manualSkipHistory + 1] = { guideID = guide.id, step = currentStep, time = time() }
    end
    if currentStep < count then
        self.db.currentStep = currentStep + 1
    else
        self.db.guideComplete[guide.id] = true
    end
    self:EvaluateCurrentStep()
    return true
end

function VG:NextStep() return self:AdvanceStep(false) end
function VG:SkipStep() return self:AdvanceStep(true) end

function VG:PreviousStep()
    local guide = self:GetCurrentGuide()
    local count = self:GetGuideStepCount(guide)
    if not guide or count == 0 then return false end

    local currentStep = self:NormalizeCurrentStep(guide)
    self.db.guideComplete[guide.id] = false
    if currentStep > 1 then self.db.currentStep = currentStep - 1 end
    self:RefreshCurrentStepUI()
    return true
end

function VG:ResetCurrentGuide()
    local guide = self:GetCurrentGuide()
    if not guide or self:GetGuideStepCount(guide) == 0 then return false end
    self.db.currentStep = 1
    self.db.completedSteps[guide.id] = {}
    self.db.guideComplete[guide.id] = false
    self:EvaluateCurrentStep()
    return true
end
