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
    end
end