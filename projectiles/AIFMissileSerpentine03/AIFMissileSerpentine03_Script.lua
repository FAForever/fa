local AMissileSerpentineProjectile = import("/lua/aeonprojectiles.lua").AMissileSerpentine02Projectile

-- upvalue for performance
local ForkThread = ForkThread
local TrashBagAdd = TrashBag.Add

--- Serpentine Missile 03 : XAS0306
---@class AIFMissileTactical03: AMissileSerpentineProjectile
AIFMissileTactical03 = ClassProjectile(AMissileSerpentineProjectile) {

    -- separate trajectory components to make it feel like a barrage
    LaunchTicks = 26,
    LaunchTicksRange = 10,
    LaunchTurnRate = 6,
    LaunchTurnRateRange = 2,
    HeightDistanceFactor = 5,
    MinHeight = 10,
    FinalBoostAngle = 45,

    ---@param self AIFMissileTactical03
    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)

        local trash = self.Trash
        self:SetCollisionShape('Sphere', 0, 0, 0, 3.0)
        self.MoveThread = TrashBagAdd(trash, ForkThread(self.MovementThread, self))
    end,
}
TypeClass = AIFMissileTactical03

--- backwards compatibility
AIFMissileTactical02 = AIFMissileTactical03