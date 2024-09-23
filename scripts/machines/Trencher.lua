---@type MachineType
local machineTypeTrencher = {
    id = 'trencher',
    name = g_i18n:getText('machineType_trencher'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = false,
    useShovel = false
}

g_machineManager:registerMachineType(machineTypeTrencher)
