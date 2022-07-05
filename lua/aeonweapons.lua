----------------------------------------------------------------
-- File     :  /lua/aeonweapons.lua
-- Author(s):  John Comes, David Tomandl, Gordon Duclos, Greg Kohne
-- Summary  :  Default definitions of Aeon weapons
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-------------------------------------------------------------------

local Entity = import('/lua/sim/Entity.lua').Entity
local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local CollisionBeamFile = import('defaultcollisionbeams.lua')
local DisruptorBeamCollisionBeam = CollisionBeamFile.DisruptorBeamCollisionBeam
local QuantumBeamGeneratorCollisionBeam = CollisionBeamFile.QuantumBeamGeneratorCollisionBeam
local PhasonLaserCollisionBeam = CollisionBeamFile.PhasonLaserCollisionBeam
local TractorClawCollisionBeam = CollisionBeamFile.TractorClawCollisionBeam
local Explosion = import('defaultexplosions.lua')

local KamikazeWeapon = WeaponFile.KamikazeWeapon
local BareBonesWeapon = WeaponFile.BareBonesWeapon

local DefaultProjectileWeapon = WeaponFile.DefaultProjectileWeapon
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('EffectUtilities.lua')

---@class AIFBallisticMortarWeapon : DefaultProjectileWeapon
AIFBallisticMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AIFBallisticMortarFlash02,
}

---@class ADFReactonCannon : DefaultProjectileWeapon
ADFReactonCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/reacton_cannon_muzzle_charge_01_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_charge_02_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_charge_03_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_01_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_02_emit.bp',
        '/effects/emitters/reacton_cannon_muzzle_flash_03_emit.bp',
    },
}

---@class ADFOverchargeWeapon : OverchargeWeapon
ADFOverchargeWeapon = Class(WeaponFile.OverchargeWeapon) {
    FxMuzzleFlash = EffectTemplate.ACommanderOverchargeFlash01,
    DesiredWeaponLabel = 'RightDisruptor'
}

---@class ADFTractorClaw : DefaultBeamWeapon
---@field TractorTrashbag TrashBag
---@field TractorThreadInstance thread
ADFTractorClaw = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},

    TractorEffect = import('/lua/EffectTemplates.lua').AQuantumGateAmbient,

    --- Called by the engine when the weapon is created
    ---@param self ADFTractorClaw
    OnCreate = function(self)
        DefaultBeamWeapon.OnCreate(self)

        self.TractorTrashbag = TrashBag()
    end,

    --- Called by the engine when the weapon is destroyed
    ---@param self ADFTractorClaw
    OnDestroy = function(self)
        self.TractorTrashbag:Destroy()
    end,

    --- Called when the beam effect starts
    ---@param self ADFTractorClaw
    ---@param muzzle string
    PlayFxBeamStart = function(self, muzzle)
        -- get the real target behind a blip
        local target = self:GetCurrentTarget()
        target = self:GetRealTarget(target)
        self.Target = target
        -- the colossus has three weapons, we don't want them to overlap. If it does happen, reset the tractor beam
        if self:IsTargetAlreadyUsed(target) or self.TractorThreadInstance then
            self:ForkThread(
                function(self)
                    self:ResetTarget()
                    self:SetEnabled(false)
                    self:AimManipulatorSetEnabled(false)
                    WaitSeconds(0.5)
                    self:SetEnabled(true)
                    self:AimManipulatorSetEnabled(true)
                end
            )
            return
        end

        -- create vacuum suck up from ground effects on the unit targetted.
        for _, effect in EffectTemplate.ACollossusTractorBeamVacuum01 do
            CreateEmitterAtEntity(target, target.Army, effect):ScaleEmitter(0.125 * target.FootPrintSize)
            CreateEmitterAtEntity(target, target.Army, effect):ScaleEmitter(0.125 * target.FootPrintSize)
        end

        -- create a flash
        CreateLightParticle(target, -1, self.Army, 5, 5, 'glow_02', 'ramp_blue_22')

        -- slow down the rate of fire
        self:ChangeRateOfFire(1.0)
        
        -- run the default beam start, such as the beam effect
        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)

        -- keep track of the status quo of the tractor weapon
        self.TractorThreadInstance = self:ForkThread(self.TractorThread, target)
        self:ForkThread(self.TractorWatchThread, target)
    end,

    --- Checks whether our target is unique for this unit
    ---@param self ADFTractorClaw
    ---@param target Unit
    ---@return boolean
    IsTargetAlreadyUsed = function(self, target)
        local weap
        for i = 1, self.unit:GetWeaponCount() do
            weap = self.unit:GetWeapon(i)
            if (weap ~= self) then
                if self:GetRealTarget(weap:GetCurrentTarget()) == target then
                    return true
                end
            end
        end
        return false
    end,

    --- In case the target is a blip, retrieve the unit
    ---@param self ADFTractorClaw
    ---@param target Unit | Blip
    ---@return Unit
    GetRealTarget = function(self, target)
        if target and not IsUnit(target) then
            local unitTarget = target:GetSource()
            local unitPos = unitTarget:GetPosition()
            local reconPos = target:GetPosition()
            local dist = VDist2(unitPos[1], unitPos[3], reconPos[1], reconPos[3])
            if dist < 10 then
                return unitTarget
            end
        end
        return target
    end,

    --- Called by the engine when the weapon lost a target
    ---@param self ADFTractorClaw
    OnLostTarget = function(self)

        -- reset the state of the target
        if not IsDestroyed(self.Target) then 
            self.Target:SetDoNotTarget(false)
            self.Target.DisallowCollisions = false 
        end

        self:AimManipulatorSetEnabled(true)
        DefaultBeamWeapon.OnLostTarget(self)
        DefaultBeamWeapon.PlayFxBeamEnd(self, self.Beams[1].Beam)
    end,

    --- Applies the tractor thread behavior
    ---@param self ADFTractorClaw
    ---@param target Unit
    TractorThread = function(self, target)
        -- sanity checks
        local beam = self.Beams[1].Beam
        if not beam then return end

        local muzzle = self:GetBlueprint().MuzzleSpecial
        if not muzzle then return end

        -- do not allow collisions to the target
        target.DisallowCollisions = true

        -- do not allow the target to become target of another weapon
        target:SetDoNotTarget(true)

        -- compute the distance and adjust our muzzle bone
        local pos0 = beam:GetPosition(0)
        local pos1 = beam:GetPosition(1)
        local dist = VDist3(pos0, pos1)
        self.Slider = CreateSlider(self.unit, muzzle, 0, 0, dist, -1, true)

        -- rotate the target 
        self.TractorTrashbag:Add(self.Slider)
        self.TractorTrashbag:Add(CreateRotator(target, 0, 'x', nil, 0, 15, 20 + Random(0, 40)))
        self.TractorTrashbag:Add(CreateRotator(target, 0, 'y', nil, 0, 15, 20 + Random(0, 40)))
        self.TractorTrashbag:Add(CreateRotator(target, 0, 'z', nil, 0, 15, 20 + Random(0, 40)))

        WaitTicks(1)
        WaitFor(self.Slider)

        -- Just in case attach fails...
        target:SetDoNotTarget(false)
        target:AttachBoneTo(-1, self.unit, muzzle)
        target:SetDoNotTarget(true)

        self.AimControl:SetResetPoseTime(10)

        self.Slider:SetSpeed(8)
        self.Slider:SetGoal(0, 0, 0)

        WaitTicks(1)
        WaitFor(self.Slider)

        if not IsDestroyed(target) then

            target.DestructionExplosionWaitDelayMin = 0
            target.DestructionExplosionWaitDelayMax = 0

            -- create fancy explosion
            for k, effect in EffectTemplate.ACollossusTractorBeamCrush01 do
                CreateEmitterAtBone(self.unit, muzzle, self.unit.Army, effect)
            end

            -- create a flash
            CreateLightParticle(target, -1, self.Army, 10, 5, 'glow_02', 'ramp_blue_22')

            -- take out the unit, set the weapon owner as the instigator
            target:Kill(self.unit)
        end

        -- reset our rate of fire
        self:ChangeRateOfFire(1.0)
    end,

    --- Checks the tractor thread behavior
    ---@param self ADFTractorClaw
    ---@param target Unit
    TractorWatchThread = function(self, target)

        -- keep checking and stunning the target
        while not target.Dead do
            WaitTicks(1)
        end

        -- if the unit is destroyed, take out the tractor thread instance and the sliders / rotators
        KillThread(self.TractorThreadInstance)
        self.TractorThreadInstance = nil
        self.TractorTrashbag:Destroy()

        -- detache the anything attached to our muzzle
        self.unit:DetachAll(self.Blueprint.MuzzleSpecial or 0)

        -- adjust our rate of fire
        self:ChangeRateOfFire(1.0)

        -- reset target to start searching for a new target
        WaitSeconds(0.5)
        self:ResetTarget()
    end,
}

---@class ADFTractorClawStructure : DefaultBeamWeapon
ADFTractorClawStructure = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
}

---@class ADFChronoDampener : DefaultProjectileWeapon
ADFChronoDampener = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AChronoDampener,
    FxMuzzleFlashScale = 0.5,

    RackSalvoFiringState = State(DefaultProjectileWeapon.RackSalvoFiringState) {
        Main = function(self)
            local bp = self:GetBlueprint()
            -- Align to a tick which is a multiple of 50
            WaitTicks(51 - math.mod(GetGameTick(), 50))

            while true do
                if bp.Audio.Fire then
                    self:PlaySound(bp.Audio.Fire)
                end
                self:DoOnFireBuffs()
                self:PlayFxMuzzleSequence(1)
                self:StartEconomyDrain()
                self:OnWeaponFired()

                WaitTicks(51)
            end
        end,

        OnFire = function(self)
        end,

        OnLostTarget = function(self)
            ChangeState(self, self.IdleState)
            DefaultProjectileWeapon.OnLostTarget(self)
        end,
    },

    CreateProjectileAtMuzzle = function(self, muzzle)
    end,
}

---@class ADFQuadLaserLightWeapon : DefaultProjectileWeapon
ADFQuadLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class ADFLaserLightWeapon : DefaultProjectileWeapon
ADFLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class ADFSonicPulsarWeapon : DefaultProjectileWeapon
ADFSonicPulsarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_02_emit.bp'},
    FxMuzzleFlashScale = 0.5,
}

---@class ADFLaserHeavyWeapon : DefaultProjectileWeapon
ADFLaserHeavyWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {},
}

---@class ADFGravitonProjectorWeapon : DefaultProjectileWeapon
ADFGravitonProjectorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AGravitonBolterMuzzleFlash01,
}

---@class ADFDisruptorCannonWeapon : DefaultProjectileWeapon
ADFDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ADisruptorCannonMuzzle01,
}

---@class ADFDisruptorWeapon : DefaultProjectileWeapon
ADFDisruptorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASDisruptorCannonMuzzle01,
    FxChargeMuzzleFlash = EffectTemplate.ASDisruptorCannonChargeMuzzle01,
}

---@class ADFCannonQuantumWeapon : DefaultProjectileWeapon
ADFCannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle01,
}

---@class ADFCannonOblivionWeapon : DefaultProjectileWeapon
ADFCannonOblivionWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/oblivion_cannon_flash_01_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_02_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_03_emit.bp',
    },
}

---@class ADFCannonOblivionWeapon02 : DefaultProjectileWeapon
ADFCannonOblivionWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AOblivionCannonMuzzleFlash02,
    FxChargeMuzzleFlash = EffectTemplate.AOblivionCannonChargeMuzzleFlash02,
}

---@class ADFCannonOblivionWeapon03 : DefaultProjectileWeapon
ADFCannonOblivionWeapon03 = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
        '/effects/emitters/oblivion_cannon_flash_04_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_05_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_06_emit.bp',
    },
}

---@class AIFMortarWeapon : DefaultProjectileWeapon
AIFMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

---@class AIFBombGravitonWeapon : DefaultProjectileWeapon
AIFBombGravitonWeapon = Class(DefaultProjectileWeapon) {}

---@class AIFArtilleryMiasmaShellWeapon : DefaultProjectileWeapon
AIFArtilleryMiasmaShellWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
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

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AIFArtillerySonanceShellWeapon : DefaultProjectileWeapon
AIFArtillerySonanceShellWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/aeon_sonance_muzzle_01_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_02_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_03_emit.bp',
    },
}

---@class AIFBombQuarkWeapon : DefaultProjectileWeapon
AIFBombQuarkWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp', },
}

---@class AANDepthChargeBombWeapon : DefaultProjectileWeapon
AANDepthChargeBombWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp', },

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AANDepthChargeBombWeapon02 : DefaultProjectileWeapon
AANDepthChargeBombWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_01_emit.bp', },

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AANTorpedoCluster : DefaultProjectileWeapon
AANTorpedoCluster = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_torpedocluster_flash_01_emit.bp', },

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
            Army = self.unit.Army,
            Instigator = self.unit,
            StartRadius = blueprint.DOTStartRadius,
            EndRadius = blueprint.DOTEndRadius,
            DOTtype = blueprint.DOTtype,
            Damage = blueprint.DoTDamage,
            Duration = blueprint.DoTDuration,
            Frequency = blueprint.DoTFrequency,
            Type = 'Normal',
        }

        if proj and not proj:BeenDestroyed() then
            proj:PassDamageData(damageTable)
            proj:PassData(data)
        end

        return proj
    end,
}

---@class AIFSmartCharge : DefaultProjectileWeapon
AIFSmartCharge = Class(DefaultProjectileWeapon) {
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

---@class AANChronoTorpedoWeapon : DefaultProjectileWeapon
AANChronoTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
   },
}

---@class AIFQuasarAntiTorpedoWeapon : DefaultProjectileWeapon
AIFQuasarAntiTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AQuasarAntiTorpedoFlash,
}

---@class AKamikazeWeapon : KamikazeWeapon
AKamikazeWeapon = Class(KamikazeWeapon) {
    FxMuzzleFlash = {},
}

---@class AIFQuantumWarhead : DefaultProjectileWeapon
AIFQuantumWarhead = Class(DefaultProjectileWeapon) {
}

---@class ACruiseMissileWeapon : DefaultProjectileWeapon
ACruiseMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_missile_launch_01_emit.bp', },
}

---@class ADFLaserHighIntensityWeapon : DefaultProjectileWeapon
ADFLaserHighIntensityWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AHighIntensityLaserFlash01,
}

---@class AAATemporalFizzWeapon : DefaultProjectileWeapon
AAATemporalFizzWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = {'/effects/emitters/temporal_fizz_muzzle_charge_01_emit.bp', },
    FxMuzzleFlash = {'/effects/emitters/temporal_fizz_muzzle_flash_01_emit.bp', },
    ChargeEffectMuzzles = {},

    PlayFxRackSalvoChargeSequence = function(self)
        DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence(self)
        for _, v in self.ChargeEffectMuzzles do
            for i, j in self.FxChargeEffects do
                CreateAttachedEmitter(self.unit, v, self.unit.Army, j)
            end
        end
    end,
}

---@class AAASonicPulseBatteryWeapon : DefaultProjectileWeapon
AAASonicPulseBatteryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_01_emit.bp', },
}

---@class AAAZealotMissileWeapon : DefaultProjectileWeapon
AAAZealotMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CZealotLaunch01,
}

---@class AAAZealot02MissileWeapon : DefaultProjectileWeapon
AAAZealot02MissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp'},
}

---@class AAALightDisplacementAutocannonMissileWeapon : DefaultProjectileWeapon
AAALightDisplacementAutocannonMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ALightDisplacementAutocannonMissileMuzzleFlash,
}

---@class AAAAutocannonQuantumWeapon : DefaultProjectileWeapon
AAAAutocannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/quantum_displacement_cannon_flash_01_emit.bp', },

}

---@class AIFMissileTacticalSerpentineWeapon : DefaultProjectileWeapon
AIFMissileTacticalSerpentineWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_missile_launch_02_emit.bp', },
}

---@class AIFMissileTacticalSerpentine02Weapon : DefaultProjectileWeapon
AIFMissileTacticalSerpentine02Weapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASerpFlash01,
}

---@class AQuantumBeamGenerator : DefaultBeamWeapon
AQuantumBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = QuantumBeamGeneratorCollisionBeam,

    FxUpackingChargeEffects = {},
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        local bp = self:GetBlueprint()
        for _, v in self.FxUpackingChargeEffects do
            for i, j in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                CreateAttachedEmitter(self.unit, j, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
            end
        end
        DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
    end,
}

---@class AAMSaintWeapon : DefaultProjectileWeapon
AAMSaintWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASaintLaunch01,
}

---@class AAMWillOWisp : DefaultProjectileWeapon
AAMWillOWisp = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AAntiMissileFlareFlash,
}

---@class ADFPhasonLaser : DefaultBeamWeapon
ADFPhasonLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.PhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function(self)
        if not self.ContBeamOn then
            local bp = self:GetBlueprint()
            for _, v in self.FxUpackingChargeEffects do
                for i, j in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, j, self.unit.Army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

---@class ADFQuantumAutogunWeapon : DefaultProjectileWeapon
ADFQuantumAutogunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_DualQuantumAutoGunMuzzleFlash,
}

---@class ADFHeavyDisruptorCannonWeapon : DefaultProjectileWeapon
ADFHeavyDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
}

---@class AIFQuanticArtillery : DefaultProjectileWeapon
AIFQuanticArtillery = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_QuanticClusterMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_QuanticClusterChargeMuzzleFlash,
}
