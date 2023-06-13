-- Terran Ship-based torpedo

local TTorpedoShipProjectile = import("/lua/terranprojectiles.lua").TTorpedoShipProjectile

---@class TorpedoShipTerran01 : TTorpedoShipProjectile
TorpedoShipTerran01 = ClassProjectile(TTorpedoShipProjectile) {}
TypeClass = TorpedoShipTerran01
