local modFolder = g_currentModDirectory
local ICON_SIZE = 64

TERRAFORM_MODE_IMAGE_FILE = {
    [TerraFarm.MODE.NORMAL] = modFolder .. 'textures/hud_mode_normal.png',
    [TerraFarm.MODE.RAISE] = modFolder .. 'textures/hud_mode_raise.png',
    [TerraFarm.MODE.LOWER] = modFolder .. 'textures/hud_mode_lower.png',
    [TerraFarm.MODE.SMOOTH] = modFolder .. 'textures/hud_mode_smooth.png',
    [TerraFarm.MODE.FLATTEN] = modFolder .. 'textures/hud_mode_flatten.png',
    [TerraFarm.MODE.PAINT] = modFolder .. 'textures/hud_mode_paint.png',
}

TERRAFORM_STATE_DISABLED_TEXT = 'Disabled'
TERRAFORM_STATE_DISABLED_IMAGE_FILE = modFolder .. 'textures/hud_mode_blank.png'
TERRAFORM_MODE_STATUS_TEXT = {
    [TerraFarm.MODE.NORMAL] = 'Normal',
    [TerraFarm.MODE.RAISE] = 'Raise ground',
    [TerraFarm.MODE.LOWER] = 'Lower ground',
    [TerraFarm.MODE.SMOOTH] = 'Smooth ground',
    [TerraFarm.MODE.FLATTEN] = 'Flatten ground',
    [TerraFarm.MODE.PAINT] = 'Paint ground',
}

---@class MachineHUDExtension : VehicleHUDExtension
---@field statusOverlay Overlay
---@field dischargeModeOverlay Overlay
---@field disabled boolean
---@field disabledIcon table
---@field displayHeight number
---@field modeIcon table
---@field vehicle Machine
MachineHUDExtension = {}
local MachineHUDExtension_mt = Class(MachineHUDExtension, VehicleHUDExtension)

VehicleHUDExtension.registerHUDExtension(Shovel, MachineHUDExtension)
VehicleHUDExtension.registerHUDExtension(Enterable, MachineHUDExtension)

function MachineHUDExtension.new(vehicle, uiScale, uiTextColor, uiTextSize)
    local self = VehicleHUDExtension.new(MachineHUDExtension_mt, vehicle, uiScale, uiTextColor, uiTextSize)

    if not self.vehicle.spec_machine then
        self.disabled = true
        return
    end

    self.modeIcon = {}
    for mode, path in pairs(TERRAFORM_MODE_IMAGE_FILE) do
        local overlay = {
            filename = path,
            overlayId = createImageOverlay(path)
        }
        self.modeIcon[mode] = overlay
    end

    self.disabledIcon = {
        filename = TERRAFORM_STATE_DISABLED_IMAGE_FILE,
        overlayId = createImageOverlay(TERRAFORM_STATE_DISABLED_IMAGE_FILE)
    }

    local height = self:createModeOverlay()

    if self.vehicle.spec_machine.type == TerraFarmShovel.machineType then
        height = height + self:createDischargeModeOverlay() + 0.002
    end

    self.displayHeight = height

    return self
end

function MachineHUDExtension:createModeOverlay()
    local width, height = getNormalizedScreenValues(ICON_SIZE * self.uiScale, ICON_SIZE * self.uiScale)
    self.statusOverlay = Overlay.new(g_baseUIFilename, 0, 0, width, height)
    self:addComponentForCleanup(self.statusOverlay)

    return height
end

function MachineHUDExtension:createDischargeModeOverlay()
    local width, height = getNormalizedScreenValues(ICON_SIZE * self.uiScale, ICON_SIZE * self.uiScale)
    self.dischargeModeOverlay = Overlay.new(g_baseUIFilename, 0, 0, width, height)
    self:addComponentForCleanup(self.dischargeModeOverlay)

    return height
end

function MachineHUDExtension:setOverlayIcon(overlay, mode)
    if not mode then
        overlay.filename = self.disabledIcon.filename
        overlay.overlayId = self.disabledIcon.overlayId
    else
        local icon = self.modeIcon[mode]
        if icon and overlay.filename ~= icon.filename then
            overlay.filename = icon.filename
            overlay.overlayId = icon.overlayId
        end
    end
end

function MachineHUDExtension:canDraw()
    if self.disabled or not g_terraFarm.currentMachine then
        return false
    end
    return true
end

function MachineHUDExtension:getDisplayHeight()
    return self:canDraw() and self.displayHeight or 0
end

---@param leftPosX number
---@param rightPosX number
---@param posY number
function MachineHUDExtension:drawDischargeMode(leftPosX, rightPosX, posY)
    ---@type TerraFarmShovel | TerraFarmTractor
    local machine = g_terraFarm.currentMachine

    local modeText = TERRAFORM_MODE_STATUS_TEXT[machine.dischargeMode]
    if not modeText then
        self:setOverlayIcon(self.dischargeModeOverlay)
        renderText(leftPosX, posY + self.uiTextSize * 1.5, self.uiTextSize, 'Invalid discharge mode')
        return
    end

    self:setOverlayIcon(self.dischargeModeOverlay, machine.dischargeMode)

    setTextBold(true)
    renderText(leftPosX, posY + self.uiTextSize * 1.5, self.uiTextSize, 'Discharge mode: ')
    local offsetX = getTextWidth(self.uiTextSize, 'Discharge mode:   ')

    setTextBold(false)
    renderText(leftPosX + offsetX, posY + self.uiTextSize * 1.5, self.uiTextSize, modeText)

    self.dischargeModeOverlay:setInvertX(false)
    self.dischargeModeOverlay:setPosition(rightPosX - self.statusOverlay.width + 0.006, posY)
    self.dischargeModeOverlay:render()
end

---@param leftPosX number
---@param rightPosX number
---@param posY number
function MachineHUDExtension:drawMode(leftPosX, rightPosX, posY)
    ---@type TerraFarmShovel | TerraFarmTractor
    local machine = g_terraFarm.currentMachine

    local modeText = TERRAFORM_MODE_STATUS_TEXT[machine.mode]
    if not modeText then
        self:setOverlayIcon(self.statusOverlay)
        renderText(leftPosX, posY + self.uiTextSize, self.uiTextSize, 'Invalid mode')
        return
    end

    self:setOverlayIcon(self.statusOverlay, machine.mode)

    setTextBold(true)
    renderText(leftPosX, posY + self.uiTextSize * 1.5, self.uiTextSize, 'Mode: ')
    local offsetX = getTextWidth(self.uiTextSize, 'Mode:   ')

    setTextBold(false)
    renderText(leftPosX + offsetX, posY + self.uiTextSize * 1.5, self.uiTextSize, modeText)

    self.statusOverlay:setInvertX(false)
    self.statusOverlay:setPosition(rightPosX - self.statusOverlay.width + 0.006, posY)
    self.statusOverlay:render()
end

function MachineHUDExtension:draw(leftPosX, rightPosX, posY)
    ---@type TerraFarmShovel
    local machine = g_terraFarm.currentMachine

    ---@diagnostic disable-next-line: undefined-global
    setTextAlignment(RenderText.ALIGN_LEFT)

    if machine then
        if self.vehicle.spec_machine.type == TerraFarmShovel.machineType then
            self:drawMode(leftPosX, rightPosX, posY + self.displayHeight / 2 + 0.002)
            self:drawDischargeMode(leftPosX, rightPosX, posY)
        else
            self:drawMode(leftPosX, rightPosX, posY)
        end
    end
end