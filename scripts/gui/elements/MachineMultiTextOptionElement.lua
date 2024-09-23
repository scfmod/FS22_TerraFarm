---@class MachineMultiTextOptionElement : MultiTextOptionElement
MachineMultiTextOptionElement = {}

local MachineMultiTextOptionElement_mt = Class(MachineMultiTextOptionElement, MultiTextOptionElement)

function MachineMultiTextOptionElement.new(target, custom_mt)
    local self = MultiTextOptionElement.new(target, custom_mt or MachineMultiTextOptionElement_mt)

    return self
end

function MachineMultiTextOptionElement:inputLeft(isShoulderButton)
    if not isShoulderButton then
        return MultiTextOptionElement.inputLeft(self, isShoulderButton)
    end

    return false
end

function MachineMultiTextOptionElement:inputRight(isShoulderButton)
    if not isShoulderButton then
        return MultiTextOptionElement.inputRight(self, isShoulderButton)
    end

    return false
end

Gui.CONFIGURATION_CLASS_MAPPING['machineMultiTextOption'] = MachineMultiTextOptionElement
Gui.ELEMENT_PROCESSING_FUNCTIONS['machineMultiTextOption'] = Gui.assignPlaySampleCallback
