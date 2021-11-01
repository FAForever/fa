-- Automatically upvalued moho functions for performance
local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetDestroyOnWater = ProjectileMethods.SetDestroyOnWater
-- End of automatically upvalued moho functions

#
# Terran Gauss Cannon Projectile
#
local TDFGaussCannonProjectile = import('/lua/terranprojectiles.lua').TDFLandGaussCannonProjectile
TDFGauss04 = Class(TDFGaussCannonProjectile)({

    FxUnitHitScale = 0.9,
    FxLandHitScale = 0.9,

    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            ProjectileMethodsSetDestroyOnWater(self, true)
        else
            self:ForkThread(self.DestroyOnWaterThread)
        end
    end,

    DestroyOnWaterThread = function(self)
        WaitSeconds(0.2)
        ProjectileMethodsSetDestroyOnWater(self, true)
    end,
})
TypeClass = TDFGauss04

