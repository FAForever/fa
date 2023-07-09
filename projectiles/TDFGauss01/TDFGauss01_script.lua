local TDFGaussCannonProjectile = import("/lua/terranprojectiles.lua").TDFGaussCannonProjectile

-- Terran Gauss Cannon Projectile
---@class TDFGauss01: TDFGaussCannonProjectile
TDFGauss01 = ClassProjectile(TDFGaussCannonProjectile) {

    ---@param self TDFGauss01
    ---@param inWater? boolean
    OnCreate = function(self, inWater)
        TDFGaussCannonProjectile.OnCreate(self, inWater)
        if not inWater then
            self:SetDestroyOnWater(true)
        else
            self.Trash:Add(ForkThread(self.DestroyOnWaterThread,self))
        end
    end,

    ---@param self TDFGauss01
    DestroyOnWaterThread = function(self)
        WaitTicks(3)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = TDFGauss01

