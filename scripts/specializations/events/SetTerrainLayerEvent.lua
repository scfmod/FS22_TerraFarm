---@class SetTerrainLayerEvent : Event
---@field vehicle Machine
---@field terrainLayerId number
SetTerrainLayerEvent = {}

local SetTerrainLayerEvent_mt = Class(SetTerrainLayerEvent, Event)

InitEventClass(SetTerrainLayerEvent, 'SetTerrainLayerEvent')

---@return SetTerrainLayerEvent
---@nodiscard
function SetTerrainLayerEvent.emptyNew()
    ---@type SetTerrainLayerEvent
    local self = Event.new(SetTerrainLayerEvent_mt)
    return self
end

---@param vehicle Machine
---@param terrainLayerId number
---@return SetTerrainLayerEvent
---@nodiscard
function SetTerrainLayerEvent.new(vehicle, terrainLayerId)
    local self = SetTerrainLayerEvent.emptyNew()

    self.vehicle = vehicle
    self.terrainLayerId = terrainLayerId

    return self
end

---@param streamId number
---@param connection Connection
function SetTerrainLayerEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.terrainLayerId, TerrainDeformation.LAYER_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetTerrainLayerEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.terrainLayerId = streamReadUIntN(streamId, TerrainDeformation.LAYER_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetTerrainLayerEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineTerrainLayerId(self.terrainLayerId, true)
    end
end

---@param vehicle Machine
---@param terrainLayerId number
---@param noEventSend boolean | nil
function SetTerrainLayerEvent.sendEvent(vehicle, terrainLayerId, noEventSend)
    if not noEventSend then
        local event = SetTerrainLayerEvent.new(vehicle, terrainLayerId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
