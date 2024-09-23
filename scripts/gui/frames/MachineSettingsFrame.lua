---@class MachineSettingsFrame : TabbedMenuFrameElement
---@field target MachineSettingsDialog
---@field boxLayout ScrollingLayoutElement
---
---@field enabledOption CheckedOptionElement
---@field resourcesEnabledOption CheckedOptionElement
---@field enableInputMaterialOption CheckedOptionElement
---@field enableOutputMaterialOption CheckedOptionElement
---@field enablePaintGroundTextureOption CheckedOptionElement
---
---@field materialButton ButtonElement
---@field materialText TextElement
---@field materialImage BitmapElement
---@field terrainLayerButton ButtonElement
---@field terrainLayerText TextElement
---@field terrainLayerImage TerrainLayerElement
---
---@field radiusOption TextInputElement
---@field strengthOption TextInputElement
---@field hardnessOption TextInputElement
---@field brushShapeOption MultiTextOptionElement
---
---@field superClass fun(): TabbedMenuFrameElement
MachineSettingsFrame = {}

MachineSettingsFrame.CLASS_NAME = 'MachineSettingsFrame'
MachineSettingsFrame.XML_FILENAME = g_currentModDirectory .. 'xml/gui/frames/MachineSettingsFrame.xml'

MachineSettingsFrame.CONTROLS = {
    'boxLayout',

    'enabledOption',
    'resourcesEnabledOption',
    'enableInputMaterialOption',
    'enableOutputMaterialOption',
    'enablePaintGroundTextureOption',

    'materialButton',
    'materialText',
    'materialImage',
    'terrainLayerButton',
    'terrainLayerText',
    'terrainLayerImage',

    'radiusOption',
    'strengthOption',
    'hardnessOption',
    'brushShapeOption',
}

local MachineSettingsFrame_mt = Class(MachineSettingsFrame, TabbedMenuFrameElement)

---@param target MachineSettingsDialog
---@return MachineSettingsFrame
---@nodiscard
function MachineSettingsFrame.new(target)
    ---@type MachineSettingsFrame
    local self = TabbedMenuFrameElement.new(target, MachineSettingsFrame_mt)

    self:registerControls(MachineSettingsFrame.CONTROLS)

    return self
end

function MachineSettingsFrame:onGuiSetupFinished()
    self:superClass().onGuiSetupFinished(self)

    self.brushShapeOption:setTexts({
        g_i18n:getText('ui_square'),
        g_i18n:getText('ui_circle')
    })
end

function MachineSettingsFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function MachineSettingsFrame:onFrameOpen()
    self:superClass().onFrameOpen(self)

    self:updateMachine()
    self:updateState()
    self:updateMaterial()
    self:updateTerrainLayer()

    self.boxLayout:invalidateLayout()

    g_messageCenter:subscribe(SetEnabledEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetInputModeEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetOutputModeEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetResourcesEnabledEvent, self.updateMachine, self)
    g_messageCenter:subscribe(SetFillTypeEvent, self.updateMaterial, self)
    g_messageCenter:subscribe(SetTerrainLayerEvent, self.updateTerrainLayer, self)

    g_messageCenter:subscribe(SetMachineStateEvent, self.updateState, self)

    local focusedElement = FocusManager:getFocusedElement()

    if focusedElement == nil or focusedElement.name == MachineSettingsFrame.CLASS_NAME then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function MachineSettingsFrame:onFrameClose()
    self:superClass().onFrameClose(self)

    g_messageCenter:unsubscribeAll(self)
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateMachine(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine
        local hasManagePermission = MachineUtils.getPlayerHasPermission('manageRights', nil, self.target.vehicle:getOwnerFarmId())
        local resourcesAvailable = g_resources:getIsActive()

        self.enabledOption:setDisabled(not hasManagePermission or not g_settings:getIsEnabled())
        self.enabledOption:setIsChecked(spec.enabled)

        self.resourcesEnabledOption:setDisabled(not resourcesAvailable or not hasManagePermission)
        self.resourcesEnabledOption:setIsChecked(spec.resourcesEnabled)

        if not g_resources:getIsAvailable() then
            self.resourcesEnabledOption.textElement:setText(g_i18n:getText('ui_notAvailable'))
        end
    end
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateState(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine

        local enableInput = (spec.machineType.useFillUnit and spec.hasFillUnit) or spec.machineType.id == 'ripper' or spec.machineType.id == 'excavatorRipper'

        self.enableInputMaterialOption:setIsChecked(spec.state.enableInputMaterial)
        self.enableInputMaterialOption:setDisabled(not enableInput)

        if not enableInput then
            self.enableInputMaterialOption.textElement:setText(g_i18n:getText('ui_notAvailable'))
        end

        local enableOutput = spec.dischargeNode ~= nil

        self.enableOutputMaterialOption:setIsChecked(spec.state.enableOutputMaterial)
        self.enableOutputMaterialOption:setDisabled(not enableOutput)

        if not enableOutput then
            self.enableOutputMaterialOption.textElement:setText(g_i18n:getText('ui_notAvailable'))
        end

        self.enablePaintGroundTextureOption:setIsChecked(spec.state.enablePaintGroundTexture)

        self.radiusOption:setText(string.format('%.2f', spec.state.radius))
        self.strengthOption:setText(string.format('%.2f', spec.state.strength))
        self.hardnessOption:setText(string.format('%.2f', spec.state.hardness))
        self.brushShapeOption:setState(spec.state.brushShape)
    end
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateMaterial(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine

        local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

        if fillType ~= nil then
            self.materialText:setText(fillType.title)
            self.materialImage:setImageFilename(fillType.hudOverlayFilename)
        else
            self.materialText:setText('')
            self.materialImage:setImageFilename(nil)
        end
    end
end

---@param vehicle Machine | nil
function MachineSettingsFrame:updateTerrainLayer(vehicle)
    if vehicle == nil or vehicle == self.target.vehicle then
        local spec = self.target.vehicle.spec_machine

        local terrainLayer = g_resources:getTerrainLayerById(spec.terrainLayerId)

        self.terrainLayerImage:setTerrainLayer(g_currentMission.terrainRootNode, terrainLayer.id)
        self.terrainLayerText:setText(terrainLayer.title)
    end
end

---@param name string
---@param defaultValue any
---@return any
---@nodiscard
function MachineSettingsFrame:getStateValue(name, defaultValue)
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        return spec.state[name] or defaultValue
    end
end

---@param name string
---@param value any
function MachineSettingsFrame:setStateValue(name, value)
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        if spec.state[name] ~= value then
            local newState = spec.state:clone()

            newState[name] = value

            self.target.vehicle:setMachineState(newState)
        end
    end
end

---@param state number
---@param element CheckedOptionElement
function MachineSettingsFrame:onClickStateCheckedOption(state, element)
    if element.name ~= nil then
        self:setStateValue(element.name, state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsFrame:onClickEnabledOption(state)
    if self.target.vehicle ~= nil then
        self.target.vehicle:setMachineEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsFrame:onClickResourcesEnabledOption(state)
    if self.target.vehicle ~= nil then
        self.target.vehicle:setResourcesEnabled(state == CheckedOptionElement.STATE_CHECKED)
    end
end

---@param state number
function MachineSettingsFrame:onClickBrushShapeOption(state)
    self:setStateValue('brushShape', state)
end

---@param element TextInputElement
function MachineSettingsFrame:onEnterPressedInput(element)
    if element.name ~= nil then
        if element.text ~= '' then
            local value = tonumber(element.text)

            if value ~= nil then
                self:setStateValue(element.name, MathUtil.round(MathUtil.clamp(value, 0, 15), 2))
            end
        end

        element:setText(string.format('%.2f', self:getStateValue(element.name, 0)))
    end
end

function MachineSettingsFrame:onClickSelectMaterial()
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        g_selectMaterialDialog:setSelectCallback(self.selectMaterialCallback, self)
        g_selectMaterialDialog:show(spec.fillTypeIndex)
    end
end

---@param fillTypeIndex number | nil
function MachineSettingsFrame:selectMaterialCallback(fillTypeIndex)
    if self.target.vehicle ~= nil and fillTypeIndex ~= nil then
        self.target.vehicle:setMachineFillTypeIndex(fillTypeIndex)
    end
end

function MachineSettingsFrame:onClickSelectTerrainLayer()
    if self.target.vehicle ~= nil then
        local spec = self.target.vehicle.spec_machine

        g_selectTerrainLayerDialog:setSelectCallback(self.selectTerrainLayerCallback, self)
        g_selectTerrainLayerDialog:show(spec.terrainLayerId)
    end
end

---@param terrainLayerId number | nil
function MachineSettingsFrame:selectTerrainLayerCallback(terrainLayerId)
    if self.target.vehicle ~= nil and terrainLayerId ~= nil then
        self.target.vehicle:setMachineTerrainLayerId(terrainLayerId)
    end
end
