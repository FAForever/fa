--------------------------------------------------------------------------------
-- File :  /units/XRL0403/XRL0403_script.lua
-- Summary  :  Megalith script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local explosion = import("/lua/defaultexplosions.lua")
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone
local EffectTemplate = import("/lua/EffectTemplates.lua")
local utilities = import("/lua/utilities.lua")
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFHvyProtonCannonWeapon = CybranWeaponsFile.CDFHvyProtonCannonWeapon
local CANNaniteTorpedoWeapon = CybranWeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = CybranWeaponsFile.CIFSmartCharge
local CAABurstCloudFlakArtilleryWeapon = CybranWeaponsFile.CAABurstCloudFlakArtilleryWeapon
local CDFBrackmanCrabHackPegLauncherWeapon = CybranWeaponsFile.CDFBrackmanCrabHackPegLauncherWeapon

local CConstructionTemplate = import("/lua/cybranunits.lua").CConstructionTemplate

---@class XRL0403 : CWalkingLandUnit, CConstructionTemplate
XRL0403 = ClassUnit(CWalkingLandUnit, CConstructionTemplate) {
    WalkingAnimRate = 1.2,

    BotBlueprintId = 'ura0001o',
    BotBone = 'Centraltgt',

    Weapons = {
        ParticleGunRight = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        ParticleGunLeft = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo02 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo03 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo04 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo = ClassWeapon(CIFSmartCharge) {},
        AAGun = ClassWeapon(CAABurstCloudFlakArtilleryWeapon) {},
        HackPegLauncher = ClassWeapon(CDFBrackmanCrabHackPegLauncherWeapon) {},
    },

    ---@param self XRL0403
    DisableAllButHackPegLauncher = function(self)
        self:SetWeaponEnabledByLabel('ParticleGunRight', false)
        self:SetWeaponEnabledByLabel('ParticleGunLeft', false)
        self:SetWeaponEnabledByLabel('AAGun', false)
        self:SetWeaponEnabledByLabel('Torpedo01', false)
        self:ShowBone('Missile_Turret', true)
    end,

    ---@param self XRL0403
    EnableHackPegLauncher = function(self)
        self:SetWeaponEnabledByLabel('HackPegLauncher', true)
    end,

    ---@param self XRL0403 |m
    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        CConstructionTemplate.OnCreate(self)

        self:SetWeaponEnabledByLabel('HackPegLauncher', false)
        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end
    end,

    ---@param self CConstructionUnit
    DestroyAllBuildEffects = function(self)
        CWalkingLandUnit.DestroyAllBuildEffects(self)
        CConstructionTemplate.DestroyAllBuildEffects(self)
    end,

   ---@param self CConstructionUnit
    ---@param built boolean
    StopBuildingEffects = function(self, built)
        CWalkingLandUnit.StopBuildingEffects(self, built)
        CConstructionTemplate.StopBuildingEffects(self, built)
    end,

    ---@param self CConstructionUnit
    OnPaused = function(self)
        CWalkingLandUnit.OnPaused(self)
        CConstructionTemplate.OnPaused(self)
    end,

    ---@param self CConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order number
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CConstructionTemplate.CreateBuildEffects(self, unitBeingBuilt, order, true)
    end,

    ---@param self CConstructionUnit
    OnDestroy = function(self) 
        CWalkingLandUnit.OnDestroy(self)
        CConstructionTemplate.OnDestroy(self)
    end,

    ---@param self XRL0403
    ---@param builder Unit
    ---@param layer Layer
    OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end

        self.AnimationManipulator:PlayAnim(self.Blueprint.Display.AnimationActivate, false):SetRate(0)

        self:SetCollisionShape(
            'Box',
            self.Blueprint.CollisionOffsetX,
            self.Blueprint.CollisionOffsetY,
            self.Blueprint.CollisionOffsetZ,
            0.5 * self.Blueprint.SizeX,
            0.5 * self.Blueprint.SizeY,
            0.5 * self.Blueprint.SizeZ
        )

    end,

    ---@param self XRL0403
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        self:SetCollisionShape('Box',
            2 * self.Blueprint.CollisionOffsetX,
            2 * self.Blueprint.CollisionOffsetY,
            2 * self.Blueprint.CollisionOffsetZ,
            0.5 * self.Blueprint.SizeX,
            0.5 * self.Blueprint.SizeY,
            0.5 * self.Blueprint.SizeZ
        )

        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end

        if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(1)

            self.Trash:Add(ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration() * self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end, self))
        end
    end,

    ---@param self XRL0403
    OnLayerChange = function(self, new, old)
        CWalkingLandUnit.OnLayerChange(self, new, old)

        if new == 'Land' then
            self:DisableUnitIntel('Layer', 'Sonar')
            self:SetSpeedMult(1)
        elseif new == 'Seabed' then
            self:EnableUnitIntel('Layer', 'Sonar')
            self:SetSpeedMult(self.Blueprint.Physics.WaterSpeedMultiplier or 1)
        end
    end,

    ---@param self XRL0403
    OnMotionHorzEventChange = function(self, new, old)
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)

        if (old == 'Stopped') then
            local bpDisplay = self.Blueprint.Display
            if bpDisplay.AnimationWalk and self.Animator then
                self.Animator:SetDirectionalAnim(true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate)
            end
        end
    end,

    ---@param self XRL0403
    DeathThread = function(self)
        -- local scope for performance
        local army = self.Army
        local position = self:GetPosition()
        local CreateFirePlumes = explosion.CreateFirePlumes
        local CreateLargeDebrisEmitters = explosion.CreateLargeDebrisEmitters
        local CreateDefaultHitExplosionAtBone = explosion.CreateDefaultHitExplosionAtBone
        local CreateDamageEmitters = explosion.CreateDamageEmitters

        -- matches the death animation
        self:PlayUnitSound('Destroyed')

        explosion.CreateFlash(self, 'Left_Leg01_B01', 4.5, army)
        CreateAttachedEmitter(self, 'XRL0403', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp')
            :OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self, 'XRL0403', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp')
            :OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self, 'XRL0403', army, '/effects/emitters/distortion_ring_01_emit.bp')
        CreateFirePlumes(self, army, { 'XRL0403' }, 0)
        CreateFirePlumes(self, army, { 'Right_Leg01_B01', 'Right_Leg02_B01', 'Left_Leg02_B01', }, 0.5)

        CreateLargeDebrisEmitters(self, army, 'XRL0403')
        CreateLargeDebrisEmitters(self, army, 'XRL0403')
        CreateLargeDebrisEmitters(self, army, 'XRL0403')

        WaitTicks(10)

        CreateDefaultHitExplosionAtBone(self, 'Right_Turret_Barrel', 1.5)
        CreateDamageEmitters(self, 'Right_Turret_Barrel', army, 1.5)
        CreateDamageEmitters(self, 'Left_Turret_Barrel', army, 1.5)

        WaitTicks(10)

        CreateFirePlumes(self, army, { 'Right_Leg01_B01', 'Right_Leg02_B01', 'Left_Leg02_B01', }, 0.5)

        WaitTicks(4)

        local bp = self.Blueprint
        local FractionThreshold = bp.General.FractionThreshold or 0.99
        if self:GetFractionComplete() >= FractionThreshold then
            local bp = self.Blueprint
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if (bp.Weapon[i].Label == 'MegalithDeath') then
                    position[3] = position[3] + 2.5 * math.cos(a)
                    position[1] = position[1] + 2.5 * math.sin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType,
                        bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end

        WaitTicks(4)

        -- this is where the megalith impacts with the ground

        self:ShakeCamera(40, 4, 1, 3.8)
        CreateDefaultHitExplosionAtBone(self, 'Left_Turret_Barrel', 1)
        CreateLargeDebrisEmitters(self, army, 'XRL0403')
        CreateLargeDebrisEmitters(self, army, 'XRL0403')

        local bonePosition
        bonePosition = self:GetPosition('Right_Leg02_B01')
        DamageArea(self, bonePosition, 4, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Right_Leg01_B01')
        DamageArea(self, bonePosition, 4, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Left_Leg02_B01')
        DamageArea(self, bonePosition, 4, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Left_Leg01_B01')
        DamageArea(self, bonePosition, 4, 1, "TreeForce", false, false)

        WaitTicks(1)

        bonePosition = self:GetPosition('Right_Footfall_01')
        DamageArea(self, bonePosition, 3, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Right_Footfall_02')
        DamageArea(self, bonePosition, 3, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Left_Footfall_02')
        DamageArea(self, bonePosition, 3, 1, "TreeForce", false, false)
        bonePosition = self:GetPosition('Left_Footfall_02')
        DamageArea(self, bonePosition, 3, 1, "TreeForce", false, false)


        CreateDefaultHitExplosionAtBone(self, 'Right_Turret', 2)
        CreateDefaultHitExplosionAtBone(self, 'Right_Leg0' .. Random(1, 2) .. '_B0' .. Random(1, 2), 0.25)
        CreateDefaultHitExplosionAtBone(self, 'Flare_Muzzle03', 2)
        CreateFirePlumes(self, army, { 'Torpedo_Muzzle11' }, -1)
        CreateDamageEmitters(self, 'Right_Turret', army, 1.5)

        WaitTicks(1)

        CreateDefaultHitExplosionAtBone(self, 'Left_Leg0' .. Random(1, 2) .. '_B0' .. Random(1, 2), 0.25)
        CreateDamageEmitters(self, 'Right_Footfall_02', army, 1.5)

        WaitTicks(1)

        CreateDefaultHitExplosionAtBone(self, 'Left_Turret_Muzzle01', 1)
        CreateLargeDebrisEmitters(self, army, 'XRL0403')
        CreateDefaultHitExplosionAtBone(self, 'Right_Leg0' .. Random(1, 2) .. '_B0' .. Random(1, 2), 0.25)
        CreateDamageEmitters(self, 'Torpedo_Muzzle01', army, 1.5)

        WaitTicks(1)

        CreateDefaultHitExplosionAtBone(self, 'Left_Leg0' .. Random(1, 2) .. '_B0' .. Random(1, 2), 0.25)
        CreateDefaultHitExplosionAtBone(self, 'Flare_Muzzle06', 2)
        CreateDamageEmitters(self, 'Left_Leg02_B02', army, 1.5)
        explosion.CreateFlash(self, 'Right_Leg01_B01', 3.2, army)
        self:CreateWreckage(0.1)
        self:ShakeCamera(3, 2, 0, 0.15)
        self:Destroy()
    end,

    ---@deprecated
    ---@param self XRL0403
    ---@param bone Bone
    ---@param army Army
    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
        end
    end,

    ---@deprecated
    ---@param self XRL0403
    CreateDeathExplosionDustRing = function(self)
        local blanketSides = 18
        local blanketAngle = (2 * math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 2.8

        for i = 0, (blanketSides - 1) do
            local blanketX = math.sin(i * blanketAngle)
            local blanketZ = math.cos(i * blanketAngle)

            local Blanketparts = self:CreateProjectile(
                '/effects/entities/DestructionDust01/DestructionDust01_proj.bp',
                blanketX, 1.5,
                blanketZ + 4,
                blanketX, 0,
                blanketZ
            ):SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
    end,

    ---@deprecated
    ---@param self XRL0403
    ---@param army Army
    ---@param bones Bone[]
    ---@param yBoneOffset number
    CreateFirePlumes = function(self, army, bones, yBoneOffset)
        local proj, position, offset, velocity
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            position = self:GetPosition(vBone)
            offset = utilities.GetDifferenceVector(position, basePosition)
            velocity = utilities.GetDirectionVector(position, basePosition) --
            velocity.x = velocity.x + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + utilities.GetRandomFloat(0.0, 0.3)
            proj = self:CreateProjectile(
                '/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp',
                offset.x,
                offset.y + yBoneOffset,
                offset.z,
                velocity.x,
                velocity.y,
                velocity.z
            )
            proj:SetBallisticAcceleration(utilities.GetRandomFloat(-1, -2)):SetVelocity(utilities.GetRandomFloat(3, 4)):
                SetCollision(false)

            local emitter = CreateEmitterOnEntity(proj, army,
                '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')

            local lifetime = utilities.GetRandomFloat(12, 22)
        end
    end,

    ---@deprecated
    ---@param self XRL0403
    ---@param army Army
    CreateExplosionDebris = function(self, army)
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter(self, 'XRL0403', army, v):OffsetEmitter(0, 5, 0)
        end
    end,
}

TypeClass = XRL0403

--- Kept for mod support
local EffectUtil = import('/lua/EffectUtilities.lua')
local Entity = import("/lua/sim/entity.lua").Entity
local Weapon = import("/lua/sim/weapon.lua").Weapon
local MobileUnit = import("/lua/defaultunits.lua").MobileUnit
