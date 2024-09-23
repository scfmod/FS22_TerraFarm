---@class LandscapingPaint : BaseLandscaping
LandscapingPaint = {}

local LandscapingPaint_mt = Class(LandscapingPaint, BaseLandscaping)

---@param workArea MachineWorkArea
---@return LandscapingPaint
---@nodiscard
function LandscapingPaint.new(workArea)
    ---@type LandscapingPaint
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = BaseLandscaping.new(LandscapingOperation.PAINT, workArea, LandscapingPaint_mt)

    self.strength = 0.5
    self.hardness = 0.2

    return self
end

function LandscapingPaint:apply()
    local deformation = self:createTerrainDeformation()
    local densityRadius = self.radius * self.state.densityModifier
    local paintRadius = self.radius * self.state.paintModifier

    if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftCircleBrush(position[1], position[3], paintRadius, self.hardness, self.strength, self.terrainLayerId)
                MachineUtils.addModifiedCircleArea(self.modifiedAreas, position[1], position[3], paintRadius)
                MachineUtils.addModifiedCircleArea(self.densityModifiedAreas, position[1], position[3], densityRadius)
            end
        end
    else
        for node, position in pairs(self.workArea.nodePosition) do
            if self.workArea.nodeActive[node] then
                deformation:addSoftSquareBrush(position[1], position[3], paintRadius * 2, self.hardness, self.strength, self.terrainLayerId)
                MachineUtils.addModifiedSquareArea(self.modifiedAreas, position[1], position[3], paintRadius * 2)
                MachineUtils.addModifiedSquareArea(self.densityModifiedAreas, position[1], position[3], densityRadius * 2)
            end
        end
    end

    deformation:apply(false, 'onDeformationCallback', self)
end

---@return TerrainDeformation
---@nodiscard
function LandscapingPaint:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enablePaintingMode()

    return self.deformation
end

---@param volume number
function LandscapingPaint:onDeformationSuccess(volume)
    self:applyDeformationChanges()
end

function LandscapingPaint:applyDeformationChanges()
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
end
