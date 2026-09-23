local _, VG = ...

local function truncate(text, limit)
    text = tostring(text or "")
    if #text > limit then return string.sub(text, 1, limit - 3) .. "..." end
    return text
end

function VG:CreateGuideSelector()
    if self.UI.GuideSelector then return self.UI.GuideSelector end
    local frame = CreateFrame("Frame", "VoxarioGuideSelector", UIParent, "BackdropTemplate")
    frame:SetSize(390, 300); frame:SetPoint("CENTER"); frame:SetClampedToScreen(true)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); frame:Hide()
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); frame.title:SetPoint("TOP", 0, -18); frame.title:SetText(VG:T("SELECT_GUIDE"))
    frame.scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    frame.scroll:SetPoint("TOPLEFT", 18, -45); frame.scroll:SetPoint("BOTTOMRIGHT", -32, 16); frame.scroll:EnableMouseWheel(true)
    frame.content = CreateFrame("Frame", nil, frame.scroll); frame.content:SetWidth(330); frame.content:SetHeight(1); frame.scroll:SetScrollChild(frame.content)
    frame.items = {}
    frame.scroll:SetScript("OnMouseWheel", function(scroll, delta)
        local current = scroll:GetVerticalScroll() or 0
        local maximum = scroll:GetVerticalScrollRange() or 0
        scroll:SetVerticalScroll(math.max(0, math.min(maximum, current - delta * 36)))
    end)
    function frame:Refresh()
        for _, row in ipairs(self.items) do row:Hide() end
        local guides = {}; for _, guide in pairs(VG.Guides) do table.insert(guides, guide) end
        table.sort(guides, function(a, b) return (a.priority or 0) == (b.priority or 0) and tostring(a.name) < tostring(b.name) or (a.priority or 0) > (b.priority or 0) end)
        if #guides == 0 then self.title:SetText(VG:T("NO_GUIDE_SELECTED")); self.content:SetHeight(1); return end
        self.title:SetText(VG:T("SELECT_GUIDE"))
        for index, guide in ipairs(guides) do
            local row = self.items[index]
            if not row then
                row = CreateFrame("Button", nil, self.content, "UIPanelButtonTemplate")
                row:SetSize(330, 44); row:SetText("")
                row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row.name:SetPoint("TOPLEFT", 8, -5); row.name:SetPoint("TOPRIGHT", -8, -5); row.name:SetJustifyH("LEFT")
                row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); row.meta:SetPoint("BOTTOMLEFT", 8, 5); row.meta:SetPoint("BOTTOMRIGHT", -8, 5); row.meta:SetJustifyH("LEFT")
                self.items[index] = row
            end
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -(index - 1) * 48)
            local availability, reason = VG:GetGuideCompatibility(guide, VG.Player)
            local label = availability == "development" and VG:T("DEVELOPMENT") or (availability == "recommended" and VG:T("RECOMMENDED") or (availability == "compatible" and VG:T("COMPATIBLE") or (availability == "overleveled" and VG:T("OVERLEVELED") or VG:T("UNAVAILABLE"))))
            local range = string.format("Level %d-%d", tonumber(guide.minLevel) or 1, tonumber(guide.maxLevel) or 60)
            row.name:SetText(truncate(guide.name, 42))
            local content = guide.contentStatus == "incomplete" and "Data incomplete" or (guide.contentStatus == "partial" and "Partial route" or "Ready")
            row.meta:SetText(truncate((guide.faction or VG:T("DEVELOPMENT")) .. " | " .. (guide.category or "guide") .. " | " .. range .. " | " .. content .. " | " .. label, 66))
            local guideID = guide.id
            row:SetEnabled(availability ~= "unavailable")
            row:SetScript("OnClick", function() if VG:SelectGuide(guideID) then self:Hide() end end)
            row:Show()
        end
        self.content:SetHeight(math.max(1, #guides * 48))
        self.scroll:SetVerticalScroll(0)
    end
    self.UI.GuideSelector = frame
    return frame
end

function VG:ShowGuideSelector() local frame = self:CreateGuideSelector(); frame:Refresh(); frame:Show() end
