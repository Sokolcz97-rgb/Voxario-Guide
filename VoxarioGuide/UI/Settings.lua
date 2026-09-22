local _, VG = ...

function VG:CreateSettings()
    if self.UI.Settings then return self.UI.Settings end
    local frame = CreateFrame("Frame", "VoxarioGuideSettings", UIParent, "BackdropTemplate")
    frame:SetSize(250, 150); frame:SetPoint("CENTER", 200, 0); frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); frame:Hide()
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); title:SetPoint("TOP", 0, -16); title:SetText(VG:T("SETTINGS"))
    frame.lock = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"); frame.lock:SetPoint("TOPLEFT", 16, -46); frame.lock:SetChecked(VG.db.settings.locked); frame.lock:SetScript("OnClick", function(b) VG.db.settings.locked = b:GetChecked() end)
    frame.lockLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); frame.lockLabel:SetPoint("LEFT", frame.lock, "RIGHT", 2, 0); frame.lockLabel:SetText(VG:T("LOCKED"))
    frame.scaleDown = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"); frame.scaleDown:SetSize(80, 22); frame.scaleDown:SetPoint("BOTTOMLEFT", 16, 16); frame.scaleDown:SetText("Scale −"); frame.scaleDown:SetScript("OnClick", function() VG.db.settings.scale = math.max(.7, VG.db.settings.scale - .1); VG.UI.GuideFrame:SetScale(VG.db.settings.scale) end)
    frame.scaleUp = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"); frame.scaleUp:SetSize(80, 22); frame.scaleUp:SetPoint("LEFT", frame.scaleDown, "RIGHT", 8, 0); frame.scaleUp:SetText("Scale +"); frame.scaleUp:SetScript("OnClick", function() VG.db.settings.scale = math.min(1.5, VG.db.settings.scale + .1); VG.UI.GuideFrame:SetScale(VG.db.settings.scale) end)
    self.UI.Settings = frame; return frame
end
function VG:ToggleSettings() local f = self:CreateSettings(); if f:IsShown() then f:Hide() else f:Show() end end
