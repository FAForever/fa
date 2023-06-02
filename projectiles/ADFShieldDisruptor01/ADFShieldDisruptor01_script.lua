------------------------------------------------------------------------------------------
-- File     :  /data/projectiles/ADFShieldDisruptor01/ADFShieldDisruptor01_script.lua
-- Author(s):  Matt Vainio
-- Summary  :  Aeon Shield Disruptor Projectile, DAL0310
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------------------
local ADisruptorProjectile = import("/lua/aeonprojectiles.lua").AShieldDisruptorProjectile
ADFShieldDisruptor01 = ClassProjectile(ADisruptorProjectile) {
    OnImpact = function(self, TargetType, TargetEntity)
        ADisruptorProjectile.OnImpact(self, TargetType, TargetEntity)
        if TargetType ~= 'Shield' then
            TargetEntity = TargetEntity.MyShield
        end

        if not TargetEntity then return end

        -- Never cause overspill damage to the unit, 1 min to avoid logspam with 0 declared damage
        local damage = math.max(math.min(1300, TargetEntity:GetHealth()), 1) -- TODO: find a better way to pass this damage
        Damage(self, {0,0,0}, TargetEntity, damage, 'Normal')
    end,
}
TypeClass = ADFShieldDisruptor01