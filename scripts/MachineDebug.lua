---@class MachineDebug
MachineDebug = {}

MachineDebug.NODE_TEXT = '↓'
MachineDebug.NODE_TEXT_SIZE = getCorrectTextSize(0.01)

MachineDebug.NODE_WORK_AREA = 0

MachineDebug.NODE_COLOR = {
    DEFAULT = { 0.8, 0.42, 1, 1 },
    TERRAIN = { 0, 1, 0, 1 },
    INACTIVE = { 0.4, 0.4, 0.4, 1 },
    INACTIVE_TERRAIN = { 0.9, 0.3, 0.3, 1 }
}

MachineDebug.CALIBRATION_COLOR = {
    INACTIVE = { 0.35, 0.35, 0.35, 1.0 },
    POSITION_START = { 0.7, 0.64, 1, 1 },
    POSITION_END = { 0.7, 0.64, 1, 1 },
    TERRAIN_LINE = { 1, 1, 1, 1 },
    OFFSET_LINE = { 0.5, 0.5, 0.5, 1.0 },
    TARGET = { 0.3, 1, 0.3, 1 }
}

MachineDebug.CALIBRATION_RADIUS = 1
MachineDebug.CALIBRATION_STEPS = 16
MachineDebug.CALIBRATION_TEXT_SIZE = getCorrectTextSize(0.025)

MachineDebug.CALIBRATION_SOURCE_COLOR = { 0.8, 0.2, 0.8, 1.0 }
MachineDebug.CALIBRATION_LINE_COLOR = { 0.01, 0.8, 0.9, 1.0 }

local MachineDebug_mt = Class(MachineDebug)

---@return MachineDebug
---@nodiscard
function MachineDebug.new()
    ---@type MachineDebug
    local self = setmetatable({}, MachineDebug_mt)

    return self
end

function MachineDebug:draw()
    local vehicle = g_machineManager.activeVehicle

    if vehicle ~= nil and g_settings:getIsEnabled() and vehicle:getMachineEnabled() then
        local spec = vehicle.spec_machine

        if g_settings:getDebugNodes() then
            for _, node in ipairs(spec.workArea.nodes) do
                self:drawNode(vehicle, spec.workArea.nodePosition[node], spec.workArea.nodeActive[node])
            end
        end

        if spec.inputMode == Machine.MODE.FLATTEN and g_settings:getDebugCalibration() then
            self:drawMachineCalibration(vehicle)
        end
    end
end

---@param vehicle Machine
---@param position Position
---@param active boolean
function MachineDebug:drawNode(vehicle, position, active)
    local spec = vehicle.spec_machine

    if position ~= nil then
        local color = MachineDebug.NODE_COLOR.DEFAULT

        if active then
            if spec.active then
                color = MachineDebug.NODE_COLOR.TERRAIN
            else
                color = MachineDebug.NODE_COLOR.INACTIVE_TERRAIN
            end
        elseif not spec.active then
            color = MachineDebug.NODE_COLOR.INACTIVE
        end

        MachineUtils.renderTextAtWorldPosition(
            position[1], position[2], position[3],
            MachineDebug.NODE_TEXT, MachineDebug.NODE_TEXT_SIZE, 0, color, true
        )
    end
end

---@param startPosX number
---@param startPosY number
---@param startPosZ number
---@param endPosX number
---@param endPosY number
---@param endPosZ number
---@param offsetY number
---@param isActive boolean | nil
function MachineDebug:drawCalibration(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, offsetY, isActive)
    if startPosY ~= math.huge then
        if isActive == nil then
            isActive = true
        end

        local textColor = isActive and MachineDebug.CALIBRATION_COLOR.TARGET or MachineDebug.CALIBRATION_COLOR.INACTIVE
        local startColor = isActive and MachineDebug.CALIBRATION_COLOR.POSITION_START or MachineDebug.CALIBRATION_COLOR.INACTIVE
        local endColor = isActive and MachineDebug.CALIBRATION_COLOR.POSITION_END or MachineDebug.CALIBRATION_COLOR.INACTIVE
        local terrainColor = isActive and MachineDebug.CALIBRATION_COLOR.TERRAIN_LINE or MachineDebug.CALIBRATION_COLOR.INACTIVE
        local offsetColor = isActive and MachineDebug.CALIBRATION_COLOR.OFFSET_LINE or MachineDebug.CALIBRATION_COLOR.INACTIVE

        Utils.renderTextAtWorldPosition(startPosX, startPosY, startPosZ, MachineDebug.NODE_TEXT, MachineDebug.CALIBRATION_TEXT_SIZE, 0, textColor)

        DebugUtil.drawDebugLine(startPosX, startPosY, startPosZ, startPosX, startPosY + offsetY, startPosZ, startColor[1], startColor[2], startColor[3])
        DebugUtil.drawDebugCircle(startPosX, startPosY + offsetY, startPosZ, MachineDebug.CALIBRATION_RADIUS, MachineDebug.CALIBRATION_STEPS, startColor)

        if endPosY ~= math.huge then
            Utils.renderTextAtWorldPosition(endPosX, endPosY, endPosZ, MachineDebug.NODE_TEXT, MachineDebug.CALIBRATION_TEXT_SIZE, 0, textColor)

            DebugUtil.drawDebugLine(endPosX, endPosY, endPosZ, endPosX, endPosY + offsetY, endPosZ, endColor[1], endColor[2], endColor[3])
            DebugUtil.drawDebugCircle(endPosX, endPosY + offsetY, endPosZ, MachineDebug.CALIBRATION_RADIUS, MachineDebug.CALIBRATION_STEPS, endColor)

            DebugUtil.drawDebugLine(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, terrainColor[1], terrainColor[2], terrainColor[3])
            DebugUtil.drawDebugLine(startPosX, startPosY + offsetY, startPosZ, endPosX, endPosY + offsetY, endPosZ, offsetColor[1], offsetColor[2], offsetColor[3])
        end
    end
end

---@param vehicle Machine
function MachineDebug:drawMachineCalibration(vehicle)
    local spec = vehicle.spec_machine
    local surveyor = vehicle:getSurveyor()

    if surveyor ~= nil then
        local startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ = surveyor:getCalibration()

        if startPosY ~= math.huge then
            local offsetY = surveyor.spec_surveyor.offsetY
            local isActive = vehicle:getMachineActive()

            self:drawCalibration(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, offsetY, isActive)

            local nodePosX, nodePosY, nodePosZ = spec.workArea:getPosition()
            local targetColor = isActive and MachineDebug.CALIBRATION_COLOR.TARGET or MachineDebug.CALIBRATION_COLOR.INACTIVE

            if endPosY ~= math.huge then
                local linePosX, linePosY, linePosZ, _ = MachineUtils.getClosestPointOnLine(
                    startPosX, startPosY, startPosZ,
                    endPosX, endPosY, endPosZ,
                    nodePosX, nodePosY, nodePosZ
                )

                DebugUtil.drawDebugCircle(linePosX, linePosY, linePosZ, MachineDebug.CALIBRATION_RADIUS / 2, MachineDebug.CALIBRATION_STEPS, targetColor)
                DebugUtil.drawDebugCircle(nodePosX, linePosY, nodePosZ, MachineDebug.CALIBRATION_RADIUS / 2, MachineDebug.CALIBRATION_STEPS, targetColor)
            else
                DebugUtil.drawDebugCircle(nodePosX, startPosY, nodePosZ, MachineDebug.CALIBRATION_RADIUS / 2, MachineDebug.CALIBRATION_STEPS, targetColor)
            end
        end
    end
end

---@param str string
---@param ... unknown
function MachineDebug:debug(str, ...)
    print('DEBUG:  ' .. string.format(str, ...))
end

function MachineDebug:onMapLoaded()
    if g_client ~= nil then
        g_currentMission:addDrawable(self)
    end
end

---@diagnostic disable-next-line: lowercase-global
g_machineDebug = MachineDebug.new()
