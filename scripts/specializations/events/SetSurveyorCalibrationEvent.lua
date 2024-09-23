---@class SetSurveyorCalibrationEvent : Event
---@field vehicle Surveyor
---@field startPosX number
---@field startPosY number
---@field startPosZ number
---@field endPosX number
---@field endPosY number
---@field endPosZ number
SetSurveyorCalibrationEvent = {}

local SetSurveyorCalibrationEvent_mt = Class(SetSurveyorCalibrationEvent, Event)

InitEventClass(SetSurveyorCalibrationEvent, 'SetSurveyorCalibrationEvent')

---@return SetSurveyorCalibrationEvent
---@nodiscard
function SetSurveyorCalibrationEvent.emptyNew()
    ---@type SetSurveyorCalibrationEvent
    local self = Event.new(SetSurveyorCalibrationEvent_mt)
    return self
end

---@param vehicle Surveyor
---@param startPosX number
---@param startPosY number
---@param startPosZ number
---@param endPosX number
---@param endPosY number
---@param endPosZ number
---@return SetSurveyorCalibrationEvent
---@nodiscard
function SetSurveyorCalibrationEvent.new(vehicle, startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)
    local self = SetSurveyorCalibrationEvent.emptyNew()

    self.vehicle = vehicle

    self.startPosX = startPosX
    self.startPosY = startPosY
    self.startPosZ = startPosZ
    self.endPosX = endPosX
    self.endPosY = endPosY
    self.endPosZ = endPosZ

    return self
end

---@param streamId number
---@param connection Connection
function SetSurveyorCalibrationEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)

    MachineUtils.writeCompressedPosition(streamId, self.startPosX, self.startPosY, self.startPosZ)
    MachineUtils.writeCompressedPosition(streamId, self.endPosX, self.endPosY, self.endPosZ)
end

---@param streamId number
---@param connection Connection
function SetSurveyorCalibrationEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)

    self.startPosX, self.startPosY, self.startPosZ = MachineUtils.readCompressedPosition(streamId)
    self.endPosX, self.endPosY, self.endPosZ = MachineUtils.readCompressedPosition(streamId)

    self:run(connection)
end

---@param connection Connection
function SetSurveyorCalibrationEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, true)
    end
end

---@param vehicle Surveyor
---@param startPosX number
---@param startPosY number
---@param startPosZ number
---@param endPosX number
---@param endPosY number
---@param endPosZ number
---@param noEventSend boolean | nil
function SetSurveyorCalibrationEvent.sendEvent(vehicle, startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, noEventSend)
    if not noEventSend then
        local event = SetSurveyorCalibrationEvent.new(vehicle, startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
