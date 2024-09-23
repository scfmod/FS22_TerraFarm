---@class SetSurveyorEvent : Event
---@field vehicle Machine
---@field surveyorId string | nil
SetSurveyorEvent = {}

local SetSurveyorEvent_mt = Class(SetSurveyorEvent, Event)

InitEventClass(SetSurveyorEvent, 'SetSurveyorEvent')

---@return SetSurveyorEvent
---@nodiscard
function SetSurveyorEvent.emptyNew()
    ---@type SetSurveyorEvent
    local self = Event.new(SetSurveyorEvent_mt)
    return self
end

---@param vehicle Machine
---@param surveyorId string | nil
---@return SetSurveyorEvent
function SetSurveyorEvent.new(vehicle, surveyorId)
    local self = SetSurveyorEvent.emptyNew()

    self.vehicle = vehicle
    self.surveyorId = surveyorId

    return self
end

---@param streamId number
---@param connection Connection
function SetSurveyorEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    if streamWriteBool(streamId, self.surveyorId ~= nil) then
        streamWriteString(streamId, self.surveyorId)
    end
end

---@param streamId number
---@param connection Connection
function SetSurveyorEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    if streamReadBool(streamId) then
        self.surveyorId = streamReadString(streamId)
    else
        self.surveyorId = nil
    end

    self:run(connection)
end

---@param connection Connection
function SetSurveyorEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setSurveyorId(self.surveyorId, true)
    end
end

---@param vehicle Machine
---@param surveyorId string | nil
---@param noEventSend boolean | nil
function SetSurveyorEvent.sendEvent(vehicle, surveyorId, noEventSend)
    if not noEventSend then
        local event = SetSurveyorEvent.new(vehicle, surveyorId)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
