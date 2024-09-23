---@class MachineSettingsLandscapingFrame : TabbedMenuFrameElement
---@field target MachineSettingsDialog
---@field boxLayout ScrollingLayoutElement
---
---@field clearDecoAreaOption CheckedOptionElement
---@field clearDensityMapHeightAreaOption CheckedOptionElement
---@field eraseTireTracksOption CheckedOptionElement
---@field removeFieldAreaOption CheckedOptionElement
---@field removeStoneAreaOption CheckedOptionElement
---@field removeWeedAreaOption CheckedOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsLandscapingFrame = {}

MachineSettingsLandscapingFrame.CLASS_NAME = 'MachineSettingsLandscapingFrame'
MachineSettingsLandscapingFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/MachineSettingsLandscapingFrame.xml'

MachineSettingsLandscapingFrame.CONTROLS = {
    'boxLayout',

    'clearDecoAreaOption',
    'clearDensityMapHeightAreaOption',
    'eraseTireTracksOption',
    'removeFieldAreaOption',
    'removeStoneAreaOption',
    'removeWeedAreaOption'
}

local MachineSettingsLandscapingFrame_mt = Class(MachineSettingsLandscapingFrame, TabbedMenuFrameElement)

---@param target MachineSettingsDialog
---@return MachineSettingsLandscapingFrame
function MachineSettingsLandscapingFrame.new(target)
    ---@type MachineSettingsLandscapingFrame
    local self = TabbedMenuFrameElement.new(target, MachineSettingsLandscapingFrame_mt)

    self:registerControls(MachineSettingsLandscapingFrame.CONTROLS)

    return self
end

function MachineSettingsLandscapingFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsLandscapingFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateState()

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsLandscapingFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)
end

function MachineSettingsLandscapingFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle Machine | nil
function MachineSettingsLandscapingFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine

        self.clearDecoAreaOption:setIsChecked(spec.state.clearDecoArea)
        self.clearDensityMapHeightAreaOption:setIsChecked(spec.state.clearDensityMapHeightArea)
        self.eraseTireTracksOption:setIsChecked(spec.state.eraseTireTracks)
        self.removeFieldAreaOption:setIsChecked(spec.state.removeFieldArea)
        self.removeStoneAreaOption:setIsChecked(spec.state.removeStoneArea)
        self.removeWeedAreaOption:setIsChecked(spec.state.removeWeedArea)
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsLandscapingFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        ---@diagnostic disable-next-line: param-type-mismatch
        MachineSettingsFrame.setStateValue(self, element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end
