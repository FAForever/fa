HEL0001 = Class(moho.unit_methods) {
    OnDamage = function(self, instigator, amount, vector, damageType)
    end,

    OnCreate = function(self)
        self:SetCapturable(false)
        self:SetReclaimable(false)
        self:SetIsValidTarget(false)
        self:SetCollisionShape('None')

        ForkThread(self.KillHelperWhenIdle, self)
    end,
    
    -- The ferry helper unit is destroyed when command queue is empty (happens when beacon is destroyed with shift-ctrl right click)
    KillHelperWhenIdle = function(self)
        repeat 
            WaitSeconds(1)
            cmds = self:GetCommandQueue()
        until table.empty(cmds)
        
        self:Destroy()
    end
}

TypeClass = HEL0001
