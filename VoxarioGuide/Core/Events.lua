local _, VG = ...
local eventFrame = CreateFrame("Frame")

local refreshEvents = {
    PLAYER_ENTERING_WORLD = true, QUEST_ACCEPTED = true, QUEST_TURNED_IN = true,
    QUEST_REMOVED = true, QUEST_LOG_UPDATE = true, PLAYER_LEVEL_UP = true,
    ZONE_CHANGED = true, ZONE_CHANGED_NEW_AREA = true,
}

function VG:RefreshFromGameState()
    self:UpdatePlayerState()
    self:RefreshQuestState()
    self:EvaluateCurrentStep()
end

function VG:OnLogin()
    self:InitializeDatabase()
    self:UpdatePlayerState()
    self:RefreshQuestState()
    self:CreateGuideFrame()
    self:CreateNavigationArrow()
    if self.db.selectedGuide and self:GetGuide(self.db.selectedGuide) then
        if not self:SelectGuide(self.db.selectedGuide) then self:ShowGuideSelector() end
    else
        self:ShowGuideSelector()
    end
    self:Info("Loaded " .. self.Version)
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
for eventName in pairs(refreshEvents) do eventFrame:RegisterEvent(eventName) end
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then VG:SafeCall("Initialization", VG.OnLogin, VG)
    elseif VG.db then VG:SafeCall("State refresh after " .. event, VG.RefreshFromGameState, VG) end
end)

SLASH_VOXARIOGUIDE1 = "/vg"
SLASH_VOXARIOGUIDE2 = "/voxarioguide"
SlashCmdList.VOXARIOGUIDE = function(message)
    local command = string.lower((message or ""):match("^%s*(%S*)") or "")
    if command == "guides" then VG:ShowGuideSelector()
    elseif command == "reset" then VG:ResetCurrentGuide(); VG:Info(VG:T("RESET_GUIDE"))
    elseif command == "debug" then VG.db.settings.debug = not VG.db.settings.debug; VG:Info("Debug " .. (VG.db.settings.debug and "enabled" or "disabled"))
    elseif command == "status" then VG:ShowDebugStatus()
    elseif command == "version" then VG:Info(VG.Version)
    else local frame = VG:CreateGuideFrame(); if frame:IsShown() then frame:Hide() else frame:Show(); frame:Refresh() end end
end
