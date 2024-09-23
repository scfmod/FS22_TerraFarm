local function inj_GuiOverlay_loadOverlay(self, superFunc, overlay, ...)
    ---@type Overlay
    local result_overlay = superFunc(self, overlay, ...)

    if overlay ~= nil and result_overlay ~= nil and overlay.filename == 'g_machineUIFilename' then
        result_overlay.filename = g_machineUIFilename
    end

    return result_overlay
end

GuiOverlay.loadOverlay = Utils.overwrittenFunction(GuiOverlay.loadOverlay, inj_GuiOverlay_loadOverlay)
