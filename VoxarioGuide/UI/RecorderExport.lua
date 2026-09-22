local _, VG = ...

local function quote(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\"):gsub("\r", "\\r"):gsub("\n", "\\n"):gsub("\"", "\\\"")
    return "\"" .. value .. "\""
end

local function stepToLua(step)
    local lines = { "        {", "            type = " .. quote(step.type) .. "," }
    local questID, mapID = tonumber(step.questID), tonumber(step.mapID)
    if questID then table.insert(lines, "            questID = " .. questID .. ",") end
    if mapID then table.insert(lines, "            mapID = " .. mapID .. ",") end
    if type(step.x) == "number" then table.insert(lines, string.format("            x = %.6f,", step.x)) end
    if type(step.y) == "number" then table.insert(lines, string.format("            y = %.6f,", step.y)) end
    if step.text and step.text.enUS then table.insert(lines, "            text = { enUS = " .. quote(step.text.enUS) .. " },") end
    table.insert(lines, "        },")
    return table.concat(lines, "\n")
end

function VG:BuildRecorderExport()
    local recorder = self:InitializeRecorder()
    local faction = recorder.faction or self.Player.faction
    local minLevel = tonumber(recorder.startedLevel)
    local routeID = "RECORDED_" .. (faction and string.upper((faction:gsub("[^%w]", "_"))) or "ROUTE") .. "_" .. tostring(recorder.startedAt or time())
    local lines = {
        "local _, VG = ...", "", "VG:RegisterGuide({",
        "    id = " .. quote(routeID) .. ",", "    name = " .. quote(faction and ("Recorded " .. faction .. " Route") or "Recorded Route") .. ",",
    }
    if faction then table.insert(lines, "    faction = " .. quote(faction) .. ",") end
    if minLevel then table.insert(lines, "    minLevel = " .. minLevel .. ",") end
    table.insert(lines, "    steps = {")
    for _, step in ipairs(recorder.steps) do table.insert(lines, stepToLua(step)) end
    table.insert(lines, "    },"); table.insert(lines, "})")
    return table.concat(lines, "\n")
end

function VG:CreateRecorderExportFrame()
    if self.UI.RecorderExport then return self.UI.RecorderExport end
    local frame = CreateFrame("Frame", "VoxarioGuideRecorderExport", UIParent, "BackdropTemplate")
    frame:SetSize(580, 450); frame:SetPoint("CENTER"); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving); frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12 }); frame:Hide()
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); title:SetPoint("TOP", 0, -16); title:SetText("Voxario Recorder Export")
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT", 18, -45); scroll:SetPoint("BOTTOMRIGHT", -32, 18)
    local edit = CreateFrame("EditBox", nil, scroll); edit:SetMultiLine(true); edit:SetAutoFocus(false); if ChatFontNormal then edit:SetFontObject(ChatFontNormal) end; edit:SetWidth(510); edit:SetHeight(360); edit:SetTextInsets(6, 6, 6, 6); edit:SetScript("OnEscapePressed", function() frame:Hide() end)
    scroll:SetScrollChild(edit); frame.edit = edit
    self.UI.RecorderExport = frame
    return frame
end

function VG:ShowRecorderExport()
    local frame = self:CreateRecorderExportFrame()
    frame.edit:SetText(self:BuildRecorderExport()); frame.edit:SetHeight(math.max(360, frame.edit:GetStringHeight() + 20)); frame.edit:HighlightText(); frame:Show()
end
