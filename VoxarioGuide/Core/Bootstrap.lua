local addonName, VG = ...

VG.Name = addonName
VG.Version = "0.5.4-alpha"
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
    db.settings.scale = tonumber(db.settings.scale) or 1
    db.settings.scale = math.max(0.7, math.min(1.5, db.settings.scale))
    if type(db.settings.locked) ~= "boolean" then db.settings.locked = false end
    if type(db.settings.debug) ~= "boolean" then db.settings.debug = false end
    if type(db.settings.minimized) ~= "boolean" then db.settings.minimized = false end
    if type(db.settings.devMode) ~= "boolean" then db.settings.devMode = false end
    if type(db.settings.navigation) ~= "table" then db.settings.navigation = {} end
    if type(db.settings.navigation.showArrow) ~= "boolean" then db.settings.navigation.showArrow = true end
    if type(db.settings.navigation.showDistance) ~= "boolean" then db.settings.navigation.showDistance = true end
    if type(db.settings.navigation.autoCompleteGoTo) ~= "boolean" then db.settings.navigation.autoCompleteGoTo = false end
    if type(db.zoneScanner) ~= "table" then db.zoneScanner = {} end
    if type(db.zoneScanner.maps) ~= "table" then db.zoneScanner.maps = {} end
    if type(db.zoneScanner.roots) ~= "table" then db.zoneScanner.roots = {} end
    db.zoneScanner.lastRoot = tonumber(db.zoneScanner.lastRoot) or nil
    db.zoneScanner.lastScanCount = math.max(0, math.floor(tonumber(db.zoneScanner.lastScanCount) or 0))
    if type(db.zoneScanner.lastScanMode) ~= "string" then db.zoneScanner.lastScanMode = nil end
    if type(db.guidePaused) ~= "boolean" then db.guidePaused = false end
    if type(db.completedSteps) ~= "table" then db.completedSteps = {} end
    if type(db.guideComplete) ~= "table" then db.guideComplete = {} end
    if type(db.manualSkipHistory) ~= "table" then db.manualSkipHistory = {} end
    local currentStep = tonumber(db.currentStep) or 1
    if currentStep ~= currentStep or currentStep == math.huge or currentStep == -math.huge then currentStep = 1 end
    currentStep = math.floor(currentStep)
    db.currentStep = math.max(1, currentStep)
    if type(db.position) == "table" then
        local point = db.position.point or db.position[1]
        local relativePoint = db.position.relativePoint or db.position[3] or point
        local x, y = tonumber(db.position.x or db.position[4]), tonumber(db.position.y or db.position[5])
        local validPoints = { TOP = true, TOPLEFT = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true, BOTTOM = true, BOTTOMLEFT = true, BOTTOMRIGHT = true }
        if validPoints[point] and validPoints[relativePoint] and x and y then
            db.position = { point = point, relativePoint = relativePoint, x = x, y = y }
        else
            db.position = nil
        end
    else
        db.position = nil
    end
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
