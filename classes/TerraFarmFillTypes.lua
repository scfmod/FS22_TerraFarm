---@class TerraFarmFillTypes
TerraFarmFillTypes = {}

TerraFarmFillTypes.SUPPORTED_TYPES_LIST = {
    'STONE',
    'DIRT',
    'ASPHALT',
    'COAL',
    'TAILINGS',
    'CONCRETE',
    'LIMESTONE',
    'GRAVEL',
    'SAND',
    'IRON',
    'PAYDIRT',
    'CEMENT',
    'RIVERSAND',
    'RIVERSANDP',
    'STONEPOWDER',
    'CLAY',
}

-- For GUI
---@type table<number, string>
TerraFarmFillTypes.TYPES_LIST = {}

-- For GUI
---@type table<string, number>
TerraFarmFillTypes.NAME_TO_INDEX = {}

-- For GUI
---@type table<string, string>
TerraFarmFillTypes.TITLE_TO_NAME = {}


function TerraFarmFillTypes:init()
    for _, name in pairs(self.SUPPORTED_TYPES_LIST) do
        self:add(name)
    end
end

function TerraFarmFillTypes:add(name)
    local fillType = g_fillTypeManager.nameToFillType[name]
    if fillType then
        local title = string.lower(name):gsub("^%l", string.upper)

        table.insert(self.TYPES_LIST, title)
        self.NAME_TO_INDEX[name] = #self.TYPES_LIST
        self.TITLE_TO_NAME[title] = name

        if not g_densityMapHeightManager.fillTypeNameToHeightType[name] then
            if self:addDensityMapHeight(name) then
                Logging.info('TerraFarm: Successfully added custom density map height - ' .. tostring(name))
            end
        end
    end
end

function TerraFarmFillTypes:addDensityMapHeight(fillTypeName)
    local heightType = g_densityMapHeightManager.fillTypeNameToHeightType[fillTypeName] or {}
    local maxAngle = 41
    local maxSurfaceAngle = heightType.maxSurfaceAngle or math.rad(26)

    if maxAngle ~= nil then
        maxSurfaceAngle = math.rad(maxAngle)
    end

    local fillToGroundScale = 1.0
    local allowsSmoothing = true
    local collisionScale = 1.0
    local collisionBaseOffset = 0.08
    local minCollisionOffset = 0.0
    local maxCollisionOffset = 0.08

    local isBaseType = false

    return g_densityMapHeightManager:addDensityMapHeightType(fillTypeName, maxSurfaceAngle, collisionScale, collisionBaseOffset, minCollisionOffset, maxCollisionOffset, fillToGroundScale, allowsSmoothing, isBaseType)
end