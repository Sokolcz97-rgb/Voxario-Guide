local _, VG = ...

local function countMaps(maps) local count = 0; for _ in pairs(maps or {}) do count = count + 1 end; return count end
local function validZone(mapID, zone) return tonumber(mapID) and type(zone) == "table" and type(zone.name) == "string" and zone.name ~= "" end

function VG:InitializeZoneScanner() self.ZoneScanner = self.db.zoneScanner; return self.ZoneScanner end
function VG:GetScannedMaps()
    local scanner = self:InitializeZoneScanner()
    if type(scanner.maps) ~= "table" then scanner.maps = {} end
    return scanner.maps
end
function VG:GetMergedZones()
    local merged = {}
    for id, zone in pairs(VG.Zones or {}) do if validZone(id, zone) then merged[tonumber(id)] = zone end end
    for id, zone in pairs(self:GetScannedMaps()) do
        local mapID = tonumber(id)
        if validZone(mapID, zone) then
            local verified = zone.source == "wow_api" and zone.verified == true
            if merged[mapID] and not verified then
                self:Debug("Zone merge conflict for mapID " .. mapID .. "; keeping static record because runtime data is not verified")
            else
                if merged[mapID] and merged[mapID] ~= zone then self:Debug("Zone merge conflict for mapID " .. mapID .. "; using verified runtime record") end
                merged[mapID] = zone
            end
        end
    end
    return merged
end
function VG:GetZone(mapID) mapID = tonumber(mapID); return mapID and self:GetMergedZones()[mapID] or nil end
function VG:GetZoneName(mapID) local z = self:GetZone(mapID); return z and z.name end
function VG:GetZoneParent(mapID) local z = self:GetZone(mapID); return z and tonumber(z.parentMapID) or nil end
function VG:GetZoneChildren(mapID)
    mapID = tonumber(mapID); if not mapID then return {} end
    local children = {}; for id, zone in pairs(self:GetMergedZones()) do if tonumber(zone.parentMapID) == mapID then table.insert(children, id) end end; table.sort(children); return children
end

function VG:StoreScannedMap(mapID)
    mapID = tonumber(mapID); if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if not ok or type(info) ~= "table" or type(info.name) ~= "string" or info.name == "" then return nil end
    local maps = self:GetScannedMaps()
    local record = maps[mapID] or { mapID = mapID, source = "wow_api", verified = true }
    record.mapID, record.name, record.mapType, record.parentMapID = mapID, info.name, tonumber(info.mapType), tonumber(info.parentMapID) or 0
    record.source, record.verified = "wow_api", true
    maps[mapID] = record
    self:Debug("ZoneScanner stored mapID: " .. mapID)
    return record
end

function VG:RebuildScannedChildren()
    local maps = self:GetScannedMaps()
    for _, zone in pairs(maps) do if type(zone) == "table" then zone.children = {} end end
    for id, zone in pairs(maps) do
        local parent = tonumber(zone and zone.parentMapID)
        if parent and parent ~= 0 and maps[parent] and parent ~= tonumber(id) then table.insert(maps[parent].children, tonumber(id)) end
    end
    for _, zone in pairs(maps) do if type(zone) == "table" and zone.children then table.sort(zone.children) end end
end

function VG:ScanZoneTree(rootID)
    rootID = tonumber(rootID)
    if not rootID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then self:Warn(self:T("SCAN_FAILED")); return false end
    local root = self:StoreScannedMap(rootID)
    if not root then self:Warn(self:T("SCAN_FAILED") .. ": invalid root map") return false end
    self:Info("Scanning: " .. root.name .. " | MapID: " .. rootID)
    local visited, discovered, limit = {}, { rootID }, 1000
    visited[rootID] = true
    local mode = "direct children"
    if type(C_Map.GetMapChildrenInfo) == "function" then
        local ok, descendants = pcall(C_Map.GetMapChildrenInfo, rootID, nil, true)
        if ok and type(descendants) == "table" then
            mode = "all descendants"
            for _, child in ipairs(descendants) do local id = child and tonumber(child.mapID); if id and not visited[id] and #discovered < limit then visited[id] = true; table.insert(discovered, id) end end
        else self:Debug("GetMapChildrenInfo(root, nil, true) unavailable; using direct-child recursion") end
    end
    if mode == "direct children" then
        local cursor = 1
        while cursor <= #discovered and #discovered < limit do
            local parentID = discovered[cursor]; cursor = cursor + 1
            if C_Map and type(C_Map.GetMapChildrenInfo) == "function" then
                local ok, children = pcall(C_Map.GetMapChildrenInfo, parentID)
                if ok and type(children) == "table" then for _, child in ipairs(children) do local id = child and tonumber(child.mapID); if id and not visited[id] and #discovered < limit then visited[id] = true; table.insert(discovered, id) end end end
            end
        end
    end
    local stored = 0
    for _, mapID in ipairs(discovered) do if self:StoreScannedMap(mapID) then stored = stored + 1 end end
    self:RebuildScannedChildren()
    local scanner = self:InitializeZoneScanner(); scanner.roots[rootID] = true; scanner.lastScan = time(); scanner.lastRoot = rootID; scanner.lastScanCount = stored; scanner.lastScanMode = mode
    self:Debug("ZoneScanner mode: " .. mode .. " | runtime maps: " .. countMaps(self:GetScannedMaps()) .. " | saved maps: " .. countMaps(self.db.zoneScanner.maps))
    if #discovered >= limit then self:Warn("Zone scan reached safety limit of " .. limit .. " maps.") end
    self:Info(string.format("%s: %d", self:T("SCAN_COMPLETE"), stored)); return stored > 0
end

function VG:ScanZoneRoot(rootID) return self:ScanZoneTree(rootID) end
function VG:ScanCurrentZone() local context, reason = self:GetCurrentMapContext(); if not context or not context.mapID then self:Warn((self:T("SCAN_FAILED")) .. ": " .. tostring(reason)); return false end; return self:ScanZoneTree(context.mapID) end

function VG:GetMapAncestors(mapID)
    mapID = tonumber(mapID); if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then return nil, "Current map is unavailable" end
    local chain, visited = {}, {}
    for _ = 1, 32 do
        if visited[mapID] then return chain, "ancestor cycle detected" end
        visited[mapID] = true
        local ok, info = pcall(C_Map.GetMapInfo, mapID)
        if not ok or type(info) ~= "table" then return chain, "GetMapInfo failed for mapID " .. mapID end
        table.insert(chain, { mapID = mapID, name = info.name or "Unavailable", mapType = tonumber(info.mapType), parentMapID = tonumber(info.parentMapID) or 0 })
        local parent = tonumber(info.parentMapID) or 0
        if parent == 0 then return chain end
        mapID = parent
    end
    return chain, "ancestor safety limit reached"
end

function VG:ShowZoneAncestors()
    local mapID, reason = self:GetPlayerMapID(); if not mapID then self:Warn(reason or self:T("LOCATION_UNAVAILABLE")); return end
    local chain, warning = self:GetMapAncestors(mapID)
    if not chain or #chain == 0 then self:Warn(warning or "No map ancestors available") return end
    local labels = {}; for _, entry in ipairs(chain) do table.insert(labels, entry.name .. " (" .. entry.mapID .. ")") end
    self:Info("Ancestors: " .. table.concat(labels, " -> "))
    if warning then self:Debug(warning) end
end

function VG:ScanCurrentHierarchy()
    local mapID, reason = self:GetPlayerMapID(); if not mapID then self:Warn(reason or self:T("LOCATION_UNAVAILABLE")); return false end
    local chain, warning = self:GetMapAncestors(mapID); if not chain or #chain == 0 then self:Warn(warning or "No hierarchy root available") return false end
    local root
    for index = #chain, 1, -1 do if chain[index].mapType and chain[index].mapType ~= 0 then root = chain[index]; break end end
    if not root then self:Warn("Hierarchy root is too broad; use /vg zones scan tree <mapID> after /vg zones ancestors.") return false end
    self:Info("Scanning current hierarchy from: " .. root.name .. " | MapID: " .. root.mapID)
    return self:ScanZoneTree(root.mapID)
end

function VG:ShowZoneStatus()
    local scanner, runtime, static, merged = self:InitializeZoneScanner(), self:GetScannedMaps(), countMaps(VG.Zones), self:GetMergedZones()
    self:Info(string.format("%s | Static: %d | Runtime: %d | Merged: %d | Last root: %s | Last scan: %s", self:T("ZONE_SCANNER"), static, countMaps(runtime), countMaps(merged), tostring(scanner.lastRoot or "none"), tostring(scanner.lastScanCount or 0)))
end
function VG:FindZones(query)
    query = string.lower(query or ""); if query == "" then self:Warn("Usage: /vg zones find <name>"); return end
    local matches = 0; for id, zone in pairs(self:GetMergedZones()) do if string.find(string.lower(zone.name), query, 1, true) then self:Info(string.format("%s: %s | type %s | parent %s | %s", id, zone.name, zone.mapType or "?", zone.parentMapID or "?", zone.source or "static")); matches = matches + 1; if matches >= 20 then break end end end
    if matches == 0 then self:Info(self:T("ZONE_NOT_FOUND")) end
end
function VG:ValidateZones()
    local errors, merged = 0, self:GetMergedZones()
    for id, zone in pairs(merged) do
        if not validZone(id, zone) or tonumber(zone.mapID) ~= id or (zone.parentMapID ~= nil and not tonumber(zone.parentMapID)) or (zone.mapType ~= nil and not tonumber(zone.mapType)) or tonumber(zone.parentMapID) == id then errors = errors + 1 end
        local seen, parent = {}, tonumber(zone.parentMapID)
        while parent and parent ~= 0 and merged[parent] do if seen[parent] then errors = errors + 1; break end; seen[parent] = true; parent = tonumber(merged[parent].parentMapID) end
    end
    self:Info(string.format("%s: %d structural errors | static %d | runtime %d", self:T("ZONE_DATABASE"), errors, countMaps(VG.Zones), countMaps(self:GetScannedMaps())))
end
function VG:ShowMapAPIDiagnostics()
    local map = C_Map; self:Info("Map API Diagnostics | C_Map: " .. (type(map) == "table" and "available" or "unavailable"))
    for _, name in ipairs({ "GetBestMapForUnit", "GetPlayerMapPosition", "GetMapInfo", "GetMapChildrenInfo" }) do self:Info(name .. ": " .. (map and type(map[name]) or "unavailable")) end
    local mapID = self:GetPlayerMapID(); if mapID and map and type(map.GetMapChildrenInfo) == "function" then local ok, value = pcall(map.GetMapChildrenInfo, mapID, nil, true); self:Info("GetMapChildrenInfo(" .. mapID .. ", nil, true): " .. (ok and type(value) or "error")) end
end
