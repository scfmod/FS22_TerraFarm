---@class TerraFarmSettingsMachineFrame : TabbedMenuFrameElement
---@field boxLayout BoxLayoutElement
---@field headerText TextElement
TerraFarmSettingsMachineFrame = {}

local TerraFarmSettingsMachineFrame_mt = Class(TerraFarmSettingsMachineFrame, TabbedMenuFrameElement)

TerraFarmSettingsMachineFrame.CONTROLS = {
    'boxLayout',
    'headerText',

    'terraformPaintRadius',
    'terraformStrength',
    'terraformRadius',
    'terraformSmoothStrength',
    'terraformSmoothRadius',
    'terraformFlattenStrength',
    'terraformFlattenRadius',
}

function TerraFarmSettingsMachineFrame.new(target, mt)
    ---@type TerraFarmSettingsMachineFrame
    local self = TabbedMenuFrameElement.new(target, mt or TerraFarmSettingsMachineFrame_mt)

    self:registerControls(TerraFarmSettingsMachineFrame.CONTROLS)

    return self
end

function TerraFarmSettingsMachineFrame:initialize()
    self.backButtonInfo = {
        inputAction = InputAction.MENU_BACK
    }
end

function TerraFarmSettingsMachineFrame:onFrameOpen()
---@diagnostic disable-next-line: undefined-field
    TerraFarmSettingsMachineFrame:superClass().onFrameOpen(self)
    self:updateSettings()

    self.boxLayout:invalidateLayout()

    if FocusManager:getFocusedElement() == nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(self.boxLayout)
        self:setSoundSuppressed(false)
    end
end

function TerraFarmSettingsMachineFrame:updateSettings()
    local machine = g_terraFarm.currentMachine
    local isVisible = not not machine

    for _, control in pairs(TerraFarmSettingsMachineFrame.CONTROLS) do
        if control == 'headerText' then
            if machine then
                self.headerText:setText(tostring(machine.fullName) .. ' (id#' .. machine.id .. ')')
            else
                self.headerText:setText('No active TerraFarm machine')
            end
        elseif control ~= 'boxLayout' then
            if self[control] then
                if self[control].setVisible ~= nil then
                    self[control]:setVisible(isVisible)
                end
                local value = machine:getConfigProperty(control)
                if value ~= nil then
                    self:setElementText(self[control], value)
                end
            end
        end
    end
end

---@param element TextInputElement
---@param value number
function TerraFarmSettingsMachineFrame:setElementText(element, value)
    element:setText(string.format('%.2f', value))
end

---@param element TextInputElement
function TerraFarmSettingsMachineFrame:onStrengthPressedTextInput(element)
    if not g_terraFarm.currentMachine then return end

    local value = tonumber(element.text)
    local name = element.id

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
function TerraFarmSettingsMachineFrame:onRadiusPressedTextInput(element)
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