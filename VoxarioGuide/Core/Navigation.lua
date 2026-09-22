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
    local mapID = self:GetPlayerMapID()
    if not mapID or not C_Map or not C_Map.GetPlayerMapPosition then return nil end
    local ok, position = pcall(C_Map.GetPlayerMapPosition, "player", mapID)
    if not ok or not position or type(position.x) ~= "number" or type(position.y) ~= "number" then return nil end
    return mapID, position.x, position.y
end

function VG:ShowNavigationStatus()
    local point = self:GetWaypoint()
    if not point then self:Info(self:T("NO_WAYPOINT")); return end
    self:Info(string.format("%s: active | MapID: %s | %s | %s", self:T("NAVIGATION"), point.mapID, self:GetWaypointText() or "?", point.label or self:T("WAYPOINT")))
end
function VG:ShowCurrentLocation()
    local mapID, x, y = self:GetNavigationLocation()
    if not mapID then self:Warn(self:T("LOCATION_UNAVAILABLE")); return end
    self:Info(string.format("%s: MapID %s | %s", self:T("CURRENT_LOCATION"), mapID, self:FormatCoordinates(x, y)))
end
function VG:SetNavigationHere()
    local mapID, x, y = self:GetNavigationLocation()
    if not mapID then self:Warn(self:T("LOCATION_UNAVAILABLE")); return false end
    return self:SetWaypoint(mapID, x, y, self:T("CURRENT_LOCATION"))
end
