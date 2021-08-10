--****************************************************************************
--**
--**  File     :  /data/projectiles/CANKrilTorpedo01/CANKrilTorpedo01_script.lua
--**  Author(s):  Gordon Duclos, Matt Vainio
--**
--**  Summary  :  Kril Torpedo Projectile script, XRB2308
--**
--**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local CKrilTorpedo = import('/lua/cybranprojectiles.lua').CKrilTorpedo

CANKrilTorpedo01 = Class(CKrilTorpedo) {

    FxEnterWater= { '/effects/emitters/water_splash_ripples_ring_01_emit.bp',
                    '/effects/emitters/water_splash_plume_01_emit.bp',},                    
	TrailDelay = 2,                    

    OnCreate = function(self)
        CKrilTorpedo.OnCreate(self, true)
        self:SetCollisionShape('Sphere', 0, 0, 0, 1.0)
    end,	
    
    OnEnterWater = function(self)
        CKrilTorpedo.OnEnterWater(self)
        local army = self.Army
        for i in self.FxEnterWater do --splash
            CreateEmitterAtEntity(self,army,self.FxEnterWater[i])
        end
    end,    
}
TypeClass = CANKrilTorpedo01