---@class TerraFarmTractor : TerraFarmMachine
---@field object Vehicle
TerraFarmTractor = {}
local TerraFarmTractor_mt = Class(TerraFarmTractor, TerraFarmMachine)

g_machineTypes:registerType(TerraFarmTractor, 'tractor')

function TerraFarmTractor.new(manager, object, config)
    local self = TerraFarmMachine.new(manager, object, config, TerraFarmTractor.machineType, TerraFarmTractor_mt)

    self.mode = self.config.availableModes[1]

    return self
end

function TerraFarmTractor:getVehicle()
    return self.object
end

function TerraFarmTractor:isVehicle()
    return true
end

function TerraFarmTractor:isActive()
    return self:getIsVehicleOperating() and g_currentMission.controlledVehicle == self.object
end

function TerraFarmTractor:onUpdate(dt)
    if not self:isActive() then return end
    if not self.enabled then return end

    self:updateNodes()

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
        elseif self.mode == TerraFarm.MODE.PAINT then
            self:applyTerraformPaint()
        end

        if self.mode ~= TerraFarm.MODE.PAINT then
            if self.manager.config.terraformDisablePaint ~= true then
                self:applyPaint()
            end
        end

        self.lastUpdate = 0
    else
        self.lastUpdate = self.lastUpdate + dt
    end
end