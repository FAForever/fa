local AOblivionCannonProjectile = import("/lua/aeonprojectiles.lua").AOblivionCannonProjectile

--- Aeon Oblivion Cannon projectile
---@class ADFOblivionCannon01 : AOblivionCannonProjectile
ADFOblivionCannon03 = ClassProjectile(AOblivionCannonProjectile) {
	FxTrails = {'/effects/emitters/oblivion_cannon_munition_02_emit.bp'},
}
TypeClass = ADFOblivionCannon03