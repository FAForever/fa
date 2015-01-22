#****************************************************************************
#**
#**  File     :  /lua/aeonweapons.lua
#**  Author(s):  John Comes, David Tomandl, Gordon Duclos, Greg Kohne
#**
#**  Summary  :  Default definitions of Aeon weapons
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

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

AIFBallisticMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AIFBallisticMortarFlash02,
}

ADFReactonCannon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/reacton_cannon_muzzle_charge_01_emit.bp',
                           '/effects/emitters/reacton_cannon_muzzle_charge_02_emit.bp',
                           '/effects/emitters/reacton_cannon_muzzle_charge_03_emit.bp',
                           '/effects/emitters/reacton_cannon_muzzle_flash_01_emit.bp',
                           '/effects/emitters/reacton_cannon_muzzle_flash_02_emit.bp',
                           '/effects/emitters/reacton_cannon_muzzle_flash_03_emit.bp',},
}

ADFOverchargeWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ACommanderOverchargeFlash01,
}


ADFTractorClaw = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
   
    PlayFxBeamStart = function(self, muzzle)
        local target = self:GetCurrentTarget()
        
        -- Make absolutely certain that non-targetable units don't get caught
        if not target or
            EntityCategoryContains(categories.STRUCTURE, target) or
            EntityCategoryContains(categories.COMMAND, target) or
            EntityCategoryContains(categories.EXPERIMENTAL, target) or
            EntityCategoryContains(categories.NAVAL, target) or
            EntityCategoryContains(categories.SUBCOMMANDER, target) or
            not EntityCategoryContains(categories.ALLUNITS, target) then
            return
        end

        -- Ensure recon blips can't be the target
        target = self:GetRealTarget(target)
        
        -- Ensure that targets already targeted can't be hit twice
        if self:IsTargetAlreadyUsed(target) then 
            return 
        end
        
        -- Create visual effects for the target being sucked off the ground
        for k, v in EffectTemplate.ACollossusTractorBeamVacuum01 do
            CreateEmitterAtEntity(target, target:GetArmy(),v):ScaleEmitter(target:GetFootPrintSize()/2)
        end
        
        DefaultBeamWeapon.PlayFxBeamStart(self, muzzle)

        if not self.TT1 then
            self.TT1 = self:ForkThread(self.TractorThread, target)
            self:ForkThread(self.TractorWatchThread, target)
        else
            WARN('TT1 already exists')
        end
    end,
    
    -- Check for recon blips (aeonweapons.lua only)
    -- Returns the unit creating the blip if the blip and the source are close enough together
    GetRealTarget = function(self, target)
        if target and not IsUnit(target) then
            local unitTarget = target:GetSource() -- Find the unit creating the blip
            local unitPos = unitTarget:GetPosition() -- Find the position of that unit
            local reconPos = target:GetPosition() -- Find the position of the blip
            local dist = VDist2(unitPos[1], unitPos[3], reconPos[1], reconPos[3])
            if dist < 10 then
                return unitTarget
            end
        end
        return target
    end,
    
    -- Override this function in the unit to check if another weapon already has this
    -- unit as a target.  Target argument should not be a recon blip
    IsTargetAlreadyUsed = function(self, target)        
        -- Make a table with one value for each weapon, in this case 3 (See unit script)
        local weaponTable = {1, 2, 3}
    
        for k, v in weaponTable do
            v = self.unit:GetWeapon(v)
            if v != self then
                if self:GetRealTarget(v:GetCurrentTarget()) == target then
                    return true
                end
            end
        end
        return false
    end,

    OnLostTarget = function(self)
        self:AimManipulatorSetEnabled(true)
        DefaultBeamWeapon.OnLostTarget(self)
        DefaultBeamWeapon.PlayFxBeamEnd(self,self.Beams[1].Beam)
    end,

    -- The actual weapon thread including sliders
    TractorThread = function(self, target)
        self.unit.Trash:Add(target)
        local beam = self.Beams[1].Beam
        if not beam then return end

        local muzzle = self:GetBlueprint().MuzzleSpecial
        if not muzzle then return end

        local pos0 = beam:GetPosition(0)
        local pos1 = beam:GetPosition(1)
        local dist = VDist3(pos0, pos1) -- Length of the beam
        
        -- Disable the target
        target:SetDoNotTarget(true)
        target:SetCanTakeDamage(false)
        if target:ShieldIsOn() then
            target:DisableShield()
            target:DisableDefaultToggleCaps()
        end
        
        self.Slider = CreateSlider(self.unit, muzzle, 0, 0, dist, -1, true)
        
        WaitTicks(1)
        WaitFor(self.Slider)
        
        -- Just in case attach fails
        target:SetDoNotTarget(false)
        target:AttachBoneTo(-1, self.unit, muzzle)
        target:SetDoNotTarget(true) -- Make sure other units cease firing at the captured one
        self.AimControl:SetResetPoseTime(10)

        self.Slider:SetSpeed(15)
        self.Slider:SetGoal(0,0,0)
        WaitTicks(1)
        WaitFor(self.Slider)

        if not target:IsDead() then
            target.DestructionExplosionWaitDelayMin = 0
            target.DestructionExplosionWaitDelayMax = 0
            
            for kEffect, vEffect in EffectTemplate.ACollossusTractorBeamCrush01 do
                CreateEmitterAtBone(self.unit, muzzle , self.unit:GetArmy(), vEffect)
            end
            
            target:Destroy()
        end
        
        self.AimControl:SetResetPoseTime(2)
    end,

    TractorWatchThread = function(self, target)
        while not target:IsDead() do
            WaitTicks(1)
        end
        KillThread(self.TT1)
        self.TT1 = nil
        if self.Slider then
            self.Slider:Destroy()
            self.Slider = nil
        end
        self.unit:DetachAll(self:GetBlueprint().MuzzleSpecial or 0)
        DefaultBeamWeapon.PlayFxBeamEnd(self,self.Beams[1].Beam)
        self:ResetTarget()
        self.AimControl:SetResetPoseTime(2)
    end,
}


ADFTractorClawStructure = Class(DefaultBeamWeapon) {
    BeamType = TractorClawCollisionBeam,
    FxMuzzleFlash = {},
}


ADFChronoDampener = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AChronoDampener,
    FxMuzzleFlashScale = 0.5,

    CreateProjectileAtMuzzle = function(self, muzzle)
    end,
    
    OnGotTarget = function(self)
        DefaultProjectileWeapon.OnGotTarget(self)
        if self.FiringTimerThread == nil then
            self.FiringTimerThread = ForkThread(self.FiringTimer)
        end
    end,
    
    OnFire = function(self)
    end,
    
    FiringTimer = function(self)
        while true do
            local CurrentGameTick = GetGameTick()
            local FireTick = CurrentGameTick - math.floor((CurrentGameTick / 50) * 50)
            
            if FireTick == 0 then
                local bp = self:GetBlueprint()
                
                if bp.Audio.Fire then
                    self:PlaySound(bp.Audio.Fire)
                end
                
                if bp.WeaponUnpacks == true then
                    ChangeState(self, self.WeaponUnpackingState)
                else
                    if bp.RackSalvoChargeTime and bp.RackSalvoChargeTime > 0 then
                        ChangeState(self, self.RackSalvoChargeState)
                    elseif bp.SkipReadyState and bp.SkipReadyState == true then
                        ChangeState(self, self.RackSalvoFiringState)
                    else
                        ChangeState(self, self.RackSalvoFireReadyState)
                    end
                end
                self:DoOnFireBuffs()
                WaitTicks(50)
            end
        end
    end,
    
    OnLostTarget = function(self)
        DefaultProjectileWeapon.OnLostTarget(self)
        if self.FiringTimerThread != nil then
            KillThread(self.FiringTimerThread)
        end
    end,
}

ADFQuadLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp' },
}

ADFLaserLightWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp' },
}

ADFSonicPulsarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_02_emit.bp' },
    FxMuzzleFlashScale = 0.5,
}

ADFLaserHeavyWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {},
}


ADFGravitonProjectorWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AGravitonBolterMuzzleFlash01,
}


ADFDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ADisruptorCannonMuzzle01,
}


ADFDisruptorWeapon = Class(DefaultProjectileWeapon) {
	FxMuzzleFlash = EffectTemplate.ASDisruptorCannonMuzzle01,
    FxChargeMuzzleFlash = EffectTemplate.ASDisruptorCannonChargeMuzzle01,
}

ADFCannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AQuantumCannonMuzzle01,
}

ADFCannonOblivionWeapon = Class(DefaultProjectileWeapon) {
    FxChargeMuzzleFlash = {
		'/effects/emitters/oblivion_cannon_flash_01_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_02_emit.bp',
        '/effects/emitters/oblivion_cannon_flash_03_emit.bp',
    },
}

ADFCannonOblivionWeapon02 = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AOblivionCannonMuzzleFlash02,
    FxChargeMuzzleFlash = EffectTemplate.AOblivionCannonChargeMuzzleFlash02,
}

AIFMortarWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {},
}

AIFBombGravitonWeapon = Class(DefaultProjectileWeapon) {}

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


AIFArtillerySonanceShellWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
        '/effects/emitters/aeon_sonance_muzzle_01_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_02_emit.bp',
        '/effects/emitters/aeon_sonance_muzzle_03_emit.bp',
    },
}

AIFBombQuarkWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},
}

AANDepthChargeBombWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/antiair_muzzle_fire_02_emit.bp',},

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
                Army = self.unit:GetArmy(),
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

AANTorpedoCluster = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/aeon_torpedocluster_flash_01_emit.bp',},

    CreateProjectileForWeapon = function(self, bone)
        local proj = self:CreateProjectile(bone)
        local damageTable = self:GetDamageTable()
        local blueprint = self:GetBlueprint()
        local data = {
                Army = self.unit:GetArmy(),
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

AIFSmartCharge = Class(DefaultProjectileWeapon) {
    CreateProjectileAtMuzzle = function(self, muzzle)
        local proj = DefaultProjectileWeapon.CreateProjectileAtMuzzle(self, muzzle)
        local tbl = self:GetBlueprint().DepthCharge
        proj:AddDepthCharge(tbl)
    end,
}

AANChronoTorpedoWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {
		'/effects/emitters/default_muzzle_flash_01_emit.bp',
        '/effects/emitters/default_muzzle_flash_02_emit.bp',
        '/effects/emitters/torpedo_underwater_launch_01_emit.bp',
    },
}


AIFQuasarAntiTorpedoWeapon = Class(DefaultProjectileWeapon) {
	FxMuzzleFlash = EffectTemplate.AQuasarAntiTorpedoFlash,
}


AKamikazeWeapon = Class(KamikazeWeapon) {
    FxMuzzleFlash = {},
}


AIFQuantumWarhead = Class(DefaultProjectileWeapon) {
}
AIFCommanderDeathWeapon = Class(BareBonesWeapon) {
    OnCreate = function(self)
        BareBonesWeapon.OnCreate(self)

        local myBlueprint = self:GetBlueprint()
        # The "or x" is supplying default values in case the blueprint doesn't have an overriding value
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

AIFParagonDeathWeapon = Class(BareBonesWeapon) {
    OnCreate = function(self)
        BareBonesWeapon.OnCreate(self)

        local myBlueprint = self:GetBlueprint()
        # The "or x" is supplying default values in case the blueprint doesn't have an overriding value
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


ACruiseMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/aeon_missile_launch_01_emit.bp', },
}

ADFLaserHighIntensityWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AHighIntensityLaserFlash01,
}


AAATemporalFizzWeapon = Class(DefaultProjectileWeapon) {
    FxChargeEffects = { '/effects/emitters/temporal_fizz_muzzle_charge_01_emit.bp', },
    FxMuzzleFlash = { '/effects/emitters/temporal_fizz_muzzle_flash_01_emit.bp',},
    ChargeEffectMuzzles = {},

    PlayFxRackSalvoChargeSequence = function(self)
        DefaultProjectileWeapon.PlayFxRackSalvoChargeSequence(self)
        local army = self.unit:GetArmy()
        for keyb, valueb in self.ChargeEffectMuzzles do
            for keye, valuee in self.FxChargeEffects do
                CreateAttachedEmitter(self.unit,valueb,army, valuee)
            end
        end
    end,
}


AAASonicPulseBatteryWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/sonic_pulse_muzzle_flash_01_emit.bp',},
}

AAAZealotMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.CZealotLaunch01,
}

AAAZealot02MissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/flash_04_emit.bp' },
}

AAALightDisplacementAutocannonMissileWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ALightDisplacementAutocannonMissileMuzzleFlash,
}

AAAAutocannonQuantumWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = {'/effects/emitters/quantum_displacement_cannon_flash_01_emit.bp',},

}

AIFMissileTacticalSerpentineWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = { '/effects/emitters/aeon_missile_launch_02_emit.bp', },
}

AIFMissileTacticalSerpentine02Weapon = Class(DefaultProjectileWeapon) {
	FxMuzzleFlash = EffectTemplate.ASerpFlash01,
}

AQuantumBeamGenerator = Class(DefaultBeamWeapon) {
    BeamType = QuantumBeamGeneratorCollisionBeam,

    FxUpackingChargeEffects = {},#'/effects/emitters/quantum_generator_charge_01_emit.bp'},
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function( self )
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


AAMSaintWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.ASaintLaunch01,
}

AAMWillOWisp = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.AAntiMissileFlareFlash,
}

ADFPhasonLaser = Class(DefaultBeamWeapon) {
    BeamType = CollisionBeamFile.PhasonLaserCollisionBeam,
    FxMuzzleFlash = {},
    FxChargeMuzzleFlash = {},
    FxUpackingChargeEffects = EffectTemplate.CMicrowaveLaserCharge01,
    FxUpackingChargeEffectScale = 1,

    PlayFxWeaponUnpackSequence = function( self )
        if not self.ContBeamOn then
            local army = self.unit:GetArmy()
            local bp = self:GetBlueprint()
            for k, v in self.FxUpackingChargeEffects do
                for ek, ev in bp.RackBones[self.CurrentRackSalvoNumber].MuzzleBones do
                    CreateAttachedEmitter(self.unit, ev, army, v):ScaleEmitter(self.FxUpackingChargeEffectScale)
                end
            end
            DefaultBeamWeapon.PlayFxWeaponUnpackSequence(self)
        end
    end,
}

#------------------------------------------------------------------------
#  SC1 EXPANSION WEAPONS
#
#------------------------------------------------------------------------
ADFQuantumAutogunWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_DualQuantumAutoGunMuzzleFlash,
}

ADFHeavyDisruptorCannonWeapon = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_HeavyDisruptorCannonMuzzleCharge,
}

AIFQuanticArtillery = Class(DefaultProjectileWeapon) {
    FxMuzzleFlash = EffectTemplate.Aeon_QuanticClusterMuzzleFlash,
    FxChargeMuzzleFlash = EffectTemplate.Aeon_QuanticClusterChargeMuzzleFlash,
}

