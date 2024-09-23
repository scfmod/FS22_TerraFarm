---@class SetEnabledEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetEnabledEvent = {}

local SetEnabledEvent_mt = Class(SetEnabledEvent, Event)

InitEventClass(SetEnabledEvent, 'SetEnabledEvent')

---@return SetEnabledEvent
---@nodiscard
function SetEnabledEvent.emptyNew()
    ---@type SetEnabledEvent
    local self = Event.new(SetEnabledEvent_mt)
    return self
end

---@param vehicle Machine
---@param enabled boolean
---@return SetEnabledEvent
---@nodiscard
function SetEnabledEvent.new(vehicle, enabled)
    local self = SetEnabledEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetEnabledEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend boolean | nil
function SetEnabledEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetEnabledEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
