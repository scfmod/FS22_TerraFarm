---@class GlobalSettingsDialog : MessageDialog
---@field boxLayout ScrollingLayoutElement
---@field hudEnabledOption CheckedOptionElement
---@field enabledOption CheckedOptionElement
---@field defaultEnabledOption CheckedOptionElement
---@field settingsButton ButtonElement
---@field debugNodesOption CheckedOptionElement
---@field debugCalibrationOption CheckedOptionElement
---@field resourcesEnabledOption CheckedOptionElement
---@field extensionStatus TextElement
---@field superClass fun(): MessageDialog
GlobalSettingsDialog = {}

GlobalSettingsDialog.CLASS_NAME = 'GlobalSettingsDialog'
GlobalSettingsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/GlobalSettingsDialog.xml'

GlobalSettingsDialog.CONTROLS = {
    'boxLayout',
    'enabledOption',
    'defaultEnabledOption',
    'hudEnabledOption',
    'settingsButton',
    'debugNodesOption',
    'debugCalibrationOption',
    'resourcesEnabledOption',
    'extensionStatus'
}

GlobalSettingsDialog.L10N_FEATURE_AVAILABLE = g_i18n:getText('ui_mapResourcesAvailable')
GlobalSettingsDialog.L10N_FEATURE_NOT_AVAILABLE = g_i18n:getText('ui_mapResourcesNotAvailable')

local GlobalSettingsDialog_mt = Class(GlobalSettingsDialog, MessageDialog)

---@return GlobalSettingsDialog
---@nodiscard
function GlobalSettingsDialog.new()
    ---@type GlobalSettingsDialog
    local self = MessageDialog.new(nil, GlobalSettingsDialog_mt)

    self:registerControls(GlobalSettingsDialog.CONTROLS)

    return self
end

function GlobalSettingsDialog:delete()
    self:superClass().delete(self)

    FocusManager.guiFocusData[GlobalSettingsDialog.CLASS_NAME] = {
        idToElementMapping = {}
    }

    g_messageCenter:unsubscribeAll(self)
end

function GlobalSettingsDialog:load()
    g_gui:loadGui(GlobalSettingsDialog.XML_FILENAME, GlobalSettingsDialog.CLASS_NAME, self)
end

function GlobalSettingsDialog:show()
    g_gui:showDialog(GlobalSettingsDialog.CLASS_NAME)
end

function GlobalSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateSettings()
    self:updateMenuButtons()

    self.boxLayout:invalidateLayout()

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == GlobalSettingsDialog.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end

    g_messageCenter:subscribe(SetDefaultEnabledEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetGlobalEnabledEvent, self.updateSettings, self)
    g_messageCenter:subscribe(SetGlobalResourcesEvent, self.updateSettings, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
end

function GlobalSettingsDialog:onClose()
    self:superClass().onClose(self)

    g_messageCenter:unsubscribeAll(self)
end

function GlobalSettingsDialog:updateSettings()
    local canModifySettings = MachineUtils.getCanModifySettings()

    self.enabledOption:setIsChecked(g_settings:getIsEnabled())
    self.enabledOption:setDisabled(not canModifySettings)

    self.defaultEnabledOption:setDisabled(not canModifySettings)
    self.defaultEnabledOption:setIsChecked(g_settings.defaultMachineEnabled)

    self.debugNodesOption:setIsChecked(g_settings:getDebugNodes())
    self.debugCalibrationOption:setIsChecked(g_settings:getDebugCalibration())

    self.settingsButton:setVisible(canModifySettings)

    local resourcesAvailable = g_resources:getIsAvailable()

    self.resourcesEnabledOption:setDisabled(not resourcesAvailable)
    self.resourcesEnabledOption:setIsChecked(g_resources:getIsActive())

    self.hudEnabledOption:setIsChecked(g_machineHUD.display.isVisible)

    if resourcesAvailable then
        self.extensionStatus:setText(g_i18n:getText('ui_mapResourcesAvailable'))
        self.extensionStatus:setDisabled(false)
    else
        self.extensionStatus:setText(g_i18n:getText('ui_mapResourcesNotAvailable'))
        self.extensionStatus:setDisabled(true)
    end
end

function GlobalSettingsDialog:updateMenuButtons()
    self.settingsButton:setVisible(MachineUtils.getCanModifySettings())
end

function GlobalSettingsDialog:forceReload()
    self:updateSettings()
    self.boxLayout:invalidateLayout()
end

---@param state number
function GlobalSettingsDialog:onClickHudEnabledOption(state)
    g_machineHUD.display:setVisible(state == CheckedOptionElement.STATE_CHECKED, false)

    g_settings:saveUserSettings()
end

---@param state number
function GlobalSettingsDialog:onClickDebugNodesOption(state)
    g_settings:setDebugNodes(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickDebugCalibrationOption(state)
    g_settings:setDebugCalibration(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickEnabledOption(state)
    g_settings:setIsEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

---@param state number
function GlobalSettingsDialog:onClickDefaultEnabledOption(state)
    g_settings:setDefaultMachineEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

function GlobalSettingsDialog:onClickMaterialSettings()
    g_globalMaterialsDialog:show()
end

---@param state number
function GlobalSettingsDialog:onClickResourcesEnabledOption(state)
    g_resources:setIsActive(state == CheckedOptionElement.STATE_CHECKED)
end

---@param user User
function GlobalSettingsDialog:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateSettings()
        self:updateMenuButtons()
    end
end
