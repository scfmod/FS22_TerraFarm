---@class LandscapingLower : BaseLandscaping
LandscapingLower = {}

local LandscapingLower_mt = Class(LandscapingLower, BaseLandscaping)

---@param workArea MachineWorkArea
---@return LandscapingLower
---@nodiscard
function LandscapingLower.new(workArea)
    ---@type LandscapingLower
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = BaseLandscaping.new(LandscapingOperation.LOWER, workArea, LandscapingLower_mt)

    self:verifyAndApplyMapResources()

    return self
end

---@return TerrainDeformation
---@nodiscard
function LandscapingLower:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:enableAdditiveDeformationMode()
    self.deformation:setAdditiveHeightChangeAmount(-self.heightChangeAmount)

    return self.deformation
end

---@param volume number
function LandscapingLower:onDeformationSuccess(volume)
    self:applyDeformationChanges()

    if self.state.enableInputMaterial and volume > 0 and self.fillType ~= nil then
        local liters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)
        self.vehicle:workAreaInput(liters, self.fillType.index)
    end
end
