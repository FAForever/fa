--
-- CDFProtonCannon01
--
local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile
CDFProtonCannon01 = ClassProjectile(CDFProtonCannonProjectile) {
    OnCreate = function(self)
        CDFProtonCannonProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.ImpactWaterThread, self))
    end,

    ImpactWaterThread = function(self)
        WaitTicks(4)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CDFProtonCannon01