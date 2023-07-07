-- Aeon Bomb

local ABombProjectile = import("/lua/aeonprojectiles.lua").AGravitonBombProjectile

---@class AIFBombGraviton01: ABombProjectile
AIFBombGraviton01 = ClassProjectile(ABombProjectile) {}
TypeClass = AIFBombGraviton01