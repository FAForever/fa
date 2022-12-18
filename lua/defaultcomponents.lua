
---@class ManageShieldEffects : Unit
---@field Trash TrashBag
---@field ShieldEffectsBag TrashBag
---@field ShieldEffectsBone Bone
---@field ShieldEffectsScale number
ManageShieldEffects = ClassSimple {

    ShieldEffects = { },
    ShieldEffectsBone = 0,
    ShieldEffectsScale = 1,

    ---@param self ManageShieldEffects
    OnCreate = function(self)
        self.ShieldEffectsBag = TrashBag()
        self.Trash:Add(self.ShieldEffectsBag)
    end,

    ---@param self ManageShieldEffects
    OnShieldEnabled = function(self)
        self.ShieldEffectsBag:Destroy()
        for _, v in self.ShieldEffects do
            self.ShieldEffectsBag:Add(CreateAttachedEmitter(self, self.ShieldEffectsBone, self.Army, v):ScaleEmitter(self.ShieldEffectsScale))
        end
    end,

    ---@param self ManageShieldEffects
    OnShieldDisabled = function(self)
        self.ShieldEffectsBag:Destroy()
    end,

}
