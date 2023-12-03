local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Aeon Land-Based Tactical Missile
---@class AIFMissileTactical01 : AMissileSerpentineProjectile
AIFMissileTactical01 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileTactical01
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = AIFMissileTactical01