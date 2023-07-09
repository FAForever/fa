-- File     :  /projectiles/CIFNeutronClusterBomb01/CIFNeutronClusterBomb01.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Neutron Cluster bomb
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------
local CNeutronClusterBombProjectile = import("/lua/cybranprojectiles.lua").CNeutronClusterBombProjectile

---@class CIFNeutronClusterBomb03 : CNeutronClusterBombProjectile
CIFNeutronClusterBomb03 = ClassProjectile(CNeutronClusterBombProjectile) {}
TypeClass = CIFNeutronClusterBomb03