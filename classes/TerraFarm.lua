local modFolder = g_currentModDirectory

---@class TerraFarm
---@field isLoaded boolean
---@field configFile string
---@field config TerraFarmConfig
--- NETWORK
---@field isServer boolean
---@field isClient boolean
---@field isDedicatedServer boolean
--- MACHINES
---@field currentMachine TerraFarmMachine
---@field machineToObject table<TerraFarmMachine, table>
---@field objectToMachine table<table, TerraFarmMachine>
TerraFarm = {}
local TerraFarm_mt = Class(TerraFarm)

TerraFarm.TYPE_NUM_SEND_BITS = 4
TerraFarm.MODE_NUM_SEND_BITS = 3

TerraFarm.MODE = {
    NORMAL = 1,
    RAISE = 2,
    LOWER = 3,
    SMOOTH = 4,
    FLATTEN = 5,
    PAINT = 6
}
TerraFarm.NAME_TO_MODE = {
    ['NORMAL'] = TerraFarm.MODE.NORMAL,
    ['RAISE'] = TerraFarm.MODE.RAISE,
    ['LOWER'] = TerraFarm.MODE.LOWER,
    ['SMOOTH'] = TerraFarm.MODE.SMOOTH,
    ['FLATTEN'] = TerraFarm.MODE.FLATTEN,
    ['PAINT'] = TerraFarm.MODE.PAINT
}

---@return TerraFarm
function TerraFarm.new()
    ---@type TerraFarm
    local self = setmetatable({}, TerraFarm_mt)

    self.isLoaded = false
    self.config = TerraFarmConfig.load()

    self.isDedicatedServer = not not g_dedicatedServer
    self.isClient = g_client ~= nil
    self.isServer = g_server ~= nil

    self.machineToObject = {}
    self.objectToMachine = {}

    return self
end

function TerraFarm:saveConfig()
    if self.config then
        self.config:save()
    end
end

function TerraFarm:onReady()
    self:registerCustomFillType()
    self:updateFillTypeData()

    TerraFarmFillTypes:init()
end

function TerraFarm:setPaintLayer(name, textIndex)
    if name then
        self.config.terraformPaintLayer = name
    elseif textIndex then
        self:setPaintLayer(TerraFarmGroundTypes:getNameByIndex(textIndex))
    end
end

function TerraFarm:setFillType(name, typeIndex)
    if name then
        local fillType = g_fillTypeManager.nameToFillType[name]
        if not fillType then
            Logging.error('TerraFarm.setFillType: Failed to get fillType data - ' .. tostring(name))
            if name ~= TerraFarmConfig.DEFAULT.fillTypeName then
                -- Revert back to default value just in case ..
                Logging.info('Reverting to default')
                return self:setFillType(TerraFarmConfig.DEFAULT.fillTypeName)
            end
            return
        end

        local previousFillType = self.config.fillTypeName
        local previousFillTypeIndex = self.config.fillTypeIndex

        self.config.fillTypeName = name
        self.config.fillTypeIndex = g_fillTypeManager.nameToIndex[self.config.fillTypeName]
        self.config.fillTypeMassPerLiter = fillType.massPerLiter * 1000 * 1000

        for machine, _ in pairs(self.machineToObject) do
            if machine.updateFillType ~= nil then
                machine:updateFillType(previousFillType, previousFillTypeIndex)
            end
        end

        return true
    elseif typeIndex then
        self:setFillType(TerraFarmFillTypes.TITLE_TO_NAME[TerraFarmFillTypes.TYPES_LIST[typeIndex]])
    end
end

function TerraFarm:setDischargePaintLayer(name, textIndex)
    if name then
        self.config.dischargePaintLayer = name
    elseif textIndex then
        self:setDischargePaintLayer(TerraFarmGroundTypes:getNameByIndex(textIndex))
    end
end

function TerraFarm:openMenu()
    g_gui:showGui('TerraFarmSettingsScreen')
end

function TerraFarm:getIsEnabled()
    return self.config.enabled
end

function TerraFarm:setEnabled(enabled)
    self.config.enabled = enabled
end

function TerraFarm:updateFillTypeData()
    self:setFillType(self.config.fillTypeName)
end

function TerraFarm:updatePaintLayerData()
    self:setPaintLayer(nil, TerraFarmGroundTypes:getIndexByName(self.config.terraformPaintLayer))
    self:setDischargePaintLayer(nil, TerraFarmGroundTypes:getIndexByName(self.config.dischargePaintLayer))
end

function TerraFarm:registerCustomFillType()
    local name = 'DIRT'

    if g_fillTypeManager.nameToFillType[name] ~= nil then
        Logging.info('TerraFarm.registerCustomFillType: FillType DIRT already registered, skipping.')
        return
    end

    local title = 'Dirt'
    local showOnPriceTable = true
    local unitShort = '$l10n_unit_literShort'
    local massPerLiter = 1.0 / 1000
    local maxPhysicalSurfaceAngle = 35
    local pricePerLiter = 0.05
    local fillPlaneColors = "1.0 1.0 1.0"
    local hudFileName = 'dirt_hud_icon.png'
    local diffuseMapFilename = 'dirt_diffuse.png'
    local normalMapFilename = 'dirt_normal.png'
    local specularMapFilename = 'dirt_specular.png'
    local distanceFilename = 'dirtDistance_diffuse.png'
    local baseDirectory = modFolder .. 'textures/fillTypes/'
    local economicCurve = {}
    local prioritizedEffectType = 'ShaderPlaneEffect'
    local isBaseType = false
    local customEnv = ''

    local result = g_fillTypeManager:addFillType(
        name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle,
        hudFileName, baseDirectory, customEnv, fillPlaneColors, unitShort, nil, economicCurve,
        diffuseMapFilename, normalMapFilename, specularMapFilename, distanceFilename,
        prioritizedEffectType, nil, nil, nil, isBaseType
    )

    if result then
        Logging.info('TerraFarm: Successfully registered custom fillType - ' .. name)

        if g_fillTypeManager:addFillTypeToCategory(result.index, g_fillTypeManager.nameToCategoryIndex['BULK']) ~= true then
            Logging.error('Failed to add fillType to BULK category')
        -- else
        --     Logging.info('Added fill type to BULK category')
        end

        if g_fillTypeManager:addFillTypeToCategory(result.index, g_fillTypeManager.nameToCategoryIndex['SHOVEL']) ~= true then
            Logging.error('Failed to add fillType to SHOVEL category')
        -- else
        --     Logging.info('Added fill type to SHOVEL category')
        end

        g_currentMission.hud.fillLevelsDisplay:refreshFillTypes(g_fillTypeManager)
        g_fillTypeManager:constructFillTypeTextureArrays()
    else
        Logging.error('TerraFarm: Registering custom fillType failed')
    end
end

function TerraFarm:isActive()
    return self:getIsEnabled() and self.currentMachine ~= nil
end

function TerraFarm:onUpdate(dt)
    if self.isDedicatedServer then
        return
    end

    if self:isActive() then
        if self.currentMachine:getIsEnabled() then
            self.currentMachine:onUpdate(dt)
        end
        if self.config.debug then
            self.currentMachine:updateNodes()
            TerraFarmDebug.draw()
        end
    end

end

---@param object table
---@param config MachineConfiguration
---@param machineType number
---@return boolean
function TerraFarm:registerMachine(object, config, machineType)
    local class = g_machineTypes.typeToClass[machineType]
    if not class then
        Logging.error('TerraFarm.registerMachine: invalid machineType - ' .. tostring(machineType))
        return false
    end

    local machine = class.new(self, object, config, machineType)

    return self:addMachine(machine)
end

---@param machine TerraFarmMachine
function TerraFarm:addMachine(machine)
    if not machine.object then
        Logging.error('TerraFarm.addMachine: machine.object is nil')
        return false
    end
    if self.objectToMachine[machine.object] ~= nil then
        Logging.warning('TerraFarm.addMachine: duplicate entry')
        return false
    end

    self.machineToObject[machine] = machine.object
    self.objectToMachine[machine.object] = machine

    return true
end

function TerraFarm:setCurrentMachine(machine, object)
    if machine then
        self.currentMachine = machine
    elseif object then
        if self.objectToMachine[object] ~= nil then
            self.currentMachine = self.objectToMachine[object]
        end
    else
        self.currentMachine = nil
    end
end

function TerraFarm:sendTerraformRequest(machineType, object, operation, brushShape, nodes, radius, strength, target, paintLayer, isDischarging)
    if not self.currentMachine then return end

    local nodeStrength = strength / #nodes

    for _, node in pairs(nodes) do
        local event = TerraFarmLandscapingEvent.new(
            machineType,
            self.currentMachine.mode,
            object,
            operation,
            node,
            radius,
            nodeStrength,
            brushShape,
            paintLayer,
            target,
            isDischarging
        )
        g_client:getServerConnection():sendEvent(event)
    end
end

function TerraFarm:getMachineFromVehicle(targetVehicle)
    if targetVehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(targetVehicle:getAttachedImplements()) do
            if implement.object ~= nil then
                if self.objectToMachine[implement.object] ~= nil then
                    return self.objectToMachine[implement.object], implement.object
                elseif implement.object.getAttachedImplements ~= nil then
                    for _, s_implement in pairs(implement.object:getAttachedImplements()) do
                        if self.objectToMachine[s_implement.object] ~= nil then
                            return self.objectToMachine[s_implement.object], implement.object
                        end
                    end
                end
            end
        end
    else
        for machine, _ in pairs(self.machineToObject) do
            local vehicle = machine:getVehicle()
            if vehicle == targetVehicle then
                return machine, vehicle
            end
        end
    end
    -- for machine, _ in pairs(self.machineToObject) do
    --     local vehicle = machine:getVehicle()
    --     if vehicle == targetVehicle then
    --         return machine
    --     end
    -- end
end

---@return TerraFarmMachine
---@return Vehicle
function TerraFarm:getControlledMachine()
    local vehicle = g_currentMission.controlledVehicle
    if not vehicle then return end

    if self.objectToMachine[vehicle] then
        return self.objectToMachine[vehicle], vehicle
    end

    if vehicle.getAttachedImplements ~= nil then
        for _, implement in pairs(vehicle:getAttachedImplements()) do
            if self.objectToMachine[implement.object] then
                return self.objectToMachine[implement.object], vehicle
            elseif implement.object.getAttachedImplements ~= nil then
                for _, s_implement in pairs(implement.object:getAttachedImplements()) do
                    if self.objectToMachine[s_implement.object] ~= nil then
                        return self.objectToMachine[s_implement.object], vehicle
                    end
                end
            end
        end
    end
end


---@diagnostic disable-next-line: lowercase-global
g_terraFarm = TerraFarm.new()