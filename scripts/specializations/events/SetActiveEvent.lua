---@class SetActiveEvent : Event
---@field vehicle Machine
---@field active boolean
SetActiveEvent = {}

local SetActiveEvent_mt = Class(SetActiveEvent, Event)

InitEventClass(SetActiveEvent, 'SetActiveEvent')

---@return SetActiveEvent
---@nodiscard
function SetActiveEvent.emptyNew()
    ---@type SetActiveEvent
    local self = Event.new(SetActiveEvent_mt)
    return self
end

---@param vehicle Machine
---@param active boolean
---@return SetActiveEvent
---@nodiscard
function SetActiveEvent.new(vehicle, active)
    local self = SetActiveEvent.emptyNew()

    self.vehicle = vehicle
    self.active = active

    return self
end

---@param streamId number
---@param connection Connection
function SetActiveEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteBool(streamId, self.active)
end

---@param streamId number
---@param connection Connection
function SetActiveEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.active = streamReadBool(streamId)

    self:run(connection)
end

---@param connection Connection
function SetActiveEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setMachineActive(self.active, true)
    end
end

---@param vehicle Machine
---@param active boolean
---@param noEventSend boolean | nil
function SetActiveEvent.sendEvent(vehicle, active, noEventSend)
    if not noEventSend then
        local event = SetActiveEvent.new(vehicle, active)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
