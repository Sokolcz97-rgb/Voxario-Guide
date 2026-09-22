local _, VG = ...

function VG:NormalizeCoordinates(x, y)
    x, y = tonumber(x), tonumber(y)
    if not x or not y then return nil end
    if x > 1 or y > 1 then x, y = x / 100, y / 100 end -- Explicit percentage-coordinate support.
    if x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    return x, y
end

function VG:SetWaypoint(source, x, y, label)
    local mapID
    if type(source) == "table" then mapID, x, y, label = source.mapID, source.x, source.y, source.targetName or source.label or (source.text and source.text.enUS) else mapID = source end
    mapID, x, y = tonumber(mapID), self:NormalizeCoordinates(x, y)
    if not mapID or not x then return self:ClearWaypoint() end
    self.Navigation.waypoint = { mapID = mapID, x = x, y = y, label = type(label) == "string" and label or nil }
    if self.UI.NavigationArrow then self.UI.NavigationArrow:Refresh() end
    return true
end

function VG:ClearWaypoint()
    self.Navigation.waypoint = nil
    if self.UI.NavigationArrow then self.UI.NavigationArrow:Refresh() end
end

function VG:GetWaypoint() return self.Navigation and self.Navigation.waypoint or nil end
function VG:HasWaypoint() return self:GetWaypoint() ~= nil end
function VG:GetWaypointText() local point = self:GetWaypoint(); return point and self:FormatCoordinates(point.x, point.y) or nil end
function VG:GetWaypointDistance() return nil end -- TODO VERIFY FOREVER API: map coordinates are not yard distances.
function VG:GetWaypointDirection() return nil end -- TODO VERIFY FOREVER API: no verified facing conversion.

function VG:GetNavigationLocation()
    local context = self:GetCurrentMapContext()
    if not context then return nil end
    return context.mapID, context.x, context.y
end

-- Forever follows the C_Map signature (mapID, unit).  Keep this in one place so
-- navigation, location reporting, and recording cannot disagree about it.
function VG:GetPlayerCoordinates(mapID)
    mapID = tonumber(mapID)
    if not mapID then return nil, nil, "Player coordinates require a valid mapID" end
    if not C_Map or type(C_Map.GetPlayerMapPosition) ~= "function" then
        return nil, nil, "C_Map.GetPlayerMapPosition is unavailable"
    end

    local ok, position = pcall(C_Map.GetPlayerMapPosition, mapID, "player")
    if not ok then
        return nil, nil, "C_Map.GetPlayerMapPosition raised an error for mapID " .. mapID
    end
    if not position then
        return nil, nil, "C_Map.GetPlayerMapPosition returned nil for mapID " .. mapID
    end
    if type(position) ~= "table" or type(position.x) ~= "number" or type(position.y) ~= "number" then
        return nil, nil, "C_Map.GetPlayerMapPosition returned a value without numeric x/y for mapID " .. mapID
    end
    return position.x, position.y, nil, "vector x/y"
end

function VG:GetCurrentMapContext()
    local mapID, reason = self:GetPlayerMapID()
    if not mapID then return nil, reason end
    local context = { mapID = mapID }
    if C_Map and C_Map.GetMapInfo then local ok, info = pcall(C_Map.GetMapInfo, mapID); if ok and type(info) == "table" then context.mapInfo = info end end
    local x, y, coordinateReason = self:GetPlayerCoordinates(mapID)
    if not x then return context, coordinateReason end
    context.x, context.y = x, y
    return context
end

function VG:ShowNavigationStatus()
    local point = self:GetWaypoint()
    if not point then self:Info(self:T("NO_WAYPOINT")); return end
    self:Info(string.format("%s: active | MapID: %s | %s | %s", self:T("NAVIGATION"), point.mapID, self:GetWaypointText() or "?", point.label or self:T("WAYPOINT")))
end
function VG:ShowCurrentLocation()
    local context, reason = self:GetCurrentMapContext()
    if not context then self:Warn(reason or self:T("LOCATION_UNAVAILABLE")); return end
    local zone, info = self:GetZone(context.mapID), context.mapInfo
    self:Info(string.format("%s: MapID %s | %s | X/Y %s | type %s | parent %s | %s", self:T("CURRENT_LOCATION"), context.mapID, (zone and zone.name) or (info and info.name) or "Unavailable", context.x and self:FormatCoordinates(context.x, context.y) or "Unavailable", (zone and zone.mapType) or (info and info.mapType) or "Unavailable", (zone and zone.parentMapID) or (info and info.parentMapID) or "Unavailable", zone and zone.source or "unscanned"))
    if reason then self:Debug(reason) end
end
function VG:SetNavigationHere()
    local context, reason = self:GetCurrentMapContext()
    if not context or not context.x then
        self:Warn(context and ("Player coordinates unavailable for map " .. context.mapID .. ".") or self:T("LOCATION_UNAVAILABLE"))
        if reason then self:Debug(reason) end
        return false
    end
    return self:SetWaypoint(context.mapID, context.x, context.y, self:T("CURRENT_LOCATION"))
end
