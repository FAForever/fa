------------------------------------------------------------
--
--  File     :  /data/projectiles/AIFFragmentationSensorShell03/AIFFragmentationSensorShell03_script.lua
--  Author(s):  Drew Staltman, Gordon Duclos
--
--  Summary  :  Aeon Quantic Cluster Fragmentation Sensor shell script
--				 Child Projectile after 2st split
--              Aeon Salvation : XAB2307
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------
local AArtilleryFragmentationSensorShellProjectile = import('/lua/aeonprojectiles.lua').AArtilleryFragmentationSensorShellProjectile03
local EffectTemplate = import('/lua/EffectTemplates.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

AIFFragmentationSensorShell03 = Class(AArtilleryFragmentationSensorShellProjectile)({
    OnImpact = function(self, targetType, targetEntity)
        local pos = self:GetPosition()
        local radius = self.DamageData.DamageRadius
        local FriendlyFire = self.DamageData.DamageFriendly and radius ~= 0

        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)
        DamageArea(self, pos, radius, 1, 'Force', FriendlyFire)

        self.DamageData.DamageAmount = self.DamageData.DamageAmount - 2

        if targetType ~= 'Shield' and targetType ~= 'Water' and targetType ~= 'Air' and targetType ~= 'UnitAir' and targetType ~= 'Projectile' then
            local rotation = RandomFloat(0, 2 * math.pi)
            local size = RandomFloat(2.25, 3.75)
            local army = self.Army

            CreateDecal(pos, rotation, 'scorch_004_albedo', '', 'Albedo', size, size, 200, 50, army)
        end

        self:ShakeCamera(20, 1, 0, 1)

        AArtilleryFragmentationSensorShellProjectile.OnImpact(self, targetType, targetEntity)
    end,
})
TypeClass = AIFFragmentationSensorShell03