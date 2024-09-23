---@class SurveyorScreen : ScreenElement
---@field menuBox BitmapElement
---@field camera SurveyorCamera
---@field cursor SurveyorCursor
---@field isMouseMode boolean
---@field isMouseInMenu boolean
---@field vehicle Surveyor | nil
---@field isDebug boolean
---@field superClass fun(): ScreenElement
---@field backButtonEvent string
---@field primaryButtonEvent string
---@field isCalibrating boolean
---
---@field name string
---@field startPosX number
---@field startPosY number
---@field startPosZ number
---@field endPosX number
---@field endPosY number
---@field endPosZ number
---
---@field calibrateButton ButtonElement
---@field setAngleButton ButtonElement
---@field setLevelButton ButtonElement
---@field resetButton ButtonElement
---@field renameButton ButtonElement
---
---@field applyButton ButtonElement
---@field cancelButton ButtonElement
---@field exitButton ButtonElement
---@field useTerrain boolean
---
---@field vehicleText TextElement
---@field vehicleImage BitmapElement
---@field statusText TextElement
---@field calibrationText TextElement
---@field useTerrainOption CheckedOptionElement
SurveyorScreen = {}

SurveyorScreen.CLASS_NAME = 'SurveyorScreen'
SurveyorScreen.XML_FILENAME = g_currentModDirectory .. 'xml/gui/screens/SurveyorScreen.xml'
SurveyorScreen.INPUT_CONTEXT = 'SURVEYOR_SCREEN'

SurveyorScreen.CONTROLS = {
    'menuBox',
    'vehicleText',
    'vehicleImage',
    'statusText',
    'calibrationText',

    'calibrateButton',
    'setAngleButton',
    'setLevelButton',
    'resetButton',
    'renameButton',

    'applyButton',
    'cancelButton',
    'exitButton',
    'useTerrainOption'
}

SurveyorScreen.L10N_TARGET_POSITION = g_i18n:getText('ui_setTarget')
SurveyorScreen.L10N_EXIT_MENU = g_i18n:getText('input_CONSTRUCTION_EXIT')
SurveyorScreen.L10N_CANCEL_CALIBRATION = g_i18n:getText('button_cancel')
SurveyorScreen.L10N_STATUS_CALIBRATED = g_i18n:getText('ui_calibrated')
SurveyorScreen.L10N_STATUS_NOT_CALIBRATED = g_i18n:getText('ui_notCalibrated')


local SurveyorScreen_mt = Class(SurveyorScreen, ScreenElement)

---@return SurveyorScreen
---@nodiscard
function SurveyorScreen.new()
    ---@type SurveyorScreen
    local self = ScreenElement.new(nil, SurveyorScreen_mt)

    self:registerControls(SurveyorScreen.CONTROLS)

    self.camera = SurveyorCamera.new()
    self.cursor = SurveyorCursor.new()

    self.useTerrain = true

    self.isMouseMode = true
    self.isMouseInMenu = false
    self.isCalibrating = false

    self:resetPositions()

    return self
end

function SurveyorScreen:load()
    g_gui:loadGui(SurveyorScreen.XML_FILENAME, SurveyorScreen.CLASS_NAME, self)
end

---@param vehicle Surveyor
function SurveyorScreen:show(vehicle)
    if vehicle ~= nil then
        self.vehicle = vehicle

        g_gui:changeScreen(nil, SurveyorScreen)
    end
end

function SurveyorScreen:delete()
    self.camera:delete()
    self.cursor:delete()

    FocusManager.guiFocusData[SurveyorScreen.CLASS_NAME] = {
        idToElementMapping = {}
    }

    self:superClass().delete(self)
end

function SurveyorScreen:onOpen()
    self:superClass().onOpen(self)

    g_inputBinding:setContext(SurveyorScreen.INPUT_CONTEXT)
    self:registerMenuActionEvents()

    self.camera:setTerrainRootNode(g_currentMission.terrainRootNode)
    self.camera:setControlledVehicle(self.vehicle)
    self.camera:activate()
    self.cursor:activate()

    g_currentMission.hud.ingameMap:setTopDownCamera(self.camera)

    g_depthOfFieldManager:pushArea(
        self.menuBox.absPosition[1],
        self.menuBox.absPosition[2],
        self.menuBox.absSize[1],
        self.menuBox.absSize[2]
    )

    self:setPositionsFromVehicle(self.vehicle)
    self:updateSurveyor()
    self:updateButtons()

    self.useTerrainOption:setIsChecked(self.useTerrain)

    g_messageCenter:subscribe(MessageType.SURVEYOR_REMOVED, self.onSurveyorRemoved, self)
    g_messageCenter:subscribe(SetSurveyorNameEvent, self.onSurveyorRenamed, self)
    g_messageCenter:subscribe(SetSurveyorCalibrationEvent, self.onSurveyorChanged, self)
end

function SurveyorScreen:onClose()
    g_messageCenter:unsubscribeAll(self)

    self.cursor:deactivate()
    self.camera:deactivate()

    g_currentMission.hud.ingameMap:setTopDownCamera(nil)
    g_depthOfFieldManager:popArea()
    self:removeMenuActionEvents()
    g_inputBinding:revertContext()

    self.vehicle = nil
    self:setIsCalibrating(false)
    self:resetPositions()

    self:superClass().onClose(self)
end

---@param dt number
function SurveyorScreen:update(dt)
    self:superClass().update(self, dt)

    self.camera:setCursorLocked(self.cursor.isCatchingCursor)
    self.camera:update(dt)

    if self.isMouseInMenu then
        self.cursor:setCameraRay()
    else
        self.cursor:setCameraRay(self.camera:getPickRay())
    end

    self.cursor:update(dt)
end

---@param x number
---@param y number
function SurveyorScreen:mouseEvent(x, y)
    self.isMouseInMenu = GuiUtils.checkOverlayOverlap(
        x, y,
        self.menuBox.absPosition[1],
        self.menuBox.absPosition[2],
        self.menuBox.absSize[1],
        self.menuBox.absSize[2]
    )

    self.camera.mouseDisabled = self.isMouseInMenu
    self.cursor.mouseDisabled = self.isMouseInMenu

    self.camera:mouseEvent(x, y)
    self.cursor:mouseEvent(x, y)
end

function SurveyorScreen:draw()
    self:superClass().draw(self)

    g_currentMission.hud:drawInputHelp()

    local cursorIsCalibrating = false

    if not self.isMouseInMenu then
        self.cursor:draw()

        if self.isCalibrating and self.cursor.currentHitId ~= nil then
            self:drawCursorCalibration()
            cursorIsCalibrating = true
        end
    end

    self:drawCurrentCalibration(cursorIsCalibrating)
end

function SurveyorScreen:onButtonPrimary(_, inputValue, _, isAnalog, isMouse)
    if isMouse and self.isCalibrating and not self.isMouseInMenu and self.cursor.currentHitId ~= nil then
        ---@type Vehicle | nil
        local hitVehicle = nil
        local endPosX, endPosY, endPosZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ

        if self.cursor.currentHitId ~= g_currentMission.terrainRootNode then
            hitVehicle = self.cursor:getHitVehicle()

            if hitVehicle ~= nil then
                endPosX, endPosY, endPosZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
            else
                return
            end
        elseif not self.useTerrain then
            return
        end

        self.endPosX, self.endPosY, self.endPosZ = endPosX, endPosY, endPosZ
    end
end

function SurveyorScreen:onClickUseTerrainOption(state)
    self.useTerrain = state == CheckedOptionElement.STATE_CHECKED

    if self.isCalibrating then
        self:updateCursorRaycast()
    end
end

function SurveyorScreen:onButtonMenuBack()
    if self.isCalibrating then
        self:onClickCancel()
    else
        g_gui:showGui(nil)
    end
end

function SurveyorScreen:registerMenuActionEvents()
    local _, eventId = g_inputBinding:registerActionEvent(InputAction.MENU_BACK, self, self.onButtonMenuBack, false, true, false, true)

    g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)

    self.backButtonEvent = eventId

    _, eventId = g_inputBinding:registerActionEvent(InputAction.CONSTRUCTION_ACTION_PRIMARY, self, self.onButtonPrimary, false, true, false, true)
    g_inputBinding:setActionEventText(eventId, SurveyorScreen.L10N_TARGET_POSITION)

    self.primaryButtonEvent = eventId

    self:updateMenuActionEvents()
end

function SurveyorScreen:removeMenuActionEvents()
    if self.primaryButtonEvent ~= nil then
        g_inputBinding:removeActionEvent(self.primaryButtonEvent)
    end

    if self.backButtonEvent ~= nil then
        g_inputBinding:removeActionEvent(self.backButtonEvent)
    end
end

function SurveyorScreen:updateMenuActionEvents()
    if self.primaryButtonEvent ~= nil then
        g_inputBinding:setActionEventTextVisibility(self.primaryButtonEvent, self.isCalibrating)
    else
        Logging.warning('primaryButtonEvent not set')
    end

    if self.backButtonEvent ~= nil then
        g_inputBinding:setActionEventTextVisibility(self.backButtonEvent, true)

        if self.isCalibrating then
            g_inputBinding:setActionEventText(self.backButtonEvent, SurveyorScreen.L10N_CANCEL_CALIBRATION)
        else
            g_inputBinding:setActionEventText(self.backButtonEvent, SurveyorScreen.L10N_EXIT_MENU)
        end
    else
        Logging.warning('backButtonEvent not set')
    end
end

---@param vehicle Surveyor
function SurveyorScreen:onSurveyorRemoved(vehicle)
    if self.vehicle ~= nil and vehicle == self.vehicle then
        g_gui:changeScreen()
    end
end

---@param vehicle Surveyor
---@param name string
function SurveyorScreen:onSurveyorRenamed(vehicle, name)
    if self.vehicle ~= nil and vehicle == self.vehicle then
        self.vehicleText:setText(name)
    end
end

---@param vehicle Surveyor
function SurveyorScreen:onSurveyorChanged(vehicle)
    if self.vehicle ~= nil and self.vehicle == vehicle then
        self:setPositionsFromVehicle(vehicle)
        self:updateSurveyor()
        self:updateButtons()
    end
end

---@param isCalibrating boolean
function SurveyorScreen:setIsCalibrating(isCalibrating)
    if self.isCalibrating ~= isCalibrating then
        self.isCalibrating = isCalibrating

        self:updateCursorRaycast()
        self:updateButtons()
        self:updateMenuActionEvents()

        self.isBackAllowed = not isCalibrating
    end
end

---@param forceBack boolean | nil
---@param usedMenuButton boolean | nil
function SurveyorScreen:onClickBack(forceBack, usedMenuButton)
    if self:superClass().onClickBack(self, forceBack, usedMenuButton) and self.isCalibrating then
        self:setPositionsFromVehicle(self.vehicle)
        self:setIsCalibrating(false)
        return false
    end
end

function SurveyorScreen:onClickCalibrate()
    self.startPosX, self.startPosY, self.startPosZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)

    self:setIsCalibrating(true)
end

function SurveyorScreen:onClickRename()
    g_nameInputDialog:setCallback(self.renameCallback, self, self.vehicle:getFullName(), g_i18n:getText('button_rename'))
    g_gui:showDialog(NameInputDialog.CLASS_NAME)
end

---@param value string
---@param clickOk boolean
function SurveyorScreen:renameCallback(value, clickOk)
    if clickOk and value ~= nil then
        self.vehicle:setSurveyorName(value)
    end
end

function SurveyorScreen:onClickSetLevel()
    if not self.isCalibrating and self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        self.endPosY = self.startPosY

        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
    end
end

function SurveyorScreen:onClickSetAngle()
    if self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        local angle = MachineUtils.getAngleBetweenPoints(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)

        g_floatInputDialog:setCallback(self.setAngleCallback, self, angle, nil, nil, g_i18n:getText('ui_setAngle'))
        g_gui:showDialog(FloatInputDialog.CLASS_NAME)
    end
end

---@param value number
---@param clickOk boolean
function SurveyorScreen:setAngleCallback(value, clickOk)
    if clickOk and value ~= nil and self.startPosY ~= math.huge and self.endPosY ~= math.huge then
        local adjacent = MathUtil.getPointPointDistance(self.startPosX, self.startPosZ, self.endPosX, self.endPosZ)
        local opposite = adjacent * math.tan(math.rad(value))

        self.endPosY = self.startPosY + opposite

        if not self.isCalibrating then
            self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        end
    end
end

function SurveyorScreen:onClickReset()
    if not self.isCalibrating then
        self:resetPositions()
        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
    end
end

function SurveyorScreen:onClickCancel()
    if self.isCalibrating then
        self:setPositionsFromVehicle(self.vehicle)
        self:setIsCalibrating(false)
    end
end

function SurveyorScreen:onClickApply()
    if self.isCalibrating then
        self.vehicle:setCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ)
        self:setIsCalibrating(false)
    end
end

function SurveyorScreen:onClickExit()
    self:onButtonMenuBack()
end

---@param vehicle Surveyor
function SurveyorScreen:setPositionsFromVehicle(vehicle)
    self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ = vehicle:getCalibration()
end

function SurveyorScreen:resetPositions()
    self.startPosX = 0
    self.startPosY = math.huge
    self.startPosZ = 0

    self.endPosX = 0
    self.endPosY = math.huge
    self.endPosZ = 0
end

function SurveyorScreen:updateCursorRaycast()
    if self.isCalibrating then
        if self.useTerrain then
            self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.VEHICLE_TERRAIN)
        else
            self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.VEHICLE)
        end
    else
        self.cursor:setRaycastMode(SurveyorCursor.RAYCAST_MODE.NONE)
    end
end

function SurveyorScreen:updateButtons()
    self.calibrateButton:setDisabled(self.isCalibrating)

    local disableModifyAngle = self.isCalibrating or (self.startPosY == math.huge or self.endPosY == math.huge)

    self.setAngleButton:setDisabled(disableModifyAngle)
    self.setLevelButton:setDisabled(disableModifyAngle)

    self.resetButton:setDisabled(self.isCalibrating or self.startPosY == math.huge)
    self.renameButton:setDisabled(self.isCalibrating)

    self.applyButton:setDisabled(not self.isCalibrating or self.startPosY == math.huge)
    self.cancelButton:setDisabled(not self.isCalibrating)
    self.exitButton:setDisabled(self.isCalibrating)
end

function SurveyorScreen:updateSurveyor()
    if self.vehicle ~= nil then
        local spec = self.vehicle.spec_surveyor

        self.vehicleText:setText(self.vehicle:getFullName())
        self.vehicleImage:setImageFilename(self.vehicle:getImageFilename())

        if spec.startPosY ~= math.huge then
            local angle = MachineUtils.getAngleBetweenPoints(spec.startPosX, spec.startPosY, spec.startPosZ, spec.endPosX, spec.endPosY, spec.endPosZ)
            self.calibrationText:setText(string.format(g_i18n:getText('ui_calibratedAngleFormat'), angle))
            self.statusText:setText(SurveyorScreen.L10N_STATUS_CALIBRATED)
        else
            self.calibrationText:setText('')
            self.statusText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
        end
    end
end

---@param cursorIsCalibrating boolean
function SurveyorScreen:drawCurrentCalibration(cursorIsCalibrating)
    if self.vehicle ~= nil then
        local offsetY = self.vehicle.spec_surveyor.offsetY

        g_machineDebug:drawCalibration(self.startPosX, self.startPosY, self.startPosZ, self.endPosX, self.endPosY, self.endPosZ, offsetY, not cursorIsCalibrating)
    end
end

function SurveyorScreen:drawCursorCalibration()
    if self.vehicle ~= nil then
        local startPosX, startPosY, startPosZ = MachineUtils.getVehicleTerrainHeight(self.vehicle)
        local endPosX, endPosY, endPosZ = self.cursor.currentHitX, self.cursor.currentHitY, self.cursor.currentHitZ
        local distance = MachineUtils.getVector3Distance(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)
        local offsetY = self.vehicle.spec_surveyor.offsetY

        if distance < 2 then
            return
        end

        ---@type Vehicle | nil
        local hitVehicle = nil

        if self.cursor.currentHitId ~= g_currentMission.terrainRootNode then
            hitVehicle = self.cursor:getHitVehicle()

            if hitVehicle ~= nil then
                endPosX, endPosY, endPosZ = MachineUtils.getVehicleTerrainHeight(hitVehicle)
            else
                return
            end
        elseif not self.useTerrain then
            return
        end

        g_machineDebug:drawCalibration(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, offsetY, true)

        if hitVehicle ~= nil then
            Utils.renderTextAtWorldPosition(endPosX, endPosY + 2, endPosZ, hitVehicle:getFullName(), 0.016)
        end

        local textPosX, textPosY = self.cursor.mousePosX, self.cursor.mousePosY + 0.02
        local angle = MachineUtils.getAngleBetweenPoints(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ)

        setTextBold(false)
        renderText(textPosX, textPosY, 0.014, string.format('Angle: %.2f', angle))
    end
end
