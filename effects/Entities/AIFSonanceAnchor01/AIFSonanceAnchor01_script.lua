local NullShell = import("/lua/sim/defaultprojectiles.lua").NullShell

-- Invisible anchor for effects around the held Emissary shell (uab2302), placed and moved by the shell script
---@class AIFSonanceAnchor01 : NullShell
AIFSonanceAnchor01 = ClassProjectile(NullShell) {}
TypeClass = AIFSonanceAnchor01
