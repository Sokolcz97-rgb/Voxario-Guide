local _, VG = ...

local function MakeButton(parent, text, width, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22); button:SetText(text); button:SetScript("OnClick", handler)
    return button
end

function VG:CreateGuideFrame()
    if self.UI.GuideFrame then return self.UI.GuideFrame end
    local frame = CreateFrame("Frame", "VoxarioGuideMainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(330, 230); frame:SetPoint("CENTER", 0, 80); frame:SetClampedToScreen(true); frame:SetMovable(true)
    frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(f) if not VG.db.settings.locked then f:StartMoving() end end)
    frame:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); VG.db.position = { f:GetPoint() } end)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.04, 0.06, 0.10, 0.96)
    frame:SetScale(self.db.settings.scale)
    if self.db.position then frame:ClearAllPoints(); frame:SetPoint(unpack(self.db.position)) end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); frame.title:SetPoint("TOPLEFT", 16, -14); frame.title:SetText(self:T("TITLE"))
    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.counter:SetPoint("TOPRIGHT", -16, -20)
    frame.stepType = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); frame.stepType:SetPoint("TOPLEFT", 16, -64)
    frame.instruction = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.instruction:SetPoint("TOPLEFT", 16, -88); frame.instruction:SetPoint("TOPRIGHT", -16, -88); frame.instruction:SetJustifyH("LEFT"); frame.instruction:SetJustifyV("TOP")
    frame.details = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.details:SetPoint("TOPLEFT", 16, -145); frame.details:SetPoint("TOPRIGHT", -16, -145); frame.details:SetJustifyH("LEFT")
    frame.waypoint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.waypoint:SetPoint("BOTTOMLEFT", 16, 42)
    frame.previous = MakeButton(frame, "<", 34, function() VG:PreviousStep() end); frame.previous:SetPoint("BOTTOMLEFT", 14, 12)
    frame.skip = MakeButton(frame, self:T("SKIP_STEP"), 90, function() VG:RequestSkip() end); frame.skip:SetPoint("LEFT", frame.previous, "RIGHT", 6, 0)
    frame.next = MakeButton(frame, ">", 34, function() VG:NextStep() end); frame.next:SetPoint("LEFT", frame.skip, "RIGHT", 6, 0)
    frame.settings = MakeButton(frame, "…", 30, function() VG:ToggleSettings() end); frame.settings:SetPoint("BOTTOMRIGHT", -14, 12)
    function frame:Refresh() VG.UI:RefreshMainFrame() end
    self.UI.GuideFrame = frame
    return frame
end

function VG.UI:RefreshMainFrame()
    local frame, step, guide = self.GuideFrame, VG:GetCurrentStep()
    if not frame then return end
    local stepCount = VG:GetGuideStepCount(guide)
    if not guide or stepCount == 0 then frame.subtitle:SetText(VG:T("NO_GUIDE")); frame.counter:SetText(""); frame.stepType:SetText(""); frame.instruction:SetText(""); frame.details:SetText(""); frame.waypoint:SetText(""); return end
    frame.subtitle:SetText(string.format("%s • %s", VG:T("LEVELING"), guide.faction or ""))
    local currentStep = VG:NormalizeCurrentStep(guide)
    frame.counter:SetText(VG:T("STEP", currentStep, stepCount))
    if VG:IsGuideComplete(guide) then step = nil end
    if not step then frame.stepType:SetText(VG:T("GUIDE_COMPLETE")); frame.instruction:SetText(""); frame.details:SetText(""); frame.waypoint:SetText(""); return end
    frame.stepType:SetText(step.type or "NOTE")
    local text = step.text and (step.text[VG:GetLocale()] or step.text.enUS) or step.instruction or ""
    frame.instruction:SetText(text)
    frame.details:SetText(step.npc and ("NPC: " .. step.npc) or "")
    local point = VG:GetWaypointText(); frame.waypoint:SetText(point and VG:T("WAYPOINT", point) or "")
end

function VG:RequestSkip()
    local step = self:GetCurrentStep()
    if step and step.important and StaticPopup_Show then
        StaticPopupDialogs["VOXARIO_SKIP"] = { text = self:T("IMPORTANT_SKIP"), button1 = self:T("YES"), button2 = self:T("NO"), OnAccept = function() VG:SkipStep() end, timeout = 0, whileDead = true, hideOnEscape = true }
        StaticPopup_Show("VOXARIO_SKIP")
    else self:SkipStep() end
end
