------------------------------------------------------------------------------
-- File     :  /lua/cybranweapons.lua
-- Author(s):  David Tomandl, John Comes, Gordon Duclos
-- Summary  :  Cybran weapon definitions
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------------------

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local KamikazeWeapon = WeaponFile.KamikazeWeapon
local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon
local OverchargeWeapon = WeaponFile.OverchargeWeapon
local CollisionBeamFile = import("/lua/defaultcollisionbeams.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

---@class CDFBrackmanCrabHackPegLauncherWeapon : DefaultProjectileWeapon
CDFBrackmanCrabHackPegLauncherWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/proton_cannon_muzzle_01_emit.bp',
        '/effects/emitters/proton_cannon_muzzle_02_emit.bp', },
}

---@class CDFParticleCannonWeapon : DefaultBeamWeapon
CDFParticleCannonWeapon = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ParticleCannonCollisionBeam,
    FxMuzzleFlash = { '/effects/emitters/particle_cannon_muzzle_01_emit.bp' },
}

---@class CDFProtonCannonWeapon : DefaultProjectileWeapon
CDFProtonCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/proton_cannon_muzzle_01_emit.bp',
        '/effects/emitters/proton_cannon_muzzle_02_emit.bp', },
}

---@class CDFHvyProtonCannonWeapon : DefaultProjectileWeapon
CDFHvyProtonCannonWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CHvyProtonCannonMuzzleflash,
}

---@class CDFOverchargeWeapon : OverchargeWeapon
CDFOverchargeWeapon = ClassWeapon(OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperOverChargeFlash01,
    DesiredWeaponLabel = 'RightRipper'
}

--- COMMANDER ENHANCEMENT WEAPON!
---@class CDFHeavyMicrowaveLaserGeneratorCom : DefaultBeamWeapon
CDFHeavyMicrowaveLaserGeneratorCom = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam02,
}

--- SPIDER BOT WEAPON!
---@class CDFHeavyMicrowaveLaserGenerator : DefaultBeamWeapon
---@field RotatorManip moho.RotateManipulator
CDFHeavyMicrowaveLaserGenerator = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.MicrowaveLaserCollisionBeam01,
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param muzzle string
    PlayFxBeamStart = function(self, muzzle)
        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)

        -- create rotator if it doesn't exist
        local rotator = self.RotatorManip
        if not rotator then
            local unit = self.unit
            rotator = CreateRotator(unit, 'Center_Turret_Barrel', 'z')
            unit.Trash:Add(rotator)
            self.RotatorManip = rotator
        end

        -- set their respective properties when firing
        rotator:SetTargetSpeed(500)
        rotator:SetAccel(200)
    end,

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param beam string
    PlayFxBeamEnd = function(self, beam)
        DefaultBeamWeapon.PlayFxBeamEnd(self, beam)

        -- if it exists, then stop rotating
        local rotator = self.RotatorManip
        if rotator then
            rotator:SetTargetSpeed(0)
            rotator:SetAccel(90)
        end
    end,
}

---@class CDFEMP : DefaultProjectileWeapon
CDFEMP = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/laserturret_muzzle_flash_01_emit.bp', },
}

---@class CDFElectronBolterWeapon : DefaultProjectileWeapon
CDFElectronBolterWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash01,
}

---@class CDFHeavyElectronBolterWeapon : DefaultProjectileWeapon
CDFHeavyElectronBolterWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CElectronBolterMuzzleFlash02,
}

---@class CIFSmartCharge : DefaultProjectileWeapon
CIFSmartCharge = ClassWeapon(DefaultProjectileWeapon) {

    ---@param self CDFHeavyMicrowaveLaserGenerator
    ---@param muzzle string
    ---@return Projectile
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        if not proj or proj:BeenDestroyed() then
            return proj
        end

        local blueprint = self.Blueprint.DepthCharge
        if blueprint then
            proj:AddDepthCharge(blueprint)
        end

        return proj
    end,
}

---@class CANTorpedoLauncherWeapon : DefaultProjectileWeapon
CANTorpedoLauncherWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CANNaniteTorpedoWeapon : DefaultProjectileWeapon
CANNaniteTorpedoWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}

---@class CDFMissileMesonWeapon : DefaultProjectileWeapon
CDFMissileMesonWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CDFRocketIridiumWeapon : DefaultProjectileWeapon
CDFRocketIridiumWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/muzzle_flash_01_emit.bp', },
}

---@class CDFRocketIridiumWeapon02 : DefaultProjectileWeapon
CDFRocketIridiumWeapon02 = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_hoplight_muzzle_smoke_01_emit.bp',
        '/effects/emitters/muzzle_flash_01_emit.bp',
    },
}

---@class CIFMissileCorsairWeapon : DefaultProjectileWeapon
CIFMissileCorsairWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/muzzle_flash_01_emit.bp', },
}

---@class CDFLaserPulseLightWeapon : DefaultProjectileWeapon
CDFLaserPulseLightWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash01,
}

---@class CDFLaserHeavyWeapon : DefaultProjectileWeapon
CDFLaserHeavyWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash02,
}

---@class CDFLaserHeavyWeapon02 : DefaultProjectileWeapon
CDFLaserHeavyWeapon02 = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CLaserMuzzleFlash03,
}

---@class CDFLaserDisintegratorWeapon01 : DefaultProjectileWeapon
CDFLaserDisintegratorWeapon01 = ClassWeapon(DefaultProjectileWeapon) {
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
CDFLaserDisintegratorWeapon02 = ClassWeapon(DefaultProjectileWeapon) {
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
CDFHeavyDisintegratorWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/disintegratorhvy_muzzle_flash_01_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_02_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_03_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_04_emit.bp',
        '/effects/emitters/disintegratorhvy_muzzle_flash_05_emit.bp',
    },
}

---@class CAAAutocannon : DefaultProjectileWeapon
CAAAutocannon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CAANanoDartWeapon : DefaultProjectileWeapon
CAANanoDartWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cannon_muzzle_flash_04_emit.bp',
        '/effects/emitters/cannon_muzzle_smoke_11_emit.bp',
    },
}

---@class CAABurstCloudFlakArtilleryWeapon : DefaultProjectileWeapon
CAABurstCloudFlakArtilleryWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp'
    },
    FxMuzzleFlashScale = 1.5,
}

---@class CAAMissileNaniteWeapon : DefaultProjectileWeapon
CAAMissileNaniteWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CIFGrenadeWeapon : DefaultProjectileWeapon
CIFGrenadeWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/antiair_muzzle_fire_01_emit.bp', },
}

---@class CIFArtilleryWeapon : DefaultProjectileWeapon
CIFArtilleryWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CArtilleryFlash01
}

---@class CIFMissileStrategicWeapon : DefaultProjectileWeapon
CIFMissileStrategicWeapon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CIFMissileLoaTacticalWeapon : DefaultProjectileWeapon
CIFMissileLoaTacticalWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/cybran_tactical_missile_launch_01_emit.bp',
        '/effects/emitters/cybran_tactical_missile_launch_02_emit.bp',
    },
}

---@class CIFBombNeutronWeapon : DefaultProjectileWeapon
CIFBombNeutronWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/antiair_muzzle_fire_02_emit.bp', },
}

---@class CIFNaniteTorpedoWeapon : DefaultProjectileWeapon
CIFNaniteTorpedoWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/antiair_muzzle_fire_02_emit.bp', },
}

---@class CIFMissileLoaWeapon : DefaultProjectileWeapon
CIFMissileLoaWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CIFCruiseMissileLaunchSmoke,
}

---@class CAMEMPMissileWeapon : DefaultProjectileWeapon
CAMEMPMissileWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/missile_sam_muzzle_flash_01_emit.bp', },
}

---@class CAMZapperWeapon : DefaultBeamWeapon
---@field SphereEffectEntity Entity
CAMZapperWeapon = ClassWeapon(DefaultBeamWeapon) {

    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = { '/effects/emitters/cannon_muzzle_flash_01_emit.bp', },

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere01_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_01_emit.bp',
    SphereEffectBone = 'Turret_Muzzle',

    ---@param self CAMZapperWeapon
    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        local bp = self.Blueprint
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

    IdleState = State(DefaultBeamWeapon.IdleState) {
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
CAMZapperWeapon02 = ClassWeapon(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = { '/effects/emitters/cannon_muzzle_flash_01_emit.bp', },
}

---@class CAMZapperWeapon03 : DefaultBeamWeapon
---@field SphereEffectEntity Entity
CAMZapperWeapon03 = ClassWeapon(DefaultBeamWeapon) {

    BeamType = CollisionBeamFile.ZapperCollisionBeam,
    FxMuzzleFlash = { '/effects/emitters/cannon_muzzle_flash_01_emit.bp', },

    SphereEffectIdleMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere01_mesh',
    SphereEffectActiveMesh = '/effects/entities/cybranphalanxsphere01/cybranphalanxsphere02_mesh',
    SphereEffectBp = '/effects/emitters/zapper_electricity_02_emit.bp',
    SphereEffectBone = 'Turret_Muzzle',

    ---@param self CAMZapperWeapon03
    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        local bp = self.Blueprint
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

    IdleState = State(DefaultBeamWeapon.IdleState) {
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
CCannonMolecularWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CMolecularRipperFlash01,
}

---@class CEMPAutoCannon : DefaultProjectileWeapon
CEMPAutoCannon = ClassWeapon(DefaultProjectileWeapon) {}

---@class CKrilTorpedoLauncherWeapon : DefaultProjectileWeapon
CKrilTorpedoLauncherWeapon = ClassWeapon(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CKrilTorpedoLauncherMuzzleFlash01,
}

---@class CMobileKamikazeBombWeapon : KamikazeWeapon
---@field transportDrop boolean
CMobileKamikazeBombWeapon = ClassWeapon(KamikazeWeapon) {
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

            DamageArea(self.unit, pos, 6, 1, 'Force', true)
            DamageArea(self.unit, pos, 6, 1, 'Force', true)

            CreateDecal(pos, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end

        KamikazeWeapon.OnFire(self)
    end,
}

-- kept for mod backwards compatibility
local BareBonesWeapon = WeaponFile.BareBonesWeapon
local Explosion = import("/lua/defaultexplosions.lua")
local Util = import("/lua/utilities.lua")
