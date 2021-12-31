---@class MachineTypes
---@field _typeCount number
---@field typeToClass table<number, table>
---@field classToType table<table, number>
---@field nameToClass table<string, table>
---@field typeToString table<number, string>
---@field stringToType table<string, number>
---@field stringToClass table<string, table>
MachineTypes = {}
local MachineTypes_mt = Class(MachineTypes)

---@return MachineTypes
function MachineTypes.new()
    ---@type MachineTypes
    local self = setmetatable({}, MachineTypes_mt)

    self._typeCount = 0

    self.typeToClass = {}
    self.classToType = {}
    self.nameToClass = {}
    self.typeToString = {}
    self.stringToType = {}
    self.stringToClass = {}

    return self
end

function MachineTypes:registerType(class, name)
    if self.classToType[class] ~= nil then
        Logging.error('MachineTypes.registertype: Duplicate type ' .. name)
    end

    self._typeCount = self._typeCount + 1
    local index = self._typeCount

    self.typeToClass[index] = class
    self.classToType[class] = index
    self.nameToClass[name] = class
    self.typeToString[index] = name
    self.stringToType[name] = index
    self.stringToClass[name] = class

    class.machineType = index
    class.machineTypeName = name
end

---@diagnostic disable-next-line: lowercase-global
g_machineTypes = MachineTypes.new()