local _, VG = ...

function VG:CreateNavigationArrow()
    local frame = CreateFrame("Frame", "VoxarioGuideNavigationArrow", UIParent, "BackdropTemplate")
    frame:SetSize(190, 42); frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight") ; frame.text:SetAllPoints(); frame:Hide()
    function frame:Refresh()
        local waypoint = VG:GetWaypoint()
        if not waypoint or not VG.db.settings.navigation.showArrow then self:Hide(); return end
        local point = VG:GetWaypointText()
        local label = waypoint.label or VG:T("WAYPOINT")
        self.text:SetText(label .. ": " .. (point or "?"))
        self:Show()
    end
    self.UI.NavigationArrow = frame
    return frame
end
