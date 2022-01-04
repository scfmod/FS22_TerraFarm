--[[
    ONLY USED FOR LUA TYPE RESOLVING
]]

---@class Position
Position = {
    x  = 0,
    y = 0,
    z = 0
}
---@class MachineSpec
---@field typeName string
---@field type number
---@field name string
---@field filePath string
---@field actionEvents table
---@field machine TerraFarmMachine
MachineSpec = {}

---@class GroundTypeItem
---@field index number
---@field name string
---@field layerId number
GroundTypeItem = {}