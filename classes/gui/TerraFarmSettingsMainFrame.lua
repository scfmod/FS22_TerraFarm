---@class TerraFarmSettingsMainFrame : TabbedMenuFrameElement
---@field boxLayout BoxLayoutElement
---@field enableGlobal CheckedOptionElement
---@field enableDebug CheckedOptionElement
---@field disableDischarge CheckedOptionElement
---@field disablePaint CheckedOptionElement
---@field paintLayer MultiTextOptionElement
---@field fillType MultiTextOptionElement
---@field dischargePaintLayer MultiTextOptionElement
TerraFarmSettingsMainFrame = {}

local TerraFarmSettingsMainFrame_mt = Class(TerraFarmSettingsMainFrame, TabbedMenuFrameElement)

TerraFarmSettingsMainFrame.CONTROLS = {
    'boxLayout',

    'enableGlobal',
    'enableDebug',
    'fillType',
    'disableDischarge',
    'paintLayer',
    'dischargePaintLayer',
    'disablePaint'
}

function TerraFarmSettingsMainFrame.new(target, mt)
    ---@type TerraFarmSettingsMainFrame
    local self = TabbedMenuFrameElement.new(target, mt or TerraFarmSettingsMainFrame_mt)

    self:registerControls(TerraFarmSettingsMainFrame.CONTROLS)

    return self
end

function TerraFarmSettingsMainFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function TerraFarmSettingsMainFrame:onFrameOpen()
    ---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsMainFrame:superClass().onFrameOpen(self)
    self:updateSettings()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function TerraFarmSettingsMainFrame:updateSettings()
    self.enableGlobal:setIsChecked(g_terraFarm:getIsEnabled())
    self.enableDebug:setIsChecked(g_terraFarm.config.debug)
    self.disableDischarge:setIsChecked(g_terraFarm.config.disableDischarge)
    self.disablePaint:setIsChecked(g_terraFarm.config.terraformDisablePaint)
    self.paintLayer:setState(TerraFarmGroundTypes:getIndexByName(g_terraFarm.config.terraformPaintLayer))
    self.dischargePaintLayer:setState(TerraFarmGroundTypes:getIndexByName(g_terraFarm.config.dischargePaintLayer))
    self.fillType:setState(TerraFarmFillTypes.NAME_TO_INDEX[g_terraFarm.config.fillTypeName])
end

function TerraFarmSettingsMainFrame:onGlobalCheckClick(state)
    g_terraFarm:setEnabled(state == CheckedOptionElement.STATE_CHECKED)
end

function TerraFarmSettingsMainFrame:onDebugCheckClick(state)
    g_terraFarm.config.debug = (state == CheckedOptionElement.STATE_CHECKED)
end

function TerraFarmSettingsMainFrame:onDisableDischargeCheckClick(state)
    g_terraFarm.config.disableDischarge = (state == CheckedOptionElement.STATE_CHECKED)
end

function TerraFarmSettingsMainFrame:onDisablePaintCheckClick(state)
    g_terraFarm.config.terraformDisablePaint = (state == CheckedOptionElement.STATE_CHECKED)
end

---@param element MultiTextOptionElement
function TerraFarmSettingsMainFrame:onCreateFillType(element)
    element:setTexts(TerraFarmFillTypes.TYPES_LIST)
end

---@param state number
function TerraFarmSettingsMainFrame:onClickFillType(state)
    g_terraFarm:setFillType(nil, state)
    self:updateSettings()
end


---@param element MultiTextOptionElement
function TerraFarmSettingsMainFrame:onCreateDischargePaintLayer(element)
    element:setTexts(TerraFarmGroundTypes.TYPES_LIST)
end

---@param state number
function TerraFarmSettingsMainFrame:onClickDischargePaintLayer(state)
    g_terraFarm:setDischargePaintLayer(nil, state)
    self:updateSettings()
end

---@param element MultiTextOptionElement
function TerraFarmSettingsMainFrame:onCreatePaintLayer(element)
    element:setTexts(TerraFarmGroundTypes.TYPES_LIST)
end

---@param state number
function TerraFarmSettingsMainFrame:onClickPaintLayer(state)
    g_terraFarm:setPaintLayer(nil, state)
    self:updateSettings()
end