-- Aeon Land-Based Tactical Missile

local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

---@class AIFMissileTactical02 : AMissileSerpentineProjectile
AIFMissileTactical02 = ClassProjectile(AMissileSerpentineProjectile) {

    ---@param self AIFMissileTactical02
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread, self ))
    end,
}
TypeClass = AIFMissileTactical02