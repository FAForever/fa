#
# Cybran Anti Air Projectile
#

-- Automatically upvalued moho functions for performance
local EntityMethods = _G.moho.entity_methods
local EntityMethodsSetMesh = EntityMethods.SetMesh

local GlobalMethods = _G
local GlobalMethodsCreateEmitterOnEntity = GlobalMethods.CreateEmitterOnEntity

local ProjectileMethods = _G.moho.projectile_methods
local ProjectileMethodsSetBallisticAcceleration = ProjectileMethods.SetBallisticAcceleration
-- End of automatically upvalued moho functions

CAANanoDartProjectile = import('/lua/cybranprojectiles.lua').CAANanoDartProjectile

CAANanoDart01 = Class(CAANanoDartProjectile)({

    OnCreate = function(self)
        CAANanoDartProjectile.OnCreate(self)
        self:ForkThread(self.UpdateThread)
    end,


    UpdateThread = function(self)
        WaitSeconds(0.1)
        ProjectileMethodsSetBallisticAcceleration(self, -0.5)

        for i in self.FxTrails do
            GlobalMethodsCreateEmitterOnEntity(self, self.Army, self.FxTrails[i])
        end

        WaitSeconds(0.2)
        EntityMethodsSetMesh(self, '/projectiles/CAANanoDart01/CAANanoDartUnPacked01_mesh')


    end,
})

TypeClass = CAANanoDart01
