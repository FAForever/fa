local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

UEFNukeEffect02 = Class(NullShell) {
    OnCreate = function(self)
        NullShell.OnCreate(self)
        self.Trash:Add(ForkThread(self.EffectThread, self))
    end,

    EffectThread = function(self)
        local army = self.Army

        for k, v in EffectTemplate.TNukeHeadEffects01 do
            CreateEmitterOnEntity(self, army, v)
        end
        self:SetVelocity(0, 1, 0)
    end,
}
TypeClass = UEFNukeEffect02
