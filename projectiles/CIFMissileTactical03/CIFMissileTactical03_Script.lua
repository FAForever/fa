local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- URB2108 : cybran TML
--- Cybran "Loa" Tactical Missile, structure unit launched variant of this projectile,
--- with a higher arc and distance based adjusting trajectory. Splits into child projectile
--- if it takes enough damage.
---@class CIFMissileTactical03 : CLOATacticalMissileProjectile
CIFMissileTactical03 = ClassProjectile(CLOATacticalMissileProjectile) {
    ChildCount = 3,
    SpreadMultiplier = 0.25,


    LaunchTicks = 12,
    LaunchTicksRange = 2,

    LaunchTurnRate = 22,
    LaunchTurnRateRange = 2,

    HeightDistanceFactor = 4.5,
    HeightDistanceFactorRange = 0.4,

    MinHeight = 10,
    MinHeightRange = 1,

    FinalBoostAngle = 30,
    FinalBoostAngleRange = 0,


    ---@param self CLOATacticalMissileProjectile
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = CIFMissileTactical03