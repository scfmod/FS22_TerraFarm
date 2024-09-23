---@type MachineType
local machineTypeExcavatorRipper = {
    id = 'excavatorRipper',
    name = g_i18n:getText('machineType_ripper'),
    useDischargeable = false,
    useDrivingDirection = false,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false
}

g_machineManager:registerMachineType(machineTypeExcavatorRipper)
