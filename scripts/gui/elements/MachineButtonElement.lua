---@class MachineButtonElement : ButtonElement
---@field superClass fun(): ButtonElement
MachineButtonElement = {}

local MachineButtonElement_mt = Class(MachineButtonElement, ButtonElement)

function MachineButtonElement.new(target, customMt)
    local self = ButtonElement.new(target, customMt or MachineButtonElement_mt)
    return self
end

function MachineButtonElement:setDisabled(disabled)
    if self.disabled ~= disabled then
        self:superClass().setDisabled(self, disabled)
    end
end

Gui.CONFIGURATION_CLASS_MAPPING['machineButton'] = MachineButtonElement
Gui.ELEMENT_PROCESSING_FUNCTIONS['machineButton'] = Gui.assignPlaySampleCallback
