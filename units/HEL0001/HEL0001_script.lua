HEL0001 = Class(moho.unit_methods) {
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
        self:SetIsValidTarget(false)
        self:SetCollisionShape('None')
    end,

    Kill = function(self)
        IssueClearCommands({self})
        self:Destroy()
    end,
}

TypeClass = HEL0001
