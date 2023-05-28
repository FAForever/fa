--
-- Terran Gauss Cannon Projectile (UEL0401) Fatboy
--
local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFBigLandGaussCannonProjectile
TDFGauss04 = ClassProjectile(TDFGaussCannonProjectile) {
    
    FxUnitHitScale = 0.9,
    FxLandHitScale = 0.9,

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
TypeClass = TDFGauss04

