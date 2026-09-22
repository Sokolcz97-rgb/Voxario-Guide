local _, VG = ...

local function quote(value)
    value = tostring(value or "")
    return '"' .. value:gsub("\\", "\\\\"):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub('"', '\\"') .. '"'
end

function VG:BuildZoneExport(scannedMaps)
    local maps = scannedMaps or self:GetScannedMaps()
    local ids, seen = {}, {}
    for key, zone in pairs(maps) do
        local mapID = tonumber(key)
        if mapID and type(zone) == "table" and not seen[mapID] then
            seen[mapID] = true
            table.insert(ids, mapID)
        end
    end
    table.sort(ids)

    local lines = { "return {" }
    for _, mapID in ipairs(ids) do
        local zone = maps[mapID] or maps[tostring(mapID)]
        local mapType, parent = tonumber(zone.mapType), tonumber(zone.parentMapID)
        table.insert(lines, string.format("    [%d] = { mapID = %d, name = %s, mapType = %s, parentMapID = %s, source = %s },", mapID, mapID, quote(zone.name), tostring(mapType or "nil"), tostring(parent or "nil"), quote(zone.source or "wow_api")))
    end
    table.insert(lines, "}")
    local export = table.concat(lines, "\n")
    self:Debug("Exporter maps: " .. #ids)
    self:Debug("Export generated: " .. #export .. " bytes")
    return export
end

function VG:CreateZoneExportFrame()
    if self.UI.ZoneExport then return self.UI.ZoneExport end
    local frame = CreateFrame("Frame", "VoxarioGuideZoneExport", UIParent, "BackdropTemplate")
    frame:SetSize(580, 450); frame:SetPoint("CENTER")
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 })
    frame:Hide()
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -20); scroll:SetPoint("BOTTOMRIGHT", -32, 18)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true); edit:SetAutoFocus(false)
    if ChatFontNormal then edit:SetFontObject(ChatFontNormal) elseif STANDARD_TEXT_FONT then edit:SetFont(STANDARD_TEXT_FONT, 12, "") end
    edit:SetWidth(510); edit:SetHeight(380); edit:SetTextInsets(6, 6, 6, 6)
    edit:EnableMouse(true)
    edit:SetScript("OnMouseUp", function(self) self:SetFocus() end)
    edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    scroll:SetScrollChild(edit)
    frame.edit = edit
    self.UI.ZoneExport = frame
    return frame
end

function VG:ShowZoneExport()
    local maps = self:GetScannedMaps()
    if not next(maps) then self:Warn("No scanned zone data available. Run /vg zones scan current or /vg zones scan <mapID> first."); return end
    local export = self:BuildZoneExport(maps)
    if type(export) ~= "string" or export == "" then self:Warn("Zone export could not be generated."); return end
    local frame = self:CreateZoneExportFrame()
    frame.edit:SetText(export)
    frame:Show(); frame.edit:SetFocus(); frame.edit:HighlightText()
    self:Debug("Zone export window displayed")
    self:Debug("Export edit box text: " .. #(frame.edit:GetText() or "") .. " bytes")
end
