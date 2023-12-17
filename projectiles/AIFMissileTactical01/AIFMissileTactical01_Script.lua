local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- Aeon Land-Based Tactical Missile
---@class AIFMissileTactical01 : AMissileSerpentineProjectile
AIFMissileTactical01 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileTactical01
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        local trash = self.Trash
        self.MoveThread = TrashBagAdd(trash, ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = AIFMissileTactical01