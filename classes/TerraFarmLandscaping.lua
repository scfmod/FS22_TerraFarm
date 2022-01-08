local SQRT_2_DIV_FACTOR = 1 / math.sqrt(2)

---@class TerraFarmLandscaping
---@field terrainDeformationQueue TerrainDeformationQueue
---@field terrainRootNode number
---@field terrainUnit number
---@field halfTerrainUnit number
---@field modifiedAreas table
---@field callbackFunction function
---@field callbackFunctionTarget table
---@field isTerrainDeformationPending boolean
---@field currentTerrainDeformation TerrainDeformation
---@field operation number
---@field isDischarging boolean
TerraFarmLandscaping = {}
local TerraFarmLandscaping_mt = Class(TerraFarmLandscaping)

-- Limiting to max 16 nodes when sending event
TerraFarmLandscaping.NODES_NUM_SEND_BITS = 4
TerraFarmLandscaping.OPERATION_NUM_SEND_BITS = 3
TerraFarmLandscaping.OPERATION = {
    PAINT = 1,
    RAISE = 2,
    LOWER = 3,
    SMOOTH = 4,
    FLATTEN = 5
}

---@return TerraFarmLandscaping
function TerraFarmLandscaping.new(callbackFunction, callbackFunctionTarget)
    ---@type TerraFarmLandscaping
    local self = setmetatable({}, TerraFarmLandscaping_mt)

    self.terrainDeformationQueue = g_terrainDeformationQueue
    self.terrainRootNode = g_currentMission.terrainRootNode
    self.terrainUnit = Landscaping.TERRAIN_UNIT
    self.halfTerrainUnit = self.terrainUnit / 2
    self.modifiedAreas = {}

    self.callbackFunction = callbackFunction
    self.callbackFunctionTarget = callbackFunctionTarget

    return self
end

---@param machineType number
---@param mode number
---@param object table
---@param operation number
---@param position Position
---@param radius number
---@param strength number
---@param brushShape number
---@param paintLayer number
---@param target Position[]
---@param isDischarging boolean
function TerraFarmLandscaping:sculpt(
    machineType,
    mode,
    object,
    operation,
    position,
    radius,
    strength,
    brushShape,
    paintLayer,
    target,
    isDischarging
)
    self.isTerrainDeformationPending = true
    local deform = TerrainDeformation.new(self.terrainRootNode)
    self.currentTerrainDeformation = deform

    self.operation = operation
    self.object = object
    self.isDischarging = isDischarging

    if operation == TerraFarmLandscaping.OPERATION.SMOOTH then
        self:assignSmoothingParameters(deform, position.x, position.z, radius, strength, brushShape)

        deform:setBlockedAreaMaxDisplacement(0.00001)
        deform:setDynamicObjectCollisionMask(0)
        deform:setDynamicObjectMaxDisplacement(0.00003)

        self.terrainDeformationQueue:queueJob(deform, false, 'onSculptingApplied', self)
    elseif operation == TerraFarmLandscaping.OPERATION.PAINT then
        self:assignPaintingParameters(deform, position.x, position.z, radius, brushShape, paintLayer)
        deform:apply(false, 'onSculptingApplied', self)
    else
        self:assignSculptingParameters(deform, machineType, mode, operation, position, radius, strength, brushShape, target)

        deform:setBlockedAreaMaxDisplacement(0.00001)
        deform:setDynamicObjectCollisionMask(0)
        deform:setDynamicObjectMaxDisplacement(0.00003)

        self.terrainDeformationQueue:queueJob(deform, false, 'onSculptingApplied', self)
    end
end

---@param x number
---@param z number
---@param radius number
function TerraFarmLandscaping:addModifiedCircleArea(x, z, radius)
    if radius < self.terrainUnit + self.halfTerrainUnit then
		local size = radius * 2 * SQRT_2_DIV_FACTOR

		self:addModifiedSquareArea(x, z, size)
	else
		for ox = -radius / self.terrainUnit, radius / self.terrainUnit - 1 do
			local xStart = ox * self.terrainUnit
			local xEnd = ox * self.terrainUnit + self.terrainUnit
			local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
			local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
			local zOffset = math.min(zOffset1, zOffset2) - 0.02

			table.insert(self.modifiedAreas, {
				x + xStart,
				z - zOffset,
				x + xEnd,
				z - zOffset,
				x + xStart,
				z + zOffset
			})
		end
	end
end

---@param x number
---@param z number
---@param side number
function TerraFarmLandscaping:addModifiedSquareArea(x, z, side)
    local halfSide = side * 0.5

	table.insert(self.modifiedAreas, {
		x - halfSide,
		z - halfSide,
		x + halfSide,
		z - halfSide,
		x - halfSide,
		z + halfSide
	})
end

function TerraFarmLandscaping:assignPaintingParameters(deform, x, z, radius, brushShape, layer)
    local hardness = 1.0
    local strength = 1.0

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(x, z, radius, hardness, strength, layer)
        self:addModifiedCircleArea(x, z, radius)
    else
        deform:addSoftSquareBrush(x, z, radius * 2, hardness, strength, layer)
        self:addModifiedSquareArea(x, z, radius * 2)
    end
end

---@param deform TerrainDeformation
---@param x number
---@param z number
---@param radius number
---@param strength number
---@param brushShape number
function TerraFarmLandscaping:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
    local hardness = 0.2

    deform:setAdditiveHeightChangeAmount(0.5)
    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(x, z, radius, hardness, strength)
        self:addModifiedCircleArea(x, z, radius)
    else
        deform:addSoftSquareBrush(x, z, radius * 2, hardness, strength)
        self:addModifiedSquareArea(x, z, radius * 2)
    end

    deform:enableSmoothingMode()
end


---@param deform TerrainDeformation
---@param machineType number
---@param mode number
---@param operation number
---@param position Position
---@param radius number
---@param strength number
---@param brushShape number
---@param target table
---@diagnostic disable-next-line: unused-local
function TerraFarmLandscaping:assignSculptingParameters(deform, machineType, mode, operation, position, radius, strength, brushShape, target)
    local hardness = 0.2

    if operation == TerraFarmLandscaping.OPERATION.LOWER then
        deform:enableAdditiveDeformationMode()
        deform:setAdditiveHeightChangeAmount(-0.005)
    elseif operation == TerraFarmLandscaping.OPERATION.RAISE then
        deform:enableAdditiveDeformationMode()
        deform:setAdditiveHeightChangeAmount(0.005)
    elseif operation == TerraFarmLandscaping.OPERATION.FLATTEN then
        deform:setAdditiveHeightChangeAmount(0.05)
        deform:setHeightTarget(target.y, target.y, 0, 1, 0, -target.y)
        -- deform:setHeightTarget(45, 45, 0, 1, 0, -45)
        deform:enableSetDeformationMode()
    end

    if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
        deform:addSoftCircleBrush(position.x, position.z, radius, hardness, strength)
        self:addModifiedCircleArea(position.x, position.z, radius)
    else
        deform:addSoftSquareBrush(position.x, position.z, radius * 2, hardness, strength)
        self:addModifiedSquareArea(position.x, position.z, radius * 2)
    end

    deform:setOutsideAreaConstraints(0, math.pi * 2, math.pi * 2)
end


function TerraFarmLandscaping:onSculptingApplied(errorCode, displacedVolumeOrArea)
    if errorCode == TerrainDeformation.STATE_SUCCESS then
        for _, area in pairs(self.modifiedAreas) do
            local x, z, x1, z1, x2, z2 = unpack(area)

            FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
            FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
            FSDensityMapUtil.removeStoneArea(x, z, x1, z1, x2, z2)

            FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
            DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)

            if self.operation == TerraFarmLandscaping.OPERATION.PAINT then
                FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
            end

            local minX = math.min(x, x1, x2, x2 + x1 - x)
            local maxX = math.max(x, x1, x2, x2 + x1 - x)
            local minZ = math.min(z, z1, z2, z2 + z1 - z)
            local maxZ = math.max(z, z1, z2, z2 + z1 - z)

            g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
        end

        ---@type TerraFarmShovel
        local machine = g_terraFarm.objectToMachine[self.object]

        if machine ~= nil and machine.onVolumeDisplacement ~= nil then
            if self.operation == TerraFarmLandscaping.OPERATION.RAISE then
                -- machine:onVolumeDisplacement(-displacedVolumeOrArea)
                machine:onVolumeDisplacement(-displacedVolumeOrArea * g_terraFarm.config.raiseDisplacementVolumeRatio)
            elseif self.operation == TerraFarmLandscaping.OPERATION.LOWER then
                -- machine:onVolumeDisplacement(displacedVolumeOrArea * 1.618)
                machine:onVolumeDisplacement(displacedVolumeOrArea * g_terraFarm.config.lowerDisplacementVolumeRatio)
            elseif self.operation == TerraFarmLandscaping.OPERATION.FLATTEN then
                if self.isDischarging then
                    -- machine:onVolumeDisplacement(displacedVolumeOrArea * -0.5)
                    machine:onVolumeDisplacement(displacedVolumeOrArea * g_terraFarm.config.flattenDischargeDisplacementVolumeRatio * -1.0)
                else
                    -- machine:onVolumeDisplacement(displacedVolumeOrArea)
                    machine:onVolumeDisplacement(displacedVolumeOrArea * g_terraFarm.config.flattenDisplacementVolumeRatio)
                end
            end
        else
            Logging.warning('TerraFarmLandscaping.onSculptingApplied: machine is nil')
        end
    end

    if self.callbackFunctionTarget ~= nil then
        self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)
    elseif self.callbackFunction ~= nil then
        self.callbackFunction(errorCode, displacedVolumeOrArea)
    end

    self.currentTerrainDeformation:delete()
    self.currentTerrainDeformation = nil
end