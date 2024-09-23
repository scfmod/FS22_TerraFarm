---@class MachineWorkArea
---@field vehicle Machine
---@field machineType MachineType
---@field referenceNode number
---@field rootNode number
---@field nodes number[]
---@field width number
---@field offset Position
---@field rotation Position
---@field isActive boolean
---
---@field nodeActive table<number, boolean>
---@field nodePosition table<number, Position>
---@field nodeTerrainY table<number, number>
---
---@field density number
MachineWorkArea = {}

local MachineWorkArea_mt = Class(MachineWorkArea)

---@param schema XMLSchema
---@param key string
function MachineWorkArea.registerXMLPaths(schema, key)
    schema:register(XMLValueType.NODE_INDEX, key .. '#referenceNode')
    schema:register(XMLValueType.FLOAT, key .. '#width')
    schema:register(XMLValueType.FLOAT, key .. '#density', 'Node density', 0.75)
    schema:register(XMLValueType.VECTOR_3, key .. '#offset', 'Offset position from reference node', '0 0 0')
    schema:register(XMLValueType.VECTOR_ROT, key .. '#rotation', 'Rotation in degrees', '0 0 0')
end

---@param vehicle Machine
---@return MachineWorkArea
---@nodiscard
function MachineWorkArea.new(vehicle)
    ---@type MachineWorkArea
    local self = setmetatable({}, MachineWorkArea_mt)

    self.vehicle = vehicle
    self.machineType = vehicle.spec_machine.machineType
    self.isActive = false
    self.density = 0.75

    self.nodes = {}
    self.nodeActive = {}
    self.nodePosition = {}
    self.nodeTerrainY = {}

    return self
end

---@param xmlFile XMLFile
---@param key string
function MachineWorkArea:loadFromXMLFile(xmlFile, key)
    self.referenceNode = xmlFile:getValue(key .. '#referenceNode', nil, self.vehicle.components, self.vehicle.i3dMappings)

    self.width = xmlFile:getValue(key .. '#width')

    if self.width ~= nil then
        self.width = MathUtil.clamp(self.width, 0.1, 16)
    end

    self.density = MathUtil.clamp(xmlFile:getValue(key .. '#density', self.density), 0.25, 4)
    self.offset = xmlFile:getValue(key .. '#offset', '0 0 0', true)
    self.rotation = xmlFile:getValue(key .. '#rotation', '0 0 0', true)
end

function MachineWorkArea:rebuild()
    Logging.info('MachineWorkArea:rebuild()')

    self.isActive = false
    self.nodeActive = {}
    self.nodePosition = {}
    self.nodeTerrainY = {}

    for _, node in ipairs(self.nodes) do
        delete(node)
    end

    self.nodes = {}

    self:createNodes()
end

function MachineWorkArea:createNodes()
    local halfWidth = self.width / 2
    local z = 0

    if self.width < 0.5 then
        self:addWorkAreaNode(0, 0, z)
    elseif self.width < 0.8 then
        self:addWorkAreaNode(-halfWidth, 0, z)
        self:addWorkAreaNode(halfWidth, 0, z)
    elseif self.width < 1.5 then
        self:addWorkAreaNode(-halfWidth, 0, z)
        self:addWorkAreaNode(0, 0, z)
        self:addWorkAreaNode(halfWidth, 0, z)
    else
        local numOfNodes = MathUtil.round(self.width / self.density)
        local distance = self.width / numOfNodes

        for i = 0, numOfNodes do
            local x = -halfWidth + (i * distance)

            self:addWorkAreaNode(x, 0, z)
        end
    end
end

function MachineWorkArea:initialize()
    if self.rootNode ~= nil then
        Logging.error('MachineWorkArea:initialize() workArea is already initialized!')
        return
    end

    if self.referenceNode == nil and self.machineType.useShovel and self.vehicle.spec_machine.hasShovel then
        local shovelNode = self.vehicle.spec_machine.shovelNode

        if shovelNode ~= nil then
            self.referenceNode = shovelNode.node
            self.offset[2] = self.offset[2] + shovelNode.yOffset
            self.offset[3] = self.offset[3] + shovelNode.zOffset

            if self.width == nil then
                self.width = shovelNode.width
            end
        end
    end

    if self.referenceNode == nil and self.machineType.useLeveler and self.vehicle.spec_machine.hasLeveler then
        local levelerNode = self.vehicle.spec_machine.levelerNode

        if levelerNode ~= nil then
            self.referenceNode = levelerNode.node
            -- self.referenceNode = levelerNode.referenceFrame
            self.offset[2] = self.offset[2] + levelerNode.yOffset
            self.offset[3] = self.offset[3] + levelerNode.zOffset

            if self.width == nil then
                self.width = levelerNode.width
            end
        end
    end

    assert(self.referenceNode ~= nil, 'No referenceNode found ...')

    self.rootNode = createTransformGroup('root')
    link(self.referenceNode, self.rootNode)
    setTranslation(self.rootNode, self.offset[1], self.offset[2], self.offset[3])
    setRotation(self.rootNode, self.rotation[1], self.rotation[2], self.rotation[3])

    self:createNodes()
end

---@param x number
---@param y number
---@param z number
function MachineWorkArea:addWorkAreaNode(x, y, z)
    local node = createTransformGroup('node')

    link(self.rootNode, node)
    setTranslation(node, x, y, z)

    table.insert(self.nodes, node)
end

function MachineWorkArea:update()
    self.isActive = false

    for _, node in ipairs(self.nodes) do
        local x, y, z = getWorldTranslation(node)
        local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
        local active = h >= y

        self.nodePosition[node] = { x, y, z }
        self.nodeTerrainY[node] = h
        self.nodeActive[node] = active

        if active then
            self.isActive = true
        end
    end
end

function MachineWorkArea:paint()
    local op = LandscapingPaint.new(self)
    op:apply()
end

function MachineWorkArea:flatten()
    local targetWorldPosY = self:getTargetTerrainHeight()
    local op = LandscapingFlatten.new(self, targetWorldPosY)

    op:apply()
end

function MachineWorkArea:smooth()
    local op = LandscapingSmooth.new(self)
    op:apply()
end

function MachineWorkArea:lower()
    local op = LandscapingLower.new(self)
    op:apply()
end

function MachineWorkArea:raise()
    -- TODO .. if/when needed
end

-- Get current calibration angle
---@return number
---@nodiscard
function MachineWorkArea:getCalibrationAngle()
    local surveyor = self.vehicle:getSurveyor()

    if surveyor ~= nil then
        local startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ = surveyor:getCalibration()

        return MachineUtils.getAngleBetweenPoints(
            startPosX, startPosY, startPosZ,
            endPosX, endPosY, endPosZ
        )
    end

    return 0
end

-- Get target height at current position
-- Calculated based on variable conditions
---@return number
---@nodiscard
function MachineWorkArea:getTargetTerrainHeight()
    local surveyor = self.vehicle:getSurveyor()

    if surveyor ~= nil and surveyor:getIsCalibrated() then
        local startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ = surveyor:getCalibration()

        if endPosY ~= math.huge then
            local nodePosX, nodePosY, nodePosZ = self:getPosition()
            local _, linePosY, _, _ = MachineUtils.getClosestPointOnLine(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, nodePosX, nodePosY, nodePosZ)

            return linePosY
        end

        return startPosY
    end

    return MachineUtils.getVehicleTargetHeight(self.vehicle)
end

---@return number worldPosX
---@return number worldPosY
---@return number worldPosZ
function MachineWorkArea:getPosition()
    return getWorldTranslation(self.rootNode)
end