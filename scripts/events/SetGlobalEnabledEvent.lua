---@class SetGlobalEnabledEvent : Event
---@field enabled boolean
SetGlobalEnabledEvent = {}

local SetGlobalEnabledEvent_mt = Class(SetGlobalEnabledEvent, Event)

InitEventClass(SetGlobalEnabledEvent, 'SetGlobalEnabledEvent')

---@return SetGlobalEnabledEvent
---@nodiscard
function SetGlobalEnabledEvent.emptyNew()
    ---@type SetGlobalEnabledEvent
    local self = Event.new(SetGlobalEnabledEvent_mt)
    return self
end

---@param enabled boolean
---@return SetGlobalEnabledEvent
function SetGlobalEnabledEvent.new(enabled)
    local self = SetGlobalEnabledEvent.emptyNew()

    self.enabled = enabled

    return self
end

---@param streamId number
---@param connection Connection
function SetGlobalEnabledEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.enabled)
end

---@param streamId number
---@param connection Connection
function SetGlobalEnabledEvent:readStream(streamId, connection)
    self.enabled = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetGlobalEnabledEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_settings:setIsEnabled(self.enabled, true)
end

---@param enabled boolean
---@param noEventSend boolean | nil
function SetGlobalEnabledEvent.sendEvent(enabled, noEventSend)
    if not noEventSend then
        local event = SetGlobalEnabledEvent.new(enabled)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
