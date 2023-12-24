local CDFProtonCannonProjectile = import("/lua/cybranprojectiles.lua").CDFProtonCannonProjectile

-- upvalue for perfomance
local ForkThread = ForkThread
local WaitTicks = WaitTicks
local TrashBagAdd = TrashBag.Add

--- Cybran Proton Cannon
---@class CDFProtonCannon01 : CDFProtonCannonProjectile
CDFProtonCannon01 = ClassProjectile(CDFProtonCannonProjectile) {

    ---@param self CDFProtonCannon01
    OnCreate = function(self)
        CDFProtonCannonProjectile.OnCreate(self)
        local trash = self.Trash
        TrashBagAdd(trash,ForkThread(self.ImpactWaterThread, self))
    end,

    ---@param self CDFProtonCannon01
    ImpactWaterThread = function(self)
        WaitTicks(4)
        self:SetDestroyOnWater(true)
    end,
}
TypeClass = CDFProtonCannon01