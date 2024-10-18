---@class InGameMenuMachinesFrame : TabbedMenuFrameElement
---@field isOpen boolean
---@field lastUpdate number
---@field backButtonInfo table
---@field vehicles Machine[]
---@field list SmoothListElement
---@field superClass fun(): TabbedMenuFrameElement
---
---@field infoBox BitmapElement
---@field infoVehicleImage BitmapElement
---@field infoVehicleName TextElement
---@field infoVehicleBrandName TextElement
---@field infoStateRadius TextElement
---@field infoStateStrength TextElement
---@field infoStateHardness TextElement
---@field infoStateTerrainLayer TerrainLayerElement
---@field infoStateTerrainLayerName TextElement
---@field infoStateFillTypeName TextElement
---@field infoStateFillType BitmapElement
InGameMenuMachinesFrame = {}

InGameMenuMachinesFrame.MENU_PAGE_NAME = 'ingameMenuMachines'
InGameMenuMachinesFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/InGameMenuMachinesFrame.xml'
InGameMenuMachinesFrame.UPDATE_INTERVAL = 4000

InGameMenuMachinesFrame.ICON_UVS = GuiUtils.getUVs('0 0.5 0.25 0.25')

InGameMenuMachinesFrame.L10N_ENABLED = g_i18n:getText('ui_enabled')
InGameMenuMachinesFrame.L10N_DISABLED = g_i18n:getText('ui_disabled')

InGameMenuMachinesFrame.L10N_ACTION_ENABLE = g_i18n:getText('ui_enable')
InGameMenuMachinesFrame.L10N_ACTION_DISABLE = g_i18n:getText('ui_disable')
InGameMenuMachinesFrame.L10N_ACTION_SETTINGS = g_i18n:getText('ui_globalSettings')
InGameMenuMachinesFrame.L10N_ACTION_MACHINE_SETTINGS = g_i18n:getText('ui_machineSettings')

InGameMenuMachinesFrame.CONTROLS = {
    'layout',
    'list',
    'infoBox',
    'infoVehicleImage',
    'infoVehicleName',
    'infoVehicleBrandName',
    'infoStateRadius',
    'infoStateStrength',
    'infoStateHardness',
    'infoStateTerrainLayer',
    'infoStateTerrainLayerName',
    'infoStateFillTypeName',
    'infoStateFillType',
}

local InGameMenuMachinesFrame_mt = Class(InGameMenuMachinesFrame, TabbedMenuFrameElement)

---@return InGameMenuMachinesFrame
---@nodiscard
function InGameMenuMachinesFrame.new()
    ---@type InGameMenuMachinesFrame
    local self = TabbedMenuFrameElement.new(nil, InGameMenuMachinesFrame_mt)

    self:registerControls(InGameMenuMachinesFrame.CONTROLS)

    self.isOpen = false
    self.lastUpdate = 0
    self.vehicles = {}

    self.hasCustomMenuButtons = true
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }

    return self
end

function InGameMenuMachinesFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.list:setDataSource(self)

    self:initialize()
end

function InGameMenuMachinesFrame:initialize()
    self.settingsButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_2,
        text = InGameMenuMachinesFrame.L10N_ACTION_SETTINGS,
        callback = function()
            self:onClickGlobalSettings()
        end
    }

    self.machineSettingsButtonInfo = {
        inputAction = InputAction.MENU_ACTIVATE,
        text = InGameMenuMachinesFrame.L10N_ACTION_MACHINE_SETTINGS,
        callback = function()
            self:onClickMachineSettings()
        end
    }


    self.toggleEnabledButtonInfo = {
        inputAction = InputAction.MENU_EXTRA_1,
        text = InGameMenuMachinesFrame.L10N_ACTION_ENABLE,
        callback = function()
            self:onClickToggleEnabled()
        end
    }
end

function InGameMenuMachinesFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self.isOpen = true

    self:updateVehicles()

    self:setSoundSuppressed(true)
    FocusManager:setFocus(self.list)
    self:setSoundSuppressed(false)

    g_messageCenter:subscribe(MessageType.MACHINE_ADDED, self.onMachineAdded, self)
    g_messageCenter:subscribe(MessageType.MACHINE_REMOVED, self.onMachineRemoved, self)
    g_messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
    g_messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
    g_messageCenter:subscribe(PlayerPermissionsEvent, self.onPlayerPermissionsChanged, self)

    g_machineManager:checkDisplayWarning()
end

function InGameMenuMachinesFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    self.isOpen = false

    g_messageCenter:unsubscribeAll(self)
end

---@param dt number
function InGameMenuMachinesFrame:update(dt)
    self:superClass().update(self, dt)

    if self.isOpen then
        self.lastUpdate = self.lastUpdate + dt

        if self.lastUpdate > InGameMenuMachinesFrame.UPDATE_INTERVAL then
            self:updateVehicles()
        end
    end
end

function InGameMenuMachinesFrame:getNumberOfItemsInSection()
    return #self.vehicles
end

---@param list SmoothListElement
---@param section number
---@param index number
---@param cell table
function InGameMenuMachinesFrame:populateCellForItemInSection(list, section, index, cell)
    local vehicle = self.vehicles[index]

    if vehicle ~= nil then
        local spec = vehicle.spec_machine
        local farmName = MachineUtils.getVehicleFarmName(vehicle)

        cell:getAttribute('vehicleName'):setText(vehicle:getName())

        if vehicle.brand ~= nil then
            cell:getAttribute('vehicleBrandName'):setText(vehicle.brand.title)
        else
            cell:getAttribute('vehicleBrandName'):setText('unknown')
        end

        ---@type Machine
        ---@diagnostic disable-next-line: assign-type-mismatch
        local rootVehicle = vehicle:getRootVehicle()

        if rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then
            cell:getAttribute('playerName'):setText(rootVehicle:getControllerName())
            cell:getAttribute('playerName'):setDisabled(false)
        else
            cell:getAttribute('playerName'):setText('-')
            cell:getAttribute('playerName'):setDisabled(true)
        end

        cell:getAttribute('machineStatus'):setText(spec.enabled and InGameMenuMachinesFrame.L10N_ENABLED or InGameMenuMachinesFrame.L10N_DISABLED)
        cell:getAttribute('machineStatus'):setDisabled(not spec.enabled)
        cell:getAttribute('machineTypeName'):setText(spec.machineType.name)

        cell:getAttribute('farmName'):setText(farmName)
    end
end

---@param list SmoothListElement
---@param section number
---@param index number
function InGameMenuMachinesFrame:onListSelectionChanged(list, section, index)
    self:updateVehicleDetails()
    self:updateMenuButtons()
end

function InGameMenuMachinesFrame:updateMenuButtons()
    self.menuButtonInfo = {
        self.backButtonInfo
    }

    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        local spec = vehicle.spec_machine

        if spec.enabled then
            self.toggleEnabledButtonInfo.text = InGameMenuMachinesFrame.L10N_ACTION_DISABLE
        else
            self.toggleEnabledButtonInfo.text = InGameMenuMachinesFrame.L10N_ACTION_ENABLE
        end

        if MachineUtils.getPlayerHasPermission('manageRights') then
            table.insert(self.menuButtonInfo, self.toggleEnabledButtonInfo)
        end

        if MachineUtils.getPlayerHasPermission('landscaping') then
            table.insert(self.menuButtonInfo, self.machineSettingsButtonInfo)
        end
    end

    table.insert(self.menuButtonInfo, self.settingsButtonInfo)

    self:setMenuButtonInfoDirty()
end

---@return Machine | nil
---@nodiscard
function InGameMenuMachinesFrame:getSelectedVehicle()
    if self.list ~= nil then
        return self.vehicles[self.list:getSelectedIndexInSection()]
    end
end

function InGameMenuMachinesFrame:updateVehicles()
    self.vehicles = g_machineManager:getAccessibleVehicles()

    table.sort(self.vehicles, function(a, b)
        return a:getName() < b:getName()
    end)

    self.list:reloadData()

    self:updateVehicleDetails()
    self:updateMenuButtons()

    self.lastUpdate = 0
end

function InGameMenuMachinesFrame:updateVehicleDetails()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        self.infoBox:setVisible(true)

        self.infoVehicleImage:setImageFilename(vehicle:getImageFilename())
        self.infoVehicleName:setText(vehicle:getName())

        if vehicle.brand ~= nil then
            self.infoVehicleBrandName:setText(vehicle.brand.title)
        else
            self.infoVehicleBrandName:setText('')
        end

        local spec = vehicle.spec_machine

        self.infoStateRadius:setText(string.format('%.2f', spec.state.radius))
        self.infoStateStrength:setText(string.format('%.2f', spec.state.strength))
        self.infoStateHardness:setText(string.format('%.2f', spec.state.hardness))

        local terrainLayer = g_resources:getTerrainLayerById(spec.terrainLayerId)

        self.infoStateTerrainLayer:setTerrainLayer(g_currentMission.terrainRootNode, terrainLayer.id)
        self.infoStateTerrainLayerName:setText(terrainLayer.title)

        local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

        if fillType ~= nil then
            self.infoStateFillTypeName:setText(fillType.title)
            self.infoStateFillType:setImageFilename(fillType.hudOverlayFilename)
        else
            self.infoStateFillTypeName:setText('')
            self.infoStateFillType:setImageFilename(nil)
        end
    else
        self.infoBox:setVisible(false)
    end
end

---@param vehicle Machine
function InGameMenuMachinesFrame:onMachineAdded(vehicle)
    self:updateVehicles()
end

---@param vehicle Machine
function InGameMenuMachinesFrame:onMachineRemoved(vehicle)
    if table.hasElement(self.vehicles, vehicle) then
        self:updateVehicles()
    end
end

function InGameMenuMachinesFrame:onClickGlobalSettings()
    g_globalSettingsDialog:show()
end

function InGameMenuMachinesFrame:onClickMachineSettings()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        g_machineSettingsDialog:show(vehicle)
    end
end

function InGameMenuMachinesFrame:onClickToggleEnabled()
    local vehicle = self:getSelectedVehicle()

    if vehicle ~= nil then
        vehicle:setMachineEnabled(not vehicle:getMachineEnabled())
        self:updateVehicles()
    end
end

function InGameMenuMachinesFrame:onItemDoubleClick()
    self:onClickMachineSettings()
end

---@param user User
function InGameMenuMachinesFrame:onMasterUserAdded(user)
    if user:getId() == g_currentMission.playerUserId then
        self:updateVehicles()
    end
end

---@param player Player | nil
function InGameMenuMachinesFrame:onPlayerFarmChanged(player)
    if player ~= nil and player.userId == g_currentMission.playerUserId then
        self:updateVehicles()
    end
end

---@param userId number
function InGameMenuMachinesFrame:onPlayerPermissionsChanged(userId)
    if userId == g_currentMission.playerUserId then
        self:updateMenuButtons()
    end
end
