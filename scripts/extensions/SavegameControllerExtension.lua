local function post_SavegameController_onSaveComplete(self, errorCode)
    if errorCode == Savegame.ERROR_OK and g_settings ~= nil then
        pcall(function()
            g_settings:saveUserSettings()
            g_settings:saveModSettings()
        end)
    end
end

SavegameController.onSaveComplete = Utils.appendedFunction(SavegameController.onSaveComplete, post_SavegameController_onSaveComplete)
