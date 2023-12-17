local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

-- Aeon Serpentine Missile
---@class AIFMissileSerpentine01: AMissileSerpentineProjectile
AIFMissileSerpentine01 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileSerpentine01
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        local trash = self.Trash

        self.MoveThread = TrashBagAdd(trash, ForkThread(self.MovementThread,self ))
    end,
}
TypeClass = AIFMissileSerpentine01
