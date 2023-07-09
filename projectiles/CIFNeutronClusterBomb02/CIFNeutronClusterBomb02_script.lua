-- File     :  /projectiles/CIFNeutronClusterBomb02/CIFNeutronClusterBomb02.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Cybran Neutron Cluster bomb
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------
local CNeutronClusterBombChildProjectile = import("/lua/cybranprojectiles.lua").CNeutronClusterBombChildProjectile

---@class CIFNeutronClusterBomb02 : CNeutronClusterBombChildProjectile  
CIFNeutronClusterBomb02 = ClassProjectile(CNeutronClusterBombChildProjectile) {}
TypeClass = CIFNeutronClusterBomb02