---------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/SBOOhwalliStategicBomb01/SBOOhwalliStategicBomb01_script.lua
-- Author(s):  Greg Kohne, Gordon Duclos, Matt Vainio
-- Summary  :  Ohwalli-Strategic Bomb script, used on XSA402
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------

local SOhwalliStrategicBombProjectile = import('/lua/seraphimprojectiles.lua').SOhwalliStrategicBombProjectile

SBOOhwalliStategicBomb01 = Class(SOhwalliStrategicBombProjectile) {
    OnCreate = function(self)
        self.Collisions = {}
        SOhwalliStrategicBombProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
    end,

    OnImpact = function(self, TargetType, TargetEntity)
        self:CreateProjectile('/effects/entities/SBOOhwalliBombEffectController01/SBOOhwalliBombEffectController01_proj.bp', 0, 0, 0, 0, 0, 0):SetCollision(false)
        SOhwalliStrategicBombProjectile.OnImpact(self, TargetType, TargetEntity) 
    end,

    OnCollisionCheck = function(self, other)
        -- If not myself, not already been hit, and is Air, damage it and continue without colliding and exploding.
        local id = other:GetEntityId()
        if self.Collisions[id] then
            return false
        elseif other ~= self and EntityCategoryContains(categories.AIR, other) then
            Damage(self:GetLauncher() or self, self:GetPosition(), other, self.DamageData.DamageAmount, 'Normal')
            self.Collisions[id] = true
            return false
        end

        return SOhwalliStrategicBombProjectile.OnCollisionCheck(self, other)
    end,
}

TypeClass = SBOOhwalliStategicBomb01
