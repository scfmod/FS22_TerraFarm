---@type MachineType
local machineTypeExcavatorShovel = {
    id = 'excavatorShovel',
    name = g_i18n:getText('machineType_excavator'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = true,
    useShovel = true
}

g_machineManager:registerMachineType(machineTypeExcavatorShovel)
