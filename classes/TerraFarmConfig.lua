---@class TerraFarmConfig
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
TerraFarmConfig = {}

TerraFarmConfig.DEFAULT = {
    enabled = true,
    debug = true,
    -- interval = 200,
    interval = 50,
    disableDischarge = false,
    fillTypeName = 'STONE',
    fillTypeMassRatio = 0.5,
    volumeFillRatio = 1.0,
    terraformStrength = 50.0,
    terraformRadius = 2.0,
    terraformPaintRadius = 2.0,
    terraformMode = 1,
    terraformPaintLayer = 'dirt',
    terraformSmoothStrength = 50.0,
    terraformSmoothRadius = 2.0,
    terraformFlattenStrength = 50.0,
    terraformFlattenRadius = 2.0,
    terraformDisablePaint = false,
    -- terraformDisablePaint = true,
    dischargePaintLayer = 'dirt'
}

TerraFarmConfig.RADIUS_MIN = 0.1
TerraFarmConfig.RADIUS_MAX = 20
TerraFarmConfig.STRENGTH_MIN = 0.1
TerraFarmConfig.STRENGTH_MAX = 100

---@return TerraFarmConfig
function TerraFarmConfig.newDefault()
    local self = table.copy(TerraFarmConfig.DEFAULT)
    return self
end

---@return TerraFarmConfig
---@diagnostic disable-next-line: unused-local
function TerraFarmConfig.load(file)
end

---@return boolean
---@diagnostic disable-next-line: unused-local
function TerraFarmConfig.save(file)
end