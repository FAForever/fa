local EffectTemplate = import("/lua/effecttemplates.lua")

local Entity = import("/lua/sim/entity.lua").Entity
local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit
local MobileUnitOnCreate = MobileUnit.OnCreate
local MobileUnitOnMotionVertEventChange = MobileUnit.OnMotionVertEventChange

---@class SubUnit : MobileUnit
SubUnit = ClassUnit(MobileUnit) {
    -- Use default spark effect until underwater damaged states are made
    FxDamage1 = { EffectTemplate.DamageSparks01 },
    FxDamage2 = { EffectTemplate.DamageSparks01 },
    FxDamage3 = { EffectTemplate.DamageSparks01 },

    -- DESTRUCTION PARAMS
    ShowUnitDestructionDebris = false,
    DeathThreadDestructionWaitTime = 0,

    ---@param self SubUnit
    ---@param spec any
    OnCreate = function(self, spec)
        MobileUnitOnCreate(self, spec)

        -- submarines do not make a sound by default, we want them to make sound so we use an entity as source instead
        self.SoundEntity = Entity()
        self.Trash:Add(self.SoundEntity)
        Warp(self.SoundEntity, self:GetPosition())
        self.SoundEntity:AttachTo(self, -1)
    end,

    ---@param self Unit
    ---@param new VerticalMovementState
    ---@param old VerticalMovementState
    OnMotionVertEventChange = function(self, new, old)
        MobileUnitOnMotionVertEventChange(self, new, old)

        -- only temporarily remove/add dive command if the submarine should have a dive command
        if self.Blueprint.General.CommandCaps.RULEUCC_Dive then
            if new == 'Up' or new == 'Down' then
                self:RemoveCommandCap("RULEUCC_Dive")
                self:RequestRefreshUI()
            end

            if new == 'Top' or new == 'Bottom' then
                self:AddCommandCap("RULEUCC_Dive")
                self:RequestRefreshUI()
            end
        end
    end,
}
