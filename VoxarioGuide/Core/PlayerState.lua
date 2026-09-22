local _, VG = ...

function VG:UpdatePlayerState()
    local _, class = UnitClass("player")
    local raceName, race = UnitRace("player")
    local faction = UnitFactionGroup("player")
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
        if ok then return mapID end
    end
    return nil
end
