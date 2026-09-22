local _, VG = ...

function VG:SetWaypoint(step)
    if step and step.mapID and step.x and step.y then self.Navigation.waypoint = { mapID = step.mapID, x = step.x, y = step.y } else self.Navigation.waypoint = nil end
    if self.UI.NavigationArrow then self.UI.NavigationArrow:Refresh() end
end

function VG:GetWaypointText()
    local point = self.Navigation.waypoint
    return point and self:FormatCoordinates(point.x, point.y) or nil
end

function VG:GetWaypointDistance()
    local point = self.Navigation.waypoint
    if not point or not C_Map or not C_Map.GetPlayerMapPosition then return nil end
    local mapID = self:GetPlayerMapID()
    if mapID ~= point.mapID then return nil end
    local ok, position = pcall(C_Map.GetPlayerMapPosition, "player", mapID)
    if not ok or not position then return nil end
    local dx, dy = point.x - position.x, point.y - position.y
    return math.sqrt(dx * dx + dy * dy) * 1000 -- relative map-unit estimate only
end
