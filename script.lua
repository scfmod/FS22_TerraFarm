local modFolder = g_currentModDirectory

source(modFolder .. 'classes/TerraFarmConfig.lua')
source(modFolder .. 'classes/TerraFarm.lua')
source(modFolder .. 'classes/debug/TerraFarmDebug.lua')

source(modFolder .. 'classes/TerraFarmFillTypes.lua')
source(modFolder .. 'classes/TerraFarmGroundTypes.lua')

source(modFolder .. 'classes/TerraFarmLandscaping.lua')
source(modFolder .. 'classes/events/TerraFarmLandscapingEvent.lua')

source(modFolder .. 'classes/MachineTypes.lua')
source(modFolder .. 'classes/specializations/Machine.lua')

source(modFolder .. 'classes/TerraFarmMachine.lua')
source(modFolder .. 'classes/machines/TerraFarmShovel.lua')
source(modFolder .. 'classes/machines/TerraFarmTractor.lua')

source(modFolder .. 'classes/MachineConfiguration.lua')
source(modFolder .. 'classes/configurations/ShovelConfiguration.lua')
source(modFolder .. 'classes/configurations/TractorConfiguration.lua')

source(modFolder .. 'classes/hud/MachineHUDExtension.lua')

source(modFolder .. 'classes/gui/TerraFarmSettingsScreen.lua')
source(modFolder .. 'classes/gui/TerraFarmSettingsMainFrame.lua')
source(modFolder .. 'classes/gui/TerraFarmSettingsMachineFrame.lua')

local TerraFarmMod = {}

function TerraFarmMod:update(dt)
    if g_terraFarm then
        g_terraFarm:onUpdate(dt)
    end
end

function TerraFarmMod:loadMap()
    g_terraFarm:onReady()
    self:setupGui()

    GameSettings.saveToXMLFile = Utils.appendedFunction(GameSettings.saveToXMLFile,
        function(xmlFile)
            if xmlFile and g_terraFarm then
                g_terraFarm:saveConfig()
            end
        end
    )
end

function TerraFarmMod:setupGui()
    ---@diagnostic disable-next-line: lowercase-global
    g_terraFarmSettingsScreen = TerraFarmSettingsScreen.new(nil, nil, g_messageCenter, g_i18n, g_inputBinding)

    -- Load frames first
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsMainFrame.xml', 'TerraFarmSettingsMainFrame', TerraFarmSettingsMainFrame.new(), true)
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsMachineFrame.xml', 'TerraFarmSettingsMachineFrame', TerraFarmSettingsMachineFrame.new(), true)

    -- Load screen last
    g_gui:loadGui(modFolder .. 'xml/TerraFarmSettingsScreen.xml', 'TerraFarmSettingsScreen', g_terraFarmSettingsScreen)
end

addModEventListener(TerraFarmMod)