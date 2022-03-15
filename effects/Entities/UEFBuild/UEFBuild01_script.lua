--
-- script for projectile UEFBuild01
--

local CreateEmitterOnEntity = CreateEmitterOnEntity

UEFBuild01 = Class(import('/lua/sim/projectile.lua').DummyProjectile) {

    OnCreate = function(self, spec)
        local army = self:GetArmy()
        CreateEmitterOnEntity(self, army, '/effects/emitters/build_terran_glow_01_emit.bp')
        CreateEmitterOnEntity(self, army, '/effects/emitters/build_sparks_blue_01_emit.bp')
    end,
}

TypeClass = UEFBuild01

