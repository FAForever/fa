#
# Terran Gauss Cannon Projectile
#
local TDFGaussCannonProjectile = import('/lua/terranprojectiles.lua').TDFLandGaussCannonProjectile
TDFGauss04 = Class(TDFGaussCannonProjectile) {
    
    FxUnitHitScale = 0.75,
    FxLandHitScale = 0.75,

    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            self:SetDestroyOnWater(true)
        else
            self:ForkThread(self.DestroyOnWaterThread)
        end
    end,
    
    DestroyOnWaterThread = function(self)
        WaitSeconds(0.2)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TDFGauss04

