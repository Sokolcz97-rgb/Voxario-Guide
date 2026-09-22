local _, VG = ...

function VG:CreateGuideSelector()
    if self.UI.GuideSelector then return self.UI.GuideSelector end
    local frame = CreateFrame("Frame", "VoxarioGuideSelector", UIParent, "BackdropTemplate")
    frame:SetSize(360, 260); frame:SetPoint("CENTER"); frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); frame:Hide()
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); frame.title:SetPoint("TOP", 0, -18); frame.title:SetText(VG:T("SELECT_GUIDE"))
    frame.items = {}
    function frame:Refresh()
        for _, button in ipairs(self.items) do button:Hide() end
        local guides = {}
        for _, guide in pairs(VG.Guides) do table.insert(guides, guide) end
        table.sort(guides, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
        if #guides == 0 then
            frame.title:SetText(VG:T("NO_GUIDE_SELECTED"))
            return
        end
        frame.title:SetText(VG:T("SELECT_GUIDE"))
        for index, guide in ipairs(guides) do
            local button = self.items[index] or CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
            self.items[index] = button; button:SetSize(310, 36); button:SetPoint("TOP", 0, -48 - (index - 1) * 42)
            local range = string.format("%d–%d", guide.minLevel or 1, guide.maxLevel or 60)
            local availability = VG:GetGuideAvailability(guide, VG.Player)
            local label = availability == "recommended" and VG:T("RECOMMENDED") or (availability == "compatible" and VG:T("COMPATIBLE") or VG:T("UNAVAILABLE"))
            button:SetText("[" .. label .. "] " .. guide.name .. " (" .. range .. ")")
            button:SetEnabled(availability ~= "unavailable"); button:SetScript("OnClick", function() if VG:SelectGuide(guide.id) then self:Hide() end end); button:Show()
        end
    end
    self.UI.GuideSelector = frame
    return frame
end

function VG:ShowGuideSelector() local f = self:CreateGuideSelector(); f:Refresh(); f:Show() end
