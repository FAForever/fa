--
-- Terran Gauss Cannon Projectile
--
local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFMediumShipGaussCannonProjectile
TDFGauss05 = Class(TDFGaussCannonProjectile) {
    
    FxUnitHitScale = 1.6,
    FxLandHitScale = 1.6,

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
TypeClass = TDFGauss05

