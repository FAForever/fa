-- File     :  /data/projectiles/SANAjelluAntiTorpedo01/SANAjelluAntiTorpedo01_script.lua
-- Author(s):  Gordon Duclos
-- Summary  :  Seraphim Ajellu Torpedo Defense Projectile script, XSS0201, XSS0203, XSB2205
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------------------------------
SANAjelluAntiTorpedo01 = ClassProjectile(import("/lua/seraphimprojectiles.lua").SAnjelluTorpedoDefenseProjectile) {
	OnLostTarget = function(self)
        self:SetAcceleration(-3.6)
        self:SetLifetime(0.5)
    end,
}
TypeClass = SANAjelluAntiTorpedo01