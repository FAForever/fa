
local AmphibiousLandUnit = import("/lua/sim/units/amphibiouslandunit.lua").AmphibiousLandUnit

---@class SlowAmphibiousLandUnit : AmphibiousLandUnit
SlowAmphibiousLandUnit = ClassUnit(AmphibiousLandUnit) {

    ---@param self SlowAmphibiousLandUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)
        AmphibiousLandUnit.OnLayerChange(self, new, old)

        local mult = (self.Blueprint or self:GetBlueprint()).Physics.WaterSpeedMultiplier
        if new == 'Seabed'  then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}
