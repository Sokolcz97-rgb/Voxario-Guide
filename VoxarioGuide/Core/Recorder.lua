local _, VG = ...

local function ensureTable(parent, key)
    if type(parent[key]) ~= "table" then parent[key] = {} end
    return parent[key]
end

function VG:InitializeRecorder(stopOnLogin)
    local recorder = ensureTable(self.db, "recorder")
    if type(recorder.active) ~= "boolean" then recorder.active = false end
    if stopOnLogin then recorder.active = false end
    ensureTable(recorder, "steps")
    ensureTable(recorder, "recordedQuestEvents")
    ensureTable(recorder, "questTitles")
    recorder.sequence = tonumber(recorder.sequence) or #recorder.steps
    if recorder.sequence ~= recorder.sequence or recorder.sequence < 0 then recorder.sequence = #recorder.steps end
    self.Recorder = recorder
    return recorder
end

function VG:GetRecorderLocation()
    local mapID = self:GetPlayerMapID()
    if not mapID then return nil end
    local x, y = self:GetPlayerCoordinates(mapID)
    if not x then return nil end
    return mapID, x, y
end

function VG:GetRecorderPlayerContext()
    self:UpdatePlayerState()
    return {
        level = self.Player.level,
        faction = self.Player.faction,
        race = self.Player.race,
        class = self.Player.class,
    }
end

function VG:RecordStep(step)
    local recorder = self.Recorder
    if not recorder or not recorder.active or type(step) ~= "table" then return false end
    recorder.sequence = (tonumber(recorder.sequence) or 0) + 1
    step.recordedAt = time()
    step.recordedOrder = recorder.sequence
    step.recordedBy = self:GetRecorderPlayerContext()
    table.insert(recorder.steps, step)
    if self.UI.RecorderIndicator then self.UI.RecorderIndicator:Refresh() end
    self:Debug("Recorder stored " .. tostring(step.type))
    return true
end

function VG:StartRecording()
    local recorder = self:InitializeRecorder()
    recorder.active = true
    recorder.startedAt = recorder.startedAt or time()
    recorder.startedLevel = self:UpdatePlayerState().level
    recorder.faction = self.Player.faction
    if self.UI.RecorderIndicator then self.UI.RecorderIndicator:Refresh() end
    self:Info("Recorder started.")
end

function VG:StopRecording()
    local recorder = self:InitializeRecorder()
    recorder.active = false
    if self.UI.RecorderIndicator then self.UI.RecorderIndicator:Refresh() end
    self:Info("Recorder stopped. Steps: " .. #recorder.steps)
end

function VG:ClearRecording()
    local recorder = self:InitializeRecorder()
    recorder.active = false
    recorder.steps, recorder.recordedQuestEvents, recorder.questTitles = {}, {}, {}
    recorder.sequence, recorder.startedAt, recorder.startedLevel, recorder.faction = 0, nil, nil, nil
    if self.UI.RecorderIndicator then self.UI.RecorderIndicator:Refresh() end
    self:Info("Recorder data cleared.")
end

function VG:ShowRecordingStatus()
    local recorder = self:InitializeRecorder()
    self:Info(string.format("Recorder: %s | steps: %d", recorder.active and "active" or "stopped", #recorder.steps))
end

function VG:GetQuestTitleForRecording(questLogIndex, questID)
    local recorder = self:InitializeRecorder()
    local title = recorder.questTitles[questID]
    if not title and C_QuestLog and C_QuestLog.GetInfo and questLogIndex then
        local ok, info = pcall(C_QuestLog.GetInfo, questLogIndex)
        if ok and type(info) == "table" then title = info.title end
    end
    if type(title) == "string" and title ~= "" then recorder.questTitles[questID] = title; return title end
    return nil
end

function VG:RecordQuestEvent(kind, questID, questLogIndex)
    local recorder = self.Recorder
    questID = tonumber(questID)
    if not recorder or not recorder.active or not questID then return end
    local recorded = ensureTable(recorder.recordedQuestEvents, kind)
    if recorded[questID] then return end
    recorded[questID] = true

    local mapID, x, y = self:GetRecorderLocation()
    local title = self:GetQuestTitleForRecording(questLogIndex, questID)
    local step = { type = kind, questID = questID }
    if title then
        local verb = kind == "ACCEPT_QUEST" and "Accept" or (kind == "COMPLETE_QUEST" and "Complete" or "Turn in")
        step.text = { enUS = verb .. ": " .. title }
    end
    if mapID then step.mapID, step.x, step.y = mapID, x, y end
    self:RecordStep(step)
end

function VG:RecordQuestCompletions()
    local recorder = self.Recorder
    if not recorder or not recorder.active or not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not C_QuestLog.GetInfo then return end
    -- TODO VERIFY FOREVER API: guarded Mainline quest-log scan, invoked only on QUEST_LOG_UPDATE.
    local ok, count = pcall(C_QuestLog.GetNumQuestLogEntries)
    if not ok or type(count) ~= "number" then return end
    for index = 1, count do
        local infoOK, info = pcall(C_QuestLog.GetInfo, index)
        if infoOK and type(info) == "table" and info.questID and info.isComplete and not info.isHeader then
            self:RecordQuestEvent("COMPLETE_QUEST", info.questID, index)
        end
    end
end

function VG:RecordWaypoint(note)
    local recorder = self.Recorder
    if not recorder or not recorder.active then self:Warn("Start the recorder before creating a waypoint."); return false end
    local mapID, x, y = self:GetRecorderLocation()
    if not mapID then self:Warn("Player position is unavailable; waypoint was not recorded."); return false end
    local step = { type = "GO_TO", mapID = mapID, x = x, y = y }
    if note and note ~= "" then step.text = { enUS = note } end
    return self:RecordStep(step)
end

function VG:RecordNote(note)
    if not note or note == "" then self:Warn("Usage: /vg note <text>"); return false end
    if not self.Recorder or not self.Recorder.active then self:Warn("Start the recorder before adding a note."); return false end
    return self:RecordStep({ type = "NOTE", text = { enUS = note } })
end

function VG:OnRecorderEvent(event, ...)
    if not self.Recorder or not self.Recorder.active then return end
    if event == "QUEST_ACCEPTED" then
        local questLogIndex, questID = ...
        self:RecordQuestEvent("ACCEPT_QUEST", questID, questLogIndex)
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        self:RecordQuestEvent("TURNIN_QUEST", questID)
    elseif event == "QUEST_LOG_UPDATE" then
        self:RecordQuestCompletions()
    end
end
