---@class SetGlobalMaterialsEvent : Event
---@field materials string[]
SetGlobalMaterialsEvent = {}

local SetGlobalMaterialsEvent_mt = Class(SetGlobalMaterialsEvent, Event)

InitEventClass(SetGlobalMaterialsEvent, 'SetGlobalMaterialsEvent')

---@return SetGlobalMaterialsEvent
---@nodiscard
function SetGlobalMaterialsEvent.emptyNew()
    ---@type SetGlobalMaterialsEvent
    local self = Event.new(SetGlobalMaterialsEvent_mt)
    return self
end

---@param materials string[]
---@return SetGlobalMaterialsEvent
function SetGlobalMaterialsEvent.new(materials)
    local self = SetGlobalMaterialsEvent.emptyNew()

    self.materials = materials

    return self
end

function SetGlobalMaterialsEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, #self.materials)

    for _, name in ipairs(self.materials) do
        streamWriteString(streamId, name)
    end
end

function SetGlobalMaterialsEvent:readStream(streamId, connection)
    local numMaterials = streamReadInt32(streamId)

    self.materials = {}

    if numMaterials > 0 then
        for i = 1, numMaterials do
            local name = streamReadString(streamId)
            table.insert(self.materials, name)
        end
    end

    self:run(connection)
end

---@param connection Connection
function SetGlobalMaterialsEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection)
    end

    g_settings:setMaterials(self.materials, true)
end

---@param materials string[]
---@param noEventSend boolean | nil
function SetGlobalMaterialsEvent.sendEvent(materials, noEventSend)
    if not noEventSend then
        local event = SetGlobalMaterialsEvent.new(materials)

        if g_server ~= nil then
            g_server:broadcastEvent(event)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
