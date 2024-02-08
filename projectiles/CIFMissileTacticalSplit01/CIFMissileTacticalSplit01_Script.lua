local CLOATacticalChildMissileProjectile = import("/lua/cybranprojectiles.lua").CLOATacticalChildMissileProjectile

--- Cybran "Loa" Tactical Missile, child missiles that create when the mother projectile is shot down by
--- enemy anti-missile systems
---@class CIFMissileTacticalSplit01 : CLOATacticalChildMissileProjectile
CIFMissileTacticalSplit01 = ClassProjectile(CLOATacticalChildMissileProjectile) {}
TypeClass = CIFMissileTacticalSplit01
