local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class UEFNukeEffect02 : NullShell
UEFNukeEffect02 = Class(NullShell) {

    ---@param self UEFNukeEffect02
    OnCreate = function(self)
        NullShell.OnCreate(self)
        self:ForkThread(self.EffectThread)
    end,

    ---@param self UEFNukeEffect02
    EffectThread = function(self)
        local army = self.Army

        for k, v in EffectTemplate.TNukeHeadEffects01 do
            CreateEmitterOnEntity(self, army, v )
        end

        self:SetVelocity(0,1,0)
    end,
}
TypeClass = UEFNukeEffect02