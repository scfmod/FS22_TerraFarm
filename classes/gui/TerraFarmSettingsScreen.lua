local modFolder = g_currentModDirectory

---@class TerraFarmSettingsScreen : TabbedMenuWithDetails
---@field terraFarmMainSettings TerraFarmSettingsMainFrame
---@field terraFarmMachineSettings TerraFarmSettingsMachineFrame
TerraFarmSettingsScreen = {}
local TerraFarmSettingsScreen_mt = Class(TerraFarmSettingsScreen, TabbedMenuWithDetails)
-- local TerraFarmSettingsScreen_mt = Class(TerraFarmSettingsScreen, TabbedMenu)

TerraFarmSettingsScreen.CONTROLS = {
    'terraFarmMainSettings',
    'terraFarmMachineSettings'
}

function TerraFarmSettingsScreen.new(target, mt, messageCenter, l10n, inputManager)
    ---@type TerraFarmSettingsScreen
    local self = TabbedMenuWithDetails.new(target, mt or TerraFarmSettingsScreen_mt, messageCenter, l10n, inputManager)

    self:registerControls(TerraFarmSettingsScreen.CONTROLS)

    return self
end

function TerraFarmSettingsScreen:onGuiSetupFinished()
    ---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsScreen:superClass().onGuiSetupFinished(self)

    self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

    self.terraFarmMainSettings:initialize()
    self.terraFarmMachineSettings:initialize()

    self:setupPages()
    self:setupMenuButtonInfo()
end

function TerraFarmSettingsScreen:onOpen()
    ---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsScreen:superClass().onOpen(self)

    FocusManager:lockFocusInput(InputAction.MENU_PAGE_NEXT, 150)
    FocusManager:lockFocusInput(InputAction.MENU_PAGE_PREV, 150)

    FocusManager:lockFocusInput(FocusManager.TOP, 150)
    FocusManager:lockFocusInput(FocusManager.BOTTOM, 150)
end

function TerraFarmSettingsScreen:setupPages()
    local pages = {
        {
            self.terraFarmMainSettings,
            'tab_main.png'
        },
        {
            self.terraFarmMachineSettings,
            'tab_machine.png'
        },
    }

    for i, _page in ipairs(pages) do
        local page, icon = unpack(_page)

        self:registerPage(page, i)
        self:addPageTab(page, modFolder .. 'textures/' .. icon)
    end
end

function TerraFarmSettingsScreen:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback
    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
            callback = onButtonBackFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction
    }
end

function TerraFarmSettingsScreen:exitMenu()
    self:changeScreen()
end