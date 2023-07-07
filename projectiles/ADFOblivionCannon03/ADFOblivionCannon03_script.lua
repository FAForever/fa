-- Aeon Oblivion Cannon projectile
---@class ADFOblivionCannon03: AOblivionCannonProjectile
ADFOblivionCannon03 = ClassProjectile(import("/lua/aeonprojectiles.lua").AOblivionCannonProjectile) {
	FxTrails = {'/effects/emitters/oblivion_cannon_munition_02_emit.bp'},
}
TypeClass = ADFOblivionCannon03