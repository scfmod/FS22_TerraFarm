source(g_currentModDirectory .. 'scripts/gui/dialogs/input/FloatInputDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/input/NameInputDialog.lua')

source(g_currentModDirectory .. 'scripts/gui/dialogs/SelectSurveyorDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/SelectMachineDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/SelectMaterialDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/SelectTerrainLayerDialog.lua')

source(g_currentModDirectory .. 'scripts/gui/dialogs/GlobalMaterialsDialog.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/GlobalSettingsDialog.lua')

source(g_currentModDirectory .. 'scripts/gui/frames/MachineSettingsAdvancedFrame.lua')
source(g_currentModDirectory .. 'scripts/gui/frames/MachineSettingsCalibrationFrame.lua')
source(g_currentModDirectory .. 'scripts/gui/frames/MachineSettingsLandscapingFrame.lua')
source(g_currentModDirectory .. 'scripts/gui/frames/MachineSettingsFrame.lua')
source(g_currentModDirectory .. 'scripts/gui/dialogs/MachineSettingsDialog.lua')

source(g_currentModDirectory .. 'scripts/gui/screens/SurveyorCamera.lua')
source(g_currentModDirectory .. 'scripts/gui/screens/SurveyorCursor.lua')
source(g_currentModDirectory .. 'scripts/gui/screens/SurveyorScreen.lua')

source(g_currentModDirectory .. 'scripts/gui/elements/MachineButtonElement.lua')
source(g_currentModDirectory .. 'scripts/gui/elements/MachineCheckedOptionElement.lua')
source(g_currentModDirectory .. 'scripts/gui/elements/MachineMultiTextOptionElement.lua')
source(g_currentModDirectory .. 'scripts/gui/elements/MachineTextInputElement.lua')
source(g_currentModDirectory .. 'scripts/gui/frames/InGameMenuMachinesFrame.lua')

---@class MachineGUI
---@field machinesFrame InGameMenuMachinesFrame
---@field surveyorScreen SurveyorScreen
---@field profiles string[]
MachineGUI = {}

local MachineGUI_mt = Class(MachineGUI)

---@return MachineGUI
---@nodiscard
function MachineGUI.new()
    ---@type MachineGUI
    local self = setmetatable({}, MachineGUI_mt)

    self.profiles = {
        g_currentModDirectory .. 'xml/gui/guiProfiles.base.xml',
        g_currentModDirectory .. 'xml/gui/guiProfiles.dialogs.xml',
        g_currentModDirectory .. 'xml/gui/guiProfiles.hud.xml',
        g_currentModDirectory .. 'xml/gui/guiProfiles.menu.xml',
        g_currentModDirectory .. 'xml/gui/guiProfiles.screens.xml'
    }

    addConsoleCommand('tfGuiReload', '', 'consoleReloadGui', self)

    return self
end

function MachineGUI:delete()
    if g_globalMaterialsDialog.isOpen then
        g_globalMaterialsDialog:close()
    end

    if g_globalSettingsDialog.isOpen then
        g_globalSettingsDialog:close()
    end

    if g_machineSettingsDialog.isOpen then
        g_machineSettingsDialog:exitMenu()
    end

    if g_selectMaterialDialog.isOpen then
        g_selectMaterialDialog:close()
    end

    if g_selectTerrainLayerDialog.isOpen then
        g_selectTerrainLayerDialog:close()
    end

    if g_selectMachineDialog.isOpen then
        g_selectMachineDialog:close()
    end

    if g_selectSurveyorDialog.isOpen then
        g_selectSurveyorDialog:close()
    end

    if g_nameInputDialog.isOpen then
        g_nameInputDialog:close()
    end

    if g_floatInputDialog.isOpen then
        g_floatInputDialog:close()
    end

    g_gui:showGui(nil)

    self.surveyorScreen:delete()
    self.surveyorScreen = nil

    g_machineSettingsDialog:delete()
    g_selectMaterialDialog:delete()
    g_selectTerrainLayerDialog:delete()
    g_selectMachineDialog:delete()
    g_selectSurveyorDialog:delete()
    g_globalMaterialsDialog:delete()
    g_globalSettingsDialog:delete()
end

function MachineGUI:load()
    self:loadProfiles()
    self:loadDialogs()
    self:loadScreens()
end

function MachineGUI:loadProfiles()
    g_gui.currentlyReloading = true

    for _, file in ipairs(self.profiles) do
        g_gui:loadProfiles(file)
    end

    g_gui.currentlyReloading = false
end

function MachineGUI:loadDialogs()
    ---@diagnostic disable-next-line: lowercase-global
    g_machineSettingsDialog = MachineSettingsDialog.new()
    g_machineSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectMaterialDialog = SelectMaterialDialog.new()
    g_selectMaterialDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectTerrainLayerDialog = SelectTerrainLayerDialog.new()
    g_selectTerrainLayerDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectMachineDialog = SelectMachineDialog.new()
    g_selectMachineDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_selectSurveyorDialog = SelectSurveyorDialog.new()
    g_selectSurveyorDialog:load()

    if g_nameInputDialog == nil then
        ---@diagnostic disable-next-line: lowercase-global
        g_nameInputDialog = NameInputDialog.new()
        g_nameInputDialog:load()
    end

    if g_floatInputDialog == nil then
        ---@diagnostic disable-next-line: lowercase-global
        g_floatInputDialog = FloatInputDialog.new()
        g_floatInputDialog:load()
    end

    ---@diagnostic disable-next-line: lowercase-global
    g_globalSettingsDialog = GlobalSettingsDialog.new()
    g_globalSettingsDialog:load()

    ---@diagnostic disable-next-line: lowercase-global
    g_globalMaterialsDialog = GlobalMaterialsDialog.new()
    g_globalMaterialsDialog:load()
end

function MachineGUI:loadFrames()
    self.machinesFrame = InGameMenuMachinesFrame.new()

    g_gui:loadGui(InGameMenuMachinesFrame.XML_FILENAME, InGameMenuMachinesFrame.MENU_PAGE_NAME, self.machinesFrame, true)

    ---@type InGameMenu
    local inGameMenu = g_currentMission.inGameMenu

    inGameMenu[InGameMenuMachinesFrame.MENU_PAGE_NAME] = self.machinesFrame
    inGameMenu:registerPage(self.machinesFrame, nil, function()
        return true
    end)
    inGameMenu:addPageTab(self.machinesFrame, g_machineUIFilename, InGameMenuMachinesFrame.ICON_UVS)
    inGameMenu.pagingElement:addElement(self.machinesFrame)

    self.machinesFrame:applyScreenAlignment()
    self.machinesFrame:updateAbsolutePosition()
end

function MachineGUI:loadScreens()
    self.surveyorScreen = SurveyorScreen.new()
    self.surveyorScreen:load()
end

function MachineGUI:reload()
    local currentGuiName = g_gui.currentGuiName

    local machineDialogIsOpen = g_machineSettingsDialog.isOpen
    local globalSettingsDialogIsOpen = g_globalSettingsDialog.isOpen
    local globalMaterialsDialogIsOpen = g_globalMaterialsDialog.isOpen

    local selectedVehicle

    if machineDialogIsOpen then
        selectedVehicle = g_machineSettingsDialog.vehicle
    end

    self:delete()
    self:loadProfiles()
    self:loadDialogs()
    self:loadScreens()

    g_machineHUD:reload()

    if currentGuiName ~= SurveyorScreen.CLASS_NAME then
        g_gui:showGui(currentGuiName)
    end

    if machineDialogIsOpen and selectedVehicle ~= nil then
        g_machineSettingsDialog:show(selectedVehicle)
    end

    if globalSettingsDialogIsOpen then
        g_globalSettingsDialog:show()
    end

    if globalMaterialsDialogIsOpen then
        g_globalMaterialsDialog:show()
    end
end

function MachineGUI:onMapLoaded()
    if g_client ~= nil then
        self:loadFrames()
    end
end

function MachineGUI:consoleReloadGui()
    self:reload()

    return 'Reloaded GUI'
end

---@diagnostic disable-next-line: lowercase-global
g_machineGUI = MachineGUI.new()
