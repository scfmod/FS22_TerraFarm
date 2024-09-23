---@type MachineType
local machineTypeShovel = {
    id = 'shovel',
    name = g_i18n:getText('machineType_shovel'),
    useDischargeable = true,
    useDrivingDirection = true,
    useFillUnit = true,
    useLeveler = true,
    useShovel = true
}

g_machineManager:registerMachineType(machineTypeShovel)
