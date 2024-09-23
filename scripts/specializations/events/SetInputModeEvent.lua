---@class SetInputModeEvent : Event
---@field vehicle Machine
---@field mode MachineMode
SetInputModeEvent = {}

local SetInputModeEvent_mt = Class(SetInputModeEvent, Event)

InitEventClass(SetInputModeEvent, 'SetInputModeEvent')

---@return SetInputModeEvent
---@nodiscard
function SetInputModeEvent.emptyNew()
    ---@type SetInputModeEvent
    local self = Event.new(SetInputModeEvent_mt)
    return self
end

---@param vehicle Machine
---@param mode MachineMode
---@return SetInputModeEvent
---@nodiscard
function SetInputModeEvent.new(vehicle, mode)
    local self = SetInputModeEvent.emptyNew()

    self.vehicle = vehicle
    self.mode = mode

    return self
end

---@param streamId number
---@param connection Connection
function SetInputModeEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.mode, Machine.NUM_BITS_MODE)
end

---@param streamId number
---@param connection Connection
function SetInputModeEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.mode = streamReadUIntN(streamId, Machine.NUM_BITS_MODE)

    self:run(connection)
end

---@param connection Connection
function SetInputModeEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setInputMode(self.mode, true)
    end
end

---@param vehicle Machine
---@param mode MachineMode
---@param noEventSend boolean | nil
function SetInputModeEvent.sendEvent(vehicle, mode, noEventSend)
    if not noEventSend then
        local event = SetInputModeEvent.new(vehicle, mode)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
