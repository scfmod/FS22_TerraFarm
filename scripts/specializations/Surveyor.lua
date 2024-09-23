source(g_currentModDirectory .. 'scripts/specializations/events/SetSurveyorNameEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/events/SetSurveyorCalibrationEvent.lua')

---@class SurveyorProperties
---@field surveyorId string
---@field surveyorName string
---@field triggerNode number
---@field activatable SurveyorActivatable
---@field offsetY number
---@field startPosX number
---@field startPosY number
---@field startPosZ number
---@field endPosX number
---@field endPosY number
---@field endPosZ number
---@field objectChanges table | nil
---@field animationNodes table | nil
---@field isEffectActive boolean

---@class Surveyor : Vehicle, Foldable
---@field spec_surveyor SurveyorProperties
---@field spec_foldable FoldableSpecialization | nil
Surveyor = {}

Surveyor.MOD_NAME = g_currentModName
Surveyor.SPEC_NAME = string.format('spec_%s.surveyor', g_currentModName)

---@return boolean
function Surveyor.prerequisitesPresent()
    return true
end

---@param schema XMLSchema
---@param key string
function Surveyor.registerXMLPaths(schema, key)
    schema:register(XMLValueType.L10N_STRING, key .. '#defaultName', 'Set default name', 'Surveyor')
    schema:register(XMLValueType.NODE_INDEX, key .. '#trigger', 'Interaction trigger node', nil, true)
    schema:register(XMLValueType.FLOAT, key .. '#offsetY', 'Offset Y position for line rendering', 0)

    ObjectChangeUtil.registerObjectChangesXMLPaths(schema, key)
    AnimationManager.registerAnimationNodesXMLPaths(schema, key .. '.animations')
end

---@param schema XMLSchema
---@param key string
function Surveyor.registerSavegameXMLPaths(schema, key)
    schema:register(XMLValueType.STRING, key .. '#id')
    schema:register(XMLValueType.STRING, key .. '#name')
    schema:register(XMLValueType.FLOAT, key .. '#startPosX')
    schema:register(XMLValueType.FLOAT, key .. '#startPosY')
    schema:register(XMLValueType.FLOAT, key .. '#startPosZ')
    schema:register(XMLValueType.FLOAT, key .. '#endPosX')
    schema:register(XMLValueType.FLOAT, key .. '#endPosY')
    schema:register(XMLValueType.FLOAT, key .. '#endPosZ')
end

function Surveyor.initSpecialization()
    g_storeManager:addSpecType('surveyor', 'tfGui_shopListAttributeIconSurveyor', Surveyor.loadSpecValue, Surveyor.getSpecValue)

    ---@type XMLSchema
    local schema = Vehicle.xmlSchema

    schema:setXMLSpecializationType('Surveyor')
    Surveyor.registerXMLPaths(schema, 'vehicle.surveyor')
    schema:setXMLSpecializationType()

    ---@type XMLSchema
    local schemaSavegame = Vehicle.xmlSchemaSavegame

    schemaSavegame:setXMLSpecializationType('Surveyor')
    Surveyor.registerSavegameXMLPaths(schemaSavegame, string.format('vehicles.vehicle(?).%s.surveyor', Surveyor.MOD_NAME))
    schemaSavegame:setXMLSpecializationType()
end

---@param xmlFile XMLFile
---@param customEnvironment string | nil
---@param baseDir string
function Surveyor.loadSpecValue(xmlFile, customEnvironment, baseDir)
    local rootName = xmlFile:getRootName()

    if rootName == 'vehicle' then
        if xmlFile:hasProperty('vehicle.surveyor') then
            return {}
        end
    end
end

---@param storeItem StoreItem
---@param realItem any
---@param configurations any
---@param saleItem any
---@param returnValues any
---@param returnRange any
---@return string | nil
function Surveyor.getSpecValue(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
    if storeItem ~= nil and storeItem.specs ~= nil and storeItem.specs.surveyor ~= nil then
        return g_i18n:getText('displayItem_surveyor')
    end
end

function Surveyor.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, 'getFullName', Surveyor.getFullName)
end

function Surveyor.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, 'setCalibration', Surveyor.setCalibration)
    SpecializationUtil.registerFunction(vehicleType, 'getCalibration', Surveyor.getCalibration)
    SpecializationUtil.registerFunction(vehicleType, 'resetCalibration', Surveyor.resetCalibration)
    SpecializationUtil.registerFunction(vehicleType, 'getSurveyorId', Surveyor.getSurveyorId)

    SpecializationUtil.registerFunction(vehicleType, 'getDamageAmount', Surveyor.getDamageAmount)
    SpecializationUtil.registerFunction(vehicleType, 'getIsCalibrated', Surveyor.getIsCalibrated)
    SpecializationUtil.registerFunction(vehicleType, 'getCalibrationAngle', Surveyor.getCalibrationAngle)
    SpecializationUtil.registerFunction(vehicleType, 'setSurveyorName', Surveyor.setSurveyorName)
    SpecializationUtil.registerFunction(vehicleType, 'surveyorActivationTriggerCallback', Surveyor.surveyorActivationTriggerCallback)
end

function Surveyor.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', Surveyor)
    SpecializationUtil.registerEventListener(vehicleType, 'onPostLoad', Surveyor)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', Surveyor)
    SpecializationUtil.registerEventListener(vehicleType, 'onWriteStream', Surveyor)
    SpecializationUtil.registerEventListener(vehicleType, 'onReadStream', Surveyor)
end

function Surveyor:onLoad()
    ---@type SurveyorProperties
    local spec = self[Surveyor.SPEC_NAME]

    ---@type XMLFile
    local xmlFile = self.xmlFile

    self.spec_surveyor = spec

    spec.surveyorId = nil
    spec.surveyorName = xmlFile:getValue('vehicle.surveyor#defaultName', Vehicle.getName(self), self.customEnvironment)
    spec.offsetY = xmlFile:getValue('vehicle.surveyor#offsetY', 0)
    spec.activatable = SurveyorActivatable.new(self)
    spec.isEffectActive = false

    spec.objectChanges = {}

    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, 'vehicle.surveyor.objectChanges', spec.objectChanges, self.components, self)

    if #spec.objectChanges == 0 then
        spec.objectChanges = nil
    else
        ObjectChangeUtil.setObjectChanges(spec.objectChanges, false)
    end

    if self.isClient then
        spec.triggerNode = xmlFile:getValue('vehicle.surveyor#trigger', nil, self.components, self.i3dMappings)

        if spec.triggerNode ~= nil then
            if CollisionFlag.getHasFlagSet(spec.triggerNode, CollisionFlag.TRIGGER_PLAYER) then
                addTrigger(spec.triggerNode, 'surveyorActivationTriggerCallback', self)
            else
                Logging.xmlWarning(xmlFile, 'Missing TRIGGER_PLAYER flag (bit 20) on node "%s"', xmlFile:getString('vehicle.surveyor#trigger'))
            end
        else
            Logging.xmlWarning(xmlFile, 'Missing "vehicle.surveyor#trigger"')
        end

        spec.animationNodes = g_animationManager:loadAnimations(xmlFile, 'vehicle.surveyor.animations', self.components, self, self.i3dMappings)
    end

    if SpecializationUtil.hasSpecialization(Foldable, self.specializations) then
        SpecializationUtil.registerEventListener(self, 'onFoldStateChanged', Surveyor)
        SpecializationUtil.registerEventListener(self, 'onFoldTimeChanged', Surveyor)
    end

    spec.startPosX = 0
    spec.startPosY = math.huge
    spec.startPosZ = 0
    spec.endPosX = 0
    spec.endPosY = math.huge
    spec.endPosZ = 0

    if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
        g_machineManager:registerSurveyor(self)
    end
end

---@param savegame SavegameObject | nil
function Surveyor:onPostLoad(savegame)
    local spec = self.spec_surveyor

    if self.isServer then
        if savegame ~= nil and savegame.xmlFile.filename ~= nil then
            local key = savegame.key .. '.' .. Surveyor.MOD_NAME .. '.surveyor'

            Surveyor.loadFromXMLFile(self, savegame.xmlFile, key)
        end

        if spec.surveyorId == nil then
            spec.surveyorId = MachineUtils.createUniqueId()
        end
    end

    Surveyor.updateSurveyorEffects(self)
end

---@param xmlFile XMLFile
---@param key string
function Surveyor:saveToXMLFile(xmlFile, key)
    local spec = self.spec_surveyor

    if spec.surveyorId ~= nil then
        xmlFile:setValue(key .. '#id', spec.surveyorId)
    end

    xmlFile:setValue(key .. '#name', spec.surveyorName)

    if spec.startPosY ~= math.huge then
        xmlFile:setValue(key .. '#startPosX', spec.startPosX)
        xmlFile:setValue(key .. '#startPosY', spec.startPosY)
        xmlFile:setValue(key .. '#startPosZ', spec.startPosZ)

        if spec.endPosY ~= math.huge then
            xmlFile:setValue(key .. '#endPosX', spec.endPosX)
            xmlFile:setValue(key .. '#endPosY', spec.endPosY)
            xmlFile:setValue(key .. '#endPosZ', spec.endPosZ)
        end
    end
end

---@param xmlFile XMLFile
---@param key string
function Surveyor:loadFromXMLFile(xmlFile, key)
    local spec = self.spec_surveyor

    spec.surveyorId = xmlFile:getValue(key .. '#id', spec.surveyorId)
    spec.surveyorName = xmlFile:getValue(key .. '#name', spec.surveyorName)

    spec.startPosX = xmlFile:getValue(key .. '#startPosX', 0)
    spec.startPosY = xmlFile:getValue(key .. '#startPosY', math.huge)
    spec.startPosZ = xmlFile:getValue(key .. '#startPosZ', 0)

    if spec.startPosY ~= math.huge then
        spec.endPosX = xmlFile:getValue(key .. '#endPosX', 0)
        spec.endPosY = xmlFile:getValue(key .. '#endPosY', math.huge)
        spec.endPosZ = xmlFile:getValue(key .. '#endPosZ', 0)
    end
end

function Surveyor:onDelete()
    local spec = self.spec_surveyor

    g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

    if spec.triggerNode ~= nil then
        removeTrigger(spec.triggerNode)
    end

    if self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG then
        g_machineManager:unregisterSurveyor(self)
    end
end

---@return boolean
---@nodiscard
function Surveyor:getIsCalibrated()
    return self.spec_surveyor.startPosY ~= math.huge
end

function Surveyor:getDamageAmount()
    return 0
end

---@return number
---@nodiscard
function Surveyor:getCalibrationAngle()
    local spec = self.spec_surveyor

    return MachineUtils.getAngleBetweenPoints(
        spec.startPosX, spec.startPosY, spec.startPosZ,
        spec.endPosX, spec.endPosY, spec.endPosZ
    )
end

---@param name string
---@param noEventSend boolean | nil
function Surveyor:setSurveyorName(name, noEventSend)
    local spec = self.spec_surveyor

    if spec.surveyorName ~= name then
        SetSurveyorNameEvent.sendEvent(self, name, noEventSend)

        spec.surveyorName = name

        g_messageCenter:publish(SetSurveyorNameEvent, self, name)
    end
end

---@param startPosX any
---@param startPosY any
---@param startPosZ any
---@param endPosX any
---@param endPosY any
---@param endPosZ any
---@param noEventSend boolean | nil
function Surveyor:setCalibration(startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, noEventSend)
    local spec = self.spec_surveyor

    SetSurveyorCalibrationEvent.sendEvent(self, startPosX, startPosY, startPosZ, endPosX, endPosY, endPosZ, noEventSend)

    spec.startPosX = startPosX
    spec.startPosY = startPosY
    spec.startPosZ = startPosZ

    spec.endPosX = endPosX
    spec.endPosY = endPosY
    spec.endPosZ = endPosZ

    Surveyor.updateSurveyorEffects(self)

    g_messageCenter:publish(SetSurveyorCalibrationEvent, self)
end

---@return number startPosX
---@return number startPosX
---@return number startPosX
---@return number endPosX
---@return number endPosY
---@return number endPosX
function Surveyor:getCalibration()
    local spec = self.spec_surveyor

    return spec.startPosX, spec.startPosY, spec.startPosZ, spec.endPosX, spec.endPosY, spec.endPosZ
end

function Surveyor:resetCalibration()
    self:setCalibration(0, math.huge, 0, 0, math.huge, 0)
end

function Surveyor:getFullName(superFunc)
    if self.spec_surveyor ~= nil then
        return self.spec_surveyor.surveyorName
    end

    return superFunc(self)
end

---@return string | nil
function Surveyor:getSurveyorId()
    return self.spec_surveyor.surveyorId
end

---@return boolean
---@nodiscard
function Surveyor:getIsFoldable()
    local spec = self.spec_foldable

    if spec ~= nil then
        return #spec.foldingParts > 0
    end

    return false
end

function Surveyor:onFoldStateChanged(direction, moveToMiddle)
    Surveyor.updateSurveyorEffects(self)
end

function Surveyor:onFoldTimeChanged()
    local spec = self.spec_foldable

    if spec ~= nil and spec.foldMoveDirection == 1 and self:getIsUnfolded() then
        Surveyor.updateSurveyorEffects(self)
    end
end

function Surveyor:updateSurveyorEffects()
    local spec = self.spec_surveyor
    local isActive = self:getIsCalibrated()

    if Surveyor.getIsFoldable(self) and not self:getIsUnfolded() then
        isActive = false
    end

    ObjectChangeUtil.setObjectChanges(spec.objectChanges, isActive)

    if self.isClient then
        if isActive then
            if not spec.isEffectActive then
                g_animationManager:startAnimations(spec.animationNodes)

                spec.isEffectActive = true
            end
        elseif spec.isEffectActive then
            g_animationManager:stopAnimations(spec.animationNodes)

            spec.isEffectActive = false
        end
    end
end

---@param triggerId number
---@param otherActorId number | nil
---@param onEnter boolean
---@param onLeave boolean
---@param onStay boolean
---@param otherShapeId number | nil
function Surveyor:surveyorActivationTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
    local spec = self.spec_surveyor

    if (onEnter or onLeave) and g_currentMission.player ~= nil and otherActorId == g_currentMission.player.rootNode and g_currentMission.accessHandler:canPlayerAccess(self) then
        if onEnter then
            g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
        elseif onLeave then
            g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
        end
    end
end

---@param streamId number
---@param connection Connection
function Surveyor:onWriteStream(streamId, connection)
    local spec = self.spec_surveyor

    streamWriteString(streamId, spec.surveyorId)
    streamWriteString(streamId, spec.surveyorName)
    MachineUtils.writeCompressedPosition(streamId, spec.startPosX, spec.startPosY, spec.startPosZ)
    MachineUtils.writeCompressedPosition(streamId, spec.endPosX, spec.endPosY, spec.endPosZ)
end

---@param streamId number
---@param connection Connection
function Surveyor:onReadStream(streamId, connection)
    local spec = self.spec_surveyor

    spec.surveyorId = streamReadString(streamId)
    spec.surveyorName = streamReadString(streamId)
    spec.startPosX, spec.startPosY, spec.startPosZ = MachineUtils.readCompressedPosition(streamId)
    spec.endPosX, spec.endPosY, spec.endPosZ = MachineUtils.readCompressedPosition(streamId)
end

---@class SurveyorActivatable
---@field vehicle Surveyor
---@field warningUnfold string
---@field activateText string
---@field activateEventId string
---@field toggleFoldEventId string
SurveyorActivatable = {}

local SurveyorActivatable_mt = Class(SurveyorActivatable)

---@param vehicle Surveyor
---@return SurveyorActivatable
---@nodiscard
function SurveyorActivatable.new(vehicle)
    ---@type SurveyorActivatable
    local self = setmetatable({}, SurveyorActivatable_mt)

    self.vehicle = vehicle
    self.activateText = g_i18n:getText('ui_calibrate')
    self.warningUnfold = g_i18n:getText('warning_unfoldSurveyor')

    return self
end

function SurveyorActivatable:registerCustomInput()
    local _, actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onPressActivate, false, true, false, true)

    g_inputBinding:setActionEventText(actionEventId, self.activateText)
    g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
    g_inputBinding:setActionEventTextVisibility(actionEventId, true)

    self.activateEventId = actionEventId

    if Surveyor.getIsFoldable(self.vehicle) then
        _, actionEventId = g_inputBinding:registerActionEvent(InputAction.IMPLEMENT_EXTRA2, self, self.onPressToggleFold, false, true, false, true)

        g_inputBinding:setActionEventText(actionEventId, self.vehicle.spec_foldable.negDirectionText)
        g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
        g_inputBinding:setActionEventTextVisibility(actionEventId, true)

        self.toggleFoldEventId = actionEventId
    end
end

function SurveyorActivatable:removeCustomInput()
    if self.activateEventId ~= nil then
        g_inputBinding:removeActionEvent(self.activateEventId)
    end

    if self.toggleFoldEventId ~= nil then
        g_inputBinding:removeActionEvent(self.toggleFoldEventId)
    end
end

function SurveyorActivatable:updateFoldAction()
    local spec = self.vehicle.spec_foldable

    if spec ~= nil and self.toggleFoldEventId ~= nil then
        local direction = self.vehicle:getToggledFoldDirection()
        local text

        if direction == spec.turnOnFoldDirection then
            text = spec.negDirectionText
        else
            text = spec.posDirectionText
        end

        g_inputBinding:setActionEventText(self.toggleFoldEventId, text)
    end
end

---@param dt number
function SurveyorActivatable:update(dt)
    self:updateFoldAction()
end

function SurveyorActivatable:getDistance(x, y, z)
    local tx, ty, tz = getWorldTranslation(self.vehicle.rootNode)

    return MathUtil.vector3Length(x - tx, y - ty, z - tz)
end

---@return boolean
function SurveyorActivatable:getIsActivatable()
    return g_currentMission.accessHandler:canPlayerAccess(self.vehicle)
end

function SurveyorActivatable:onPressActivate()
    if Surveyor.getIsFoldable(self.vehicle) then
        if self.vehicle:getIsUnfolded() then
            g_machineGUI.surveyorScreen:show(self.vehicle)
        else
            g_currentMission:showBlinkingWarning(self.warningUnfold, 2000)
        end
    else
        g_machineGUI.surveyorScreen:show(self.vehicle)
    end
end

function SurveyorActivatable:onPressToggleFold()
    Foldable.actionEventFold(self.vehicle)
end
