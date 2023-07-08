local TShellPhalanxProjectile = import('/lua/kirvesprojectiles.lua').TShellPhalanxProjectile

-- Terran AA Phalanx projectile
---@class TDPhalanx01: TShellPhalanxProjectile
TDPhalanx01 = ClassProjectile(TShellPhalanxProjectile) { }
TypeClass = TDPhalanx01