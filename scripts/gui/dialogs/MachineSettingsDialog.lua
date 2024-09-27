---@class MachineSettingsDialog : TabbedMenuWithDetails
---@field dialogElement GuiElement
---@field pageSelector MultiTextOptionElement
---@field isCloseAllowed boolean
---@field settingsFrame MachineSettingsFrame
---@field landscapingSettingsFrame MachineSettingsLandscapingFrame
---@field advancedSettingsFrame MachineSettingsAdvancedFrame
---@field calibrationSettingsFrame MachineSettingsCalibrationFrame
---@field vehicle Machine | nil
---@field defaultMenuButtonInfoByActions table -- src: TabbedMenu
---
---@field vehicleImage BitmapElement
---@field vehicleName TextElement
---@field vehicleBrandName TextElement
---@field machineTypeName TextElement
---
---@field superClass fun(): TabbedMenuWithDetails
MachineSettingsDialog = {}

MachineSettingsDialog.CLASS_NAME = 'MachineSettingsDialog'
MachineSettingsDialog.XML_FILENAME = g_currentModDirectory .. 'xml/gui/dialogs/MachineSettingsDialog.xml'
MachineSettingsDialog.CONTROLS = {
    'settingsFrame',
    'landscapingSettingsFrame',
    'advancedSettingsFrame',
    'calibrationSettingsFrame',

    'vehicleImage',
    'vehicleName',
    'vehicleBrandName',
    'machineTypeName'
}

local MachineSettingsDialog_mt = Class(MachineSettingsDialog, TabbedMenuWithDetails)

---@return MachineSettingsDialog
---@nodiscard
function MachineSettingsDialog.new()
    ---@type MachineSettingsDialog
    local self = TabbedMenuWithDetails.new(nil, MachineSettingsDialog_mt, g_messageCenter, g_i18n, g_inputBinding)

    self.isCloseAllowed = true

    self:registerControls(MachineSettingsDialog.CONTROLS)

    return self
end

function MachineSettingsDialog:load()
    self.settingsFrame = MachineSettingsFrame.new(self)
    self.landscapingSettingsFrame = MachineSettingsLandscapingFrame.new(self)
    self.advancedSettingsFrame = MachineSettingsAdvancedFrame.new(self)
    self.calibrationSettingsFrame = MachineSettingsCalibrationFrame.new(self)

    g_gui:loadGui(MachineSettingsFrame.XML_FILENAME, MachineSettingsFrame.CLASS_NAME, self.settingsFrame, true)
    g_gui:loadGui(MachineSettingsLandscapingFrame.XML_FILENAME, MachineSettingsLandscapingFrame.CLASS_NAME, self.landscapingSettingsFrame, true)
    g_gui:loadGui(MachineSettingsAdvancedFrame.XML_FILENAME, MachineSettingsAdvancedFrame.CLASS_NAME, self.advancedSettingsFrame, true)
    g_gui:loadGui(MachineSettingsCalibrationFrame.XML_FILENAME, MachineSettingsCalibrationFrame.CLASS_NAME, self.calibrationSettingsFrame, true)

    g_gui:loadGui(MachineSettingsDialog.XML_FILENAME, MachineSettingsDialog.CLASS_NAME, self)
end

function MachineSettingsDialog:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.settingsFrame:initialize()
    self.landscapingSettingsFrame:initialize()
    self.advancedSettingsFrame:initialize()
    self.calibrationSettingsFrame:initialize()

    self:setupPages()
    self:setupMenuButtonInfo()
end

function MachineSettingsDialog:setupPages()
    ---@return boolean
    local function calibrationPredicateFunction()
        if self.vehicle ~= nil and self.vehicle.spec_machine ~= nil then
            return MachineUtils.getHasInputMode(self.vehicle, Machine.MODE.FLATTEN) or MachineUtils.getHasOutputMode(self.vehicle, Machine.MODE.FLATTEN)
        end

        return false
    end

    local pages = {
        {
            self.settingsFrame,
            g_iconsUIFilename,
            GuiUtils.getUVs(InGameMenu.TAB_UV.GENERAL_SETTINGS),
        },
        {
            self.landscapingSettingsFrame,
            g_iconsUIFilename,
            GuiUtils.getUVs(ShopMenu.TAB_UV.LANDSCAPING)
        },
        {
            self.advancedSettingsFrame,
            g_iconsUIFilename,
            GuiUtils.getUVs(SettingsScreen.TAB_UV.DEVICE_SETTINGS),
        },
        {
            self.calibrationSettingsFrame,
            g_machineUIFilename,
            GuiUtils.getUVs('0.75 0.5 0.25 0.25'),
            calibrationPredicateFunction
        },
    }

    for i, page in ipairs(pages) do
        local element, iconFilename, iconUVs, enablingPredicateFunction = unpack(page)

        self:registerPage(element, i, enablingPredicateFunction)
        self:addPageTab(element, iconFilename, iconUVs)
    end
end

function MachineSettingsDialog:setupMenuButtonInfo()
    local onButtonBackFunction = self.clickBackCallback

    self.defaultMenuButtonInfo = {
        {
            inputAction = InputAction.MENU_BACK,
            text = g_i18n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
            callback = onButtonBackFunction
        }
    }
    self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
    self.defaultButtonActionCallbacks = {
        [InputAction.MENU_BACK] = onButtonBackFunction
    }
end

function MachineSettingsDialog:show(vehicle)
    if vehicle ~= nil then
        self.vehicle = vehicle
        g_gui:showDialog(MachineSettingsDialog.CLASS_NAME)
    end
end

function MachineSettingsDialog:exitMenu()
    self:popToRoot()
    g_gui:closeDialogByName(self.name)
end

function MachineSettingsDialog:onOpen()
    self:superClass().onOpen(self)

    self:updateVehicle()

    g_messageCenter:subscribe(MessageType.MACHINE_REMOVED, self.onMachineRemoved, self)

    FocusManager:lockFocusInput(InputAction.MENU_PAGE_NEXT, 150)
    FocusManager:lockFocusInput(InputAction.MENU_PAGE_PREV, 150)
    FocusManager:lockFocusInput(FocusManager.TOP, 150)
    FocusManager:lockFocusInput(FocusManager.BOTTOM, 150)
end

function MachineSettingsDialog:onClose()
    self:superClass().onClose(self)

    self.vehicle = nil

    g_messageCenter:unsubscribeAll(self)
end

function MachineSettingsDialog:onClickBack()
    if self.currentPage:requestClose(self.clickBackCallback) and self.isCloseAllowed then
        self:exitMenu()
        return false
    end

    return true
end

---@param vehicle Machine
function MachineSettingsDialog:onMachineRemoved(vehicle)
    if vehicle ~= nil and vehicle == self.vehicle then
        self:exitMenu()
    end
end

function MachineSettingsDialog:updateVehicle()
    if self.vehicle ~= nil then
        local spec = self.vehicle.spec_machine

        self.vehicleImage:setImageFilename(self.vehicle:getImageFilename())
        self.machineTypeName:setText(spec.machineType.name)
        self.vehicleName:setText(self.vehicle:getName())

        if self.vehicle.brand ~= nil then
            self.vehicleBrandName:setText(self.vehicle.brand.title)
        else
            self.vehicleBrandName:setText('Unknown')
        end
    end
end

function MachineSettingsDialog:getBlurArea()
    if self.dialogElement ~= nil then
        return self.dialogElement.absPosition[1], self.dialogElement.absPosition[2], self.dialogElement.absSize[1], self.dialogElement.absSize[2]
    end
end

---@param dt number
function MachineSettingsDialog:update(dt)
    ScreenElement.update(self, dt)

    if FocusManager.currentGui ~= self.currentPageName and #g_gui.dialogs == 1 then
        FocusManager:setGui(self.currentPageName)
    end

    if self.currentPage ~= nil then
        if self.currentPage:isMenuButtonInfoDirty() then
            self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
            self.currentPage:clearMenuButtonInfoDirty()
        end

        if self.currentPage:isTabbingMenuVisibleDirty() then
            self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
        end
    end
end

function MachineSettingsDialog:onClickGlobalSettings()
    g_globalSettingsDialog:show()
end
