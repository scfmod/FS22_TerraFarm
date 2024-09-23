---@class MachineSettingsAdvancedFrame : TabbedMenuFrameElement
---@field target MachineSettingsDialog
---@field boxLayout ScrollingLayoutElement
---@field selectMachineButton ButtonElement
---
---@field paintModifierOption TextInputElement
---@field densityModifierOption TextInputElement
---@field inputRatioOption TextInputElement
---
---@field enableEffectsOption CheckedOptionElement
---@field allowGradingUpOption CheckedOptionElement
---@field forceNodesOption CheckedOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsAdvancedFrame = {}

MachineSettingsAdvancedFrame.CLASS_NAME = 'MachineSettingsAdvancedFrame'
MachineSettingsAdvancedFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/MachineSettingsAdvancedFrame.xml'

MachineSettingsAdvancedFrame.CONTROLS = {
    'boxLayout',

    'paintModifierOption',
    'densityModifierOption',
    'inputRatioOption',

    'enableEffectsOption',
    'allowGradingUpOption',
    'forceNodesOption',

    'selectMachineButton'
}

local MachineSettingsAdvancedFrame_mt = Class(MachineSettingsAdvancedFrame, TabbedMenuFrameElement)

---@param target MachineSettingsDialog
---@return MachineSettingsAdvancedFrame
---@nodiscard
function MachineSettingsAdvancedFrame.new(target)
    ---@type MachineSettingsAdvancedFrame
    local self = TabbedMenuFrameElement.new(target, MachineSettingsAdvancedFrame_mt)

    self:registerControls(MachineSettingsAdvancedFrame.CONTROLS)

    return self
end

function MachineSettingsAdvancedFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsAdvancedFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateState()

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsAdvancedFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)
end

function MachineSettingsAdvancedFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle Machine | nil
function MachineSettingsAdvancedFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine

        self.paintModifierOption:setText(string.format('%.2f', spec.state.paintModifier))
        self.densityModifierOption:setText(string.format('%.2f', spec.state.densityModifier))
        self.inputRatioOption:setText(string.format('%.2f', spec.state.inputRatio))

        self.inputRatioOption:setDisabled(#spec.modesInput == 0)

        self.enableEffectsOption:setIsChecked(spec.state.enableEffects)
        self.allowGradingUpOption:setIsChecked(spec.state.allowGradingUp)
        self.forceNodesOption:setIsChecked(spec.state.forceNodes)

        self.enableEffectsOption:setDisabled(#spec.effects == 0)

        if #spec.effects == 0 then
            self.enableEffectsOption.textElement:setText(g_i18n:getText('ui_notAvailable'))
        end
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsAdvancedFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        ---@diagnostic disable-next-line: param-type-mismatch
        MachineSettingsFrame.setStateValue(self, element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param element TextInputElement
function MachineSettingsAdvancedFrame:onEnterPressedInput(element)
    if element.name ~= nil then
        if element.text ~= '' then
            local value = tonumber(element.text)

            if value ~= nil then
                ---@diagnostic disable-next-line: param-type-mismatch
                MachineSettingsFrame.setStateValue(self, element.name, MathUtil.round(MathUtil.clamp(value, 0, 15), 2))
            end
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        element:setText(string.format('%.2f', MachineSettingsFrame.getStateValue(self, element.name, 0)))
    end
end

function MachineSettingsAdvancedFrame:onClickSelectMachine()
    g_selectMachineDialog:setSelectCallback(self.selectMachineCallback, self)
    g_selectMachineDialog:show(self.target.vehicle)
end

---@param vehicle Machine | nil
function MachineSettingsAdvancedFrame:selectMachineCallback(vehicle)
    if vehicle ~= nil and self.target.vehicle ~= nil then
        local spec = vehicle.spec_machine
        local state = spec.state:clone()

        self.target.vehicle:setMachineState(state)
        self.target.vehicle:setMachineFillTypeIndex(spec.fillTypeIndex)
        self.target.vehicle:setMachineTerrainLayerId(spec.terrainLayerId)
    end
end
