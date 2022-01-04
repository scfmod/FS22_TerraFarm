---@class TerraFarmGroundTypes
---@field items GroundTypeItem[]
TerraFarmGroundTypes = {}

TerraFarmGroundTypes.items = {}
TerraFarmGroundTypes.TYPES_LIST = {}

local function isValidGroundTypeName(name)
    return name == string.upper(name)
end

function TerraFarmGroundTypes:init()
    for name, layerId in pairs(g_groundTypeManager.terrainLayerMapping) do
        if isValidGroundTypeName(name) then
            local index = #self.items + 1
            local item = {
                index = index,
                name = name,
                layerId = layerId
            }
            table.insert(self.items, item)
            table.insert(self.TYPES_LIST, name)
        end
    end

    g_terraFarm:updatePaintLayerData()
end

function TerraFarmGroundTypes:getIndexByName(name)
    for index, item in ipairs(self.items) do
        if item.name == name then
            return index
        end
    end
    return 1
end

function TerraFarmGroundTypes:getNameByIndex(index)
    if self.items[index] ~= nil then
        return self.items[index].name
    end
end

function TerraFarmGroundTypes:getLayerByName(name)
    for _, item in ipairs(self.items) do
        if item.name == name then
            return item.layerId
        end
    end

    return 0
end

GroundTypeManager.initTerrain = Utils.appendedFunction(GroundTypeManager.initTerrain,
    function ()
        TerraFarmGroundTypes:init()
    end
)