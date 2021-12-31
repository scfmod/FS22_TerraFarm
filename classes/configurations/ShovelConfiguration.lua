---@class ShovelConfiguration : MachineConfiguration
---@field fillUnitIndex number
---@field fillTypeMassPerLiter number
---@field fillTypeMassRatio number
---@field volumeFillRatio number
---@field availableDischargeModes table<number, string>
---@field availableDischargeModeByIndex table<number, boolean>
---@field availableDischargeModeByName table<string, boolean>
ShovelConfiguration = {}
local ShovelConfiguration_mt = Class(ShovelConfiguration, MachineConfiguration)

---@return ShovelConfiguration
function ShovelConfiguration.new(object, name, filePath)
    ---@type ShovelConfiguration
    local self = MachineConfiguration.new(object, name, filePath, ShovelConfiguration_mt)

    self.fillUnitIndex = 1
    self.availableDischargeModes = {}
    self.availableDischargeModeByIndex = {}
    self.availableDischargeModeByName = {}

    return self
end

function ShovelConfiguration:loadSettings(xmlFile)
    MachineConfiguration.loadSettings(self, xmlFile)

    self.fillUnitIndex = getXMLInt(xmlFile, 'configuration.settings.fillUnitIndex') or 1
    self.fillTypeMassPerLiter = getXMLFloat(xmlFile, 'configuration.setttings.fillTypeMassPerLiter')
    self.fillTypeMassRatio = getXMLFloat(xmlFile, 'configuration.setttings.fillTypeMassRatio')
    self.volumeFillRatio = getXMLFloat(xmlFile, 'configuration.setttings.volumeFillRatio')

    local i = 0
    while true do
        local key = string.format('configuration.settings.availableDischargeModes.mode(%d)', i)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local modeName = getXMLString(xmlFile, key)
        if modeName then
            local mode = g_terraFarm.NAME_TO_MODE[modeName]
            if mode then
                table.insert(self.availableDischargeModes, mode)
                self.availableDischargeModeByIndex[mode] = true
                self.availableDischargeModeByName[modeName] = true
            else
                Logging.warning('ShovelConfiguration.loadSettings: unknown mode - ' .. tostring(mode))
            end
        end
        i = i + 1
    end
end