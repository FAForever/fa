local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

---@class UEFNukeEffect01 : NullShell
UEFNukeEffect01 = Class(NullShell) {

    ---@param self UEFNukeEffect01
    OnCreate = function(self)
        NullShell.OnCreate(self)
        self.Trash:Add(ForkThread(self.EffectThread,self))
    end,

    ---@param self UEFNukeEffect01
    EffectThread = function(self)
        local scale = self.Blueprint.Display.UniformScale
        local scaleChange = 0.30 * scale

        self:SetScaleVelocity(scaleChange,scaleChange,scaleChange)
        self:SetVelocity(0,0.25,0)

        WaitSeconds(4)
        scaleChange = -0.01 * scale
        self:SetScaleVelocity(scaleChange,12*scaleChange,scaleChange)
        self:SetVelocity(0,2,0)
        self:SetBallisticAcceleration(-0.5)

        WaitSeconds(5)
        scaleChange = -0.1 * scale        
        self:SetScaleVelocity(scaleChange,scaleChange,scaleChange)
    end,
}
TypeClass = UEFNukeEffect01