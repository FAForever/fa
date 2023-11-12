local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFBigLandGaussCannonProjectile

--- Terran Gauss Cannon Projectile (UEL0401) Fatboy
---@class TDFGauss04: TDFBigLandGaussCannonProjectile
TDFGauss04 = ClassProjectile(TDFGaussCannonProjectile) {

    FxUnitHitScale = 0.9,
    FxLandHitScale = 0.9,

    ---@param self TDFGauss04
    ---@param inWater boolean
    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            self:SetDestroyOnWater(true)
        else
            self.Trash:Add(ForkThread(self.DestroyOnWaterThread,self))
        end
    end,

    ---@param self TDFGauss04
    DestroyOnWaterThread = function(self)
        WaitTicks(3)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TDFGauss04

