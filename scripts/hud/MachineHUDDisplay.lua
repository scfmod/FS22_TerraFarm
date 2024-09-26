---@class MachineHUDDisplay
---@field isVisible boolean
---@field isEnabled boolean
---@field animation TweenSequence
---@field animateDuration number
---@field boxLayout BoxLayoutElement
---
---@field inputItem BitmapElement
---@field inputTitle TextElement
---@field inputImage BitmapElement
---@field inputText TextElement
---@field outputItem BitmapElement
---@field outputImage BitmapElement
---@field outputText TextElement
---@field materialItem BitmapElement
---@field materialImage BitmapElement
---@field materialText TextElement
---@field textureItem BitmapElement
---@field textureImage TerrainLayerElement
---@field textureText TextElement
---@field surveyorItem BitmapElement
---@field surveyorImage BitmapElement
---@field surveyorTitle TextElement
---@field surveyorText TextElement
---@field vehicleItem BitmapElement
---@field vehicleImage BitmapElement
---@field vehicleText TextElement
---@field elements table<string, GuiElement>
---@field posX number
---@field posY number
MachineHUDDisplay = {}

MachineHUDDisplay.ANIMATE_DURATION = 150
MachineHUDDisplay.CONTROLS = {
    'vehicleItem',
    'vehicleImage',
    'vehicleText',
    'inputItem',
    'inputImage',
    'inputTitle',
    'inputText',
    'outputItem',
    'outputImage',
    'outputTitle',
    'outputText',
    'materialItem',
    'materialImage',
    'materialText',
    'textureItem',
    'textureImage',
    'textureText',
    'surveyorItem',
    'surveyorImage',
    'surveyorTitle',
    'surveyorText'
}

local MachineHUDDisplay_mt = Class(MachineHUDDisplay)

---@return MachineHUDDisplay
---@nodiscard
function MachineHUDDisplay.new()
    ---@type MachineHUDDisplay
    local self = setmetatable({}, MachineHUDDisplay_mt)

    self.isVisible = true
    self.isEnabled = true
    self.elements = {}

    self.posX = 1
    self.posY = 0.5
    self.animateDuration = MachineHUDDisplay.ANIMATE_DURATION

    self.animation = TweenSequence.NO_SEQUENCE

    return self
end

function MachineHUDDisplay:delete()
    if self.boxLayout ~= nil then
        self.boxLayout:delete()
        self.boxLayout = nil
    end

    self.animation = nil
end

---@param xmlFile XMLFile
---@param key string
function MachineHUDDisplay:loadFromXMLFile(xmlFile, key)
    local profile = xmlFile:getString(key .. '#profile')

    self.boxLayout = BoxLayoutElement.new()
    self.boxLayout:loadFromXML(xmlFile.handle, key)
    self.boxLayout:applyProfile(profile)

    self:loadHUDElements(xmlFile, key, self.boxLayout)

    self.boxLayout:updateAbsolutePosition()
    self.boxLayout:onGuiSetupFinished()

    self:savePosition()

    self.animateDuration = xmlFile:getFloat('HUD#animateDuration', self.animateDuration)

    for _, id in ipairs(MachineHUDDisplay.CONTROLS) do
        if self.elements[id] ~= nil then
            self[id] = self.elements[id]
        else
            Logging.warning('MachineHUDDisplay:loadFromXMLFile() Element with id "%s" not found', id)
        end
    end

    self.inputImage:setImageFilename(g_machineUIFilename)
    self.outputImage:setImageFilename(g_machineUIFilename)

    self.elements = {}
end

---@param xmlFile XMLFile
---@param xmlKey string
---@param parent GuiElement
function MachineHUDDisplay:loadHUDElements(xmlFile, xmlKey, parent)
    xmlFile:iterate(xmlKey .. '.HudElement', function(_, key)
        local typeName = xmlFile:getString(key .. '#type', 'empty')
        local class = Gui.CONFIGURATION_CLASS_MAPPING[typeName] or GuiElement
        ---@type GuiElement
        local element = class.new()
        local profile = xmlFile:getString(key .. '#profile')

        element.handleFocus = false
        element.soundDisabled = true

        element:loadFromXML(xmlFile.handle, key)
        element:applyProfile(profile)

        parent:addElement(element)

        self:loadHUDElements(xmlFile, key, element)

        self:onCreateElement(element)
    end)

    self:setVisible(g_settings.hudEnabled, false)
end

---@param element GuiElement
function MachineHUDDisplay:onCreateElement(element)
    if element.id ~= nil then
        self.elements[element.id] = element
    end
end

---@param isVisible any
---@param animate boolean | nil
function MachineHUDDisplay:setVisible(isVisible, animate)
    if animate and self.animation:getFinished() then
        if isVisible then
            self:animateShow()
        else
            self:animateHide()
        end
    else
        self.animation:stop()

        self.boxLayout:setVisible(isVisible)

        local posX, posY = self:getBasePosition()
        local hideX, hideY = self:getHidingPosition()

        if isVisible then
            self:setPosition(posX, posY)
        else
            self:setPosition(hideX, hideY)
        end
    end

    self.isVisible = isVisible
end

function MachineHUDDisplay:setIsEnabled(isEnabled)
    if self.isEnabled ~= isEnabled then
        self.isEnabled = isEnabled

        self.boxLayout:setDisabled(not isEnabled)
    end
end

function MachineHUDDisplay:savePosition()
    self.posX, self.posY = self.boxLayout.absPosition[1], self.boxLayout.absPosition[2]
end

---@return number
---@return number
function MachineHUDDisplay:getHidingPosition()
    return 1, self.posY
end

---@return number
---@return number
function MachineHUDDisplay:getBasePosition()
    return self.posX, self.posY
end

---@return number
---@return number
function MachineHUDDisplay:getPosition()
    return self.boxLayout.absPosition[1], self.boxLayout.absPosition[2]
end

---@param posX any
---@param posY any
function MachineHUDDisplay:setPosition(posX, posY)
    self.boxLayout:setAbsolutePosition(posX, posY)
end

function MachineHUDDisplay:animateShow()
    self.boxLayout:setVisible(true)

    local targetX, targetY = self:getBasePosition()
    local posX, posY = self:getPosition()
    ---@type TweenSequence
    local sequence = TweenSequence.new(self)

    sequence:insertTween(MultiValueTween.new(self.setPosition, { posX, posY }, { targetX, targetY }, self.animateDuration), 0)
    sequence:addCallback(self.onAnimateFinished, true)
    sequence:setCurve(MachineHUDDisplay.CURVE_EASE_OUT_CUBIC)
    sequence:start()

    self.animation = sequence
end

---@param t number
---@return number
MachineHUDDisplay.CURVE_EASE_OUT_CUBIC = function(t)
    return 1 - math.pow(1 - t, 3)
end

function MachineHUDDisplay:animateHide()
    local targetX, targetY = self:getHidingPosition()
    local posX, posY = self:getPosition()
    ---@type TweenSequence
    local sequence = TweenSequence.new(self)

    sequence:insertTween(MultiValueTween.new(self.setPosition, { posX, posY }, { targetX, targetY }, self.animateDuration), 0)
    sequence:addCallback(self.onAnimateFinished, false)
    sequence:setCurve(Tween.CURVE.LINEAR)
    sequence:start()

    self.animation = sequence
end

function MachineHUDDisplay:onAnimateFinished(isVisible)
    if not isVisible then
        self.boxLayout:setVisible(false)
    end
end

function MachineHUDDisplay:draw()
    if self.boxLayout ~= nil and (self.isVisible or not self.animation:getFinished()) then
        self.boxLayout:draw()
    end
end

---@param dt number
function MachineHUDDisplay:update(dt)
    if self.animation ~= nil then
        self.animation:update(dt)
    end
end

function MachineHUDDisplay:updateDisplay()
    local vehicle = g_machineHUD.vehicle

    if vehicle ~= nil then
        local active = vehicle:getMachineActive() and vehicle:getCanActivateMachine()

        self:setIsEnabled(active)

        self:updateVehicleDisplay()
        self:updateModeDisplay()
        self:updateMaterialDisplay()
        self:updateTextureDisplay()
        self:updateSurveyorDisplay()

        self.boxLayout:invalidateLayout()
    end
end

function MachineHUDDisplay:updateModeDisplay()
    local spec = g_machineHUD.vehicle.spec_machine

    if #spec.modesInput > 0 then
        self.inputItem:setVisible(true)
        self.inputImage:setImageUVs(nil, unpack(Machine.MODE_ICON_UVS[spec.inputMode]))
        self.inputText:setText(Machine.L10N_MODE[spec.inputMode])
    else
        self.inputItem:setVisible(false)
    end

    if #spec.modesOutput > 0 then
        self.outputItem:setVisible(true)
        self.outputImage:setImageUVs(nil, unpack(Machine.MODE_ICON_UVS[spec.outputMode]))
        self.outputText:setText(Machine.L10N_MODE[spec.outputMode])

        self.inputTitle:setVisible(true)
        if self.inputText.profile ~= 'machineHud_itemDescription' then
            self.inputText:applyProfile('machineHud_itemDescription') -- TODO
        end
    else
        self.outputItem:setVisible(false)
        self.inputTitle:setVisible(false)

        if self.inputText.profile ~= 'machineHud_itemText' then
            self.inputText:applyProfile('machineHud_itemText') -- TODO
        end
    end
end

function MachineHUDDisplay:updateMaterialDisplay()
    local spec = g_machineHUD.vehicle.spec_machine

    ---@type FillTypeObject | nil
    local fillType = g_fillTypeManager:getFillTypeByIndex(spec.fillTypeIndex)

    if fillType ~= nil and spec.machineType.useFillUnit then
        self.materialItem:setVisible(true)
        self.materialImage:setImageFilename(fillType.hudOverlayFilename)
        self.materialText:setText(fillType.title)
    else
        self.materialItem:setVisible(false)
    end
end

function MachineHUDDisplay:updateTextureDisplay()
    local spec = g_machineHUD.vehicle.spec_machine

    if #spec.modesInput > 0 then
        local terrainLayer = g_resources:getTerrainLayerById(spec.terrainLayerId)

        self.textureItem:setVisible(true)
        self.textureImage:setTerrainLayer(g_currentMission.terrainRootNode, terrainLayer.id)
        self.textureText:setText(terrainLayer.title)
    else
        self.textureItem:setVisible(false)
    end
end

function MachineHUDDisplay:updateVehicleDisplay()
    local vehicle = g_machineHUD.vehicle

    ---@diagnostic disable-next-line: need-check-nil
    self.vehicleImage:setImageFilename(vehicle:getImageFilename())
    ---@diagnostic disable-next-line: need-check-nil
    self.vehicleText:setText(vehicle.spec_machine.machineType.name)
end

function MachineHUDDisplay:updateSurveyorDisplay()
    local vehicle = g_machineHUD.vehicle

    if vehicle ~= nil then
        if vehicle:getInputMode() == Machine.MODE.FLATTEN or vehicle:getOutputMode() == Machine.MODE.FLATTEN then
            local surveyor = vehicle:getSurveyor()

            if surveyor ~= nil then
                self.surveyorItem:setVisible(true)
                self.surveyorImage:setImageFilename(surveyor:getImageFilename())
                self.surveyorTitle:setText(surveyor:getFullName())

                if surveyor:getIsCalibrated() then
                    local angle = surveyor:getCalibrationAngle()

                    if angle ~= 0 then
                        self.surveyorText:setText(string.format(g_i18n:getText('ui_calibratedFormat'), angle))
                    else
                        self.surveyorText:setText(g_i18n:getText('construction_item_level'))
                    end
                else
                    self.surveyorText:setText(SurveyorScreen.L10N_STATUS_NOT_CALIBRATED)
                end
            else
                self.surveyorItem:setVisible(false)
            end
        else
            self.surveyorItem:setVisible(false)
        end
    end
end
