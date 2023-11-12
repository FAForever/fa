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

--- Weapon Files ---
CDFBrackmanCrabHackPegLauncherWeapon = import('/lua/sim/weapons/cybran/CDFBrackmanCrabHackPegLauncherWeapon.lua').CDFBrackmanCrabHackPegLauncherWeapon
CDFParticleCannonWeapon = import('/lua/sim/weapons/cybran/CDFParticleCannonWeapon.lua').CDFParticleCannonWeapon
CDFProtonCannonWeapon = import('/lua/sim/weapons/cybran/CDFProtonCannonWeapon.lua').CDFProtonCannonWeapon
CDFHvyProtonCannonWeapon = import('/lua/sim/weapons/cybran/CDFHvyProtonCannonWeapon.lua').CDFHvyProtonCannonWeapon
CDFHeavyMicrowaveLaserGeneratorCom = import('/lua/sim/weapons/cybran/CDFHeavyMicrowaveLaserGeneratorCom.lua').CDFHeavyMicrowaveLaserGeneratorCom
CDFHeavyMicrowaveLaserGenerator = import('/lua/sim/weapons/cybran/CDFHeavyMicrowaveLaserGenerator.lua').CDFHeavyMicrowaveLaserGenerator
CDFEMP = import('/lua/sim/weapons/cybran/CDFEMP.lua').CDFEMP
CDFElectronBolterWeapon = import('/lua/sim/weapons/cybran/CDFElectronBolterWeapon.lua').CDFElectronBolterWeapon
CDFHeavyElectronBolterWeapon = import('/lua/sim/weapons/cybran/CDFHeavyElectronBolterWeapon.lua').CDFHeavyElectronBolterWeapon
CIFSmartCharge = import('/lua/sim/weapons/cybran/CIFSmartCharge.lua').CIFSmartCharge
CANTorpedoLauncherWeapon = import('/lua/sim/weapons/cybran/CANTorpedoLauncherWeapon.lua').CANTorpedoLauncherWeapon
CANNaniteTorpedoWeapon = import('/lua/sim/weapons/cybran/CANNaniteTorpedoWeapon.lua').CANNaniteTorpedoWeapon
CDFMissileMesonWeapon = import('/lua/sim/weapons/cybran/CDFMissileMesonWeapon.lua').CDFMissileMesonWeapon
CDFRocketIridiumWeapon = import('/lua/sim/weapons/cybran/CDFRocketIridiumWeapon.lua').CDFRocketIridiumWeapon
CDFRocketIridiumWeapon02 = import('/lua/sim/weapons/cybran/CDFRocketIridiumWeapon02.lua').CDFRocketIridiumWeapon02
CIFMissileCorsairWeapon = import('/lua/sim/weapons/cybran/CIFMissileCorsairWeapon.lua').CIFMissileCorsairWeapon
CDFLaserPulseLightWeapon = import('/lua/sim/weapons/cybran/CDFLaserPulseLightWeapon.lua').CDFLaserPulseLightWeapon
CDFLaserHeavyWeapon = import('/lua/sim/weapons/cybran/CDFLaserHeavyWeapon.lua').CDFLaserHeavyWeapon
CDFLaserHeavyWeapon02 = import('/lua/sim/weapons/cybran/CDFLaserHeavyWeapon02.lua').CDFLaserHeavyWeapon02
CDFLaserDisintegratorWeapon01 = import('/lua/sim/weapons/cybran/CDFLaserDisintegratorWeapon01.lua').CDFLaserDisintegratorWeapon01
CDFLaserDisintegratorWeapon02 = import('/lua/sim/weapons/cybran/CDFLaserDisintegratorWeapon02.lua').CDFLaserDisintegratorWeapon02
CDFHeavyDisintegratorWeapon = import('/lua/sim/weapons/cybran/CDFHeavyDisintegratorWeapon.lua').CDFHeavyDisintegratorWeapon
CAAAutocannon = import('/lua/sim/weapons/cybran/CAAAutocannon.lua').CAAAutocannon
CAANanoDartWeapon = import('/lua/sim/weapons/cybran/CAANanoDartWeapon.lua').CAANanoDartWeapon
CAABurstCloudFlakArtilleryWeapon = import('/lua/sim/weapons/cybran/CAABurstCloudFlakArtilleryWeapon.lua').CAABurstCloudFlakArtilleryWeapon
CAAMissileNaniteWeapon = import('/lua/sim/weapons/cybran/CAAMissileNaniteWeapon.lua').CAAMissileNaniteWeapon
CIFGrenadeWeapon = import('/lua/sim/weapons/cybran/CIFGrenadeWeapon.lua').CIFGrenadeWeapon
CIFArtilleryWeapon = import('/lua/sim/weapons/cybran/CIFArtilleryWeapon.lua').CIFArtilleryWeapon
CIFMissileStrategicWeapon = import('/lua/sim/weapons/cybran/CIFMissileStrategicWeapon.lua').CIFMissileStrategicWeapon
CIFMissileLoaTacticalWeapon = import('/lua/sim/weapons/cybran/CIFMissileLoaTacticalWeapon.lua').CIFMissileLoaTacticalWeapon
CIFBombNeutronWeapon = import('/lua/sim/weapons/cybran/CIFBombNeutronWeapon.lua').CIFBombNeutronWeapon
CIFNaniteTorpedoWeapon = import('/lua/sim/weapons/cybran/CIFNaniteTorpedoWeapon.lua').CIFNaniteTorpedoWeapon
CIFMissileLoaWeapon = import('/lua/sim/weapons/cybran/CIFMissileLoaWeapon.lua').CIFMissileLoaWeapon
CAMEMPMissileWeapon = import('/lua/sim/weapons/cybran/CAMEMPMissileWeapon.lua').CAMEMPMissileWeapon
CAMZapperWeapon = import('/lua/sim/weapons/cybran/CAMZapperWeapon.lua').CAMZapperWeapon
CAMZapperWeapon02 = import('/lua/sim/weapons/cybran/CAMZapperWeapon02.lua').CAMZapperWeapon02
CAMZapperWeapon03 = import('/lua/sim/weapons/cybran/CAMZapperWeapon03.lua').CAMZapperWeapon03
CCannonMolecularWeapon = import('/lua/sim/weapons/cybran/CCannonMolecularWeapon.lua').CCannonMolecularWeapon
CEMPAutoCannon = import('/lua/sim/weapons/cybran/CEMPAutoCannon.lua').CEMPAutoCannon
CKrilTorpedoLauncherWeapon = import('/lua/sim/weapons/cybran/CKrilTorpedoLauncherWeapon.lua').CKrilTorpedoLauncherWeapon
CMobileKamikazeBombWeapon = import('/lua/sim/weapons/cybran/CMobileKamikazeBombWeapon.lua').CMobileKamikazeBombWeapon
CDFOverchargeWeapon = import('/lua/sim/weapons/cybran/CDFOverchargeWeapon.lua').CDFOverchargeWeapon


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
