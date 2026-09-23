local _, VG = ...

local function count(tableValue) local total = 0; for _ in pairs(tableValue or {}) do total = total + 1 end; return total end
local function search(records, query, idField)
    local id = tonumber(query); if id then return records[id] and { records[id] } or {} end
    local matches, needle = {}, string.lower(query or "")
    for _, record in pairs(records or {}) do if type(record.name) == "string" and string.find(string.lower(record.name), needle, 1, true) then table.insert(matches, record) end end
    return matches
end
function VG:GetQuestData(questID) return (VG.Quests or {})[tonumber(questID)] end
function VG:FindQuestByName(query) return search(VG.Quests, query, "questID") end
function VG:GetQuestObjectives(questID) local quest = self:GetQuestData(questID); return quest and quest.objectives or {} end
function VG:GetQuestStartNPCs(questID) local quest = self:GetQuestData(questID); return quest and quest.starts or {} end
function VG:GetQuestEndNPCs(questID) local quest = self:GetQuestData(questID); return quest and quest.ends or {} end
function VG:GetNPC(npcID) return (VG.NPCs or {})[tonumber(npcID)] end
function VG:FindNPCByName(query) return search(VG.NPCs, query, "npcID") end
function VG:GetNPCLocations(npcID) local npc = self:GetNPC(npcID); return npc and npc.locations or {} end

function VG:ShowQuestData(query)
    local matches = search(VG.Quests, query, "questID")
    if #matches == 0 then self:Info("Quest not found in static database."); return end
    for index, quest in ipairs(matches) do if index > 10 then break end; self:Info(string.format("Quest %s: %s | level %s | %s | %s", quest.questID, quest.name, quest.level or "?", quest.faction or "any", quest.verification or "unverified")) end
end
function VG:ShowNPCData(query)
    local matches = search(VG.NPCs, query, "npcID")
    if #matches == 0 then self:Info("NPC not found in static database."); return end
    for index, npc in ipairs(matches) do if index > 10 then break end; self:Info(string.format("NPC %s: %s | level %s | locations %d | %s", npc.npcID, npc.name, npc.level or "?", #(npc.locations or {}), npc.verification or "unverified")) end
end
function VG:ShowDatabaseStatus()
    local quests, npcs, objectives, verified, pending = VG.Quests or {}, VG.NPCs or {}, 0, 0, 0
    for _, quest in pairs(quests) do objectives = objectives + #(quest.objectives or {}); if quest.verification == "verified" or quest.verification == "forever_client" then verified = verified + 1 else pending = pending + 1 end end
    for _, npc in pairs(npcs) do if npc.verification == "verified" or npc.verification == "forever_client" then verified = verified + 1 else pending = pending + 1 end end
    self:Info(string.format("Database | Zones: %d | Quests: %d | NPCs: %d | Items: %d | Objectives: %d | Verified: %d | Pending: %d", count(self:GetMergedZones()), count(quests), count(npcs), count(VG.Items), objectives, verified, pending))
end
function VG:ShowDatabaseCoverage()
    local names, zones, objectives, starts, ends, locations, rawPoi = 0, 0, 0, 0, 0, 0, 0
    for _, q in pairs(VG.Quests or {}) do
        if q.name then names=names+1 end; if q.zoneMapID then zones=zones+1 end
        if #(q.objectives or {})>0 then objectives=objectives+1 end; if #(q.starts or {})>0 then starts=starts+1 end; if #(q.ends or {})>0 then ends=ends+1 end
        for _, poi in ipairs(q.poi or {}) do if #(poi.rawPoints or {}) > 0 then rawPoi=rawPoi+1; break end end
    end
    for _, n in pairs(VG.NPCs or {}) do if #(n.locations or {})>0 then locations=locations+1 end end
    self:Info(string.format("Coverage | Quest records: %d | Names: %d | Zone-linked: %d | Objectives: %d | Starts: %d | Ends: %d | NPC locations: %d | Raw POI: %d", count(VG.Quests), names, zones, objectives, starts, ends, locations, rawPoi))
end
function VG:ValidateDataDatabase()
    local errors, warnings = 0, 0
    for id, quest in pairs(VG.Quests or {}) do
        if tonumber(id) ~= tonumber(quest.questID) or (quest.name ~= nil and (type(quest.name) ~= "string" or quest.name == "")) then errors = errors + 1 end
        if quest.minLevel and quest.level and tonumber(quest.minLevel) > tonumber(quest.level) then errors = errors + 1 end
        if quest.faction and self:NormalizeFaction(quest.faction) ~= "Horde" and self:NormalizeFaction(quest.faction) ~= "Alliance" then errors = errors + 1 end
        if quest.zoneMapID and not tonumber(quest.zoneMapID) then errors = errors + 1 end
        for _, npcID in ipairs(quest.starts or {}) do if not self:GetNPC(npcID) then warnings = warnings + 1 end end
        for _, npcID in ipairs(quest.ends or {}) do if not self:GetNPC(npcID) then warnings = warnings + 1 end end
        for _, objective in ipairs(quest.objectives or {}) do if type(objective) ~= "table" or type(objective.type) ~= "string" or (objective.count and tonumber(objective.count) and tonumber(objective.count) < 1) then errors = errors + 1 end end
    end
    for id, npc in pairs(VG.NPCs or {}) do
        if tonumber(id) ~= tonumber(npc.npcID) or type(npc.name) ~= "string" or npc.name == "" then errors = errors + 1 end
        for _, location in ipairs(npc.locations or {}) do if not tonumber(location.mapID) or (location.x or location.y) and not self:NormalizeCoordinates(location.x, location.y) then errors = errors + 1 end end
    end
    self:Info(string.format("Database validation: %d errors | %d reference warnings", errors, warnings))
end
