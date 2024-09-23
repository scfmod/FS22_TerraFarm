---@type MachineType
local machineTypeRipper = {
    id = 'ripper',
    name = g_i18n:getText('machineType_ripper'),
    useDischargeable = false,
    useDrivingDirection = true,
    useFillUnit = false,
    useLeveler = false,
    useShovel = false
}

g_machineManager:registerMachineType(machineTypeRipper)
