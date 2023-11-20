local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile

--- Cybran Proton Cannon
---@class CDFProtonCannon01 : CDFProtonCannonProjectile
CDFProtonCannon01 = ClassProjectile(CDFProtonCannonProjectile) {

    ---@param self CDFProtonCannon01
    OnCreate = function(self)
        CDFProtonCannonProjectile.OnCreate(self)
        self.Trash:Add(ForkThread(self.ImpactWaterThread, self))
    end,

    ---@param self CDFProtonCannon01
    ImpactWaterThread = function(self)
        WaitTicks(4)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CDFProtonCannon01