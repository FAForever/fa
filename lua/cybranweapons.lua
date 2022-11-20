--****************************************************************************
--**
--**  File     :  /lua/cybranweapons.lua
--**  Author(s):  David Tomandl, John Comes, Gordon Duclos
--**
--**  Summary  :  Cybran weapon definitions
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OverchargeWeapon = WeaponFile.OverchargeWeapon
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class CDFBrackmanCrabHackPegLauncherWeapon : DefaultProjectileWeapon
CDFBrackmanCrabHackPegLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/proton_cannon_muzzle_01_emit.bp',
                     '/effects/emitters/proton_cannon_muzzle_02_emit.bp',},
}

---@class CDFParticleCannonWeapon : DefaultBeamWeapon
CDFParticleCannonWeapon = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ParticleCannonCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/particle_cannon_muzzle_01_emit.bp'},
}

---@class CDFProtonCannonWeapon : DefaultProjectileWeapon
CDFProtonCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/proton_cannon_muzzle_01_emit.bp',
                     '/effects/emitters/proton_cannon_muzzle_02_emit.bp',},
}

---@class CDFHvyProtonCannonWeapon : DefaultProjectileWeapon
CDFHvyProtonCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CHvyProtonCannonMuzzleflash,
}

---@class CDFOverchargeWeapon : OverchargeWeapon
CDFOverchargeWeapon = Class(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperOverChargeFlash01,
    DesiredWeaponLabel = 'RightRipper'
}

-- COMMANDER ENHANCEMENT WEAPON!
---@class CDFHeavyMicrowaveLaserGeneratorCom : DefaultBeamWeapon
CDFHeavyMicrowaveLaserGeneratorCom = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self CDFHeavyMicrowaveLaserGeneratorCom
    PlayFxWeaponUnpackSequence = function(self)
        if not self:EconomySupportsBeam() then return end
        local bp = self:GetBlueprint()
        for k, v in self.FxUpackingChargeEffects do
            for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, ev, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
            end
        end
        DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
    end,
}

-- SPIDER BOT WEAPON!
---@class CDFHeavyMicrowaveLaserGenerator : DefaultBeamWeapon
CDFHeavyMicrowaveLaserGenerator = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam01,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param muzzle string
    PlayFxBeamStart = function(self, muzzle)

        -- create rotator if it doesn't exist
        if not self.RotatorManip then
            self.RotatorManip = CreateRotator(self.unit, 'Center_Turret_Barrel', 'z')
            self.unit.Trash:Add(self.RotatorManip)
        end

        -- set their respective properties when firing
        self.RotatorManip:SetTargetSpeed(500)
        self.RotatorManip:SetAccel(200)

        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)
    end,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param beam string
    PlayFxBeamEnd = function(self, beam)

        -- if it exists, then stop rotating
        if self.RotatorManip then
            self.RotatorManip:SetTargetSpeed(0)
            self.RotatorManip:SetAccel(90)
        end

        DefaultBeamWeapon.PlayFxBeamEnd(self, beam)
    end,


    ---@param self CDFHeavyMicrowaveLaserGenerator
    PlayFxWeaponUnpackSequence = function(self)

        if not self.ContBeamOn then
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            if self.RotatorManip then
                self.RotatorManip:SetTargetSpeed(179)
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class CDFEMP : DefaultProjectileWeapon
CDFEMP = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/laserturret_muzzle_flash_01_emit.bp',},
}

---@class CDFElectronBolterWeapon : DefaultProjectileWeapon
CDFElectronBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash01,
}

---@class CDFHeavyElectronBolterWeapon : DefaultProjectileWeapon
CDFHeavyElectronBolterWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash02,
}

---@class CIFSmartCharge : DefaultProjectileWeapon
CIFSmartCharge = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

---@class CANTorpedoLauncherWeapon : DefaultProjectileWeapon
CANTorpedoLauncherWeapon = Class(DefaultProjectileWeapon) {
}

---@class CANNaniteTorpedoWeapon : DefaultProjectileWeapon
CANNaniteTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },

    ---@param self CANNaniteTorpedoWeapon
    ---@param bone Bone
    ---@return Projectile|nil
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

---@class CDFMissileMesonWeapon : DefaultProjectileWeapon
CDFMissileMesonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

---@class CDFRocketIridiumWeapon : DefaultProjectileWeapon
CDFRocketIridiumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/muzzle_flash_01_emit.bp',},
}

---@class CDFRocketIridiumWeapon02 : DefaultProjectileWeapon
CDFRocketIridiumWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_hoplight_muzzle_smoke_01_emit.bp',
        '/effects/emitters/muzzle_flash_01_emit.bp',
    },
}

---@class CIFMissileCorsairWeapon : DefaultProjectileWeapon
CIFMissileCorsairWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/muzzle_flash_01_emit.bp',},
}

---@class CDFLaserPulseLightWeapon : DefaultProjectileWeapon
CDFLaserPulseLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash01,
}

---@class CDFLaserHeavyWeapon : DefaultProjectileWeapon
CDFLaserHeavyWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash02,
}

---@class CDFLaserHeavyWeapon02 : DefaultProjectileWeapon
CDFLaserHeavyWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash03,
}

---@class CDFLaserDisintegratorWeapon01 : DefaultProjectileWeapon
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

---@class CDFLaserDisintegratorWeapon02 : DefaultProjectileWeapon
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

---@class CDFHeavyDisintegratorWeapon : DefaultProjectileWeapon
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

---@class CAAAutocannon : DefaultProjectileWeapon
CAAAutocannon = Class(DefaultProjectileWeapon) {
}

---@class CAANanoDartWeapon : DefaultProjectileWeapon
CAANanoDartWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cannon_muzzle_flash_04_emit.bp',
        '/effects/emitters/cannon_muzzle_smoke_11_emit.bp',
    },
}

---@class CAABurstCloudFlakArtilleryWeapon : DefaultProjectileWeapon
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

---@class CAAMissileNaniteWeapon : DefaultProjectileWeapon
CAAMissileNaniteWeapon = Class(DefaultProjectileWeapon) {
    -- Uses default muzzle flash
}

---@class CIFGrenadeWeapon : DefaultProjectileWeapon
CIFGrenadeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_01_emit.bp',},
}

---@class CIFArtilleryWeapon : DefaultProjectileWeapon
CIFArtilleryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CArtilleryFlash01
}

---@class CIFMissileStrategicWeapon : DefaultProjectileWeapon
CIFMissileStrategicWeapon = Class(DefaultProjectileWeapon) {
}


---@class CIFMissileLoaTacticalWeapon : DefaultProjectileWeapon
CIFMissileLoaTacticalWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_tactical_missile_launch_01_emit.bp',
        '/effects/emitters/cybran_tactical_missile_launch_02_emit.bp',
    },
}

---@class CIFBombNeutronWeapon : DefaultProjectileWeapon
CIFBombNeutronWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

---@class CIFNaniteTorpedoWeapon : DefaultProjectileWeapon
CIFNaniteTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

    ---@param self CIFNaniteTorpedoWeapon
    ---@param bone Bone
    ---@return Projectile|nil
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


---@class CIFMissileLoaWeapon : DefaultProjectileWeapon
CIFMissileLoaWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CIFCruiseMissileLaunchSmoke,
}

---@class CAMEMPMissileWeapon : DefaultProjectileWeapon
CAMEMPMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/missile_sam_muzzle_flash_01_emit.bp',},
}

---@class CAMZapperWeapon : DefaultBeamWeapon
CAMZapperWeapon = Class(DefaultBeamWeapon) {

    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',},

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere01_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_01_emit.bp',
    SphereEffectBone = 'Turret_Muzzle',

    ---@param self CAMZapperWeapon
    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        local bp = self:GetBlueprint()
        self.SphereEffectEntity = import("/lua/sim/entity.lua").Entity()
        self.SphereEffectEntity:AttachBoneTo(-1, self.unit, bp.RackBones[1].MuzzleBones[1])
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
        self.SphereEffectEntity:SetDrawScale(0.6)
        self.SphereEffectEntity:SetVizToAllies('Intel')
        self.SphereEffectEntity:SetVizToNeutrals('Intel')
        self.SphereEffectEntity:SetVizToEnemies('Intel')

        local emit = CreateAttachedEmitter(self.unit, bp.RackBones[1].MuzzleBones[1], self.unit.Army, self.SphereEffectBp)

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

    ---@param self CAMZapperWeapon
    OnLostTarget = function(self)
        DefaultBeamWeapon.OnLostTarget(self)
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
    end,
}

---@class CAMZapperWeapon02 : DefaultBeamWeapon
CAMZapperWeapon02 = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',},
}

---@class CAMZapperWeapon03 : DefaultBeamWeapon
CAMZapperWeapon03 = Class(DefaultBeamWeapon) {

    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = {'/effects/emitters/cannon_muzzle_flash_01_emit.bp',},

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere01_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_02_emit.bp',
    SphereEffectBone = 'Turret_Muzzle',

    ---@param self CAMZapperWeapon03
    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        local bp = self:GetBlueprint()
        self.SphereEffectEntity = import("/lua/sim/entity.lua").Entity()
        self.SphereEffectEntity:AttachBoneTo(-1, self.unit, bp.RackBones[1].MuzzleBones[1])
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
        self.SphereEffectEntity:SetDrawScale(0.28)
        self.SphereEffectEntity:SetVizToAllies('Intel')
        self.SphereEffectEntity:SetVizToNeutrals('Intel')
        self.SphereEffectEntity:SetVizToEnemies('Intel')

        local emit = CreateAttachedEmitter(self.unit, bp.RackBones[1].MuzzleBones[1], self.unit.Army, self.SphereEffectBp)

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

    ---@param self CAMZapperWeapon03
    OnLostTarget = function(self)
        DefaultBeamWeapon.OnLostTarget(self)
        self.SphereEffectEntity:SetMesh(self.SphereEffectIdleMesh)
    end,
}

---@class CCannonMolecularWeapon : DefaultProjectileWeapon
CCannonMolecularWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperFlash01,
}

---@class CEMPAutoCannon : DefaultProjectileWeapon
CEMPAutoCannon = Class(DefaultProjectileWeapon) {
}

---@class CKrilTorpedoLauncherWeapon : DefaultProjectileWeapon
CKrilTorpedoLauncherWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CKrilTorpedoLauncherMuzzleFlash01,
}

---@class CMobileKamikazeBombWeapon : KamikazeWeapon
CMobileKamikazeBombWeapon = Class(KamikazeWeapon){
    FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,

    ---@param self CMobileKamikazeBombWeapon
    OnFire = function(self)
        local army = self.unit.Army
        
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
        end
        
        if not self.unit.transportDrop then
            local pos = self.unit:GetPosition()
            local rotation = math.random(0, 6.28)
            
            DamageArea( self.unit, pos, 6, 1, 'Force', true )
            DamageArea( self.unit, pos, 6, 1, 'Force', true )
            
            CreateDecal( pos, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end
        
        KamikazeWeapon.OnFire(self)
    end,
}

-- kept for mod backwards compatibility
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local Explosion = import("/lua/defaultexplosions.lua")
local Util = import("/lua/utilities.lua")