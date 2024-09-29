---@class MachineManager
---@field types table<string, MachineType>
---@field activeVehicle Machine | nil
---@field vehicles Machine[]
---@field surveyors Surveyor[]
---@field configurations table<string, string> -- <vehicleFile, xmlFilename>
MachineManager = {}

local MachineManager_mt = Class(MachineManager)

---@return MachineManager
---@nodiscard
function MachineManager.new()
    ---@type MachineManager
    local self = setmetatable({}, MachineManager_mt)

    self.types = {}
    self.vehicles = {}
    self.surveyors = {}
    self.configurations = {}

    if g_server ~= nil then
        addConsoleCommand('tfReloadConfigurations', '', 'consoleReloadConfigurations', self)
    end

    return self
end

---@param vehicle Machine | nil
function MachineManager:setActiveVehicle(vehicle)
    if self.activeVehicle ~= vehicle then
        self.activeVehicle = vehicle

        g_messageCenter:publish(MessageType.ACTIVE_MACHINE_CHANGED, vehicle)
    end
end

---@return Machine | nil
---@nodiscard
function MachineManager:getActiveVehicle()
    return self.activeVehicle
end

---@return Machine[]
---@nodiscard
function MachineManager:getAccessibleVehicles()
    ---@type Machine[]
    local result = {}

    if g_currentMission.isMasterUser then
        return table.copy(self.vehicles)
    end

    for _, vehicle in ipairs(self.vehicles) do
        if g_currentMission.accessHandler:canPlayerAccess(vehicle) then
            table.insert(result, vehicle)
        end
    end

    return result
end

---@return Surveyor[]
---@nodiscard
function MachineManager:getAccessibleSurveyors()
    return self.surveyors
end

---@param vehicle Machine
function MachineManager:registerVehicle(vehicle)
    -- g_machineDebug:debug('MachineManager:registerVehicle()')

    if not table.hasElement(self.vehicles, vehicle) then
        table.insert(self.vehicles, vehicle)

        -- g_machineDebug:debug('Registered vehicle: %s', vehicle:getFullName())
        g_messageCenter:publishDelayed(MessageType.MACHINE_ADDED, vehicle)
    end
end

---@param vehicle Machine
function MachineManager:unregisterVehicle(vehicle)
    if table.removeElement(self.vehicles, vehicle) then
        -- g_machineDebug:debug('Unregistered vehicle: %s', vehicle:getFullName())
        g_messageCenter:publish(MessageType.MACHINE_REMOVED, vehicle)
    end
end

---@param vehicle Surveyor
function MachineManager:registerSurveyor(vehicle)
    -- g_machineDebug:debug('MachineManager:registerSurveyor()')

    if not table.hasElement(self.surveyors, vehicle) then
        table.insert(self.surveyors, vehicle)

        g_messageCenter:publishDelayed(MessageType.SURVEYOR_ADDED, vehicle)
    end
end

---@param vehicle Surveyor
function MachineManager:unregisterSurveyor(vehicle)
    -- g_machineDebug:debug('MachineManager:unregisterSurveyor()')

    if table.removeElement(self.surveyors, vehicle) then
        g_messageCenter:publish(MessageType.SURVEYOR_REMOVED, vehicle)
    end
end

---@param id string
---@return Surveyor | nil
---@nodiscard
function MachineManager:getSurveyorById(id)
    if id ~= nil then
        for _, vehicle in ipairs(self.surveyors) do
            if vehicle:getSurveyorId() == id then
                return vehicle
            end
        end
    end
end

---@param xmlFilename string
---@param vehicleFile string
---@return boolean
function MachineManager:registerConfiguration(xmlFilename, vehicleFile)
    local wasAdded = false

    if self.configurations[vehicleFile] ~= nil then
        g_machineDebug:debug('Replaced existing machine configuration: %s', vehicleFile)
    else
        wasAdded = true
    end

    self.configurations[vehicleFile] = xmlFilename

    return wasAdded
end

---@param vehicleFile string
---@return string | nil xmlFilename
---@nodiscard
function MachineManager:getConfigurationXMLFilename(vehicleFile)
    return self.configurations[vehicleFile]
end

---@param xmlFilename string
---@param modEnv string
function MachineManager:loadConfigurationsFromXMLFile(xmlFilename, modEnv)
    ---@type XMLFile | nil
    local xmlFile = XMLFile.loadIfExists('machineConfigurations', xmlFilename)

    if xmlFile ~= nil then
        local baseDirectory = g_modNameToDirectory[modEnv]
        local numEntries = 0

        Logging.info('Loading machine configuration entries from "%s"', xmlFilename)

        xmlFile:iterate('configurations.configuration', function(_, key)
            local vehicleFile = xmlFile:getString(key .. '#vehicle')
            local configFile = xmlFile:getString(key .. '#file')

            if vehicleFile ~= nil and configFile ~= nil then
                self:registerConfiguration(baseDirectory .. configFile, vehicleFile)
                numEntries = numEntries + 1
            end
        end)

        xmlFile:delete()

        if numEntries > 0 then
            Logging.info('  Registered %i new machine configurations', numEntries)
        end
    else
        Logging.warning('Failed to load configurations file: %s', tostring(xmlFilename))
    end
end

function MachineManager:loadInternalConfigurations()
    self:loadConfigurationsFromXMLFile(Machine.MOD_CONFIGURATIONS_FILE, Machine.MOD_NAME)
end

function MachineManager:loadModsConfigurations()
    ---@type Mod[]
    local mods = g_modManager:getActiveMods()

    for _, mod in ipairs(mods) do
        if mod.modName ~= Machine.MOD_NAME then
            ---@type string | nil
            local xmlFilename

            if fileExists(mod.modDir .. 'machineConfigurations.xml') then
                xmlFilename = mod.modDir .. 'machineConfigurations.xml'
            elseif fileExists(mod.modDir .. 'xml/machineConfigurations.xml') then
                xmlFilename = mod.modDir .. 'xml/machineConfigurations.xml'
            end

            if xmlFilename ~= nil then
                self:loadConfigurationsFromXMLFile(xmlFilename, mod.modName)
            end
        end
    end
end

local modCollisionNames = {
    'FS22_TerraFarm',
    'FS22_TerraFarm_MCE',
    'FS22_Terrafarm16x',
    'FS22_TerraFarm_16x',
    'FS22_TerraFarm_V3',
    'FS22_1_TerraFarm',
}

function MachineManager:onModsLoaded()
    for _, modName in ipairs(modCollisionNames) do
        if g_modIsLoaded[modName] then
            Logging.error(' ** WARNING **  An older mod version of TerraFarm is loaded, please deactivate to prevent bugs. (%s) ** WARNING **', modName)
        end
    end

    self:loadInternalConfigurations()
    self:loadModsConfigurations()
end

function MachineManager:consoleReloadConfigurations()
    if g_server ~= nil and not g_currentMission.missionDynamicInfo.isMultiplayer then
        self.configurations = {}

        g_machineDebug:debug('Cleared all configuration entries')

        self:loadInternalConfigurations()
        self:loadModsConfigurations()

        return 'Mods configurations reloaded'
    end

    return 'Only available in single player'
end

--
-- Note: can be nil!
-- Omitted from return type because we only use it in MachineSpecialization:onLoad()
--
---@param id string
---@return MachineType
---@nodiscard
function MachineManager:getMachineTypeById(id)
    return self.types[id]
end

---@param type MachineType
function MachineManager:registerMachineType(type)
    if self.types[type.id] == nil then
        self.types[type.id] = type

        print(string.format("  Register machineType '%s'", type.id))
    else
        Logging.warning('Duplicate machine type ID: %s', type.id)
    end
end

---@param dt number
function MachineManager:update(dt)
    if g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil then
        self:setActiveVehicle(MachineUtils.getActiveVehicle(g_currentMission.controlledVehicle))
    else
        self:setActiveVehicle(nil)
    end
end

function MachineManager:onMapLoaded()
    if g_client ~= nil then
        g_currentMission:addUpdateable(self)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_machineManager = MachineManager.new()
