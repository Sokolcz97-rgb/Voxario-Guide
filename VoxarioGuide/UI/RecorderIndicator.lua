local _, VG = ...

function VG:CreateRecorderIndicator()
    if self.UI.RecorderIndicator then return self.UI.RecorderIndicator end
    local frame = CreateFrame("Frame", "VoxarioGuideRecorderIndicator", UIParent, "BackdropTemplate")
    frame:SetSize(76, 24); frame:SetPoint("TOP", UIParent, "TOP", 0, -82)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 10 })
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); frame.text:SetAllPoints()
    function frame:Refresh()
        local recorder = VG.Recorder
        if recorder and recorder.active then self.text:SetText("|cffff4040REC|r " .. #recorder.steps); self:Show() else self:Hide() end
    end
    self.UI.RecorderIndicator = frame
    frame:Refresh()
    return frame
end
