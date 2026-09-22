local _, VG = ...

function VG:NormalizeFaction(value)
    if type(value) ~= "string" then return nil end
    local normalized = string.lower(value)
    if normalized == "horde" then return "Horde" end
    if normalized == "alliance" then return "Alliance" end
    return value
end

function VG:IsFactionCompatible(guideFaction, playerFaction)
    if not guideFaction then return true end
    return self:NormalizeFaction(guideFaction) == self:NormalizeFaction(playerFaction)
end

function VG:UpdatePlayerState()
    local _, class = UnitClass("player")
    local raceName, race = UnitRace("player")
    local faction = self:NormalizeFaction(UnitFactionGroup("player"))
    self.Player = {
        name = UnitName("player"), level = UnitLevel("player") or 1, class = class,
        race = race or raceName, faction = faction, mapID = self:GetPlayerMapID(),
    }
    return self.Player
end

function VG:GetPlayerMapID()
    -- TODO VERIFY FOREVER API: C_Map.GetBestMapForUnit is expected on Mainline-style clients.
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, mapID = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and mapID then return mapID end
    end
    if not C_Map then return nil, "C_Map is unavailable" end
    if not C_Map.GetBestMapForUnit then return nil, "C_Map.GetBestMapForUnit is unavailable" end
    return nil, "C_Map.GetBestMapForUnit returned nil for player"
end
