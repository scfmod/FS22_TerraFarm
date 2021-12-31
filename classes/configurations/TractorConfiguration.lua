---@class TractorConfiguration : MachineConfiguration
TractorConfiguration = {}
local TractorConfiguration_mt = Class(TractorConfiguration, MachineConfiguration)

---@return TractorConfiguration
function TractorConfiguration.new(object, name, filePath)
    ---@type TractorConfiguration
    local self = MachineConfiguration.new(object, name, filePath, TractorConfiguration_mt)
    return self
end