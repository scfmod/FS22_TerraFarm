---@class MachineSettingsCalibrationFrame : TabbedMenuFrameElement
---@field target MachineSettingsDialog
---@field boxLayout ScrollingLayoutElement
---
---@field selectSurveyorButton ButtonElement
---@field selectMachineButton ButtonElement
---@field resetButton ButtonElement
---@field statusLayout BoxLayoutElement
---@field statusText TextElement
---@field surveyorImage BitmapElement
---@field surveyorName TextElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsCalibrationFrame = {}

MachineSettingsCalibrationFrame.CLASS_NAME = 'MachineSettingsCalibrationFrame'
MachineSettingsCalibrationFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/MachineSettingsCalibrationFrame.xml'

MachineSettingsCalibrationFrame.CONTROLS = {
    'boxLayout',

    'selectSurveyorButton',
    'selectMachineButton',
    'resetButton',
    'statusLayout',
    'statusText',
    'surveyorImage',
    'surveyorName'
}

local MachineSettingsCalibrationFrame_mt = Class(MachineSettingsCalibrationFrame, TabbedMenuFrameElement)

---@param target MachineSettingsDialog
---@return MachineSettingsCalibrationFrame
---@nodiscard
function MachineSettingsCalibrationFrame.new(target)
    ---@type MachineSettingsCalibrationFrame
    local self = TabbedMenuFrameElement.new(target, MachineSettingsCalibrationFrame_mt)

    self:registerControls(MachineSettingsCalibrationFrame.CONTROLS)

    return self
end

function MachineSettingsCalibrationFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsCalibrationFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateSettings()

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsCalibrationFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetSurveyorEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetSurveyorCalibrationEvent, self.onSurveyorChanged, self)
end

function MachineSettingsCalibrationFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle Machine | nil
function MachineSettingsCalibrationFrame:updateSettings(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local surveyor = self.target.vehicle:getSurveyor()

        if surveyor ~= nil then
            self.surveyorName:setText(surveyor:getFullName())
            self.surveyorName:setVisible(true)

            self.surveyorImage:setImageFilename(surveyor:getImageFilename())
            self.surveyorImage:setDisabled(false)

            self.resetButton:setDisabled(false)

            if surveyor:getIsCalibrated() then
                local angle = surveyor:getCalibrationAngle()

                self.statusText:setText(string.format(g_i18n:getText('ui_calibratedAngleFormat'), angle))
                self.statusText:setDisabled(false)
            else
                self.statusText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
                self.statusText:setDisabled(true)
            end
        else
            self.surveyorName:setText('')
            self.surveyorName:setVisible(false)

            self.surveyorImage:setImageFilename(g_machineUIFilename)
            self.surveyorImage:setDisabled(true)

            self.statusText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
            self.statusText:setDisabled(true)

            self.resetButton:setDisabled(true)
        end

        self.statusLayout:invalidateLayout()
    end
end

---@param vehicle Surveyor
function MachineSettingsCalibrationFrame:onSurveyorChanged(vehicle)
    local surveyorId = vehicle:getSurveyorId()

    if self.target.vehicle:getSurveyorId() == surveyorId then
        self:updateSettings()
    end
end

function MachineSettingsCalibrationFrame:onClickSelectSurveyor()
    if self.target.vehicle ~= nil then
        g_selectSurveyorDialog:setSelectCallback(self.selectSurveyorCallback, self)
        g_selectSurveyorDialog:show(self.target.vehicle)
    end
end

---@param vehicle Surveyor
function MachineSettingsCalibrationFrame:selectSurveyorCallback(vehicle)
    if self.target.vehicle ~= nil and vehicle ~= nil then
        local surveyorId = vehicle:getSurveyorId()

        self.target.vehicle:setSurveyorId(surveyorId)
    end
end

function MachineSettingsCalibrationFrame:onClickSelectMachine()
    if self.target.vehicle ~= nil then
        g_selectMachineDialog:setSelectCallback(self.selectMachineCallback, self)
        g_selectMachineDialog:show(self.target.vehicle)
    end
end

---@param vehicle Machine
function MachineSettingsCalibrationFrame:selectMachineCallback(vehicle)
    if self.target.vehicle ~= nil and vehicle ~= nil then
        local surveyorId = vehicle:getSurveyorId()

        self.target.vehicle:setSurveyorId(surveyorId)
    end
end

function MachineSettingsCalibrationFrame:onClickReset()
    if self.target.vehicle ~= nil then
        self.target.vehicle:setSurveyorId(nil)
    end
end
