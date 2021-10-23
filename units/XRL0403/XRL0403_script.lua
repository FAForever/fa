-- ****************************************************************************
-- **
-- **  File     :  /units/XRL0403/XRL0403_script.lua
-- **
-- **  Summary  :  Megalith script
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************


local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local MobileUnit = import('/lua/defaultunits.lua').MobileUnit
local explosion = import('/lua/defaultexplosions.lua')
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone
local EffectTemplate = import('/lua/EffectTemplates.lua')
local utilities = import('/lua/Utilities.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local Entity = import('/lua/sim/Entity.lua').Entity

local Weapon = import('/lua/sim/Weapon.lua').Weapon
local CybranWeaponsFile = import('/lua/cybranweapons.lua')
local CDFHvyProtonCannonWeapon = CybranWeaponsFile.CDFHvyProtonCannonWeapon
local CANNaniteTorpedoWeapon = CybranWeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = CybranWeaponsFile.CIFSmartCharge
local CAABurstCloudFlakArtilleryWeapon = CybranWeaponsFile.CAABurstCloudFlakArtilleryWeapon
local CDFBrackmanCrabHackPegLauncherWeapon = CybranWeaponsFile.CDFBrackmanCrabHackPegLauncherWeapon

XRL0403 = Class(CWalkingLandUnit) {
    WalkingAnimRate = 1.2,

    Weapons = {
        ParticleGunRight = Class(CDFHvyProtonCannonWeapon) {},
        ParticleGunLeft = Class(CDFHvyProtonCannonWeapon) {},
        Torpedo01 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo02 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo03 = Class(CANNaniteTorpedoWeapon) {},
        Torpedo04 = Class(CANNaniteTorpedoWeapon) {},
        AntiTorpedo = Class(CIFSmartCharge) {},
        AAGun = Class(CAABurstCloudFlakArtilleryWeapon) {},
        HackPegLauncher= Class(CDFBrackmanCrabHackPegLauncherWeapon){},
    },

    DisableAllButHackPegLauncher= function(self)
        self:SetWeaponEnabledByLabel('ParticleGunRight', false) -- -- -- Disable all other weapons.
        self:SetWeaponEnabledByLabel('ParticleGunLeft', false)
        self:SetWeaponEnabledByLabel('AAGun', false)
        self:SetWeaponEnabledByLabel('Torpedo01', false)

        self:ShowBone('Missile_Turret', true)
    end,

    EnableHackPegLauncher= function(self)
        self:SetWeaponEnabledByLabel('HackPegLauncher', true)   -- -- -- Enable and show hack-peg launcher.
    end,

    OnCreate= function(self)
        CWalkingLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('HackPegLauncher', false)
        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end
    end,

    OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end
        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)

        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end

        if self.AnimationManipulator then
            self:SetUnSelectable(true)
            self.AnimationManipulator:SetRate(1)

            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration()*self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
    end,

    OnLayerChange = function(self, new, old)
        CWalkingLandUnit.OnLayerChange(self, new, old)

        --LOG("Mega Layerchange from ", old, " to ", new)

        if new == 'Land' then
            self:DisableUnitIntel('Layer', 'Sonar')
            -- Set movement speed to default
            self:SetSpeedMult(1)
        elseif new == 'Seabed' then
            self:EnableUnitIntel('Layer', 'Sonar')
            -- Increase speed while in water
            self:SetSpeedMult(self:GetBlueprint().Physics.WaterSpeedMultiplier)
        end
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
        end
    end,

    CreateDeathExplosionDustRing = function(self)
        local blanketSides = 18
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 2.8

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)

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
            velocity = utilities.GetDirectionVector(position, basePosition) --
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
            CreateAttachedEmitter(self, 'XRL0403', army, v):OffsetEmitter(0, 5, 0)
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self.Army

        -- Create Initial explosion effects
        explosion.CreateFlash(self, 'Left_Leg01_B01', 4.5, army)
        CreateAttachedEmitter(self, 'XRL0403', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp'):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self,'XRL0403', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp'):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self,'XRL0403', army, '/effects/emitters/distortion_ring_01_emit.bp')
        self:CreateFirePlumes(army, {'XRL0403'}, 0)

        self:CreateFirePlumes(army, {'Right_Leg01_B01','Right_Leg02_B01','Left_Leg02_B01',}, 0.5)

        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        WaitSeconds(1)

        -- Create damage effects on turret bone
        CreateDeathExplosion(self, 'Right_Turret_Barrel', 1.5)
        self:CreateDamageEffects('Right_Turret_Barrel', army)
        self:CreateDamageEffects('Left_Turret_Barrel', army)

        WaitSeconds(1)
        self:CreateFirePlumes(army, {'Right_Leg01_B01','Right_Leg02_B01','Left_Leg02_B01',}, 0.5)
        WaitSeconds(0.4)
        self:CreateDeathExplosionDustRing()
        
        -- only apply death damage when the unit is sufficiently build
        local bp = self:GetBlueprint()
        local FractionThreshold = bp.General.FractionThreshold or 0.99
        if self:GetFractionComplete() >= FractionThreshold then 
            local bp = self:GetBlueprint()
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if(bp.Weapon[i].Label == 'MegalithDeath') then
                    position[3] = position[3]+2.5*math.cos(a)
                    position[1] = position[1]+2.5*math.sin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end
        
        WaitSeconds(0.4)


        -- When the spider bot impacts with the ground
        -- Effects: Explosion on turret, dust effects on the muzzle tip, large dust ring around unit
        -- Other: Damage force ring to force trees over and camera shake
        self:ShakeCamera(40, 4, 1, 3.8)
        CreateDeathExplosion(self, 'Left_Turret_Barrel', 1)

        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        local x, y, z = unpack(self:GetPosition())
        z = z + 3
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Right_Turret', 2)

        -- Finish up force ring to push trees
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)

        -- Explosion on and damage fire on various bones
        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        CreateDeathExplosion(self, 'Flare_Muzzle03', 2)
        self:CreateFirePlumes(army, {'Torpedo_Muzzle11'}, -1)
        self:CreateDamageEffects('Right_Turret', army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        self:CreateDamageEffects('Right_Footfall_02', army)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Left_Turret_Muzzle01', 1)
        self:CreateExplosionDebris(army)

        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        self:CreateDamageEffects('Torpedo_Muzzle01', army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        CreateDeathExplosion(self, 'Flare_Muzzle06', 2)
        self:CreateDamageEffects('Left_Leg02_B02', army)
        explosion.CreateFlash(self, 'Right_Leg01_B01', 3.2, army)

        self:CreateWreckage(0.1)
        self:ShakeCamera(3, 2, 0, 0.15)
        self:Destroy()
    end,


    OnMotionHorzEventChange = function(self, new, old)
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)

        if (old == 'Stopped') then
            local bpDisplay = self:GetBlueprint().Display
            if bpDisplay.AnimationWalk and self.Animator then
                self.Animator:SetDirectionalAnim(true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate)
            end
         end
    end,
}

TypeClass = XRL0403
