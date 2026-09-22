local _, VG = ...

function VG:InitializeZoneScanner() self.ZoneScanner = self.db.zoneScanner; return self.ZoneScanner end
function VG:GetZone(mapID)
    mapID = tonumber(mapID); if not mapID then return nil end
    return (VG.Zones and VG.Zones[mapID]) or (self.ZoneScanner and self.ZoneScanner.maps[mapID])
end
function VG:GetZoneName(mapID) local z = self:GetZone(mapID); return z and z.name end
function VG:GetZoneParent(mapID) local z = self:GetZone(mapID); return z and z.parentMapID end
function VG:GetZoneChildren(mapID) local z = self:GetZone(mapID); return z and z.children or {} end

function VG:ScanZoneRoot(rootID)
    local scanner = self:InitializeZoneScanner(); rootID = tonumber(rootID)
    if not rootID or not C_Map or not C_Map.GetMapInfo then self:Warn(self:T("SCAN_FAILED")); return false end
    local visited, count, limit = {}, 0, 1000
    local function scan(mapID, depth)
        if visited[mapID] or count >= limit or depth > 32 then return end
        visited[mapID] = true
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if not ok or type(info) ~= "table" then return end
        count = count + 1
        local record = scanner.maps[mapID] or { mapID = mapID, source = "wow_api", verified = true }
        record.name, record.mapType, record.parentMapID = info.name, info.mapType, info.parentMapID
        record.children = {}
        scanner.maps[mapID] = record
        -- TODO VERIFY FOREVER API: child-query signature is guarded; unsupported clients simply retain this map.
        if C_Map.GetMapChildrenInfo then
            local childOK, children = pcall(C_Map.GetMapChildrenInfo, mapID)
            if childOK and type(children) == "table" then for _, child in ipairs(children) do if child and tonumber(child.mapID) then table.insert(record.children, child.mapID); scan(child.mapID, depth + 1) end end end
        end
    end
    scan(rootID, 0); scanner.roots[rootID] = true; scanner.lastScan = time(); self:Info(string.format("%s: %d", self:T("SCAN_COMPLETE"), count)); return count > 0
end
function VG:ScanCurrentZone() local context, reason = self:GetCurrentMapContext(); if not context or not context.mapID then self:Warn((self:T("SCAN_FAILED")) .. ": " .. tostring(reason)); return false end; return self:ScanZoneRoot(context.mapID) end
function VG:ShowZoneStatus()
    local s = self:InitializeZoneScanner(); local maps, roots = 0, 0; for _ in pairs(s.maps) do maps = maps + 1 end; for _ in pairs(s.roots) do roots = roots + 1 end
    self:Info(string.format("%s | %s: %d | %s: %d", self:T("ZONE_SCANNER"), self:T("MAPS_DISCOVERED"), maps, self:T("ROOTS_SCANNED"), roots))
end
function VG:FindZones(query)
    query = string.lower(query or ""); if query == "" then self:Warn("Usage: /vg zones find <name>"); return end
    local matches = 0; for id, zone in pairs(self:InitializeZoneScanner().maps) do if type(zone.name) == "string" and string.find(string.lower(zone.name), query, 1, true) then self:Info(string.format("%s: %s | type %s | parent %s | scanned", id, zone.name, zone.mapType or "?", zone.parentMapID or "?")); matches = matches + 1; if matches >= 20 then break end end end
    if matches == 0 then self:Info(self:T("ZONE_NOT_FOUND")) end
end
function VG:ValidateZones()
    local errors = 0; for id, z in pairs(self:InitializeZoneScanner().maps) do if tonumber(id) ~= tonumber(z.mapID) or type(z.name) ~= "string" or z.parentMapID == z.mapID then errors = errors + 1 end end; self:Info(string.format("%s: %d errors", self:T("ZONE_DATABASE"), errors))
end
function VG:ShowMapAPIDiagnostics()
    local map = C_Map; self:Info("Map API Diagnostics | C_Map: " .. (type(map) == "table" and "available" or "unavailable"))
    for _, name in ipairs({ "GetBestMapForUnit", "GetPlayerMapPosition", "GetMapInfo", "GetMapChildrenInfo" }) do self:Info(name .. ": " .. (map and type(map[name]) or "unavailable")) end
    if map and type(map.GetBestMapForUnit) == "function" then local ok, value = pcall(map.GetBestMapForUnit, "player"); self:Info("GetBestMapForUnit(player): " .. (ok and tostring(value) or "error")) end
    local mapID = self:GetPlayerMapID()
    if mapID then
        local x, y, reason, shape = self:GetPlayerCoordinates(mapID)
        self:Info("GetPlayerMapPosition(" .. mapID .. ", player): " .. (x and ("success | " .. shape .. " | " .. self:FormatCoordinates(x, y)) or ("unavailable | " .. tostring(reason))))
    end
    local context, reason = self:GetCurrentMapContext(); self:Info("Current map context: " .. (context and tostring(context.mapID) or "nil") .. (reason and (" | " .. reason) or ""))
end
