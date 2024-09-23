---@class LandscapingFlatten : BaseLandscaping
---@field targetY number
LandscapingFlatten = {}

local LandscapingFlatten_mt = Class(LandscapingFlatten, BaseLandscaping)

---@param workArea MachineWorkArea
---@param targetY number
---@return LandscapingFlatten
---@nodiscard
function LandscapingFlatten.new(workArea, targetY)
    ---@type LandscapingFlatten
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = BaseLandscaping.new(LandscapingOperation.FLATTEN, workArea, LandscapingFlatten_mt)

    self.targetY = targetY
    self.heightChangeAmount = 0.75

    if self.vehicle.spec_machine.machineType.id == 'excavatorShovel' then
        self.heightChangeAmount = 2.0
    end

    self:verifyAndApplyMapResources()

    return self
end

function LandscapingFlatten:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.state.forceNodes or self.workArea.nodeActive[node] then
                if self.state.allowGradingUp or self.workArea.nodeTerrainY[node] >= self.targetY then
                    deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
                    MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
                end

                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    else
        for node, position in pairs(self.workArea.nodePosition) do
            if self.state.forceNodes or self.workArea.nodeActive[node] then
                if self.state.allowGradingUp or self.workArea.nodeTerrainY[node] >= self.targetY then
                    deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
                    MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
                end

                MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    end

    deformation:setOutsideAreaConstraints(0, math.rad(65), math.rad(65))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(false, 'onDeformationCallback', self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingFlatten:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:setHeightTarget(self.targetY, self.targetY, 0, 1, 0, -self.targetY)
    self.deformation:enableSetDeformationMode()

    return self.deformation
end

---@param volume number
function LandscapingFlatten:onDeformationSuccess(volume)
    self:applyDeformationChanges()

    if self.state.enableInputMaterial and volume > 0 and self.fillType ~= nil then
        local liters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)

        self.vehicle:workAreaInput(liters, self.fillType.index)
    end
end
