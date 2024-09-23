---@class LandscapingSmooth : BaseLandscaping
LandscapingSmooth = {}

local LandscapingSmooth_mt = Class(LandscapingSmooth, BaseLandscaping)

---@param workArea MachineWorkArea
---@return LandscapingSmooth
---@nodiscard
function LandscapingSmooth.new(workArea)
    ---@type LandscapingSmooth
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = BaseLandscaping.new(LandscapingOperation.SMOOTH, workArea, LandscapingSmooth_mt)

    self.heightChangeAmount = 0.05

    if self.vehicle.spec_machine.machineType.id == 'excavatorShovel' then
        self.heightChangeAmount = 0.75
    end

    self:verifyAndApplyMapResources()

    return self
end

function LandscapingSmooth:createTerrainDeformation()
    self.deformation = MachineUtils.createTerrainDeformation()

    self.deformation:setAdditiveHeightChangeAmount(self.heightChangeAmount)
    self.deformation:enableSmoothingMode()

    return self.deformation
end

---@param volume number
function LandscapingSmooth:onDeformationSuccess(volume)
    self:applyDeformationChanges()

    if self.state.enableInputMaterial and volume > 0 and self.fillType ~= nil then
        local liters = MachineUtils.volumeToFillTypeLiters(volume, self.fillType.index)
        self.vehicle:workAreaInput(liters, self.fillType.index)
    end
end
