--------------------------------------------------------------------------
-- File     :  /cdimage/units/URL0402/URL0402_script.lua
-- Author(s):  John Comes, David Tomandl, Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Spider Bot Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------

local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local Weapon = import("/lua/sim/weapon.lua").Weapon
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFHeavyMicrowaveLaserGenerator = CybranWeaponsFile.CDFHeavyMicrowaveLaserGenerator
local CDFElectronBolterWeapon = CybranWeaponsFile.CDFElectronBolterWeapon
local CAAMissileNaniteWeapon = CybranWeaponsFile.CAAMissileNaniteWeapon
local explosion = import("/lua/defaultexplosions.lua")
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone
local EffectTemplate = import("/lua/effecttemplates.lua")
local utilities = import("/lua/utilities.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CANTorpedoLauncherWeapon = CybranWeaponsFile.CANTorpedoLauncherWeapon
local Entity = import("/lua/sim/entity.lua").Entity

---@class URL0402 : CWalkingLandUnit
URL0402 = ClassUnit(CWalkingLandUnit) {
    WalkingAnimRate = 1.2,

    Weapons = {
        MainGun = ClassWeapon(CDFHeavyMicrowaveLaserGenerator) {},
        RightLaserTurret = ClassWeapon(CDFElectronBolterWeapon) {},
        LeftLaserTurret = ClassWeapon(CDFElectronBolterWeapon) {},
        RightAntiAirMissile = ClassWeapon(CAAMissileNaniteWeapon) {},
        LeftAntiAirMissile = ClassWeapon(CAAMissileNaniteWeapon) {},
        Torpedo = ClassWeapon(CANTorpedoLauncherWeapon) {},
    },

    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self.AmbientExhaustEffectsBag = self.AmbientExhaustEffectsBag or TrashBag()
        self.Trash:Add(self.AmbientExhaustEffectsBag)
    end,

    DestroyAllTrashBags = function(self)
        CWalkingLandUnit.DestroyAllTrashBags(self)
        self.AmbientExhaustEffectsBag:Destroy()
    end,

    OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:CreateUnitAmbientEffect(self.Layer)
        if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(1)

            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration() * self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
        self:SetMaintenanceConsumptionActive()
    end,

    OnLayerChange = function(self, new, old)
        CWalkingLandUnit.OnLayerChange(self, new, old)
        self:CreateUnitAmbientEffect(new)
        if new == 'Seabed' then
            self:EnableUnitIntel('Layer', 'Sonar')
        else
            self:DisableUnitIntel('Layer', 'Sonar')
        end
    end,

    AmbientExhaustBones = {
        'Exhaust01',
        'Exhaust02',
        'Exhaust03',
        'Exhaust06',
        'Exhaust05',
    },

    AmbientLandExhaustEffects = {
        '/effects/emitters/dirty_exhaust_smoke_02_emit.bp',
        '/effects/emitters/dirty_exhaust_sparks_02_emit.bp',
    },

    AmbientSeabedExhaustEffects = {
        '/effects/emitters/underwater_vent_bubbles_02_emit.bp',
    },

    CreateUnitAmbientEffect = function(self, layer)
        if self:GetFractionComplete() ~= 1 then
            return
        end

        self.AmbientExhaustEffectsBag = self.AmbientExhaustEffectsBag or TrashBag()
        self.AmbientExhaustEffectsBag:Destroy()
        if layer == 'Land' then
            self.AmbientExhaustEffectsBag:Add(ForkThread(self.UnitLandAmbientEffectThread, self))
        elseif layer == 'Seabed' then
            local army = self.Army
            for _, vE in self.AmbientSeabedExhaustEffects do
                for _, vB in self.AmbientExhaustBones do
                    self.AmbientExhaustEffectsBag:Add(CreateAttachedEmitter(self, vB, army, vE))
                end
            end
        end
    end,

    UnitLandAmbientEffectThread = function(self)
        while not self.Dead do
            local army = self.Army

            for _, vE in self.AmbientLandExhaustEffects do
                for _, vB in self.AmbientExhaustBones do
                    self.AmbientExhaustEffectsBag:Add(CreateAttachedEmitter(self, vB, army, vE))
                end
            end

            WaitSeconds(2)
            EffectUtil.CleanupEffectBag(self, 'AmbientExhaustEffectsBag')

            WaitSeconds(utilities.GetRandomFloat(1, 7))
        end
    end,

    OnKilled = function(self, inst, type, okr)
        CWalkingLandUnit.OnKilled(self, inst, type, okr)
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
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

            local Blanketparts = self:CreateProjectile('/effects/entities/DestructionDust01/DestructionDust01_proj.bp', blanketX, 1.5, blanketZ + 4, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
    end,

    CreateFirePlumes = function(self, army, bones, yBoneOffset)
        local proj, position, offset, velocity
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            position = self:GetPosition(vBone)
            offset = utilities.GetDifferenceVector(position, basePosition)
            velocity = utilities.GetDirectionVector(position, basePosition)
            velocity.x = velocity.x + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + utilities.GetRandomFloat(0.0, 0.3)
            proj = self:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', offset.x, offset.y + yBoneOffset, offset.z, velocity.x, velocity.y, velocity.z)
            proj:SetBallisticAcceleration(utilities.GetRandomFloat(-1, -2)):SetVelocity(utilities.GetRandomFloat(3, 4)):SetCollision(false)

            local emitter = CreateEmitterOnEntity(proj, army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')

            local lifetime = utilities.GetRandomFloat(12, 22)
        end
    end,

    CreateExplosionDebris = function(self, army)
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter(self, 'URL0402', army, v)
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self.Army

        -- Create Initial explosion effects
        explosion.CreateFlash(self, 'Center_Turret', 4.5, army)
        CreateAttachedEmitter(self, 'URL0402', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp')
        CreateAttachedEmitter(self, 'URL0402', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp')
        self:CreateFirePlumes(army, {'Center_Turret'}, 0)

        self:CreateFirePlumes(army, {'Right_Leg01_B01', 'Right_Leg03_B01', 'Left_Leg03_B01', }, 0.5)

        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        WaitSeconds(1)

        -- Create damage effects on turret bone
        CreateDeathExplosion(self, 'Center_Turret', 1.5)
        self:CreateDamageEffects('Center_Turret_B01', army)
        self:CreateDamageEffects('Center_Turret_Barrel', army)

        WaitSeconds(1)
        self:CreateFirePlumes(army, {'Right_Leg01_B01', 'Right_Leg03_B01', 'Left_Leg03_B01', }, 0.5)
        WaitSeconds(0.3)
        self:CreateDeathExplosionDustRing()
        WaitSeconds(0.4)


        -- When the spider bot impacts with the ground
        -- Effects: Explosion on turret, dust effects on the muzzle tip, large dust ring around unit
        -- Other: Damage force ring to force trees over and camera shake
        self:ShakeCamera(50, 5, 0, 1)
        CreateDeathExplosion(self, 'Left_Turret_Muzzle', 1)
        for k, v in EffectTemplate.FootFall01 do
            CreateAttachedEmitter(self, 'Center_Turret_Muzzle', army, v):ScaleEmitter(2)
            CreateAttachedEmitter(self, 'Center_Turret_Muzzle', army, v):ScaleEmitter(2)
        end


        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        local x, y, z = unpack(self:GetPosition())
        z = z + 3

        -- only apply death damage when the unit is sufficiently build
        local bp = self:GetBlueprint()
        local FractionThreshold = bp.General.FractionThreshold or 0.99
        if self:GetFractionComplete() >= FractionThreshold then 
            local bp = self:GetBlueprint()
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if bp.Weapon[i].Label == 'SpiderDeath' then
                    position[3] = position[3]+3*math.cos(a)
                    position[1] = position[1]+3*math.sin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end

        DamageRing(self, {x, y,z}, 0.1, 3, 1, 'Force', true)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Center_Turret', 2)

        -- Finish up force ring to push trees
        DamageRing(self, {x, y,z}, 0.1, 3, 1, 'Force', true)

        -- Explosion on and damage fire on various bones
        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1, 3) .. '_B0' .. Random(1, 3), 0.25)
        CreateDeathExplosion(self, 'Left_Projectile01', 2)
        self:CreateFirePlumes(army, {'Left_Projectile01'}, -1)
        self:CreateDamageEffects('Right_Turret', army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1, 3) .. '_B0' .. Random(1, 3), 0.25)
        self:CreateDamageEffects('Right_Leg01_B03', army)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Left_Turret_Muzzle', 1)
        self:CreateExplosionDebris(army)

        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1, 3) .. '_B0' .. Random(1, 3), 0.25)
        self:CreateDamageEffects('Right_Projectile0' .. Random(1, 2), army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1, 3) .. '_B0' .. Random(1, 3), 0.25)
        CreateDeathExplosion(self, 'Left_Projectile01', 2)
        self:CreateDamageEffects('Left_Leg03_B03', army)

        self:CreateWreckage(0.1)
        self:Destroy()
    end,
}

TypeClass = URL0402
