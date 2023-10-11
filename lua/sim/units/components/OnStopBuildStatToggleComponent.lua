---@class OnStopBuildStatToggleComponent
OnStopBuildStatToggleComponent = ClassSimple {

    --- Initializes our default values
    ---@param self Unit | OnStopBuildStatToggleComponent
    OnCreate = function(self)
        -- Set our build toggles to their default values
        -- These will be the default values applied to units we build
        if self.Blueprint.General.StatToggles then
            for stat, toggleData in self.Blueprint.General.StatToggles do
                self:UpdateStat(stat, toggleData.default or 0)
            end
        end
    end,

    ---@param self Unit | OnStopBuildStatToggleComponent
    ---@param unit Unit
    OnStopBuild = function(self, unit)
        if self.Blueprint.General.StatToggles then
            for stat, toggleData in unit.Blueprint.General.OnStopBeingBuiltStatToggles do
                LOG(stat)
                LOG(repr(toggleData))
                if toggleData.scriptBit then
                    -- apply the script bit with our stat value
                    unit:SetScriptBit(toggleData.scriptBit, (self:GetStat(stat, 0).Value == 1 and true) or false)
                end
            end
        end
    end,
}