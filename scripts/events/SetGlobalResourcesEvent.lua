---@class SetGlobalResourcesEvent : Event
---@field active boolean
---@field available boolean
SetGlobalResourcesEvent = {}

local SetGlobalResourcesEvent_mt = Class(SetGlobalResourcesEvent, Event)

InitEventClass(SetGlobalResourcesEvent, 'SetGlobalResourcesEvent')

---@return SetGlobalResourcesEvent
---@nodiscard
function SetGlobalResourcesEvent.emptyNew()
    ---@type SetGlobalResourcesEvent
    local self = Event.new(SetGlobalResourcesEvent_mt)
    return self
end

---@param available boolean
---@param active boolean
---@return SetGlobalResourcesEvent
function SetGlobalResourcesEvent.new(available, active)
    local self = SetGlobalResourcesEvent.emptyNew()

    self.available = available
    self.active = active

    return self
end

---@param streamId number
---@param connection Connection
function SetGlobalResourcesEvent:writeStream(streamId, connection)
    streamWriteBool(streamId, self.available)
    streamWriteBool(streamId, self.active)
end

---@param streamId number
---@param connection Connection
function SetGlobalResourcesEvent:readStream(streamId, connection)
    self.available = streamReadBool(streamId)
    self.active = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetGlobalResourcesEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_resources.available = self.available
    g_resources:setIsActive(self.active, true)
end

---@param available boolean
---@param active boolean
---@param noEventSend boolean | nil
function SetGlobalResourcesEvent.sendEvent(available, active, noEventSend)
    if not noEventSend then
        local event = SetGlobalResourcesEvent.new(available, active)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
