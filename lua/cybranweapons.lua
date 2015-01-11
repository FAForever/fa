--****************************************************************************
--**
--**  File     :  /lua/cybranweapons.lua
--**  Author(s):  David Tomandl, John Comes, Gordon Duclos
--**
--**  Summary  :  Cybran weapon definitions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local CollisionBeamFile = import('defaultcollisionbeams.lua')
local Explosion = import('defaultexplosions.lua')
local EffectTemplate = import('/lua/EffectTemplates.lua')
local Util = import('utilities.lua')

CDFBrackmanCrabHackPegLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/proton_cannon_muzzle_01_emit.bp',
                     '/effects/emitters/proton_cannon_muzzle_02_emit.bp',},
}

CDFParticleCannonWeapon = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ParticleCannonCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_01_emit.bp'},
}

CDFProtonCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/proton_cannon_muzzle_01_emit.bp',
                     '/effects/emitters/proton_cannon_muzzle_02_emit.bp',},
}

CDFHvyProtonCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CHvyProtonCannonMuzzleflash,
}

CDFOverchargeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperOverChargeFlash01,
}

-- COMMANDER ENHANCEMENT WEAPON!
CDFHeavyMicrowaveLaserGeneratorCom = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function( self )
        if not self:EconomySupportsBeam() then return end
        local army = self.unit:GetArmy()
        local bp = self:GetBlueprint()
        for k, v in self.FxUpackingChargeEffects do
            for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
            end
        end
        DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
    end,
}

-- SPIDER BOT WEAPON!
CDFHeavyMicrowaveLaserGenerator = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam01,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    IdleState = State(DefaultBeamWeapon.IdleState) {
        Main = function(self)
            if self.RotatorManip then
                self.RotatorManip:SetTargetSpeed(0)
                self.RotatorManip:SetAccel(90)
            end
            if self.SliderManip then
                self.SliderManip:SetGoal(0,0,0)
                self.SliderManip:SetSpeed(2)
            end
            DefaultBeamWeapon.IdleState.Main(self)
        end,
    },

    CreateProjectileAtMuzzle = function(self, muzzle)
        if not self.SliderManip then
            self.SliderManip = CreateSlider(self.unit, 'Center_Turret_Barrel')
            self.unit.Trash:Add(self.SliderManip)
        end
        if not self.RotatorManip then
            self.RotatorManip = CreateRotator(self.unit, 'Center_Turret_Barrel', 'z')
            self.unit.Trash:Add(self.RotatorManip)
        end
        self.RotatorManip:SetTargetSpeed(500)
        self.RotatorManip:SetAccel(200)
        self.SliderManip:SetPrecedence(11)
        self.SliderManip:SetGoal(0, 0, -1)
        self.SliderManip:SetSpeed(-1)
        DefaultBeamWeapon.CreateProjectileAtMuzzle(self, muzzle)
    end,

    PlayFxWeaponUnpackSequence = function( self )
        if not self.ContBeamOn then
            local army = self.unit:GetArmy()
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            if self.RotatorManip then
                self.RotatorManip:SetTargetSpeed(179)
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

CDFEMP = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/laserturret_muzzle_flash_01_emit.bp',},
}

CDFElectronBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash01,
}

CDFHeavyElectronBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash02,
}

CIFSmartCharge = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

CANTorpedoLauncherWeapon = Class(DefaultProjectileWeapon) {
}

CANNaniteTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },

    CreateProjectileForWeapon = function(self, bone)
        local projectile = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local bp = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = bp.DoTDamage,
            Duration = bp.DoTDuration,
            Frequency = bp.DoTFrequency,
            Type = 'Normal',
            PreDamageEffects = {},
            DuringDamageEffects = {},
            PostDamageEffects = {},
        }
        if projectile and not projectile:BeenDestroyed() then
            projectile:PassData(data)
            projectile:PassDamageData(damageTable)
        end
        return projectile
    end,
}

CDFMissileMesonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

CIFCommanderDeathWeapon = Class(BareBonesWeapon) {
    FiringMuzzleBones = {0}, -- just fire from the base bone of the unit

    OnCreate = function(self)
        BareBonesWeapon.OnCreate(self)
        local myBlueprint = self:GetBlueprint()
        -- The "or x" is supplying default values in case the blueprint doesn't have an overriding value
        self.Data = {
            NukeOuterRingDamage = myBlueprint.NukeOuterRingDamage or 10,
            NukeOuterRingRadius = myBlueprint.NukeOuterRingRadius or 40,
            NukeOuterRingTicks = myBlueprint.NukeOuterRingTicks or 20,
            NukeOuterRingTotalTime = myBlueprint.NukeOuterRingTotalTime or 10,

            NukeInnerRingDamage = myBlueprint.NukeInnerRingDamage or 2000,
            NukeInnerRingRadius = myBlueprint.NukeInnerRingRadius or 30,
            NukeInnerRingTicks = myBlueprint.NukeInnerRingTicks or 24,
            NukeInnerRingTotalTime = myBlueprint.NukeInnerRingTotalTime or 24,
        }
        self:SetWeaponEnabled(false)
    end,

    OnFire = function(self)

    end,

    Fire = function(self)
        local myBlueprint = self:GetBlueprint()
        local myProjectile = self.unit:CreateProjectile( myBlueprint.ProjectileId, 0, 0, 0, nil, nil, nil):SetCollision(false)
        myProjectile:PassDamageData(self:GetDamageTable())
        if self.Data then
            myProjectile:PassData(self.Data)
        end
    end,
}

CDFRocketIridiumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/muzzle_flash_01_emit.bp',},
}

CDFRocketIridiumWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_hoplight_muzzle_smoke_01_emit.bp',
        '/effects/emitters/muzzle_flash_01_emit.bp',
    },
}

CIFMissileCorsairWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/muzzle_flash_01_emit.bp',},
}

CDFLaserPulseLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash01,
}

CDFLaserHeavyWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash02,
}

CDFLaserHeavyWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash03,
}

CDFLaserDisintegratorWeapon01 = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/disintegrator_muzzle_charge_01_emit.bp',
        '/effects/emitters/disintegrator_muzzle_charge_02_emit.bp',
        '/effects/emitters/disintegrator_muzzle_charge_05_emit.bp',
    },
    FxMuzzleFlash = {
        '/effects/emitters/disintegrator_muzzle_flash_01_emit.bp',
        '/effects/emitters/disintegrator_muzzle_flash_02_emit.bp',
        '/effects/emitters/disintegrator_muzzle_flash_03_emit.bp',
    },
}

CDFLaserDisintegratorWeapon02 = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/disintegrator_muzzle_charge_03_emit.bp',
        '/effects/emitters/disintegrator_muzzle_charge_04_emit.bp',
    },
    FxMuzzleFlash = {
        '/effects/emitters/disintegrator_muzzle_flash_04_emit.bp',
        '/effects/emitters/disintegrator_muzzle_flash_05_emit.bp',
    },
}

CDFHeavyDisintegratorWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {},
    FxMuzzleFlash = {
        '/effects/emitters/disintegratorhvy_muzzle_flash_01_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_02_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_03_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_04_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_05_emit.bp',
    },
}

CAAAutocannon = Class(DefaultProjectileWeapon) {
}

CAANanoDartWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cannon_muzzle_flash_04_emit.bp',
        '/effects/emitters/cannon_muzzle_smoke_11_emit.bp',
    },
}

CAABurstCloudFlakArtilleryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp'
    },
    FxMuzzleFlashScale = 1.5,

    CreateProjectileForWeapon = function(self, bone)
        local projectile = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Radius = blueprint.DamageRadius,
            Type = 'Normal',
            DamageFriendly = blueprint.DamageFriendly,
        }
        if projectile and not projectile:BeenDestroyed() then
            projectile:PassData(data)
            projectile:PassDamageData(damageTable)
        end
        return projectile
    end,
}

CAAMissileNaniteWeapon = Class(DefaultProjectileWeapon) {
    -- Uses default muzzle flash
}

CIFGrenadeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

CIFArtilleryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CArtilleryFlash01
}

CIFMissileStrategicWeapon = Class(DefaultProjectileWeapon) {
}


CIFMissileLoaTacticalWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_tactical_missile_launch_01_emit.bp',
        '/effects/emitters/cybran_tactical_missile_launch_02_emit.bp',
    },
}

CIFBombNeutronWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

CIFNaniteTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local bp = self:GetBlueprint()
        local data = {
            Instigator = self.unit,
            Damage = bp.DoTDamage,
            Duration = bp.DoTDuration,
            Frequency = bp.DoTFrequency,
            Type = 'Normal',
            PreDamageEffects = {},
            DuringDamageEffects = {},
            PostDamageEffects = {},
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end
        return proj
    end,
}


CIFMissileLoaWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CIFCruiseMissileLaunchSmoke,
}

CAMEMPMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/missile_sam_muzzle_flash_01_emit.bp',},
}

CAMZapperWeapon = Class(DefaultBeamWeapon) {

    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',},

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere01_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_01_emit.bp',
    SphereEffectBone = 'Turret_Muzzle',

    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        self.SphereEffectEntity = import('/lua/sim/Entity.lua').Entity()
        self.SphereEffectEntity:AttachBoneTo( -1, self.unit,self:GetBlueprint().RackBones[1].MuzzleBones[1] )
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
        self.SphereEffectEntity:SetDrawScale(0.6)
        self.SphereEffectEntity:SetVizToAllies('Intel')
        self.SphereEffectEntity:SetVizToNeutrals('Intel')
        self.SphereEffectEntity:SetVizToEnemies('Intel')

        local emit = CreateAttachedEmitter( self.unit, self:GetBlueprint().RackBones[1].MuzzleBones[1], self.unit:GetArmy(), self.SphereEffectBp )

        self.unit.Trash:Add(self.SphereEffectEntity)
        self.unit.Trash:Add(emit)
    end,

    IdleState = State (DefaultBeamWeapon.IdleState) {
        Main = function(self)
            DefaultBeamWeapon.IdleState.Main(self)
        end,

        OnGotTarget = function(self)
            DefaultBeamWeapon.IdleState.OnGotTarget(self)
            self.SphereEffectEntity:SetMesh(self.SphereEffectActiveMesh)
        end,
    },

    OnLostTarget = function(self)
        DefaultBeamWeapon.OnLostTarget(self)
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
    end,
}

CAMZapperWeapon02 = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',},
}

CCannonMolecularWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperFlash01,
}

CEMPAutoCannon = Class(DefaultProjectileWeapon) {
}

CKrilTorpedoLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CKrilTorpedoLauncherMuzzleFlash01,
}

CMobileKamikazeBombWeapon = Class(KamikazeWeapon){
    FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,

    OnFire = function(self)
        local army = self.unit:GetArmy()
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit,-2,army,v)
        end
        --CreateLightParticle( self.unit, -1, -1, 15, 10, 'flare_lens_add_02', 'ramp_red_10' )
        KamikazeWeapon.OnFire(self)
    end,
}

CMobileKamikazeBombDeathWeapon = Class(BareBonesWeapon) {
    FxDeath = EffectTemplate.CMobileKamikazeBombDeathExplosion,

    OnCreate = function(self)
        BareBonesWeapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,


    OnFire = function(self)
    end,

    Fire = function(self)
        local army = self.unit:GetArmy()
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit,-2,army,v)
        end
        --CreateLightParticle( self.unit, -1, -1, 15, 10, 'flare_lens_add_02', 'ramp_red_10' )
        local myBlueprint = self:GetBlueprint()
        DamageArea(self.unit, self.unit:GetPosition(), myBlueprint.DamageRadius, myBlueprint.Damage, myBlueprint.DamageType or 'Normal', myBlueprint.DamageFriendly or false)
    end,
}

