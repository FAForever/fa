-- File     :  /data/projectiles/SDFHeavyQuarnonCannon01/SDFHeavyQuarnonCannon01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Heavy Quarnon Cannon Projectile script, XSS0302
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------------------
local SHeavyQuarnonCannon = import('/lua/seraphimprojectiles.lua').SHeavyQuarnonCannon

---@class SDFHeavyQuarnonCannon01 : SHeavyQuarnonCannon
SDFHeavyQuarnonCannon01 = ClassProjectile(SHeavyQuarnonCannon) {}
TypeClass = SDFHeavyQuarnonCannon01