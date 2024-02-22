local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

-- Aeon Land-Based Tactical Missile
---@class AIFMissileTactical02 : AMissileSerpentineProjectile
AIFMissileTactical02 = ClassProjectile(AMissileSerpentineProjectile) {

    TerminalZigZagMultiplier = 0.5,

    ---@param self AIFMissileTactical02
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread, self ))
    end,
}
TypeClass = AIFMissileTactical02