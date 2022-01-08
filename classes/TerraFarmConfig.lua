---@class TerraFarmConfig
---@field enabled boolean
---@field debug boolean
---@field interval number
---@field disableDischarge boolean
---@field fillTypeIndex number
---@field fillTypeName string
---@field fillTypeMassPerLiter number
---@field fillTypeMassRatio number
---@field volumeFillRatio number
---@field terraformMode number
---@field terraformStrength number
---@field terraformRadius number
---@field terraformPaintRadius number
---@field terraformPaintLayer string
---@field terraformSmoothStrength number
---@field terraformSmoothRadius number
---@field terraformFlattenStrength number
---@field terraformFlattenRadius number
---@field terraformDisablePaint boolean
---@field dischargePaintLayer string
---@field raiseDisplacementVolumeRatio number
---@field lowerDisplacementVolumeRatio number
---@field flattenDisplacementVolumeRatio number
---@field flattenDischargeDisplacementVolumeRatio number
TerraFarmConfig = {}
local TerraFarmConfig_mt = Class(TerraFarmConfig)

TerraFarmConfig.DEFAULT = {
    enabled = true,
    debug = true,
    interval = 50,
    disableDischarge = false,
    fillTypeName = 'STONE',
    fillTypeMassRatio = 0.5,
    volumeFillRatio = 1.0,
    terraformStrength = 50.0,
    terraformRadius = 2.0,
    terraformPaintRadius = 2.0,
    terraformPaintLayer = 'dirt',
    terraformSmoothStrength = 50.0,
    terraformSmoothRadius = 2.0,
    terraformFlattenStrength = 50.0,
    terraformFlattenRadius = 2.0,
    terraformDisablePaint = false,
    dischargePaintLayer = 'dirt',

    raiseDisplacementVolumeRatio = 1.0,
    lowerDisplacementVolumeRatio = 1.618,
    flattenDisplacementVolumeRatio = 1.0,
    flattenDischargeDisplacementVolumeRatio = 0.5
}

TerraFarmConfig.RADIUS_MIN = 0.1
TerraFarmConfig.RADIUS_MAX = 20
TerraFarmConfig.STRENGTH_MIN = 0.1
TerraFarmConfig.STRENGTH_MAX = 100

TerraFarmConfig.FOLDER_PATH = g_modSettingsDirectory .. 'TerraFarm/'
TerraFarmConfig.FILE_PATH = TerraFarmConfig.FOLDER_PATH .. 'config.xml'

---@return TerraFarmConfig
function TerraFarmConfig.newDefault()
    local self = setmetatable({}, TerraFarmConfig_mt)

    for prop, value in pairs(TerraFarmConfig.DEFAULT) do
        self[prop] = value
    end

    return self
end

---@return TerraFarmConfig
function TerraFarmConfig.load()
    local config = TerraFarmConfig.loadXML()
    if not config then
        config = TerraFarmConfig.newDefault()
    end
    return config
end

local function getConfigBool(xmlFile, path, property)
    return Utils.getNoNil(
        getXMLBool(xmlFile, path .. '.' .. property),
        TerraFarmConfig.DEFAULT[property]
    )
end

local function getConfigString(xmlFile, path, property)
    return Utils.getNoNil(
        getXMLString(xmlFile, path .. '.' .. property),
        TerraFarmConfig.DEFAULT[property]
    )
end

local function getConfigFloat(xmlFile, path, property)
    return Utils.getNoNil(
        getXMLFloat(xmlFile, path .. '.' .. property),
        TerraFarmConfig.DEFAULT[property]
    )
end

local function getConfigInt(xmlFile, path, property)
    return Utils.getNoNil(
        getXMLInt(xmlFile, path .. '.' .. property),
        TerraFarmConfig.DEFAULT[property]
    )
end

---@return TerraFarmConfig
function TerraFarmConfig.loadXML()
    if not fileExists(TerraFarmConfig.FILE_PATH) then
        return
    end

    local xmlFile = loadXMLFile('terraFarm', TerraFarmConfig.FILE_PATH)
    if xmlFile == nil or xmlFile == 0 then
        Logging.warning('TerraFarmConfig: Found config.xml file, but could not read. Reverting to defaults')
        return
    end

    ---@type TerraFarmConfig
    local self = setmetatable({}, TerraFarmConfig_mt)

    -- SETTINGS
    self.enabled = getConfigBool(xmlFile, 'terraFarm.settings', 'enabled')
    self.debug = getConfigBool(xmlFile, 'terraFarm.settings', 'debug')
    self.interval = getConfigInt(xmlFile, 'terraFarm.settings', 'interval')
    self.disableDischarge = getConfigBool(xmlFile, 'terraFarm.settings', 'disableDischarge')
    self.terraformDisablePaint = getConfigBool(xmlFile, 'terraFarm.settings', 'terraformDisablePaint')
    self.dischargePaintLayer = getConfigString(xmlFile, 'terraFarm.settings', 'dischargePaintLayer')
    self.terraformPaintLayer = getConfigString(xmlFile, 'terraFarm.settings', 'terraformPaintLayer')
    self.fillTypeName = getConfigString(xmlFile, 'terraFarm.settings', 'fillTypeName')
    self.fillTypeMassRatio = getConfigFloat(xmlFile, 'terraFarm.settings', 'fillTypeMassRatio')


    -- DEFAULTS
    self.volumeFillRatio = getConfigFloat(xmlFile, 'terraFarm.defaults', 'volumeFillRatio')

    self.terraformStrength = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformStrength')
    self.terraformRadius = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformRadius')

    self.terraformPaintRadius = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformPaintRadius')

    self.terraformSmoothStrength = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformSmoothStrength')
    self.terraformSmoothRadius = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformSmoothRadius')

    self.terraformFlattenStrength = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformFlattenStrength')
    self.terraformFlattenRadius = getConfigFloat(xmlFile, 'terraFarm.defaults', 'terraformFlattenRadius')

    -- VOLUME DISPLACEMENT RATIOS

    self.raiseDisplacementVolumeRatio = getConfigFloat(xmlFile, 'terraFarm.settings', 'raiseDisplacementVolumeRatio')
    self.lowerDisplacementVolumeRatio = getConfigFloat(xmlFile, 'terraFarm.settings', 'lowerDisplacementVolumeRatio')
    self.flattenDisplacementVolumeRatio = getConfigFloat(xmlFile, 'terraFarm.settings', 'flattenDisplacementVolumeRatio')
    self.flattenDischargeDisplacementVolumeRatio = getConfigFloat(xmlFile, 'terraFarm.settings', 'flattenDischargeDisplacementVolumeRatio')

    delete(xmlFile)

    if g_terraFarm and g_terraFarm:updateFillTypeData() ~= true then
        Logging.warning('TerraFarmConfig: Reverting to defaults')
        return
    end

    return self
end

function TerraFarmConfig:save()
    createFolder(TerraFarmConfig.FOLDER_PATH)

    local xmlFile = createXMLFile('terraFarm', TerraFarmConfig.FILE_PATH, 'terraFarm')

    if xmlFile == nil or xmlFile == 0 then
        Logging.warning('TerraFarmConfig: Unable to create config.xml')
        return
    end

    -- SETTINGS
    setXMLBool(xmlFile, 'terraFarm.settings.enabled', self.enabled)
    setXMLBool(xmlFile, 'terraFarm.settings.debug', self.debug)
    setXMLInt(xmlFile, 'terraFarm.settings.interval', self.interval)
    setXMLBool(xmlFile, 'terraFarm.settings.disableDischarge', self.disableDischarge)
    setXMLBool(xmlFile, 'terraFarm.settings.terraformDisablePaint', self.terraformDisablePaint)
    setXMLString(xmlFile, 'terraFarm.settings.dischargePaintLayer', self.dischargePaintLayer)
    setXMLString(xmlFile, 'terraFarm.settings.terraformPaintLayer', self.terraformPaintLayer)
    setXMLString(xmlFile, 'terraFarm.settings.fillTypeName', self.fillTypeName)
    setXMLFloat(xmlFile, 'terraFarm.settings.fillTypeMassRatio', self.fillTypeMassRatio)

    -- DEFAULTS
    setXMLFloat(xmlFile, 'terraFarm.defaults.volumeFillRatio', self.volumeFillRatio)

    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformStrength', self.terraformStrength)
    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformRadius', self.terraformRadius)

    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformPaintRadius', self.terraformPaintRadius)

    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformSmoothStrength', self.terraformSmoothStrength)
    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformSmoothRadius', self.terraformSmoothRadius)

    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformFlattenStrength', self.terraformFlattenStrength)
    setXMLFloat(xmlFile, 'terraFarm.defaults.terraformFlattenRadius', self.terraformFlattenRadius)


     -- VOLUME DISPLACEMENT RATIOS

     setXMLFloat(xmlFile, 'terraFarm.settings.raiseDisplacementVolumeRatio', self.raiseDisplacementVolumeRatio)
     setXMLFloat(xmlFile, 'terraFarm.settings.lowerDisplacementVolumeRatio', self.lowerDisplacementVolumeRatio)
     setXMLFloat(xmlFile, 'terraFarm.settings.flattenDisplacementVolumeRatio', self.flattenDisplacementVolumeRatio)
     setXMLFloat(xmlFile, 'terraFarm.settings.flattenDischargeDisplacementVolumeRatio', self.flattenDischargeDisplacementVolumeRatio)

    saveXMLFile(xmlFile)
    delete(xmlFile)
end