-- Cybran Particle Cannon Projectile Script
local CParticleCannonProjectile = import("/lua/cybranprojectiles.lua").CParticleCannonProjectile

---@class CDFParticleCannon01 : CParticleCannonProjectile
CDFParticleCannon01 = ClassProjectile(CParticleCannonProjectile) {}
TypeClass = CDFParticleCannon01