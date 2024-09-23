MessageType.MACHINE_ADDED = nextMessageTypeId()
MessageType.MACHINE_REMOVED = nextMessageTypeId()
MessageType.ACTIVE_MACHINE_CHANGED = nextMessageTypeId()
MessageType.SURVEYOR_ADDED = nextMessageTypeId()
MessageType.SURVEYOR_REMOVED = nextMessageTypeId()

---@diagnostic disable-next-line: lowercase-global
g_machineUIFilename = g_currentModDirectory .. 'textures/ui_elements.png'

source(g_currentModDirectory .. 'scripts/utils/MachineUtils.lua')

source(g_currentModDirectory .. 'scripts/events/SetDefaultEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetGlobalEnabledEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetGlobalMaterialsEvent.lua')
source(g_currentModDirectory .. 'scripts/events/SetGlobalResourcesEvent.lua')

source(g_currentModDirectory .. 'scripts/landscaping/BaseLandscaping.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingFlatten.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingLower.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingPaint.lua')
-- source(g_currentModDirectory .. 'scripts/landscaping/LandscapingRaise.lua')
source(g_currentModDirectory .. 'scripts/landscaping/LandscapingSmooth.lua')

source(g_currentModDirectory .. 'scripts/MachineDebug.lua')
source(g_currentModDirectory .. 'scripts/MachineGUI.lua')
source(g_currentModDirectory .. 'scripts/MachineHUD.lua')
source(g_currentModDirectory .. 'scripts/MachineManager.lua')
source(g_currentModDirectory .. 'scripts/MachineState.lua')
source(g_currentModDirectory .. 'scripts/MachineWorkArea.lua')
source(g_currentModDirectory .. 'scripts/ResourceManager.lua')
source(g_currentModDirectory .. 'scripts/Settings.lua')

source(g_currentModDirectory .. 'scripts/machines/Compactor.lua')
source(g_currentModDirectory .. 'scripts/machines/ExcavatorShovel.lua')
source(g_currentModDirectory .. 'scripts/machines/ExcavatorRipper.lua')
source(g_currentModDirectory .. 'scripts/machines/Leveler.lua')
source(g_currentModDirectory .. 'scripts/machines/Ripper.lua')
source(g_currentModDirectory .. 'scripts/machines/Shovel.lua')
source(g_currentModDirectory .. 'scripts/machines/Trencher.lua')

source(g_currentModDirectory .. 'scripts/extensions/FSBaseMissionExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/GuiOverlayExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/InteractiveControlExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/SavegameControllerExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/ShopControllerExtension.lua')
source(g_currentModDirectory .. 'scripts/extensions/VehicleExtension.lua')

if g_client ~= nil then
    g_settings:loadUserSettings()
    g_machineGUI:load()
    g_machineHUD:load()
end

---@diagnostic disable-next-line: undefined-global
g_onCreateUtil.activateOnCreateFunctions = Utils.appendedFunction(g_onCreateUtil.activateOnCreateFunctions,
    function()
        g_machineManager:onModsLoaded()
        g_interactiveControlExtension:registerFunctions()
    end
)

---@class ModEventListener
ModEventListener = {}

function ModEventListener:loadMap()
    g_settings:onMapLoaded()
    g_machineGUI:onMapLoaded()
    g_machineHUD:onMapLoaded()
    g_machineDebug:onMapLoaded()
    g_machineManager:onMapLoaded()
end

addModEventListener(ModEventListener)
