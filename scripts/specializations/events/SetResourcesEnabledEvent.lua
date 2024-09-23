---@class SetResourcesEnabledEvent : Event
---@field vehicle Machine
---@field enabled boolean
SetResourcesEnabledEvent = {}

local SetResourcesEnabledEvent_mt = Class(SetResourcesEnabledEvent, Event)

InitEventClass(SetResourcesEnabledEvent, 'SetResourcesEnabledEvent')

---@return SetResourcesEnabledEvent
---@nodiscard
function SetResourcesEnabledEvent.emptyNew()
    ---@type SetResourcesEnabledEvent
    local self = Event.new(SetResourcesEnabledEvent_mt)
    return self
end

---@param vehicle Machine
---@param enabled boolean
---@return SetResourcesEnabledEvent
---@nodiscard
function SetResourcesEnabledEvent.new(vehicle, enabled)
    local self = SetResourcesEnabledEvent.emptyNew()

    self.vehicle = vehicle
    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetResourcesEnabledEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetResourcesEnabledEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetResourcesEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setResourcesEnabled(self.enabled, true)
    end
end

---@param vehicle Machine
---@param enabled boolean
---@param noEventSend boolean | nil
function SetResourcesEnabledEvent.sendEvent(vehicle, enabled, noEventSend)
    if not noEventSend then
        local event = SetResourcesEnabledEvent.new(vehicle, enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
