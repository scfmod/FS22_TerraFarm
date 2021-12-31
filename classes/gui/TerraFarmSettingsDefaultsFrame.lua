---@class TerraFarmSettingsDefaultsFrame : TabbedMenuFrameElement
---@field boxLayout BoxLayoutElement
TerraFarmSettingsDefaultsFrame = {}

local TerraFarmSettingsDefaultsFrame_mt = Class(TerraFarmSettingsDefaultsFrame, TabbedMenuFrameElement)

TerraFarmSettingsDefaultsFrame.CONTROLS = {
    'boxLayout'
}

function TerraFarmSettingsDefaultsFrame.new(target, mt)
    ---@type TerraFarmSettingsDefaultsFrame
    local self = TabbedMenuFrameElement.new(target, mt or TerraFarmSettingsDefaultsFrame_mt)

    self:registerControls(TerraFarmSettingsDefaultsFrame.CONTROLS)

    return self
end

function TerraFarmSettingsDefaultsFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function TerraFarmSettingsDefaultsFrame:onOpen()
---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsDefaultsFrame:superClass().onFrameOpen(self)
    self:updateSettings()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function TerraFarmSettingsDefaultsFrame:updateSettings()
    -- TODO
end

---@param element TextInputElement
---@param value number
function TerraFarmSettingsDefaultsFrame:setElementText(element, value)
    element:setText(string.format('%.2f', value))
end

---@param element TextInputElement
function TerraFarmSettingsDefaultsFrame:onStrengthPressedTextInput(element)
    if not g_terraFarm.currentMachine then return end

    local value = tonumber(element.text)

    if value ~= nil then
        if value < TerraFarmConfig.STRENGTH_MIN then
            value = TerraFarmConfig.STRENGTH_MIN
        elseif value > TerraFarmConfig.STRENGTH_MAX then
            value = TerraFarmConfig.STRENGTH_MAX
        end
        g_terraFarm.currentMachine:setConfigProperty(name, value)
    end

    self:setElementText(element, g_terraFarm.currentMachine:getConfigProperty(name))
end

---@param element TextInputElement
function TerraFarmSettingsDefaultsFrame:onRadiusPressedTextInput(element)
    if not g_terraFarm.currentMachine then return end

    local value = tonumber(element.text)
    local name = element.id

    if value ~= nil then
        if value < TerraFarmConfig.RADIUS_MIN then
            value = TerraFarmConfig.RADIUS_MIN
        elseif value > TerraFarmConfig.RADIUS_MAX then
            value = TerraFarmConfig.RADIUS_MAX
        end
        g_terraFarm.currentMachine:setConfigProperty(name, value)
    end

    self:setElementText(element, g_terraFarm.currentMachine:getConfigProperty(name))
end