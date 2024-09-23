---@param connection Connection
---@param user User
---@param farm Farm
local function post_FSBaseMission_sendInitialClientState(self, connection, user, farm)
    g_settings:onSendInitialClientState(connection)
    g_resources:onSendInitialClientState(connection)
end

---@param self FSBaseMission
local function post_FSBaseMission_initTerrain(self)
    g_resources:onTerrainInitialized()
    g_settings:onTerrainInitialized()
end

if g_server ~= nil then
    FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState, post_FSBaseMission_sendInitialClientState)
end

FSBaseMission.initTerrain = Utils.appendedFunction(FSBaseMission.initTerrain, post_FSBaseMission_initTerrain)
