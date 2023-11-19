local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell
local EffectTemplate = import("/lua/EffectTemplates.lua")

---@class UEFNukeEffect03 : NullShell
UEFNukeEffect03 = Class(NullShell) {

    ---@param self UEFNukeEffect03
    OnCreate = function(self)
        NullShell.OnCreate(self)
        self:ForkThread(self.EffectThread)
    end,

    ---@param self UEFNukeEffect03
    EffectThread = function(self)
        local army = self.Army
        for k, v in EffectTemplate.TNukeHeadEffects03 do
            CreateAttachedEmitter(self, -1, army, v ):ScaleEmitter(0.7)
        end

        WaitSeconds(6)
        for k, v in EffectTemplate.TNukeHeadEffects02 do
            CreateAttachedEmitter(self, -1, army, v ):ScaleEmitter(0.7)
        end
    end,
}
TypeClass = UEFNukeEffect03