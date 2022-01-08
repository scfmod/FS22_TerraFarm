---@class TerraFarmShovel : TerraFarmMachine
---@field config ShovelConfiguration
---@field dischargeMode number
TerraFarmShovel = {}
local TerraFarmShovel_mt = Class(TerraFarmShovel, TerraFarmMachine)

g_machineTypes:registerType(TerraFarmShovel, 'shovel')

function TerraFarmShovel.new(manager, object, config)
    ---@type TerraFarmShovel
    local self = TerraFarmMachine.new(manager, object, config, TerraFarmShovel.machineType, TerraFarmShovel_mt)

    self.fillUnit = object.spec_fillUnit.fillUnits[self.config.fillUnitIndex]
    self.dischargeMode = self.config.availableDischargeModes[1]

    self:updateFillType()

    return self
end

function TerraFarmShovel:getVehicle()
    return self:getAttacherVehicle()
end

function TerraFarmShovel:isActive()
    return self:getIsVehicleOperating() and g_currentMission.controlledVehicle == self:getVehicle()
end

function TerraFarmShovel:onVolumeDisplacement(volume)
    self:addFillUnits(self:getFillAmountFromVolume(volume))
end

function TerraFarmShovel:getAttacherVehicle()
    if self.object and self.object.getAttacherVehicle ~= nil then
        local attacherVehicle = self.object:getAttacherVehicle()
        if attacherVehicle then
            if attacherVehicle.typeName == 'attachableFrontloader' then
                local spec = attacherVehicle.spec_attacherJoints
                if spec.attachableInfo and spec.attachableInfo.attacherVehicle ~= nil then
                    return spec.attachableInfo.attacherVehicle
                end
            else
                return attacherVehicle
            end
        end
    end
end

function TerraFarmShovel:getTipFactor()
    return self.object:getShovelTipFactor()
end

function TerraFarmShovel:onDischarge()
    -- if not self:isActive() then return end
    if self.dischargeMode == TerraFarm.MODE.NORMAL then return end
    if self:isEmpty() or self:isTouchingTerrain() then return end

    local tipFactor = self:getTipFactor() * 0.05
    if tipFactor <= 0 then
        return
    end

    local nodePositions = {}

    for _, node in pairs(self.config.terraformNodes) do
        local position = self.nodePosition[node]
        local height = self.nodeTerrainHeight[node]

        if position and height then
            local entry = { x = position.x, y = height, z = position.z }
            table.insert(nodePositions, entry)
        end
    end

    if #nodePositions == 0 then return end

    if self.dischargeMode == TerraFarm.MODE.SMOOTH then
        local strength = (self:getSmoothStrength() / #nodePositions) * tipFactor

        self.manager:sendTerraformRequest(
            self.machineType,
            self.object,
            TerraFarmLandscaping.OPERATION.SMOOTH,
            Landscaping.BRUSH_SHAPE.CIRCLE,
            nodePositions,
            self:getSmoothRadius(),
            strength,
            nil,
            self:getPaintLayer(),
            true
        )
    elseif self.dischargeMode == TerraFarm.MODE.RAISE then
        local strength = (self:getStrength() / #nodePositions) * tipFactor

        self.manager:sendTerraformRequest(
            self.machineType,
            self.object,
            TerraFarmLandscaping.OPERATION.RAISE,
            Landscaping.BRUSH_SHAPE.CIRCLE,
            nodePositions,
            self:getRadius(),
            strength,
            nil,
            self:getPaintLayer(),
            true
        )
    elseif self.dischargeMode == TerraFarm.MODE.FLATTEN then
        -- local x, _, z, height, rootNode = self:getVehiclePosition()
        local vehicle = g_currentMission.controlledVehicle
        if not vehicle or not vehicle.rootNode then return end

        local x, _, z = getWorldTranslation(vehicle.rootNode)
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        if x and height then
            local target =  { x = x, y = height, z = z}
            local strength = (self:getFlattenStrength() / #nodePositions) * tipFactor

            self.manager:sendTerraformRequest(
                self.machineType,
                self.object,
                TerraFarmLandscaping.OPERATION.FLATTEN,
                Landscaping.BRUSH_SHAPE.CIRCLE,
                nodePositions,
                self:getFlattenRadius(),
                strength,
                target,
                self:getPaintLayer(),
                true
            )
        else
            Logging.warning('Unable to get vehicle position data ..')
        end
    end

    if self.manager.config.terraformDisablePaint ~= true then
        self:applyPaint(true)
    end
end

function TerraFarmShovel:getMassPerLiter()
    return self.config.fillTypeMassPerLiter or self.manager.config.fillTypeMassPerLiter
end

function TerraFarmShovel:getMassRatio()
    return self.config.fillTypeMassRatio or self.manager.config.fillTypeMassRatio
end

function TerraFarmShovel:getVolumeFillRatio()
    return self.config.volumeFillRatio or self.manager.config.volumeFillRatio
end

function TerraFarmShovel:getFillAmountFromVolume(volume)
    return volume * self:getMassPerLiter() * self:getMassRatio() * self:getVolumeFillRatio()
end

function TerraFarmShovel:addFillUnits(amount)
    return self.object:addFillUnitFillLevel(
        self.object:getOwnerFarmId(),
        self.config.fillUnitIndex,
        amount,
        self.manager.config.fillTypeIndex,
        ToolType.UNDEFINED
    )
end

function TerraFarmShovel:getFillLevel()
    if self.fillUnit then
        return self.fillUnit.fillLevel
    end
end

function TerraFarmShovel:getFreeCapacity()
    if self.fillUnit then
        return self.fillUnit.capacity - self.fillUnit.fillLevel
    end
end

function TerraFarmShovel:isEmpty()
    return self:getFillLevel() == 0
end

function TerraFarmShovel:isFull()
    local freeCapacity = self:getFreeCapacity()
    if freeCapacity and freeCapacity > 0 then
        return false
    end
    return true
end

function TerraFarmShovel:getCurrentFillType()
    return self.object:getFillUnitFillType(self.config.fillUnitIndex)
end

function TerraFarmShovel:updateFillType(oldFillType, oldFillTypeIndex)
    local fillUnit = self.fillUnit
    if fillUnit then
        if oldFillType and oldFillTypeIndex then
            local fillTypeIndex = self:getCurrentFillType()
            if fillTypeIndex == oldFillTypeIndex then
                self.object:setFillUnitFillType(self.config.fillUnitIndex, self.manager.config.fillTypeIndex)
                self:addFillUnits(0)
            end
        else
            self.object:setFillUnitFillType(self.config.fillUnitIndex, self.manager.config.fillTypeIndex)
            self:addFillUnits(0)
        end
    end
end

function TerraFarmShovel:isCorrectFillType()
    local fillType = self:getCurrentFillType()
    return fillType == self.manager.config.fillTypeIndex
end

function TerraFarmShovel:isAvailable()
    if self:isFull() then
        return false
    elseif self:isEmpty() then
        return true
    end
    return self:isCorrectFillType()
end


function TerraFarmShovel:onUpdate(dt)
    self:updateNodes()

    if not self:isAvailable() then
        return
    end

    local isUpdatePending = self.lastUpdate >= self.manager.config.interval

    if self.terraformNodesIsTouchingTerrain and isUpdatePending then
        if self.mode == TerraFarm.MODE.SMOOTH then
            self:applyTerraformSmooth(4)
        elseif self.mode == TerraFarm.MODE.FLATTEN then
            local x, _, z, height, rootNode = self:getVehiclePosition()

            if x and rootNode then
                local target =  { x = x, y = height, z = z}
                self:applyTerraformFlatten(target)
            end
        elseif self.mode == TerraFarm.MODE.LOWER then
            self:applyTerraformLower()
        elseif self.mode == TerraFarm.MODE.PAINT then
            self:applyPaint()
        end

        if self.manager.config.terraformDisablePaint ~= true then
            self:applyPaint()
        end

        self.lastUpdate = 0
    else
        self.lastUpdate = self.lastUpdate + dt
    end
end


function TerraFarmShovel:toggleDischargeMode()
    if #self.config.availableDischargeModes <= 1 then
        return
    end

    local result

    for i, mode in ipairs(self.config.availableDischargeModes) do
        if mode == self.dischargeMode then
            result = self.config.availableDischargeModes[i + 1]
            break
        end
    end

    if not result then
        result = self.config.availableDischargeModes[1]
    end

    self.dischargeMode = result
end