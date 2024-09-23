---@enum LandscapingOperation
LandscapingOperation = {
    LOWER = 1,
    RAISE = 2,
    SMOOTH = 3,
    FLATTEN = 4,
    PAINT = 5
}

---@class BaseLandscaping
---@field workArea MachineWorkArea
---@field vehicle Machine
---@field operation LandscapingOperation
---@field deformation TerrainDeformation
---@field paintDeformation TerrainDeformation
---@field state MachineState
---
---@field modifiedAreas table
---@field densityModifiedAreas table
---@field terrainUnit number
---@field halfTerrainUnit number
---
---@field radius number
---@field strength number
---@field hardness number
---@field terrainLayerId number
---@field brushShape number
---@field heightChangeAmount number
---@field fillType FillTypeObject | nil
---@field yield number
BaseLandscaping = {}

---@param operation LandscapingOperation
---@param workArea MachineWorkArea
---@param customMt table
---@return BaseLandscaping
function BaseLandscaping.new(operation, workArea, customMt)
    ---@type BaseLandscaping
    local self = setmetatable({}, customMt)

    self.operation = operation
    self.workArea = workArea
    self.vehicle = workArea.vehicle
    self.state = self.vehicle.spec_machine.state

    self.modifiedAreas = {}
    self.densityModifiedAreas = {}

    self.terrainUnit = Landscaping.TERRAIN_UNIT
    self.halfTerrainUnit = self.terrainUnit / 2

    self.radius = self.state.radius
    self.strength = self.state.strength
    self.hardness = self.state.hardness
    self.terrainLayerId = self.vehicle.spec_machine.terrainLayerId or 0
    self.heightChangeAmount = 0.05
    self.brushShape = self.state.brushShape
    self.fillType = g_fillTypeManager:getFillTypeByIndex(self.vehicle.spec_machine.fillTypeIndex)
    self.yield = 1

    return self
end

function BaseLandscaping:verifyAndApplyMapResources()
    if g_resources:getIsActive() and self.vehicle.spec_machine.resourcesEnabled then
        local worldPosX, _, worldPosZ = getWorldTranslation(self.workArea.rootNode)
        local layer = g_resources:getResourceLayerAtWorldPos(worldPosX, worldPosZ)

        if layer ~= nil then
            self.terrainLayerId = g_resources:getResourcePaintLayerId(layer, false)

            local fillType = g_fillTypeManager:getFillTypeByName(layer.fillTypeName)

            if fillType ~= nil then
                self.fillType = fillType
            end

            self.yield = layer.yield
        end
    end
end

function BaseLandscaping:apply()
    local deformation = self:createTerrainDeformation()
    local paintDeformation = self:createPaintDeformation()

    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftCircleBrush(position[1], position[3], self.radius, self.hardness, self.strength, -1)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], self.radius)
                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)

                if paintDeformation ~= nil then
                    paintDeformation:addSoftCircleBrush(position[1], position[3], paintRadius, 0.2, 0.5, self.terrainLayerId)
                end
            end
        end
    else
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftSquareBrush(position[1], position[3], self.radius * 2, self.hardness, self.strength, -1)
                MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], self.radius * 2)
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

---@param code number
---@param volume number
function BaseLandscaping:onDeformationCallback(code, volume)
    if code == TerrainDeformation.STATE_SUCCESS then
        self:onDeformationSuccess(volume)
    else
        print('onDeformationCallback error code: ' .. tostring(code))
        self.deformation:cancel()

        if self.paintDeformation ~= nil then
            self.paintDeformation:cancel()
        end
    end

    self.deformation:delete()
    self.deformation = nil

    if self.paintDeformation ~= nil then
        self.paintDeformation:delete()
        self.paintDeformation = nil
    end
end

function BaseLandscaping:applyDeformationChanges()
    for _, area in ipairs(self.densityModifiedAreas) do
        local x, z, x1, z1, x2, z2 = unpack(area)

        if self.state.removeFieldArea then
            FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
        end

        if self.state.removeWeedArea then
            FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
        end

        if self.state.removeStoneArea then
            FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)
        end

        if self.state.clearDensityMapHeightArea then
            DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)
        end

        if self.state.clearDecoArea then
            FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
        end
    end

    for _, area in ipairs(self.modifiedAreas) do
        local x, z, x1, z1, x2, z2 = unpack(area)

        if self.state.eraseTireTracks then
            FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
        end

        local minX = math.min(x, x1, x2, x2 + x1 - x)
        local maxX = math.max(x, x1, x2, x2 + x1 - x)
        local minZ = math.min(z, z1, z2, z2 + z1 - z)
        local maxZ = math.max(z, z1, z2, z2 + z1 - z)

        ---@diagnostic disable-next-line: undefined-field
        g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
    end

    if self.paintDeformation ~= nil then
        self.paintDeformation:apply(false, 'onPaintDeformationCallback', self)
    end
end

function BaseLandscaping:onPaintDeformationCallback(code, volume)
    -- void
end

---@return TerrainDeformation | nil
---@nodiscard
function BaseLandscaping:createPaintDeformation()
    if self.state.enablePaintGroundTexture then
        self.paintDeformation = MachineUtils.createTerrainDeformation()

        self.paintDeformation:enablePaintingMode()

        return self.paintDeformation
    end
end

---@param volume number
function BaseLandscaping:onDeformationSuccess(volume)
    assert(false, 'BaseLandscaping:onDeformationSuccess() must be handled by inherited class!')
end

---@return TerrainDeformation
---@nodiscard
function BaseLandscaping:createTerrainDeformation()
    ---@diagnostic disable-next-line: missing-return
    assert(false, 'BaseLandscaping:createTerrainDeformation() must be handled by inherited class!')
end
