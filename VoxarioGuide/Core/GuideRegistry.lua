local _, VG = ...
VG.Guides = VG.Guides or {}

function VG:RegisterGuide(guide)
    if type(guide) ~= "table" or not guide.id or type(guide.steps) ~= "table" then
        self:Error("Rejected invalid guide registration")
        return false
    end
    self.Guides[guide.id] = guide
    return true
end

function VG:GetGuide(id) return self.Guides[id] end

function VG:GetCompatibleGuides(player)
    local results = {}
    for _, guide in pairs(self.Guides) do
        local factionOK = not guide.faction or guide.faction == player.faction
        local levelOK = (not guide.minLevel or player.level >= guide.minLevel) and (not guide.maxLevel or player.level <= guide.maxLevel)
        if factionOK and levelOK then table.insert(results, guide) end
    end
    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end
