source(g_currentModDirectory .. 'scripts/hud/MachineHUDDisplay.lua')

---@class MachineHUD
---@field vehicle Machine | nil
---@field isDirty boolean
---@field display MachineHUDDisplay
MachineHUD = {}

MachineHUD.XML_FILENAME = g_currentModDirectory .. 'xml/gui/hud/MachineHUD.xml'

local MachineHUD_mt = Class(MachineHUD)

---@return MachineHUD
---@nodiscard
function MachineHUD.new()
    ---@type MachineHUD
    local self = setmetatable({}, MachineHUD_mt)

    self.isDirty = false
    self.display = MachineHUDDisplay.new()

    return self
end

function MachineHUD:delete()
    g_messageCenter:unsubscribeAll(self)
    g_currentMission:removeDrawable(self)
    g_currentMission:removeUpdateable(self)

    self.display:delete()
    self.display = nil
end

function MachineHUD:reload()
    self:delete()
    self.display = MachineHUDDisplay.new()
    self:load()
    self:activate()
    self.vehicle = g_machineManager:getActiveVehicle()
    self.display:updateDisplay()
end

function MachineHUD:load()
    local xmlFile = XMLFile.load('machineHud', MachineHUD.XML_FILENAME)

    if xmlFile == nil then
        Logging.error('MachineHUD:loadHUD() Failed to load HUD file "%s"', MachineHUD.XML_FILENAME)
        return
    end

    self.display:loadFromXMLFile(xmlFile, 'HUD.HudElement')

    xmlFile:delete()
end

function MachineHUD:activate()
    g_messageCenter:subscribe(MessageType.ACTIVE_MACHINE_CHANGED, self.onActiveMachineChanged, self)

    g_messageCenter:subscribe(SetActiveEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetEnabledEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetFillTypeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetInputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetOutputModeEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetTerrainLayerEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetSurveyorEvent, self.onMachineUpdated, self)
    g_messageCenter:subscribe(SetSurveyorCalibrationEvent, self.onSurveyorChanged, self)

    g_currentMission:addDrawable(self)
    g_currentMission:addUpdateable(self)
end

---@param surveyor Surveyor
function MachineHUD:onSurveyorChanged(surveyor)
    if self.vehicle ~= nil then
        local surveyorId = self.vehicle:getSurveyorId()

        if surveyorId ~= nil and surveyorId == surveyor:getSurveyorId() then
            self.isDirty = true
        end
    end
end

---@param vehicle Machine | nil
function MachineHUD:onActiveMachineChanged(vehicle)
    self.vehicle = vehicle
    self.display:updateDisplay()
end

---@param vehicle Machine | nil
function MachineHUD:onMachineUpdated(vehicle)
    if self.vehicle ~= nil and self.vehicle == vehicle then
        self.isDirty = true
    end
end

function MachineHUD:onMapLoaded()
    if g_client ~= nil then
        self:activate()
    end
end

function MachineHUD:draw()
    if self.vehicle ~= nil and g_settings:getIsEnabled() and self.vehicle:getMachineEnabled() then
        self.display:draw()
    end
end

---@param dt number
function MachineHUD:update(dt)
    if self.display ~= nil then
        if self.isDirty then
            self.display:updateDisplay()

            self.isDirty = false
        end

        self.display:update(dt)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_machineHUD = MachineHUD.new()
