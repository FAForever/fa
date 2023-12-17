local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- Aeon Serpentine Missile
---@class AIFMissileSerpentine02 : AMissileSerpentineProjectile
AIFMissileSerpentine02 = ClassProjectile(AMissileSerpentineProjectile) {
    FxWaterHitScale = 1.65,

    ---@param self AIFMissileSerpentine02
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        local trash = self.Trash

        self.MoveThread = TrashBagAdd(trash, ForkThread(self.MovementThread, self))
    end,
}
TypeClass = AIFMissileSerpentine02