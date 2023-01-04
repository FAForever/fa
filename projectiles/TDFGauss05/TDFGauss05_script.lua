--
-- Terran Gauss Cannon Projectile
--
local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFMediumShipGaussCannonProjectile
TDFGauss05 = ClassProjectile(TDFGaussCannonProjectile) {
    
    FxUnitHitScale = 1.6,
    FxLandHitScale = 1.6,

    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            self:SetDestroyOnWater(true)
        else
            self.Trash:Add(ForkThread(self.DestroyOnWaterThread,self))
        end
    end,
    
    DestroyOnWaterThread = function(self)
        WaitTicks(3)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TDFGauss05

