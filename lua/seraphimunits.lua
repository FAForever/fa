-----------------------------------------------------------------
-- File     :  /cdimage/lua/seraphimunits.lua
-- Author(s): Dru Staltman, Jessica St. Croix
-- Summary  : Units for Seraphim
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DefaultUnitsFile = import("/lua/defaultunits.lua")
local FactoryUnit = DefaultUnitsFile.FactoryUnit
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local AirStagingPlatformUnit = DefaultUnitsFile.AirStagingPlatformUnit
local AirUnit = DefaultUnitsFile.AirUnit
local ConcreteStructureUnit = DefaultUnitsFile.ConcreteStructureUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local EnergyCreationUnit = DefaultUnitsFile.EnergyCreationUnit
local EnergyStorageUnit = DefaultUnitsFile.EnergyStorageUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local MassCollectionUnit = DefaultUnitsFile.MassCollectionUnit
local MassFabricationUnit = DefaultUnitsFile.MassFabricationUnit
local MassStorageUnit = DefaultUnitsFile.MassStorageUnit
local RadarUnit = DefaultUnitsFile.RadarUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local ShieldHoverLandUnit = DefaultUnitsFile.ShieldHoverLandUnit
local ShieldLandUnit = DefaultUnitsFile.ShieldLandUnit
local ShieldStructureUnit = DefaultUnitsFile.ShieldStructureUnit
local SonarUnit = DefaultUnitsFile.SonarUnit
local StructureUnit = DefaultUnitsFile.StructureUnit
local QuantumGateUnit = DefaultUnitsFile.QuantumGateUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit

local WeaponFile = import("/lua/sim/defaultweapons.lua")
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local EffectTemplate = import("/lua/effecttemplates.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local CreateSeraphimFactoryBuildingEffects = EffectUtil.CreateSeraphimFactoryBuildingEffects

-- FACTORIES
---@class SFactoryUnit : FactoryUnit
SFactoryUnit = ClassUnit(FactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffects, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        self.BuildEffectsBag:Add(thread)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffects, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        self.BuildEffectsBag:Add(thread)
    end,

    OnPaused = function(self)
        StructureUnit.OnPaused(self)
        -- When factory is paused take some action
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            self:StopUnitAmbientSound('ConstructLoop')
            self:StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') and self.UnitBeingBuilt then
            self:StartBuildFxUnpause(self:GetFocusUnit())
        end
    end,
}

-- AIR STRUCTURES
---@class SAirFactoryUnit : AirFactoryUnit
SAirFactoryUnit = ClassUnit(AirFactoryUnit) {
    StartBuildFx = SFactoryUnit.StartBuildFx,
    StartBuildFxUnpause = SFactoryUnit.StartBuildFxUnpause,
    OnPaused = SFactoryUnit.OnPaused,
    OnUnpaused = SFactoryUnit.OnUnpaused,

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        if unitBeingBuilt and not unitBeingBuilt.Dead and EntityCategoryContains(categories.AIR, unitBeingBuilt) then
            unitBeingBuilt:DetachFrom(true)
            local bp = self:GetBlueprint()
            self:DetachAll(bp.Display.BuildAttachBone or 0)
        end
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end
    end,

    CreateRollOffEffects = function(self)
    end,

    DestroyRollOffEffects = function(self)
    end,

    RollOffUnit = function(self)
        if EntityCategoryContains(categories.AIR, self.UnitBeingBuilt) then
            local spin, x, y, z = self:CalculateRollOffPoint()
            local units = {self.UnitBeingBuilt}
            self.MoveCommand = IssueMove(units, Vector(x, y, z))
        end
    end,

    RolloffBody = function(self)
        self:SetBusy(true)
        local unitBuilding = self.UnitBeingBuilt

        -- If the unit being built isn't an engineer use normal rolloff
        if not EntityCategoryContains(categories.LAND, unitBuilding) then
            AirFactoryUnit.RolloffBody(self)
        else

            if not IsDestroyed(unitBuilding) then
                unitBuilding:DetachFrom(true)
                self:DetachAll(self.Blueprint.Display.BuildAttachBone or 0)

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                unitBuilding:HideBone(0, true)
            end

            WaitTicks(4)

            if not IsDestroyed(unitBuilding) then
                CreateLightParticle(unitBuilding, -1, unitBuilding.Army, 4, 12, 'glow_02', 'ramp_blue_22')
                unitBuilding:ShowBone(0, true)

                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_04_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_05_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_06_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_07_emit.bp'):OffsetEmitter(0, -1, 0)
                CreateEmitterAtBone(unitBuilding, -1, unitBuilding.Army, '/effects/emitters/seraphim_rifter_mobileartillery_hit_08_emit.bp'):OffsetEmitter(0, -1, 0)
            end

            WaitTicks(8)

            self:SetBusy(false)
            ChangeState(self, self.IdleState)
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            -- Stop pods that exist in the upgraded unit
            local savedAngle
            if self.Rotator1 then
                savedAngle = self.Rotator1:GetCurrentAngle()
                self.Rotator1:SetGoal(savedAngle)
                unitBeingBuilt.Rotator1:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator1:SetGoal(savedAngle)
                -- Freeze the next rotator to 0, since that's where it will be
                unitBeingBuilt.Rotator2:SetCurrentAngle(0)
                unitBeingBuilt.Rotator2:SetGoal(0)
            end

            if self.Rotator2 then
                savedAngle = self.Rotator2:GetCurrentAngle()
                self.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator2:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator3:SetCurrentAngle(0)
                unitBeingBuilt.Rotator3:SetGoal(0)
            end
        end
        AirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    UpgradingState = State(AirFactoryUnit.UpgradingState) {
        OnStopBuild = function(self, unitBuilding)
            if unitBuilding:GetFractionComplete() == 1 then
                -- Start halted rotators on upgraded unit
                if unitBuilding.Rotator1 then
                    unitBuilding.Rotator1:ClearGoal()
                end
                if unitBuilding.Rotator2 then
                    unitBuilding.Rotator2:ClearGoal()
                end
                if unitBuilding.Rotator3 then
                    unitBuilding.Rotator3:ClearGoal()
                end
            end
            AirFactoryUnit.UpgradingState.OnStopBuild(self, unitBuilding)
        end,

        OnFailedToBuild = function(self)
           AirFactoryUnit.UpgradingState.OnFailedToBuild(self)
           -- Failed to build, so resume rotators
           if self.Rotator1 then
               self.Rotator1:ClearGoal()
               self.Rotator1:SetSpeed(5)
           end

            if self.Rotator2 then
               self.Rotator2:ClearGoal()
               self.Rotator2:SetSpeed(5)
           end
        end,
    },
}

-- AIR UNITS
---@class SAirUnit : AirUnit
SAirUnit = ClassUnit(AirUnit) {
    ContrailEffects = {'/effects/emitters/contrail_ser_polytrail_01_emit.bp'}
}

--  AIR STAGING STRUCTURES
---@class SAirStagingPlatformUnit : AirStagingPlatformUnit
SAirStagingPlatformUnit = ClassUnit(AirStagingPlatformUnit) {}

-- WALL  STRUCTURES
---@class SConcreteStructureUnit : ConcreteStructureUnit
SConcreteStructureUnit = ClassUnit(ConcreteStructureUnit) {
    AdjacencyBeam = false,
}

-- Construction Units
---@class SConstructionUnit : ConstructionUnit
SConstructionUnit = ClassUnit(ConstructionUnit) {
    OnCreate = function(self)
        ConstructionUnit.OnCreate(self)
        if self.BuildingOpenAnim then
            if self.BuildArm2Manipulator then
                self.BuildArm2Manipulator:Disable()
            end
        end
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        EffectUtil.CreateSeraphimUnitEngineerBuildingEffects(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
    end,

    SetupBuildBones = function(self)
        ConstructionUnit.SetupBuildBones(self)

        local bp = self:GetBlueprint()
        local buildbones = bp.General.BuildBones
        if self.BuildArmManipulator then
            self.BuildArmManipulator:SetAimingArc(buildbones.YawMin or -180, buildbones.YawMax or 180, buildbones.YawSlew or 360, buildbones.PitchMin or -90, buildbones.PitchMax or 90, buildbones.PitchSlew or 360)
        end
        if bp.General.BuildBonesAlt1 then
            self.BuildArm2Manipulator = CreateBuilderArmController(self, bp.General.BuildBonesAlt1.YawBone or 0 , bp.General.BuildBonesAlt1.PitchBone or 0, bp.General.BuildBonesAlt1.AimBone or 0)
            self.BuildArm2Manipulator:SetAimingArc(bp.General.BuildBonesAlt1.YawMin or -180, bp.General.BuildBonesAlt1.YawMax or 180, bp.General.BuildBonesAlt1.YawSlew or 360, bp.General.BuildBonesAlt1.PitchMin or -90, bp.General.BuildBonesAlt1.PitchMax or 90, bp.General.BuildBonesAlt1.PitchSlew or 360)
            self.BuildArm2Manipulator:SetPrecedence(5)
            if self.BuildingOpenAnimManip and self.Build2ArmManipulator then
                self.BuildArm2Manipulator:Disable()
            end
            self.Trash:Add(self.BuildArm2Manipulator)
        end
    end,

    BuildManipulatorSetEnabled = function(self, enable)
        ConstructionUnit.BuildManipulatorSetEnabled(self, enable)
        if not self or self.Dead then return end
        if not self.BuildArm2Manipulator then return end
        if enable then
            self.BuildArm2Manipulator:Enable()
        else
            self.BuildArm2Manipulator:Disable()
        end
    end,

    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if enable then
                self:BuildManipulatorSetEnabled(enable)
            end
        end
    end,

    OnStopBuilderTracking = function(self)
        ConstructionUnit.OnStopBuilderTracking(self)
        if self.StoppedBuilding then
            self:BuildManipulatorSetEnabled(disable)
        end
    end,
}

-- ENERGY CREATION UNITS
---@class SEnergyCreationUnit : EnergyCreationUnit
SEnergyCreationUnit = ClassUnit(EnergyCreationUnit) {
    OnCreate = function(self)
        EnergyCreationUnit.OnCreate(self)
        self.NumUsedAdjacentUnits = 0
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        EnergyCreationUnit.OnStopBeingBuilt(self, builder, layer)
        if self.AmbientEffects then
            for k, v in EffectTemplate[self.AmbientEffects] do
                CreateAttachedEmitter(self, 0, self.Army, v)
            end
        end
    end,
}

-- ENERGY STORAGE STRUCTURES
---@class SEnergyStorageUnit : EnergyStorageUnit
SEnergyStorageUnit = ClassUnit(EnergyStorageUnit) {}

-- HOVERING LAND UNITS
---@class SHoverLandUnit : HoverLandUnit
SHoverLandUnit = ClassUnit(DefaultUnitsFile.HoverLandUnit) {
    FxHoverScale = 1,
    HoverEffects = nil,
    HoverEffectBones = nil,
}

-- LAND FACTORY STRUCTURES
---@class SLandFactoryUnit : LandFactoryUnit
SLandFactoryUnit = ClassUnit(LandFactoryUnit) {
    StartBuildFx = SFactoryUnit.StartBuildFx,
    StartBuildFxUnpause = SFactoryUnit.StartBuildFxUnpause,
    OnPaused = SFactoryUnit.OnPaused,
    OnUnpaused = SFactoryUnit.OnUnpaused,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            -- Stop pods that exist in the upgraded unit
            local savedAngle
            if self.Rotator1 then
                savedAngle = self.Rotator1:GetCurrentAngle()
                self.Rotator1:SetGoal(savedAngle)
                unitBeingBuilt.Rotator1:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator1:SetGoal(savedAngle)
                -- Freeze the next rotator to 0, since that's where it will be
                unitBeingBuilt.Rotator2:SetCurrentAngle(0)
                unitBeingBuilt.Rotator2:SetGoal(0)
            end

            if self.Rotator2 then
                savedAngle = self.Rotator2:GetCurrentAngle()
                self.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator2:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator3:SetCurrentAngle(0)
                unitBeingBuilt.Rotator3:SetGoal(0)
            end
        end
        LandFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    UpgradingState = State(LandFactoryUnit.UpgradingState) {
        OnStopBuild = function(self, unitBuilding)
            if unitBuilding:GetFractionComplete() == 1 then
                -- Start halted rotators on upgraded unit
                if unitBuilding.Rotator1 then
                    unitBuilding.Rotator1:ClearGoal()
                end
                if unitBuilding.Rotator2 then
                    unitBuilding.Rotator2:ClearGoal()
                end
                if unitBuilding.Rotator3 then
                    unitBuilding.Rotator3:ClearGoal()
                end
            end
            LandFactoryUnit.UpgradingState.OnStopBuild(self, unitBuilding)
        end,

        OnFailedToBuild = function(self)
           LandFactoryUnit.UpgradingState.OnFailedToBuild(self)
           -- Failed to build, so resume rotators
           if self.Rotator1 then
               self.Rotator1:ClearGoal()
               self.Rotator1:SetSpeed(5)
           end

            if self.Rotator2 then
               self.Rotator2:ClearGoal()
               self.Rotator2:SetSpeed(5)
           end
        end,
    },
}

-- LAND UNITS
---@class SLandUnit : LandUnit
SLandUnit = ClassUnit(DefaultUnitsFile.LandUnit) {}

-- MASS COLLECTION UNITS
---@class SMassCollectionUnit : MassCollectionUnit
SMassCollectionUnit = ClassUnit(MassCollectionUnit) {}

-- MASS FABRICATION STRUCTURES
---@class SMassFabricationUnit : MassFabricationUnit
SMassFabricationUnit = ClassUnit(MassFabricationUnit) {}

-- MASS STORAGE UNITS
---@class SMassStorageUnit : MassStorageUnit
SMassStorageUnit = ClassUnit(MassStorageUnit) {}

-- RADAR STRUCTURES
---@class SRadarUnit : RadarUnit
SRadarUnit = ClassUnit(RadarUnit) {}

-- RADAR STRUCTURES
---@class SSonarUnit : SonarUnit
SSonarUnit = ClassUnit(SonarUnit) {}

-- SEA FACTORY STRUCTURES
---@class SSeaFactoryUnit : SeaFactoryUnit
SSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {
    StartBuildFx = SFactoryUnit.StartBuildFx,
    StartBuildFxUnpause = SFactoryUnit.StartBuildFxUnpause,
    OnPaused = SFactoryUnit.OnPaused,
    OnUnpaused = SFactoryUnit.OnUnpaused,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            -- Stop pods that exist in the upgraded unit
            local savedAngle
            if self.Rotator1 then
                savedAngle = self.Rotator1:GetCurrentAngle()
                self.Rotator1:SetGoal(savedAngle)
                unitBeingBuilt.Rotator1:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator1:SetGoal(savedAngle)
                -- Freeze the next rotator to 0, since that's where it will be
                unitBeingBuilt.Rotator2:SetCurrentAngle(0)
                unitBeingBuilt.Rotator2:SetGoal(0)
            end

            if self.Rotator2 then
                savedAngle = self.Rotator2:GetCurrentAngle()
                self.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator2:SetCurrentAngle(savedAngle)
                unitBeingBuilt.Rotator2:SetGoal(savedAngle)
                unitBeingBuilt.Rotator3:SetCurrentAngle(0)
                unitBeingBuilt.Rotator3:SetGoal(0)
            end
        end
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
    end,

    UpgradingState = State(SeaFactoryUnit.UpgradingState) {
        OnStopBuild = function(self, unitBuilding)
            if unitBuilding:GetFractionComplete() == 1 then
                -- Start halted rotators on upgraded unit
                if unitBuilding.Rotator1 then
                    unitBuilding.Rotator1:ClearGoal()
                end
                if unitBuilding.Rotator2 then
                    unitBuilding.Rotator2:ClearGoal()
                end
                if unitBuilding.Rotator3 then
                    unitBuilding.Rotator3:ClearGoal()
                end
            end
            SeaFactoryUnit.UpgradingState.OnStopBuild(self, unitBuilding)
        end,

        OnFailedToBuild = function(self)
            SeaFactoryUnit.UpgradingState.OnFailedToBuild(self)
            -- Failed to build, so resume rotators
            if self.Rotator1 then
                self.Rotator1:ClearGoal()
                self.Rotator1:SetSpeed(5)
            end

            if self.Rotator2 then
               self.Rotator2:ClearGoal()
               self.Rotator2:SetSpeed(5)
           end
        end,
    },
}

-- SEA UNITS
---@class SSeaUnit : SeaUnit
SSeaUnit = ClassUnit(DefaultUnitsFile.SeaUnit) {}

-- SHIELD LAND UNITS
---@class SShieldHoverLandUnit : ShieldHoverLandUnit
SShieldHoverLandUnit = ClassUnit(ShieldHoverLandUnit) {}

-- SHIELD LAND UNITS
---@class SShieldLandUnit : ShieldLandUnit
SShieldLandUnit = ClassUnit(ShieldLandUnit) {}

-- SHIELD STRUCTURES
---@class SShieldStructureUnit : ShieldStructureUnit
SShieldStructureUnit = ClassUnit(ShieldStructureUnit) {
    OnShieldEnabled = function(self)
        ShieldStructureUnit.OnShieldEnabled(self)

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
            self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false)
        end
        self.AnimationManipulator:SetRate(1)
    end,

    OnShieldDisabled = function(self)
        ShieldStructureUnit.OnShieldDisabled(self)
        if not self.AnimationManipulator then return end

        self.AnimationManipulator:SetRate(-1)
    end,
}

-- STRUCTURES
---@class SStructureUnit : StructureUnit
SStructureUnit = ClassUnit(StructureUnit) {}

-- SUBMARINE UNITS
---@class SSubUnit : SubUnit
SSubUnit = ClassUnit(DefaultUnitsFile.SubUnit) {
    IdleSubBones = {},
    IdleSubEffects = {}
}

-- TRANSPORT BEACON UNITS
---@class STransportBeaconUnit : TransportBeaconUnit
STransportBeaconUnit = ClassUnit(DefaultUnitsFile.TransportBeaconUnit) {}

-- WALKING LAND UNITS
---@class SWalkingLandUnit : WalkingLandUnit
SWalkingLandUnit = DefaultUnitsFile.WalkingLandUnit

-- WALL  STRUCTURES
---@class SWallStructureUnit : WallStructureUnit
SWallStructureUnit = Class(DefaultUnitsFile.WallStructureUnit) {}

-- CIVILIAN STRUCTURES
---@class SCivilianStructureUnit : SStructureUnit
SCivilianStructureUnit = ClassUnit(SStructureUnit) {}

-- QUANTUM GATE UNITS
---@class SQuantumGateUnit : QuantumGateUnit
SQuantumGateUnit = ClassUnit(QuantumGateUnit) {}

-- RADAR JAMMER UNITS
---@class SRadarJammerUnit : RadarJammerUnit
SRadarJammerUnit = ClassUnit(RadarJammerUnit) {}

-- Seraphim energy ball units
---@class SEnergyBallUnit : SHoverLandUnit
SEnergyBallUnit = ClassUnit(SHoverLandUnit) {
    timeAlive = 0,

    OnCreate = function(self)
        SHoverLandUnit.OnCreate(self)
        self:SetUnSelectable(true)
        self.CanTakeDamage = false
        self.CanBeKilled = false
        self:PlayUnitSound('Spawn')
        ChangeState(self, self.KillingState)
    end,

    KillingState = State {
        LifeThread = function(self)
            WaitSeconds(self:GetBlueprint().Lifetime)
            ChangeState(self, self.DeathState)
        end,

        Main = function(self)
            local bp = self:GetBlueprint()
            local aiBrain = self:GetAIBrain()

            -- Queue up random moves
            local x, y,z = unpack(self:GetPosition())
            for i = 1, 100 do
                IssueToUnitMove(self, {x + Random(-bp.MaxMoveRange, bp.MaxMoveRange), y, z + Random(-bp.MaxMoveRange, bp.MaxMoveRange)})
            end

            -- Weapon information
            local weaponMaxRange = bp.Weapon[1].MaxRadius
            local weaponMinRange = bp.Weapon[1].MinRadius or 0
            local beamLifetime = bp.Weapon[1].BeamLifetime or 1
            local reaquireTime = bp.Weapon[1].RequireTime or 0.5
            local weapon = self:GetWeapon(1)

            self:ForkThread(self.LifeThread)

            while true do
                local location = self:GetPosition()
                local targets = aiBrain:GetUnitsAroundPoint(categories.LAND - categories.UNTARGETABLE, location, weaponMaxRange)

                local filteredUnits = {}
                for k, v in targets do
                    if VDist3(location, v:GetPosition()) >= weaponMinRange and v ~= self then
                        table.insert(filteredUnits, v)
                    end
                end

                local target = table.random(filteredUnits)
                if target then
                    weapon:SetTargetEntity(target)
                else
                    weapon:SetTargetGround({location[1] + Random(-20, 20), location[2], location[3] + Random(-20, 20)})
                end
                -- Wait a tick to let the target update awesomely.
                WaitTicks(2)
                self.timeAlive = self.timeAlive + .1

                weapon:FireWeapon()

                WaitSeconds(beamLifetime)
                DefaultBeamWeapon.PlayFxBeamEnd(weapon, weapon.Beams[1].Beam)
                WaitSeconds(reaquireTime)
            end
        end,

        ComputeWaitTime = function(self)
            local timeLeft = self:GetBlueprint().Lifetime - self.timeAlive

            local maxWait = 75
            if timeLeft < 7.5 and timeLeft > 2.5 then
                maxWait = timeLeft * 10
            end
            local waitTime = timeLeft
            if timeLeft > 2.5 then
                waitTime = Random(5, maxWait)
            end

            self.timeAlive = self.timeAlive + (waitTime * .1)
            WaitSeconds(waitTime * .1)
        end,
    },

    DeathState = State {
        Main = function(self)
            self.CanBeKilled = true
            if self.Layer == 'Water' then
                self:PlayUnitSound('HoverKilledOnWater')
            end
            self:PlayUnitSound('Destroyed')
            self:Destroy()
        end,
    },
}
