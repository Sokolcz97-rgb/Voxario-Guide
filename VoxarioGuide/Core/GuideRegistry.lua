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
    player = type(player) == "table" and player or {}
    local results = {}
    for _, guide in pairs(self.Guides) do
        local factionOK = not guide.faction or guide.faction == player.faction
        local level = tonumber(player.level) or 1
        local levelOK = (not guide.minLevel or level >= guide.minLevel) and (not guide.maxLevel or level <= guide.maxLevel)
        if factionOK and levelOK then table.insert(results, guide) end
    end
    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end

function VG:GetGuideAvailability(guide, player)
    if type(guide) ~= "table" then return "unavailable" end
    if guide.category == "development" then return "development" end
    player = type(player) == "table" and player or {}
    local level = tonumber(player.level) or 1
    if (guide.faction and guide.faction ~= player.faction) or (guide.minLevel and level < guide.minLevel) or (guide.maxLevel and level > guide.maxLevel) then return "unavailable" end
    if guide.race and not self:ValueMatches(guide.race, player.race) then return "unavailable" end
    if guide.class and not self:ValueMatches(guide.class, player.class) then return "unavailable" end
    if guide.previousGuide and not (self.db and self.db.guideComplete and self.db.guideComplete[guide.previousGuide]) then return "compatible" end
    return "recommended"
end
