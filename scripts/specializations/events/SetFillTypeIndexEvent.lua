---@class SetFillTypeEvent : Event
---@field vehicle Machine
---@field fillTypeIndex number
SetFillTypeEvent = {}

local SetFillTypeEvent_mt = Class(SetFillTypeEvent, Event)

InitEventClass(SetFillTypeEvent, 'SetFillTypeEvent')

---@return SetFillTypeEvent
---@nodiscard
function SetFillTypeEvent.emptyNew()
    ---@type SetFillTypeEvent
    local self = Event.new(SetFillTypeEvent_mt)
    return self
end

---@param vehicle Machine
---@param fillTypeIndex number
---@return SetFillTypeEvent
function SetFillTypeEvent.new(vehicle, fillTypeIndex)
    local self = SetFillTypeEvent.emptyNew()

    self.vehicle = vehicle
    self.fillTypeIndex = fillTypeIndex

    return self
end

---@param streamId number
---@param connection Connection
function SetFillTypeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetFillTypeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetFillTypeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineFillTypeIndex(self.fillTypeIndex, true)
    end
end

---@param vehicle Machine
---@param fillTypeIndex number
---@param noEventSend boolean | nil
function SetFillTypeEvent.sendEvent(vehicle, fillTypeIndex, noEventSend)
    if not noEventSend then
        local event = SetFillTypeEvent.new(vehicle, fillTypeIndex)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
