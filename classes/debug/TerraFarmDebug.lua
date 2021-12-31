---@class TerraFarmDebug
TerraFarmDebug = {}

TerraFarmDebug.COLORS = {
    terraformNode = {1, 0, 0, 1},
    terraformNodeActive = {0, 1, 0, 1},
    transformNodeDisabled = {0.3, 0.3, 0.3, 1},
    transformNodeDisabledActive = {0.9, 0.3, 0.3, 1},
    collisionNode = {0, 0, 1, 1},
    collisionNodeActive = {0, 0.8, 0.9, 1},
    collisionNodeDisabled = {0.3, 0.3, 0.3, 1},
    collisionNodeDisabledActive = {0.3, 0.3, 0.9, 1}
}

function TerraFarmDebug.draw()
    if g_terraFarm.currentMachine then
        TerraFarmDebug.drawMachineTerraformNodes(g_terraFarm.currentMachine)
        TerraFarmDebug.drawMachineCollisionNodes(g_terraFarm.currentMachine)
    end
end

---@param machine TerraFarmMachine
function TerraFarmDebug.drawMachineTerraformNodes(machine)
    local isEnabled = machine:getIsEnabled()

    for _, node in pairs(machine.config.terraformNodes) do
        local position = machine.nodePosition[node]
        if position then
            local color = TerraFarmDebug.COLORS.terraformNode

            if machine.nodeIsTouchingTerrain[node] then
                if isEnabled then
                    color = TerraFarmDebug.COLORS.terraformNodeActive
                else
                    color = TerraFarmDebug.COLORS.transformNodeDisabledActive
                end
            elseif not isEnabled then
                color = TerraFarmDebug.COLORS.transformNodeDisabled
            end

            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color)
            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color, true)

            Utils.renderTextAtWorldPosition(
                position.x, position.y, position.z,
                'o', getCorrectTextSize(0.01), 0, color
            )
        end
    end
end

---@param machine TerraFarmMachine
function TerraFarmDebug.drawMachineCollisionNodes(machine)
    local isEnabled = machine:getIsEnabled()

    for _, node in pairs(machine.config.collisionNodes) do
        local position = machine.nodePosition[node]

        if position then
            local color = TerraFarmDebug.COLORS.collisionNode
            if machine.nodeIsTouchingTerrain[node] then
                if isEnabled then
                    color = TerraFarmDebug.COLORS.collisionNodeActive
                else
                    color = TerraFarmDebug.COLORS.collisionNodeDisabledActive
                end
            elseif not isEnabled then
                color = TerraFarmDebug.COLORS.collisionNodeDisabled
            end

            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color)
            DebugUtil.drawDebugCircleAtNode(node, 0.05, 2, color, true)

            Utils.renderTextAtWorldPosition(
                position.x, position.y, position.z,
                'o', getCorrectTextSize(0.01), 0, color
            )
        end
    end
end