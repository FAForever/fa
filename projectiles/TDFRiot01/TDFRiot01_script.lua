local TShellRiotProjectile = import("/lua/terranprojectiles.lua").TShellRiotProjectile

-- Terran Riot basic projectile
---@class TDFRiot01 : TShellRiotProjectile
TDFRiot01 = ClassProjectile(TShellRiotProjectile) {
	FxImpactTrajectoryAligned = false,
}
TypeClass = TDFRiot01