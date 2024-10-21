---@type MachineType
local machineTypeDischarger = {
    id = 'discharger',
    name = g_i18n:getText('configuration_dischargeable'),
    useDischargeable = true,
    useDrivingDirection = false,
    useFillUnit = true,
    useLeveler = false,
    useShovel = false,
    useTrailer = true
}

g_machineManager:registerMachineType(machineTypeDischarger)
