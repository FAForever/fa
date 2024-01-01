local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Used by ual0111 (T2 Mobile Missile Launcher)
---@class AIFMissileSerpentine01: AMissileSerpentineProjectile
AIFMissileSerpentine01 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileSerpentine01
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = AIFMissileSerpentine01
