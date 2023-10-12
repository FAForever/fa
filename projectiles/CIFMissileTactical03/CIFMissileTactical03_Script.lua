-- 
-- URB2108 : cybran TML
-- Cybran "Loa" Tactical Missile, structure unit launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
-- 
local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- used by urb2108
---@class CIFMissileTactical03 : CLOATacticalMissileProjectile
CIFMissileTactical03 = ClassProjectile(CLOATacticalMissileProjectile) {
    NumChildMissiles = 3,

    ---@param self CLOATacticalMissileProjectile
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = CIFMissileTactical03