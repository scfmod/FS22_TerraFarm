---@class TerraFarmLandscapingEvent
---@field runConnection number
---@field machineType number
---@field object table
---@field mode number
---@field operation number
---@field position Position
---@field radius number
---@field strength number
---@field brushShape number
---@field paintLayer number
---@field target Position
---@field isDischarging boolean
--- SERVER TO CLIENT
---@field errorCode number
---@field displacedVolumeOrArea number
TerraFarmLandscapingEvent = {}
local TerraFarmLandscapingEvent_mt = Class(TerraFarmLandscapingEvent, Event)

InitEventClass(TerraFarmLandscapingEvent, 'TerraFarmLandscapingEvent')

---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.emptyNew()
    local self = Event.new(TerraFarmLandscapingEvent_mt)
    return self
end

---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.new(machineType, mode, object, operation, position, radius, strength, brushShape, paintLayer, target, isDischarging)
    -- Logging.info('TerraFarmLandscapingEvent.new')
    local self = TerraFarmLandscapingEvent.emptyNew()

    self.runConnection = nil
    self.machineType = machineType
    self.mode = mode
    self.object = object
    self.operation = operation
    self.position = position
    self.radius = radius or 0
    self.strength = strength or 0
    self.brushShape = brushShape or Landscaping.BRUSH_SHAPE.CIRCLE
    self.paintLayer = paintLayer or 0
    self.target = target
    self.isDischarging = isDischarging or false

    if type(paintLayer) == 'string' then
        self.paintLayer = TerraFarmGroundTypes:getLayerByName(paintLayer)
    end

    return self
end

---@return TerraFarmLandscapingEvent
function TerraFarmLandscapingEvent.newServerToClient(errorCode, displacedVolumeOrArea)
    -- Logging.info('TerraFarmLandscapingEvent.newServerToClient')
    local self = TerraFarmLandscapingEvent.emptyNew()

    self.errorCode = errorCode
    self.displacedVolumeOrArea = displacedVolumeOrArea

    return self
end


function TerraFarmLandscapingEvent:delete()
end

function TerraFarmLandscapingEvent:writeStream(streamId, connection)
    -- Logging.info('TerraFarmLandscapingEvent:writeStream')
    if connection:getIsServer() then
        if self.object == nil then
            Logging.warning('TerraFarmLandscapingEvent.writeStream: object is nil')
        end
        streamWriteUIntN(streamId, self.machineType, TerraFarm.TYPE_NUM_SEND_BITS)
        streamWriteUIntN(streamId, self.mode, TerraFarm.MODE_NUM_SEND_BITS)
        NetworkUtil.writeNodeObject(streamId, self.object)
        streamWriteUIntN(streamId, self.operation, TerraFarmLandscaping.OPERATION_NUM_SEND_BITS)

        streamWriteBool(streamId, self.isDischarging)

        streamWriteFloat32(streamId, self.position.x)
        streamWriteFloat32(streamId, self.position.y)
        streamWriteFloat32(streamId, self.position.z)

        streamWriteFloat32(streamId, self.radius)
        streamWriteFloat32(streamId, self.strength)
        streamWriteUIntN(streamId, self.brushShape, Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
        streamWriteFloat32(streamId, self.paintLayer)

        if streamWriteBool(streamId, self.target ~= nil) then
            streamWriteFloat32(streamId, self.target.x)
            streamWriteFloat32(streamId, self.target.y)
            streamWriteFloat32(streamId, self.target.z)
        end
    else
        streamWriteUIntN(streamId, self.errorCode, TerrainDeformation.STATE_SEND_NUM_BITS)
        if streamWriteBool(streamId, self.errorCode == TerrainDeformation.STATE_SUCCESS) then
			streamWriteFloat32(streamId, self.displacedVolumeOrArea or 0)
		end
    end
end

function TerraFarmLandscapingEvent:readStream(streamId, connection)
    -- Logging.info('TerraFarmLandscapingEvent:readStream')
    if not connection:getIsServer() then
        self.machineType = streamReadUIntN(streamId, TerraFarm.TYPE_NUM_SEND_BITS)
        self.mode = streamReadUIntN(streamId, TerraFarm.MODE_NUM_SEND_BITS)
        self.object = NetworkUtil.readNodeObject(streamId)
        self.operation = streamReadUIntN(streamId, TerraFarmLandscaping.OPERATION_NUM_SEND_BITS)

        self.isDischarging = streamReadBool(streamId)

        self.position = {}
        self.position.x = streamReadFloat32(streamId)
        self.position.y = streamReadFloat32(streamId)
        self.position.z = streamReadFloat32(streamId)

        self.radius = streamReadFloat32(streamId)
        self.strength = streamReadFloat32(streamId)
        self.brushShape = streamReadUIntN(streamId,Landscaping.BRUSH_SHAPE_NUM_SEND_BITS)
        self.paintLayer = streamReadFloat32(streamId)

        if streamReadBool(streamId) then
            self.target = {}
            self.target.x = streamReadFloat32(streamId)
            self.target.y = streamReadFloat32(streamId)
            self.target.z = streamReadFloat32(streamId)
        end
    else
        self.errorCode = streamReadUIntN(streamId, TerrainDeformation.STATE_SEND_NUM_BITS)

        if streamReadBool(streamId) then
            self.displacedVolumeOrArea = streamReadFloat32(streamId)
        else
            self.displacedVolumeOrArea = 0
        end
    end

    self:run(connection)
end

---@param connection Connection
function TerraFarmLandscapingEvent:run(connection)
    -- Logging.info('TerraFarmLandscapingEvent:run')
    -- Logging.info('connectionIsServer: ' .. tostring(connection:getIsServer()))

    if not connection:getIsServer() and g_currentMission ~= nil then
        self.runConnection = connection
        local landscaping = TerraFarmLandscaping.new(self.onSculptingFinished, self)

        landscaping:sculpt(
            self.machineType,
            self.mode,
            self.object,
            self.operation,
            self.position,
            self.radius,
            self.strength,
            self.brushShape,
            self.paintLayer,
            self.target,
            self.isDischarging
        )
    else
        g_messageCenter:publish(TerraFarmLandscapingEvent, self.errorCode, self.displacedVolumeOrArea)
    end
end

function TerraFarmLandscapingEvent:onSculptingFinished(errorCode, displacedVolumeOrArea)
    -- Logging.info('TerraFarmLandscapingEvent:onSculptingFinished')
    if self.runConnection ~= nil and self.runConnection.isConnected then
        local response = TerraFarmLandscapingEvent.newServerToClient(errorCode, displacedVolumeOrArea)
        self.runConnection:sendEvent(response)
    end
end