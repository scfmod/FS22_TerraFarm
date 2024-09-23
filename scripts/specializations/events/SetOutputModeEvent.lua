---@class SetOutputModeEvent : Event
---@field vehicle Machine
---@field mode MachineMode
SetOutputModeEvent = {}

local SetOutputModeEvent_mt = Class(SetOutputModeEvent, Event)

InitEventClass(SetOutputModeEvent, 'SetOutputModeEvent')

---@return SetOutputModeEvent
---@nodiscard
function SetOutputModeEvent.emptyNew()
    ---@type SetOutputModeEvent
    local self = Event.new(SetOutputModeEvent_mt)
    return self
end

---@param vehicle Machine
---@param mode MachineMode
---@return SetOutputModeEvent
---@nodiscard
function SetOutputModeEvent.new(vehicle, mode)
    local self = SetOutputModeEvent.emptyNew()

    self.vehicle = vehicle
    self.mode = mode

    return self
end

---@param streamId number
---@param connection Connection
function SetOutputModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.mode, Machine.NUM_BITS_MODE)
end

---@param streamId number
---@param connection Connection
function SetOutputModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUIntN(streamId, Machine.NUM_BITS_MODE)

    self:run(connection)
end

---@param connection Connection
function SetOutputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setOutputMode(self.mode, true)
    end
end

---@param vehicle Machine
---@param mode MachineMode
---@param noEventSend boolean | nil
function SetOutputModeEvent.sendEvent(vehicle, mode, noEventSend)
    if not noEventSend then
        local event = SetOutputModeEvent.new(vehicle, mode)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
