local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFMediumShipGaussCannonProjectile

-- Terran Gauss Cannon Projectile
---@class TDFGauss05: TDFGaussCannonProjectile
TDFGauss05 = ClassProjectile(TDFGaussCannonProjectile) {
    
    FxUnitHitScale = 1.6,
    FxLandHitScale = 1.6,

    ---@param self TDFGauss05
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            self:SetDestroyOnWater(true)
        else
            self.Trash:Add(ForkThread(self.DestroyOnWaterThread,self))
        end
    end,

    ---@param self TDFGauss05
    DestroyOnWaterThread = function(self)
        WaitTicks(3)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TDFGauss05

