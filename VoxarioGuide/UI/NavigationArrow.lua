local _, VG = ...

function VG:CreateNavigationArrow()
    local frame = CreateFrame("Frame", "VoxarioGuideNavigationArrow", UIParent, "BackdropTemplate")
    frame:SetSize(120, 42); frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight") ; frame.text:SetAllPoints(); frame:Hide()
    function frame:Refresh()
        local point = VG:GetWaypointText()
        if not point then self:Hide(); return end
        local distance = VG:GetWaypointDistance()
        self.text:SetText(distance and string.format("➜ %s (%.0f)", point, distance) or ("➜ " .. point))
        self:Show()
    end
    self.UI.NavigationArrow = frame
    return frame
end
