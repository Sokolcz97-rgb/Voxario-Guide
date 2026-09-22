local _, VG = ...
local function q(s) return '"' .. tostring(s or ""):gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub('"', '\\"') .. '"' end
function VG:BuildZoneExport()
    local ids, maps = {}, self:InitializeZoneScanner().maps; for id in pairs(maps) do table.insert(ids, tonumber(id)) end; table.sort(ids)
    local lines = { "return {" }; for _, id in ipairs(ids) do local z = maps[id]; local mapType, parent = tonumber(z.mapType), tonumber(z.parentMapID); table.insert(lines, string.format("    [%d] = { name = %s, mapType = %s, parentMapID = %s },", id, q(z.name), tostring(mapType or "nil"), tostring(parent or "nil"))) end; table.insert(lines, "}"); return table.concat(lines, "\n")
end
function VG:ShowZoneExport()
    if not next(self:InitializeZoneScanner().maps) then self:Warn("No scanned zone data available. Run /vg zones scan current or /vg zones scan <mapID> first."); return end
    if not self.UI.ZoneExport then local f = CreateFrame("Frame", "VoxarioGuideZoneExport", UIParent, "BackdropTemplate"); f:SetSize(580,450); f:SetPoint("CENTER"); f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:Hide(); local s=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate");s:SetPoint("TOPLEFT",18,-20);s:SetPoint("BOTTOMRIGHT",-32,18);local e=CreateFrame("EditBox",nil,s);e:SetMultiLine(true);e:SetAutoFocus(false);e:SetWidth(510);e:SetHeight(380);s:SetScrollChild(e);f.edit=e;self.UI.ZoneExport=f end
    local f=self.UI.ZoneExport;f.edit:SetText(self:BuildZoneExport());f.edit:HighlightText();f:Show()
end
