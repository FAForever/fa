-- 
-- URS0304 : cybran nuke sub
-- Cybran "Loa" Tactical Missile, structure unit and sub launched variant of this projectile,
-- with a higher arc and distance based adjusting trajectory. Splits into child projectile 
-- if it takes enough damage.
-- 
local CLOATacticalMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalMissileProjectile

--- used by urs0304
---@class CIFMissileTactical02 : CLOATacticalMissileProjectile
CIFMissileTactical02 = ClassProjectile(CLOATacticalMissileProjectile) {

    NumChildMissiles = 3,

    ---@param self CIFMissileTactical02
    OnCreate = function(self)
        CLOATacticalMissileProjectile.OnCreate(self)
        self.MoveThread = self.Trash:Add(ForkThread( self.MovementThread,self ))
    end,
}
TypeClass = CIFMissileTactical02

