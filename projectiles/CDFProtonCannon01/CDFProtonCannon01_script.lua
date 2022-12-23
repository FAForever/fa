--
-- CDFProtonCannon01
--
local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile
CDFProtonCannon01 = Class(CDFProtonCannonProjectile) {
    
    OnCreate = function(self)
        CDFProtonCannonProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.ImpactWaterThread))
    end,
    
    ImpactWaterThread = function(self)
        WaitTicks(3)
        self:SetDestroyOnWater(true)
    end,
    

}
TypeClass = CDFProtonCannon01

