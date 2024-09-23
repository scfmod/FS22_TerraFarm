---@class MachineTextInputElement : TextInputElement
---@field superClass fun(): TextInputElement
MachineTextInputElement = {}

local MachineTextInputElement_mt = Class(MachineTextInputElement, TextInputElement)

function MachineTextInputElement.new(target)
    local self = TextInputElement.new(target, MachineTextInputElement_mt)

    self.customFocusSample = nil

    return self
end

Gui.CONFIGURATION_CLASS_MAPPING['machineTextInput'] = MachineTextInputElement
Gui.ELEMENT_PROCESSING_FUNCTIONS['machineTextInput'] = Gui.assignPlaySampleCallback
