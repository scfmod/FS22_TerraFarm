local _machine_count = 0

---@class TerraFarmMachine
---@field id number
---@field fullName string
---@field manager TerraFarm
---@field machineType number
---@field machineTypeName string
---@field object table
---@field enabled boolean
---@field mode number
---@field config MachineConfiguration
---@field nodeIsTouchingTerrain table<number, boolean>
---@field nodeTerrainHeight table<number, number>
---@field nodePosition table<number, Position>
---@field terraformNodesIsTouchingTerrain boolean
---@field collisionNodesIsTouchingTerrain boolean
TerraFarmMachine = {}
local TerraFarmMachine_mt = Class(TerraFarmMachine)

function TerraFarmMachine.new(manager, object, config, machineType, mt)
    ---@type TerraFarmMachine
    local self = setmetatable({}, mt or TerraFarmMachine_mt)

    _machine_count = _machine_count + 1
    self.id = _machine_count
    self.enabled = false

    self.machineType = machineType
    self.machineTypeName = g_machineTypes.typeToString[machineType]
    self.manager = manager
    self.object = object
    self.config = config

    self.mode = self.config.availableModes[1]

    self.nodeIsTouchingTerrain = {}
    self.nodeTerrainHeight = {}
    self.nodePosition = {}

    self.terraformNodesIsTouchingTerrain = false
    self.collisionNodesIsTouchingTerrain = false

    self.lastUpdate = 0

    if object.getFullName ~= nil then
        self.fullName = object:getFullName()
    else
        self.fullName = self.machineTypeName
    end

    return self
end

function TerraFarmMachine:getIsVehicleOperating()
    local vehicle = self:getVehicle()
    return vehicle and vehicle:getIsOperating()
end

function TerraFarmMachine:getVehicle()
end

function TerraFarmMachine:setEnabled(enabled)
    self.enabled = enabled
end

function TerraFarmMachine:getIsEnabled()
    if not g_terraFarm:getIsEnabled() then return false end
    return self.enabled
end

function TerraFarmMachine:isVehicle()
    return false
end

function TerraFarmMachine:isActive()
    return false
end

function TerraFarmMachine:isTouchingTerrain()
    return self.terraformNodesIsTouchingTerrain or self.collisionNodesIsTouchingTerrain
end

function TerraFarmMachine:setMode(mode)
    if self.config.availableModeByIndex[mode] == true then
        self.mode = mode
    end
end

--- NOTE: mode can be nil
---@return number|nil
function TerraFarmMachine:getMode()
    if self.mode == nil and #self.config.availableModes > 0 and self.config.availableModes[1] ~= nil then
        self.mode = self.config.availableModes[1]
    end

    return self.mode
end

-- TODO: This function can probably be done better, but VERY LOW PRIORITY as long as it works for now..
function TerraFarmMachine:toggleMode()
    if #self.config.availableModes <= 1 then
        return
    end

    local result

    for i, mode in ipairs(self.config.availableModes) do
        if mode == self.mode then
            result = self.config.availableModes[i + 1]
            break
        end
    end

    if not result then
        result = self.config.availableModes[1]
    end

    self.mode = result
end

---@param dt number
---@diagnostic disable-next-line: unused-local
function TerraFarmMachine:onUpdate(dt)
end

---@param name string
---@param ignoreManagerConfig boolean
function TerraFarmMachine:getConfigProperty(name, ignoreManagerConfig)
    if ignoreManagerConfig then
        return self.config[name]
    else
        return self.config[name] or self.manager.config[name]
    end
end

function TerraFarmMachine:setConfigProperty(name, value)
    self.config[name] = value
end

function TerraFarmMachine:getStrength()
    return self.config.terraformStrength or self.manager.config.terraformStrength
end

function TerraFarmMachine:setStrength(value)
    self.config.terraformStrength = value
end

function TerraFarmMachine:getRadius()
    return self.config.terraformRadius or self.manager.config.terraformRadius
end

function TerraFarmMachine:setRadius(value)
    self.config.terraformRadius = value
end

function TerraFarmMachine:getSmoothStrength()
    return self.config.terraformSmoothStrength or self.manager.config.terraformSmoothStrength
end

function TerraFarmMachine:setSmoothStrength(value)
    self.config.terraformSmoothStrength = value
end

function TerraFarmMachine:getSmoothRadius()
    return self.config.terraformSmoothRadius or self.manager.config.terraformSmoothRadius
end

function TerraFarmMachine:setSmoothRadius(value)
    self.config.terraformSmoothRadius = value
end

function TerraFarmMachine:getFlattenStrength()
    return self.config.terraformFlattenStrength or self.manager.config.terraformFlattenStrength
end

function TerraFarmMachine:setFlattenStrength(value)
    self.config.terraformFlattenStrength = value
end

function TerraFarmMachine:getFlattenRadius()
    return self.config.terraformFlattenRadius or self.manager.config.terraformFlattenRadius
end

function TerraFarmMachine:setFlattenRadius(value)
    self.config.terraformFlattenRadius = value
end

function TerraFarmMachine:getPaintRadius()
    return self.config.terraformPaintRadius or self.manager.config.terraformPaintRadius
end

function TerraFarmMachine:setPaintRadius(value)
    self.config.terraformPaintRadius = value
end

---@return number x
---@return number y
---@return number z
---@return number height
---@return number rootNode
function TerraFarmMachine:getVehiclePosition()
    local vehicle = self:getVehicle()
    if vehicle then
        local x, y, z = getWorldTranslation(vehicle.rootNode)
        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

        return x, y, z, height, vehicle.rootNode
    end
end

function TerraFarmMachine:updateNodes()
    self:updateTerraformNodes()
    self:updateCollisionNodes()
    self:updatePaintNodes()
end

function TerraFarmMachine:updateTerraformNodes()
    self.terraformNodesIsTouchingTerrain = false

    for _, node in ipairs(self.config.terraformNodes) do
        local x, y, z = localToWorld(node, 0, 0, 0)
        local position = { x = x, y = y, z = z}

        self.nodePosition[node] = position

        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        self.nodeTerrainHeight[node] = height

        if height ~= nil and y < height then
            self.nodeIsTouchingTerrain[node] = true
            self.terraformNodesIsTouchingTerrain = true
        else
            self.nodeIsTouchingTerrain[node] = false
        end
    end
end

function TerraFarmMachine:updateCollisionNodes()
    self.collisionNodesIsTouchingTerrain = false

    for _, node in ipairs(self.config.collisionNodes) do
        local x, y, z = localToWorld(node, 0, 0, 0)
        local position = { x = x, y = y, z = z}

        self.nodePosition[node] = position

        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        self.nodeTerrainHeight[node] = height

        if height ~= nil and y < height then
            self.nodeIsTouchingTerrain[node] = true
            self.collisionNodesIsTouchingTerrain = true
        else
            self.nodeIsTouchingTerrain[node] = false
        end
    end
end

function TerraFarmMachine:updatePaintNodes()
    for _, node in ipairs(self.config.paintNodes) do
        local x, y, z = localToWorld(node, 0, 0, 0)
        local position = { x = x, y = y, z = z}
        self.nodePosition[node] = position

        local height = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        self.nodeTerrainHeight[node] = height
    end
end


---@return number
function TerraFarmMachine:getPaintLayer()
    return g_terraFarm.config.terraformPaintLayer
end

---@return number
function TerraFarmMachine:getDischargePaintLayer()
    return g_terraFarm.config.dischargePaintLayer or self:getPaintLayer()
end

---@return Position[]
function TerraFarmMachine:getPaintNodes()
    local result = {}

    for _, node in pairs(self.config.paintNodes) do
        local position = self.nodePosition[node]
        local height = self.nodeTerrainHeight[node]

        if position and height then
            local entry = {x = position.x, y = height, z = position.z}
            table.insert(result, entry)
        end
    end

    return result
end

---@return Position[]
function TerraFarmMachine:getActiveTerraformNodes()
    local result = {}

    for _, node in pairs(self.config.terraformNodes) do
        if self.nodeIsTouchingTerrain[node] == true then
            local position = self.nodePosition[node]
            local height = self.nodeTerrainHeight[node]

            if position and height then
                local entry = {x = position.x, y = height, z = position.z}
                table.insert(result, entry)
            end
        end
    end

    return result
end

function TerraFarmMachine:applyTerraformRaise()
    local nodePositions = self:getActiveTerraformNodes()

    if #nodePositions == 0 then
        return false
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.RAISE,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getRadius(),
        self:getStrength(),
        nil,
        self:getPaintLayer()
    )
end

function TerraFarmMachine:applyTerraformLower()
    local nodePositions = self:getActiveTerraformNodes()

    if #nodePositions == 0 then
        return false
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.LOWER,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getRadius(),
        self:getStrength(),
        nil,
        self:getPaintLayer()
    )
end


---@param factor number
function TerraFarmMachine:applyTerraformSmooth(factor)
    local nodePositions = self:getActiveTerraformNodes()

    if #nodePositions == 0 then
        return false
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.SMOOTH,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getSmoothRadius(),
        self:getSmoothStrength() * (factor or 1.0),
        nil,
        self:getPaintLayer()
    )
end

function TerraFarmMachine:applyTerraformFlatten(target)
    local nodePositions = self:getActiveTerraformNodes()

    if #nodePositions == 0 then
        return false
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.FLATTEN,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getFlattenRadius(),
        self:getFlattenStrength(),
        target,
        self:getPaintLayer()
    )
end

function TerraFarmMachine:applyTerraformPaint(isDischarging)
    local nodePositions = self:getActiveTerraformNodes()

    if #nodePositions == 0 then
        return false
    end

    local paintLayer = self:getPaintLayer()

    if isDischarging then
        paintLayer = self:getDischargePaintLayer()
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.PAINT,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getPaintRadius(),
        0,
        nil,
        paintLayer,
        isDischarging == true
    )
end

function TerraFarmMachine:applyPaint(isDischarging)
    local nodePositions = self:getPaintNodes()

    if #nodePositions == 0 then
        return false
    end

    local paintLayer = self:getPaintLayer()

    if isDischarging then
        paintLayer = self:getDischargePaintLayer()
    end

    self.manager:sendTerraformRequest(
        self.machineType,
        self.object,
        TerraFarmLandscaping.OPERATION.PAINT,
        Landscaping.BRUSH_SHAPE.CIRCLE,
        nodePositions,
        self:getPaintRadius(),
        0,
        nil,
        paintLayer,
        isDischarging == true
    )
end