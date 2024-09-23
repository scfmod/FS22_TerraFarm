---@class MachineCheckedOptionElement : CheckedOptionElement
---@field superClass fun(): CheckedOptionElement
MachineCheckedOptionElement = {}

local MachineCheckedOptionElement_mt = Class(MachineCheckedOptionElement, CheckedOptionElement)

function MachineCheckedOptionElement.new(target, custom_mt)
    local self = CheckedOptionElement.new(target, custom_mt or MachineCheckedOptionElement_mt)

    return self
end

function MachineCheckedOptionElement:setDisabled(disabled, doNotUpdateChildren)
    if self.disabled ~= disabled then
        self:superClass().setDisabled(self, disabled, doNotUpdateChildren)
    end
end

function MachineCheckedOptionElement:inputLeft(isShoulderButton)
    if not isShoulderButton then
        return CheckedOptionElement.inputLeft(self, isShoulderButton)
    end

    return false
end

function MachineCheckedOptionElement:inputRight(isShoulderButton)
    if not isShoulderButton then
        return CheckedOptionElement.inputRight(self, isShoulderButton)
    end

    return false
end

Gui.CONFIGURATION_CLASS_MAPPING['machineCheckedOption'] = MachineCheckedOptionElement
Gui.ELEMENT_PROCESSING_FUNCTIONS['machineCheckedOption'] = Gui.assignPlaySampleCallback
