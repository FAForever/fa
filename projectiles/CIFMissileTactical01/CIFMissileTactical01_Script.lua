-- URL0111 : cybran MML
-- Cybran "Loa" Tactical Missile, mobile unit launcher variant of this missile, lower and straighter trajectory. 
-- Splits into child projectile if it takes enough damage.

local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- used by url0111
---@class CIFMissileTactical01 : CLOATacticalMissileProjectile
CIFMissileTactical01 = ClassProjectile(CLOATacticalMissileProjectile) {
    NumChildMissiles = 3,

    FxUnitHitScale = 0.5,
    FxLandHitScale = 0.5,
    FxPropHitScale = 0.5,
    FxNoneHitScale = 0.5,
    FxKilledScale = 0.3,

    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,
}
TypeClass = CIFMissileTactical01

