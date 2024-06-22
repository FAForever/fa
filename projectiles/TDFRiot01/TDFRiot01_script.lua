--- Terran Riot basic projectile
---@class TDFRiot01: TShellRiotProjectile
TDFRiot01 = ClassProjectile(import("/lua/terranprojectiles.lua").TShellRiotProjectile) {
	FxImpactTrajectoryAligned = false,
}
TypeClass = TDFRiot01