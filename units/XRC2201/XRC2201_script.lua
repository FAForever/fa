--------------------------------------------------------------------------------
-- File :  /cdimage/units/XRC2201/XRC2201_script.lua
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local CCivilianStructureUnit = import("/lua/cybranunits.lua").CCivilianStructureUnit
local Util = import("/lua/utilities.lua")
local RandomFloat = Util.GetRandomFloat
local explosion = import("/lua/defaultexplosions.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class XRC2201 : CCivilianStructureUnit
XRC2201 = ClassUnit(CCivilianStructureUnit) {

    OnCreate = function(self, builder, layer)
        CCivilianStructureUnit.OnCreate(self)
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(3.5)
        end
    end,

    CreateExplosion02 = function(self, army)
        for k, v in EffectTemplate.ExplosionEffectsLrg02 do
            CreateAttachedEmitter(self, 'TargetBone01', army, v)
        end
    end,

    CreateDeathExplosionDustRing = function(self)
        local blanketSides = 18
        local blanketAngle = (2 * math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 2.8

        for i = 0, (blanketSides - 1) do
            local blanketX = math.sin(i * blanketAngle)
            local blanketZ = math.cos(i * blanketAngle)

            local Blanketparts = self:CreateProjectile('/effects/entities/DestructionDust01/DestructionDust01_proj.bp',
                blanketX, 1.5, blanketZ + 4, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
    end,

    CreateFirePlumes = function(self, army, bones, yBoneOffset)
        local proj, position, offset, velocity
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            position = self:GetPosition(vBone)
            offset = Util.GetDifferenceVector(position, basePosition)
            velocity = Util.GetDirectionVector(position, basePosition)
            velocity.x = velocity.x + RandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + RandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + RandomFloat(0.2, 0.5)
            proj = self:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp',
                offset.x, offset.y + yBoneOffset, offset.z, velocity.x, velocity.y, velocity.z)
            proj:SetBallisticAcceleration(RandomFloat(-1, -2)):SetVelocity(RandomFloat(3, 4)):
                SetCollision(false)

            local emitter = CreateEmitterOnEntity(proj, army,
                '/effects/emitters/destruction_explosion_fire_plume_03_emit.bp')
            local emitter = CreateEmitterOnEntity(proj, army,
                '/effects/emitters/destruction_explosion_fire_plume_04_emit.bp')

            local lifetime = Util.GetRandomFloat(12, 22)
        end
    end,

    CreateExplosionDebris = function(self, army)
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter(self, 'XRC2201', army, v)
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self.Army

        explosion.CreateFlash(self, 'XRC2201', 6.0, army)
        CreateAttachedEmitter(self, 'XRC2201', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp')
        CreateEmitterAtEntity(self, army, '/effects/emitters/destruction_damaged_smoke_03_emit.bp')
        CreateAttachedEmitter(self, 'XRC2201', army, '/effects/emitters/destruction_damaged_sparks_02_emit.bp')
        self:CreateFirePlumes(army, { 'XRC2201' }, 4)
        self:CreateFirePlumes(army, { 'XRC2201', 'XRC2201', 'XRC2201', 'XRC2201', }, 3.5)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        WaitTicks(11)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateDamageEffects('TargetBone01', army)
        self:CreateDamageEffects('TargetBone01', army)
        WaitTicks(11)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateFirePlumes(army, { 'XRC2201', 'XRC2201', 'XRC2201', 'XRC2201', }, 1.5)
        WaitTicks(4)
        self:CreateDeathExplosionDustRing()
        WaitTicks(5)
        self:ShakeCamera(50, 5, 0, 1)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        local x, y, z = unpack(self:GetPosition())
        z = z + 3
        DamageRing(self, { x, y, z }, 0.1, 3, 1, 'Force', true)
        WaitTicks(6)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        DamageRing(self, { x, y, z }, 0.1, 3, 1, 'Force', true)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateFirePlumes(army, { 'XRC2201' }, -1)
        self:CreateDamageEffects('TargetBone01', army)
        WaitTicks(6)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateDamageEffects('TargetBone03', army)
        WaitTicks(6)
        self:CreateExplosion02(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateDamageEffects('TargetBone03', army)
        WaitTicks(6)
        self:CreateExplosion02(army)
        explosion.CreateFlash(self, 'XRC2201', 3.0, army)
        self:CreateDamageEffects('TargetBone03', army)
        self:CreateWreckage(0.1)
        self:Destroy()
    end,

}

TypeClass = XRC2201

-- Kept for mod support
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone