local addonName, VG = ...

VG.Name = addonName
VG.Version = "0.2.0-alpha"
VG.Interface = 16001
VG.Modules = VG.Modules or {}
VG.L = VG.L or {}
VG.Player = VG.Player or {}
VG.QuestState = VG.QuestState or {}
VG.Navigation = VG.Navigation or {}
VG.UI = VG.UI or {}

function VG:Debug(message)
    if self.db and self.db.settings and self.db.settings.debug then
        print("|cff65d5ffVG Debug:|r " .. tostring(message))
    end
end

function VG:Info(message) print("|cff65d5ffVoxario Guide:|r " .. tostring(message)) end
function VG:Warn(message) print("|cffffc857VG Warning:|r " .. tostring(message)) end
function VG:Error(message) print("|cffff5c5cVG Error:|r " .. tostring(message)) end

function VG:InitializeDatabase()
    VoxarioGuideDB = VoxarioGuideDB or {}
    local db = VoxarioGuideDB
    if type(db.settings) ~= "table" then db.settings = {} end
    if db.settings.scale == nil then db.settings.scale = 1 end
    if db.settings.locked == nil then db.settings.locked = false end
    if db.settings.debug == nil then db.settings.debug = false end
    if type(db.completedSteps) ~= "table" then db.completedSteps = {} end
    if type(db.guideComplete) ~= "table" then db.guideComplete = {} end
    if type(db.manualSkipHistory) ~= "table" then db.manualSkipHistory = {} end
    local currentStep = tonumber(db.currentStep) or 1
    if currentStep ~= currentStep or currentStep == math.huge or currentStep == -math.huge then currentStep = 1 end
    currentStep = math.floor(currentStep)
    db.currentStep = math.max(1, currentStep)
    self.db = db
end

function VG:GetLocale()
    local locale = GetLocale and GetLocale() or "enUS"
    return self.L[locale] and locale or "enUS"
end

function VG:T(key, ...)
    local locale = self:GetLocale()
    local value = (self.L[locale] and self.L[locale][key]) or (self.L.enUS and self.L.enUS[key]) or key
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end
