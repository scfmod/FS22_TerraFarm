---@type table<string, boolean>
local defaultExcludeFillTypes = {
    ['BARLEY'] = true,
    ['BEETROOT'] = true,
    ['CANOLA'] = true,
    ['CARROT'] = true,
    ['CHAFF'] = true,
    ['DRYGRASS_WINDROW'] = true,
    ['FERTILIZER'] = true,
    ['FORAGE'] = true,
    ['FORAGE_MIXING'] = true,
    ['GRAPE'] = true,
    ['GRASS_WINDROW'] = true,
    ['MAIZE'] = true,
    ['MANURE'] = true,
    ['MINERAL_FEED'] = true,
    ['OAT'] = true,
    ['OLIVE'] = true,
    ['PARSNIP'] = true,
    ['PIGFOOD'] = true,
    ['POTATO'] = true,
    ['SEEDS'] = true,
    ['SILAGE'] = true,
    ['SORGHUM'] = true,
    ['STRAW'] = true,
    ['SUGARBEET'] = true,
    ['SUGARBEET_CUT'] = true,
    ['SUGARCANE'] = true,
    ['SUNFLOWER'] = true,
    ['SOYBEAN'] = true,
    ['WHEAT'] = true,
    ['WOODCHIPS'] = true,
}

---@class Settings
---@field enabled boolean
---@field defaultMachineEnabled boolean
---@field debugMachineNodes boolean
---@field debugMachineCalibration boolean
---@field litersModifier number
---@field hudEnabled boolean
Settings = {}

Settings.MOD_SETTINGS_FOLDER = g_currentModSettingsDirectory
Settings.XML_FILENAME_USER_SETTINGS = g_currentModSettingsDirectory .. 'userSettings.xml'

local Settings_mt = Class(Settings)

---@return Settings
---@nodiscard
function Settings.new()
    ---@type Settings
    local self = setmetatable({}, Settings_mt)

    self.enabled = true
    self.defaultMachineEnabled = true
    self.debugMachineNodes = true
    self.debugMachineCalibration = true
    self.litersModifier = 1.0
    self.hudEnabled = true

    return self
end

---@param defaultEnabled boolean
---@param noEventSend boolean | nil
function Settings:setDefaultMachineEnabled(defaultEnabled, noEventSend)
    if self.defaultMachineEnabled ~= defaultEnabled then
        SetDefaultEnabledEvent.sendEvent(defaultEnabled, noEventSend)

        self.defaultMachineEnabled = defaultEnabled

        g_messageCenter:publish(SetDefaultEnabledEvent, defaultEnabled)
    end
end

---@return boolean
---@nodiscard
function Settings:getDefaultMachineEnabled()
    return self.defaultMachineEnabled
end

---@param enabled boolean
---@param noEventSend boolean | nil
function Settings:setIsEnabled(enabled, noEventSend)
    if self.enabled ~= enabled then
        SetGlobalEnabledEvent.sendEvent(enabled, noEventSend)

        self.enabled = enabled

        g_messageCenter:publish(SetGlobalEnabledEvent, enabled)
    end
end

---@return boolean
---@nodiscard
function Settings:getIsEnabled()
    return self.enabled
end

---@param materials string[]
---@param noEventSend boolean | nil
function Settings:setMaterials(materials, noEventSend)
    if self.materials ~= materials then
        SetGlobalMaterialsEvent.sendEvent(materials, noEventSend)

        self.materials = materials

        g_messageCenter:publish(SetGlobalMaterialsEvent, materials)
    end
end

---@return string[]
---@nodiscard
function Settings:getMaterials()
    return self.materials
end

---@param enabled boolean
function Settings:setDebugNodes(enabled)
    self.debugMachineNodes = enabled

    self:saveUserSettings()
end

---@return boolean
---@nodiscard
function Settings:getDebugNodes()
    return self.debugMachineNodes
end

---@param enabled boolean
function Settings:setDebugCalibration(enabled)
    self.debugMachineCalibration = enabled

    self:saveUserSettings()
end

---@return boolean
---@nodiscard
function Settings:getDebugCalibration()
    return self.debugMachineCalibration
end

function Settings:getHUDIsVisible()
    return g_machineHUD.display.isVisible
end

function Settings:loadModSettings()
    if g_server ~= nil then
        if g_currentMission.missionInfo.savegameDirectory ~= nil then
            local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/terraFarmSettings.xml'

            ---@type XMLFile | nil
            local xmlFile = XMLFile.loadIfExists('modSettings', xmlFilename)

            if xmlFile ~= nil then
                self.enabled = xmlFile:getBool('settings.enabled', self.enabled)
                self.defaultMachineEnabled = xmlFile:getBool('settings.defaultMachineEnabled', self.defaultMachineEnabled)

                g_resources.active = xmlFile:getBool('settings.resourcesActive', g_resources.active)

                self:loadMaterials(xmlFile)

                xmlFile:delete()

                return
            end
        end

        self:loadDefaultMaterials()
    end
end

---@param xmlFile XMLFile
function Settings:loadMaterials(xmlFile)
    if xmlFile:hasProperty('settings.materials.material(0)') then
        self.materials = {}

        xmlFile:iterate('settings.materials.material', function(_, key)
            local fillTypeName = xmlFile:getString(key .. '#fillType')

            if fillTypeName ~= nil then
                ---@type FillTypeObject | nil
                local fillType = g_fillTypeManager:getFillTypeByName(fillTypeName)

                if fillType ~= nil then
                    table.insert(self.materials, fillType.name)
                else
                    g_machineDebug:debug('loadMaterials() fillType "%s" not found, skipping', fillTypeName)
                end
            end
        end)
    else
        self:loadDefaultMaterials()
    end
end

function Settings:loadDefaultMaterials()
    self.materials = {}

    for _, index in ipairs(g_fillTypeManager:getFillTypesByCategoryNames('SHOVEL')) do
        ---@type string | nil
        local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(index)

        if fillTypeName ~= nil and defaultExcludeFillTypes[fillTypeName] ~= true then
            table.insert(self.materials, fillTypeName)
        end
    end
end

function Settings:saveModSettings()
    if g_server ~= nil then
        local xmlFilename = g_currentMission.missionInfo.savegameDirectory .. '/terraFarmSettings.xml'

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('modSettings', xmlFilename, 'settings')

        if xmlFile ~= nil then
            xmlFile:setBool('settings.enabled', self.enabled)
            xmlFile:setBool('settings.defaultMachineEnabled', self.defaultMachineEnabled)
            xmlFile:setBool('settings.resourcesActive', g_resources.active)

            self:saveMaterialSettings(xmlFile)

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

---@param xmlFile XMLFile
function Settings:saveMaterialSettings(xmlFile)
    local i = 0

    for _, fillTypeName in ipairs(self.materials) do
        local key = string.format('settings.materials.material(%i)', i)
        xmlFile:setString(key .. '#fillType', fillTypeName)
        i = i + 1
    end
end

function Settings:loadUserSettings()
    if g_client ~= nil then
        ---@type XMLFile | nil
        local xmlFile = XMLFile.loadIfExists('userSettings', Settings.XML_FILENAME_USER_SETTINGS)

        if xmlFile ~= nil then
            self.debugMachineNodes = xmlFile:getBool('userSettings.debugNodes', self.debugMachineNodes)
            self.debugMachineCalibration = xmlFile:getBool('userSettings.debugCalibration', self.debugMachineCalibration)
            self.hudEnabled = xmlFile:getBool('userSettings.hudEnabled', true)

            xmlFile:delete()
        end
    end
end

function Settings:saveUserSettings()
    if g_client ~= nil then
        createFolder(Settings.MOD_SETTINGS_FOLDER)

        ---@type XMLFile | nil
        local xmlFile = XMLFile.create('userSettings', Settings.XML_FILENAME_USER_SETTINGS, 'userSettings')

        if xmlFile ~= nil then
            xmlFile:setBool('userSettings.debugNodes', self.debugMachineNodes)
            xmlFile:setBool('userSettings.debugCalibration', self.debugMachineCalibration)
            xmlFile:setBool('userSettings.hudEnabled', self:getHUDIsVisible())

            xmlFile:save()
            xmlFile:delete()
        end
    end
end

---@param connection Connection
function Settings:onSendInitialClientState(connection)
    connection:sendEvent(SetGlobalEnabledEvent.new(self.enabled))
    connection:sendEvent(SetGlobalMaterialsEvent.new(self.materials))
    connection:sendEvent(SetDefaultEnabledEvent.new(self.defaultMachineEnabled))
end

function Settings:onMapLoaded()
    self:loadModSettings()
end

function Settings:onTerrainInitialized()
    if g_server ~= nil then
        self.litersModifier = g_currentMission.terrainSize / g_currentMission.terrainDetailHeightMapSize * 1.85
    end
end

---@diagnostic disable-next-line: lowercase-global
g_settings = Settings.new()
