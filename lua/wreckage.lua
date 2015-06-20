--****************************************************************************
--**
--**  File     : /lua/wreckage.lua
--**
--**  Summary  : Class for wreckage so it can get pushed around
--**
--**  Copyright 2006 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local Prop = import('/lua/sim/Prop.lua').Prop

Wreckage = Class(Prop) {

    OnCreate = function(self)
        Prop.OnCreate(self)
    end,
    
    OnDamage = function(self, instigator, amount, vector, damageType)
        self:DoTakeDamage(instigator, amount, vector, damageType)
    end,

    DoTakeDamage = function(self, instigator, amount, vector, damageType)
        local maxHealth = self:GetMaxHealth()
        self:AdjustHealth(instigator, -amount)
        local health = self:GetHealth()
        if health > 0 then
            local healthRatio = health / maxHealth
            if not self.MaxReclaimTimeMassMult then
                self.MaxReclaimTimeMassMult = self.ReclaimTimeMassMult
            end
            if not self.MaxReclaimTimeEnergyMult then
                self.MaxReclaimTimeEnergyMult = self.ReclaimTimeEnergyMult
            end
            local mtime = self.MaxReclaimTimeMassMult * healthRatio
            local etime = self.MaxReclaimTimeEnergyMult * healthRatio
            local mass = self.MaxMassReclaim * healthRatio
            local energy = self.MaxEnergyReclaim * healthRatio
            self:SetReclaimValues( mtime, etime, mass, energy)
        elseif health <= 0 then
            self:Destroy()
        end
    end,
    
    OnCollisionCheck = function(self, other)
        if IsUnit(other) then
            return false
        else
            return true
        end
    end,
}
