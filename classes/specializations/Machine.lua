---@class Machine : Vehicle
---@field spec_machine MachineSpec
Machine = {}


---@param vehicle Vehicle
local function addSpecialization(vehicle, machineTypeName, name, filePath)
    local spec_name = 'spec_machine'
    local spec = {}

    setmetatable(spec, {
        __index = vehicle
    })

    spec.typeName = machineTypeName
    spec.type = g_machineTypes.stringToType[machineTypeName]
    spec.actionEvents = {}
    spec.onLoadFinished = Machine.onLoadFinished
    spec.onRegisterActionEvents = Machine.onRegisterActionEvents
    spec.onDelete = Machine.onDelete
    spec.name = name
    spec.filePath = filePath

    vehicle[spec_name] = spec

    table.insert(vehicle.eventListeners.onLoadFinished, spec)
    table.insert(vehicle.eventListeners.onRegisterActionEvents, spec)
    table.insert(vehicle.eventListeners.onDelete, spec)

    if spec.type == TerraFarmShovel.machineType then
        vehicle.getIsDischargeNodeActive = Utils.overwrittenFunction(vehicle.getIsDischargeNodeActive, Machine.getIsDischargeNodeActive)
        vehicle.handleDischarge = Utils.overwrittenFunction(vehicle.handleDischarge, Machine.handleDischarge)
        vehicle.handleDischargeRaycast = Utils.overwrittenFunction(vehicle.handleDischargeRaycast, Machine.handleDischargeRaycast)
    elseif spec.type == TerraFarmTractor.machineType then
        spec.onEnterVehicle = Machine.onEnterVehicle
        spec.onLeaveVehicle = Machine.onLeaveVehicle
        table.insert(vehicle.eventListeners.onEnterVehicle, spec)
        table.insert(vehicle.eventListeners.onLeaveVehicle, spec)
    end
end

-- Clean up when vehicle is deleted
function Machine:onDelete()
    local machine = g_terraFarm.objectToMachine[self]

    if machine then
        if g_terraFarm.currentMachine == machine then
            g_terraFarm:setCurrentMachine()
        end
        g_terraFarm.objectToMachine[self] = nil
        g_terraFarm.machineToObject[machine] = nil
    end
end

-- If vehicle type is from custom mod type then we need
-- to split string [ModName.customTypeName]
local function getRealTypeName(value)
    if type(value) ~= 'string' then return end
    local parts = string.split(value, '.')
    if #parts > 1 then
        return parts[2]
    end
    return value
end

local typeMappingToTypeName = {
    ['shovelLeveler'] = 'shovel',
    ['turnOnShovel'] = 'shovel',
    ['bucket350'] = 'shovel', -- VOLVO 350 bucket
    ['kouppaCX250D_LR'] = 'shovel', -- CASE Longreach buckets
    ['bucket990H'] = 'shovel', -- CAT 990H bucket
    ['kouppaEC750'] = 'shovel', -- Volvo EC750 buckets
}

---@param vehicle Vehicle
function Machine.afterVehicleLoad(vehicle)
    if vehicle.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
        return
    end

    local typeName = getRealTypeName(vehicle.typeName)

    -- Logging.info('Machine.afterVehicleLoad')
    -- Logging.info('typeName: ' .. tostring(typeName))
    -- Logging.info('realTypeName: ' .. tostring(getRealTypeName(typeName)))

    if typeMappingToTypeName[typeName] ~= nil then
        typeName = typeMappingToTypeName[typeName]
    end

    local machineClass = g_machineTypes.stringToClass[typeName]
    if machineClass then
        local name = vehicle.configFileNameClean
        local filePath = MachineConfiguration.getXMLFilePath(name, getRealTypeName(vehicle.typeName))

        -- Logging.info('config filepath: ' .. tostring(filePath))

        if not filePath then
            return
        end

        addSpecialization(vehicle, typeName, name, filePath)
    end
end

function Machine:onLoadFinished()
    if self:getOwnerFarmId() then
        local config

        if self.spec_machine.type == TerraFarmShovel.machineType then
            config = ShovelConfiguration.new(self, self.spec_machine.name, self.spec_machine.filePath)
        elseif self.spec_machine.type == TerraFarmTractor.machineType then
            config = TractorConfiguration.new(self, self.spec_machine.name, self.spec_machine.filePath)
        end

        if not config or not config:load() then
            return
        end

        if g_terraFarm:registerMachine(self, config, self.spec_machine.type) then
            Logging.info('Added machine to TerraFarm - ' .. tostring(self.spec_machine.name))
            self.spec_machine.machine = g_terraFarm.objectToMachine[self]
        end
    end
end

-- ---@param isControlling boolean
---@diagnostic disable-next-line: unused-local
function Machine:onEnterVehicle(isControlling)
    local machine = self.spec_machine.machine

    if machine then
        g_terraFarm:setCurrentMachine(machine)
    else
        machine = g_terraFarm:getMachineFromVehicle(self)
        if machine then
            g_terraFarm:setCurrentMachine(machine)
        end
    end
end

-- ---@param wasEntered boolean
---@diagnostic disable-next-line: unused-local
function Machine:onLeaveVehicle(wasEntered)
    local machine = g_terraFarm.objectToMachine[self]
    if g_terraFarm.currentMachine and machine == g_terraFarm.currentMachine then
        g_terraFarm:setCurrentMachine()
    end
    if machine and machine:getIsVehicleOperating() and g_currentMission.missionInfo.automaticMotorStartEnabled ~= true then
        machine:setEnabled(false)
    end
end

function Machine:getIsDischargeNodeActive(func, ...)
    local machine = g_terraFarm.objectToMachine[self]
    if g_terraFarm:getIsEnabled() and machine then
        if machine:isTouchingTerrain() then
            return false
        end
    end

    return func(self, ...)
end

function Machine:handleDischarge(func, ...)
    local dischargeNode = unpack({...})
    local machine = g_terraFarm.objectToMachine[self]
    if g_terraFarm:getIsEnabled() and machine then
        if machine:getIsEnabled() and machine:isTouchingTerrain() then
            return
        elseif g_terraFarm.config.disableDischarge == true then
            if not dischargeNode or not dischargeNode.dischargeHitObject then
                return
            end
        end
    end

    return func(self, ...)
end

function Machine:handleDischargeRaycast(func, ...)
    ---@type TerraFarmShovel
    local machine = g_terraFarm.objectToMachine[self]

    if g_terraFarm:getIsEnabled() and machine then
        if machine:getIsEnabled() then
            if machine.dischargeMode ~= TerraFarm.MODE.NORMAL and machine:isCorrectFillType() then
                machine:onDischarge()
                return
            elseif machine:isTouchingTerrain() then
                return
            end
        elseif g_terraFarm.config.disableDischarge == true then
            local dischargeNode = unpack({...})

            if not dischargeNode or not dischargeNode.dischargeHitObject then
                return
            end
        end
    end

    return func(self, ...)
end



-----@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function Machine:onRegisterActionEvents(_, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_machine

        if not spec then
            Logging.warning('Machine.onRegisterActionEvents: spec_machine not found')
            return
        end

        self:clearActionEventsTable()

        if isActiveForInputIgnoreSelection then
            local _, eventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Machine.actionEventToggleEnabled, false, true, false, true, nil)
            g_inputBinding:setActionEventText(eventId, 'Enable TerraFarm')
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)

            _, eventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, Machine.actionEventToggleMode, false, true, false, true, nil)
            g_inputBinding:setActionEventText(eventId, 'Toggle mode')
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)

            if spec.type == TerraFarmShovel.machineType then
                _, eventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, Machine.actionEventToggleDischargeMode, false, true, false, true, nil)
                g_inputBinding:setActionEventText(eventId, 'Toggle discharge mode')
                g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
            end

            _, eventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Machine.actionEventOpenMenu, false, true, false, true, nil)
            g_inputBinding:setActionEventText(eventId, 'Open TerraFarm menu')
            g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_NORMAL)
        end
    end

    Machine.updateActionEvents(self)
end

function Machine:updateActionEvents()
    local spec = self.spec_machine
    local machine = spec.machine
    local isActiveForInput = self:getIsActiveForInput()
    local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)

    local controlMachine, _ = g_terraFarm:getControlledMachine()

    if not machine or not isActiveForInputIgnoreSelection then
        local actionEvent

        if spec.type == TerraFarmShovel.machineType then
            actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
            end
        end

        actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
        end

        actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
        end

        actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
        if actionEvent ~= nil then
            g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
        end

        if machine and g_terraFarm.currentMachine == machine then
            g_terraFarm:setCurrentMachine()
        end

        return
    end

    if machine == controlMachine then
        g_terraFarm:setCurrentMachine(machine)
    end

    if isActiveForInput or isActiveForInputIgnoreSelection then
        local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

        if machine:getIsEnabled() then
            if actionEvent then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, 'Disable TerraFarm')
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, true)
            end

            actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, 'Toggle mode')
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, true)
            end

            if spec.type == TerraFarmShovel.machineType then
                actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
                if actionEvent ~= nil then
                    g_inputBinding:setActionEventText(actionEvent.actionEventId, 'Toggle discharge mode')
                    g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, true)
                end
            end

            actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventText(actionEvent.actionEventId, 'Open TerraFarm menu')
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, true)
            end
        else
            g_inputBinding:setActionEventText(actionEvent.actionEventId, 'Enable TerraFarm')

            actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
            end

            if spec.type == TerraFarmShovel.machineType then
                actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]
                if actionEvent ~= nil then
                    g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
                end
            end

            actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]
            if actionEvent ~= nil then
                g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
            end
        end
    end
end

function Machine:actionEventToggleEnabled()
    local machine = self.spec_machine.machine

    if machine then
        machine:setEnabled(not machine.enabled)
        Machine.updateActionEvents(self)
    end
end
function Machine:actionEventToggleMode()
    local machine = self.spec_machine.machine

    if machine then
        machine:toggleMode()
        Machine.updateActionEvents(self)
    end
end
function Machine:actionEventToggleDischargeMode()
    ---@type TerraFarmShovel
    local machine = self.spec_machine.machine

    if machine then
        machine:toggleDischargeMode()
        Machine.updateActionEvents(self)
    end
end
function Machine:actionEventOpenMenu()
    g_terraFarm:openMenu()
end

Vehicle.load = Utils.appendedFunction(Vehicle.load, Machine.afterVehicleLoad)
