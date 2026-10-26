local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

-- Invisible anchor for effects around the held Emissary shell (uab2302), placed and moved by the shell script
---@class AIFSonance02Anchor : NullShell
AIFSonance02Anchor = ClassProjectile(NullShell) {}
TypeClass = AIFSonance02Anchor
