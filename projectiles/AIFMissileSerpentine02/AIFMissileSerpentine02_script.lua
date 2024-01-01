local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentineProjectile

--- Used by UAS0304 (T3 Stategic Missile Submarine)
---@class AIFMissileSerpentine02 : AMissileSerpentineProjectile
AIFMissileSerpentine02 = ClassProjectile(AMissileSerpentineProjectile) {
    FxWaterHitScale = 1.65,

    ---@param self AIFMissileSerpentine02
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread, self))
    end,
}
TypeClass = AIFMissileSerpentine02