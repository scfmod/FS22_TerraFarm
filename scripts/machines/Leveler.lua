---@type MachineType
local machineTypeLeveler = {
    id = 'leveler',
    name = g_i18n:getText('machineType_leveler'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = true,
    useLeveler = true,
    useShovel = false
}

g_machineManager:registerMachineType(machineTypeLeveler)
