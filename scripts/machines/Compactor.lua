---@type MachineType
local machineTypeCompactor = {
    id = 'compactor',
    name = g_i18n:getText('machineType_compactor'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false
}

g_machineManager:registerMachineType(machineTypeCompactor)
