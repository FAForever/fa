local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- URL0111 : Cybran MML
--- Cybran "Loa" Tactical Missile, mobile unit launcher variant of this missile, lower and straighter trajectory. 
--- Splits into child projectile if it takes enough damage.
---@class CIFMissileTactical01 : CLOATacticalMissileProjectile
CIFMissileTactical01 = ClassProjectile(CLOATacticalMissileProjectile) {
    ChildCount = 3,
    SpreadMultiplier = 0.8,
    SpreadMultiplierRange = 0.1,

    LaunchTicks = 2,
    LaunchTurnRate = 0,
    HeightDistanceFactor = 4,
    MinHeight = 2,
    FinalBoostAngle = 50,

    FxUnitHitScale = 0.5,
    FxLandHitScale = 0.5,
    FxPropHitScale = 0.5,
    FxNoneHitScale = 0.5,
    FxKilledScale = 0.3,

    ---@param self CIFMissileTactical01
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,
}
TypeClass = CIFMissileTactical01