
local HoverLandUnit = import("/lua/sim/units/hoverlandunit.lua").HoverLandUnit

---@class SlowHoverLandUnit : HoverLandUnit
SlowHoverLandUnit = ClassUnit(HoverLandUnit) {

    ---@param self SlowHoverLandUnit
    ---@param new string
    ---@param old string
    OnLayerChange = function(self, new, old)

        -- call base class to make sure self.layer is set
        HoverLandUnit.OnLayerChange(self, new, old)

        -- Slow these units down when they transition from land to water
        -- The mult is applied twice thanks to an engine bug, so careful when adjusting it
        -- Newspeed = oldspeed * mult * mult

        local mult = (self.Blueprint or self:GetBlueprint()).Physics.WaterSpeedMultiplier
        if new == 'Water' then
            self:SetSpeedMult(mult)
        else
            self:SetSpeedMult(1)
        end
    end,
}
