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
    frame:SetScript("OnDragStop", function(f) local point, _, relativePoint, x, y = f:GetPoint(); f:StopMovingOrSizing(); VG.db.position = { point = point, relativePoint = relativePoint, x = x, y = y } end)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    frame:SetBackdropColor(0.04, 0.06, 0.10, 0.96)
    frame:SetScale(self.db.settings.scale)
    if self.db.position then frame:ClearAllPoints(); frame:SetPoint(self.db.position.point, UIParent, self.db.position.relativePoint, self.db.position.x, self.db.position.y) end
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); frame.title:SetPoint("TOPLEFT", 16, -14); frame.title:SetText(self:T("TITLE"))
    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.subtitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -5)
    frame.counter = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.counter:SetPoint("TOPRIGHT", -16, -20)
    frame.stepType = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); frame.stepType:SetPoint("TOPLEFT", 16, -64)
    frame.stepScroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate"); frame.stepScroll:SetPoint("TOPLEFT", 14, -82); frame.stepScroll:SetPoint("BOTTOMRIGHT", -28, 48); frame.stepScroll:EnableMouseWheel(true)
    frame.stepContent = CreateFrame("Frame", nil, frame.stepScroll); frame.stepContent:SetWidth(278); frame.stepContent:SetHeight(180); frame.stepScroll:SetScrollChild(frame.stepContent)
    frame.stepScroll:SetScript("OnMouseWheel", function(scroll, delta) local current, maximum = scroll:GetVerticalScroll() or 0, scroll:GetVerticalScrollRange() or 0; scroll:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * 24))) end)
    frame.instruction = frame.stepContent:CreateFontString(nil, "OVERLAY", "GameFontNormal"); frame.instruction:SetPoint("TOPLEFT", 2, -2); frame.instruction:SetPoint("TOPRIGHT", -2, -2); frame.instruction:SetJustifyH("LEFT"); frame.instruction:SetJustifyV("TOP")
    frame.details = frame.stepContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.details:SetPoint("TOPLEFT", 2, -115); frame.details:SetPoint("TOPRIGHT", -2, -115); frame.details:SetJustifyH("LEFT")
    frame.state = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.state:SetPoint("TOPRIGHT", -16, -45); frame.state:SetText("")
    frame.waypoint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.waypoint:SetPoint("BOTTOMLEFT", 16, 42)
    frame.previous = MakeButton(frame, "<", 34, function() VG:PreviousStep() end); frame.previous:SetPoint("BOTTOMLEFT", 14, 12)
    frame.skip = MakeButton(frame, self:T("SKIP_STEP"), 90, function() VG:RequestSkip() end); frame.skip:SetPoint("LEFT", frame.previous, "RIGHT", 6, 0)
    frame.next = MakeButton(frame, ">", 34, function() VG:NextStep() end); frame.next:SetPoint("LEFT", frame.skip, "RIGHT", 6, 0)
    frame.settings = MakeButton(frame, "…", 30, function() VG:ToggleSettings() end); frame.settings:SetPoint("BOTTOMRIGHT", -14, 12)
    frame.minimize = MakeButton(frame, "−", 24, function() VG:ToggleGuideMinimized() end); frame.minimize:SetPoint("TOPRIGHT", -12, -12)
    frame.choose = MakeButton(frame, self:T("CHOOSE_GUIDE"), 120, function() VG:ShowGuideSelector() end); frame.choose:SetPoint("BOTTOMLEFT", 145, 12); frame.choose:Hide()
    frame.restart = MakeButton(frame, self:T("RESTART_GUIDE"), 120, function() VG:ResetCurrentGuide() end); frame.restart:SetPoint("BOTTOMLEFT", 14, 12); frame.restart:Hide()
    frame.startNext = MakeButton(frame, self:T("START_NEXT_GUIDE"), 120, function() local nextGuide = VG:GetNextGuide(); if nextGuide then VG:SelectGuide(nextGuide.id) end end); frame.startNext:SetPoint("BOTTOMLEFT", 145, 12); frame.startNext:Hide()
    function frame:Refresh() VG.UI:RefreshMainFrame() end
    self.UI.GuideFrame = frame
    self:ApplyGuideMinimizedState()
    return frame
end

function VG:ApplyGuideMinimizedState()
    local frame = self.UI.GuideFrame
    if not frame or not self.db then return end
    local minimized = self.db.settings.minimized == true
    local widgets = { frame.subtitle, frame.counter, frame.stepType, frame.instruction, frame.details, frame.state, frame.waypoint, frame.previous, frame.skip, frame.next, frame.settings, frame.choose, frame.restart, frame.startNext }
    for _, widget in ipairs(widgets) do if minimized then widget:Hide() else widget:Show() end end
    frame:SetHeight(minimized and 42 or 230)
    frame.minimize:SetText(minimized and "+" or "−")
    if not minimized then frame:Refresh() end
end

function VG:ToggleGuideMinimized()
    self.db.settings.minimized = not self.db.settings.minimized
    self:ApplyGuideMinimizedState()
end

function VG.UI:RefreshMainFrame()
    local frame, step, guide = self.GuideFrame, VG:GetCurrentStep()
    if not frame then return end
    local stepCount = VG:GetGuideStepCount(guide)
    frame.choose:Hide(); frame.restart:Hide(); frame.startNext:Hide(); frame.previous:Show(); frame.skip:Show(); frame.next:Show(); frame.state:SetText("")
    if not guide or stepCount == 0 then
        frame.subtitle:SetText(VG:T("NO_GUIDE_SELECTED")); frame.counter:SetText(""); frame.stepType:SetText(""); frame.instruction:SetText(VG:T("NO_GUIDE_SELECTED")); frame.details:SetText(""); frame.waypoint:SetText("")
        frame.previous:Hide(); frame.skip:Hide(); frame.next:Hide(); frame.choose:Show(); return
    end
    frame.subtitle:SetText(string.format("%s • %s", guide.name or VG:T("TITLE"), guide.faction or VG:T("DEVELOPMENT")))
    local currentStep = VG:NormalizeCurrentStep(guide)
    frame.counter:SetText(VG:T("STEP", currentStep, stepCount))
    local section = step and step.section and guide.sections and guide.sections[step.section]
    if section then frame.state:SetText(VG:T("SECTION") .. ": " .. section) end
    if VG:IsGuidePaused() then frame.state:SetText(VG:T("PAUSED")) end
    if VG:IsGuideComplete(guide) then step = nil end
    if not step then
        frame.stepType:SetText(VG:T("GUIDE_COMPLETE")); frame.instruction:SetText(VG:T("GUIDE_COMPLETE")); frame.details:SetText(""); frame.waypoint:SetText("")
        frame.previous:Show(); frame.skip:Hide(); frame.next:Hide(); frame.restart:Show(); frame.choose:Show()
        local nextGuide = VG:GetNextGuide(guide); if nextGuide then frame.startNext:Show(); frame.choose:Hide(); frame.state:SetText(VG:T("NEXT_GUIDE") .. ": " .. (nextGuide.name or nextGuide.id)) end
        return
    end
    frame.stepType:SetText(step.type or "NOTE")
    local text = step.text and (step.text[VG:GetLocale()] or step.text.enUS) or step.instruction or ""
    frame.instruction:SetText(text)
    frame.details:SetText((step.optional and (VG:T("OPTIONAL") .. " • ") or "") .. (step.npc and ("NPC: " .. step.npc) or ""))
    local point = VG:GetWaypointText(); frame.waypoint:SetText(point and VG:T("WAYPOINT", point) or "")
end

function VG:RequestSkip()
    local step = self:GetCurrentStep()
    if step and step.important and StaticPopup_Show then
        StaticPopupDialogs["VOXARIO_SKIP"] = { text = self:T("IMPORTANT_SKIP"), button1 = self:T("YES"), button2 = self:T("NO"), OnAccept = function() VG:SkipStep() end, timeout = 0, whileDead = true, hideOnEscape = true }
        StaticPopup_Show("VOXARIO_SKIP")
    else self:SkipStep() end
end
