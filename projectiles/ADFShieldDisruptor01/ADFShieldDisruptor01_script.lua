-- Automatically upvalued moho functions for performance
local GlobalMethods = _G
local GlobalMethodsDamage = GlobalMethods.Damage
-- End of automatically upvalued moho functions

-- ****************************************************************************
-- **
-- **  File     :  /data/projectiles/ADFShieldDisruptor01/ADFShieldDisruptor01_script.lua
-- **  Author(s):  Matt Vainio
-- **
-- **  Summary  :  Aeon Shield Disruptor Projectile, DAL0310
-- **
-- **  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
local ADisruptorProjectile = import('/lua/aeonprojectiles.lua').AShieldDisruptorProjectile

ADFShieldDisruptor01 = Class(ADisruptorProjectile)({
    OnImpact = function(self, TargetType, TargetEntity)
        ADisruptorProjectile.OnImpact(self, TargetType, TargetEntity)
        if TargetType ~= 'Shield' then
            TargetEntity = TargetEntity.MyShield
        end

        if not TargetEntity then
            return
        end

        -- Never cause overspill damage to the unit, 1 min to avoid logspam with 0 declared damage
        local damage = math.max(math.min(self.Data, TargetEntity:GetHealth()), 1)
        GlobalMethodsDamage(self, {
            0,
            0,
            0,
        }, TargetEntity, damage, 'Normal')
    end,
})

TypeClass = ADFShieldDisruptor01
