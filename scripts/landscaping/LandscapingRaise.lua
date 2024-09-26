---@class LandscapingRaise : BaseLandscaping
---@field droppedLiters number
---@field litersToDrop number
LandscapingRaise = {}

local LandscapingRaise_mt = Class(LandscapingRaise, BaseLandscaping)

---@param workArea MachineWorkArea
---@param litersToDrop number
---@param fillTypeIndex number
---@return LandscapingRaise
---@nodiscard
function LandscapingRaise.new(workArea, litersToDrop, fillTypeIndex)
    ---@type LandscapingRaise
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = BaseLandscaping.new(LandscapingOperation.RAISE, workArea, LandscapingRaise_mt)

    self.droppedLiters = 0
    self.litersToDrop = litersToDrop
    self.fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

    self.strength = 0.25
    self.radius = math.max(2, math.min(self.radius, 6))
    self.hardness = 0.2

    local minValidValue = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)

    self.strength = math.max(0.1, math.min(1, (litersToDrop / minValidValue) * self.strength))
    self.heightChangeAmount = self.heightChangeAmount * self.strength * (workArea.width / 4)

    self:verifyAndApplyMapResources()

    return self
end

function LandscapingRaise:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for _, position in pairs(self.workArea.nodePosition) do
            deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
            MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
            MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

            if paintDeformation ~= nil then
                paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
            end
        end
    else
        for _, position in pairs(self.workArea.nodePosition) do
            deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
            MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
            MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)

            if paintDeformation ~= nil then
                paintDeformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, 0.2, 0.5, self.terrainLayerId)
            end
        end
    end

    deformation:setOutsideAreaConstraints(0, math.rad(65), math.rad(65))
    deformation:setBlockedAreaMaxDisplacement(0)
    deformation:setDynamicObjectCollisionMask(0)
    deformation:setDynamicObjectMaxDisplacement(0)

    deformation:apply(false, 'onDeformationCallback', self)
end

function LandscapingRaise:verifyAndApplyMapResources()
    if g_resources:getIsActive() and self.vehicle.spec_machine.resourcesEnabled then
        local worldPosX, _, worldPosZ = getWorldTranslation(self.workArea.rootNode)
        local layer = g_resources:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

        if layer ~= nil then
            self.terrainLayerId = g_resources:getResourcePaintLayerId(layer, true)
        end
    end
end

---@return TerrainDeformation
---@nodiscard
function LandscapingRaise:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enableAdditiveDeformationMode()
    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)

    return self.deformation
end

---@param volume number
function LandscapingRaise:onDeformationSuccess(volume)
    if volume > 0 and self.fillType ~= nil then
        self:applyDeformationChanges()

        self.droppedLiters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)
    end
end
