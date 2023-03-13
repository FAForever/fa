local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/effecttemplates.lua")

UEFNukeEffect03 = Class(NullShell) {
    OnCreate = function(self)
        NullShell.OnCreate(self)
        self.Trash:Add(ForkThread(self.EffectThread, self))
    end,

    EffectThread = function(self)
        local army = self.Army
        for k, v in EffectTemplate.TNukeHeadEffects03 do
            CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(0.7)
        end

        WaitTicks(61)
        for k, v in EffectTemplate.TNukeHeadEffects02 do
            CreateAttachedEmitter(self, -1, army, v):ScaleEmitter(0.7)
        end
    end,
}
TypeClass = UEFNukeEffect03
