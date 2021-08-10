-----------------------------------------------------------------
-- File     :  /cdimage/lua/seraphimunits.lua
-- Author(s): Dru Staltman, Jessica St. Croix
-- Summary  : Units for Seraphim
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local DefaultUnitsFile = import('defaultunits.lua')
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

local WeaponFile = import('/lua/sim/DefaultWeapons.lua')
local DefaultBeamWeapon = WeaponFile.DefaultBeamWeapon

local EffectTemplate = import('/lua/EffectTemplates.lua')
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateSeraphimFactoryBuildingEffects = EffectUtil.CreateSeraphimFactoryBuildingEffects
local CreateSeraphimFactoryBuildingEffectsUnPause = EffectUtil.CreateSeraphimFactoryBuildingEffectsUnPause

-- FACTORIES
SFactoryUnit = Class(FactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffects, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        local BuildBones = self.BuildEffectBones
        local thread = self:ForkThread(CreateSeraphimFactoryBuildingEffectsUnPause, unitBeingBuilt, BuildBones, 'Attachpoint', self.BuildEffectsBag)
        unitBeingBuilt.Trash:Add(thread)
    end,

    OnPaused = function(self)
        -- When factory is paused take some action
        if self:IsUnitState('Building') and self.unitBeingBuilt then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
            self:StartBuildFx(self:GetFocusUnit())
        end
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        FactoryUnit.OnUnpaused(self)
        if self:IsUnitState('Building') and self.unitBeingBuilt then
            self:StartBuildFxUnpause(self:GetFocusUnit())
        end
    end,
}

-- AIR STRUCTURES
SAirFactoryUnit = Class(AirFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFxUnpause(self, unitBeingBuilt)
    end,

    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        if unitBeingBuilt and not unitBeingBuilt.Dead and EntityCategoryContains(categories.AIR, unitBeingBuilt) then
            unitBeingBuilt:DetachFrom(true)
            local bp = self.Blueprint
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
        local unitB = self.UnitBeingBuilt
        if not self.ReleaseEffectsBag then self.ReleaseEffectsBag = {} end
        for _, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, self.Army, EffectTemplate.TTransportBeam01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            fx = AttachBeamEntityToEntity(unitB, -1, self, v, self.Army, EffectTemplate.TTransportBeam02)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            fx = CreateEmitterAtBone(self, v, self.Army, EffectTemplate.TTransportGlow01)
            table.insert(self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for _, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
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
            -- Engineers need to be slid off the factory
            local bp = self.Blueprint
            if not self.AttachmentSliderManip then
                self.AttachmentSliderManip = CreateSlider(self, bp.Display.BuildAttachBone or 0)
            end

            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(50)  -- Was 30, increased to help engineers move faster off of it
            self.AttachmentSliderManip:SetGoal(0, 0, 60)
            WaitFor(self.AttachmentSliderManip)

            self.AttachmentSliderManip:SetGoal(0, -55, 60)
            WaitFor(self.AttachmentSliderManip)

            if not unitBuilding.Dead then
                unitBuilding:DetachFrom(true)
                self:DetachAll(bp.Display.BuildAttachBone or 0)
            end

            if self.AttachmentSliderManip then
                self.AttachmentSliderManip:Destroy()
                self.AttachmentSliderManip = nil
            end
            self:DestroyRollOffEffects()
            self:SetBusy(false)

            ChangeState(self, self.IdleState)
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self.Blueprint.General.UpgradesTo
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

    OnPaused = function(self)
        SFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        SFactoryUnit.OnUnpaused(self)
    end,
}

-- AIR UNITS
SAirUnit = Class(AirUnit) {
    ContrailEffects = {'/effects/emitters/contrail_ser_polytrail_01_emit.bp'}
}

--  AIR STAGING STRUCTURES
SAirStagingPlatformUnit = Class(AirStagingPlatformUnit) {}

-- WALL  STRUCTURES
SConcreteStructureUnit = Class(ConcreteStructureUnit) {
    AdjacencyBeam = false,
}

-- Construction Units
SConstructionUnit = Class(ConstructionUnit) {
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

        local bp = self.Blueprint
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
SEnergyCreationUnit = Class(EnergyCreationUnit) {
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
SEnergyStorageUnit = Class(EnergyStorageUnit) {}

-- HOVERING LAND UNITS
SHoverLandUnit = Class(DefaultUnitsFile.HoverLandUnit) {
    FxHoverScale = 1,
    HoverEffects = nil,
    HoverEffectBones = nil,
}

-- LAND FACTORY STRUCTURES
SLandFactoryUnit = Class(LandFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFxUnpause(self, unitBeingBuilt)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self.Blueprint.General.UpgradesTo
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

    OnPaused = function(self)
        SFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        SFactoryUnit.OnUnpaused(self)
    end,
}

-- LAND UNITS
SLandUnit = Class(DefaultUnitsFile.LandUnit) {}

-- MASS COLLECTION UNITS
SMassCollectionUnit = Class(MassCollectionUnit) {}

-- MASS FABRICATION STRUCTURES
SMassFabricationUnit = Class(MassFabricationUnit) {}

-- MASS STORAGE UNITS
SMassStorageUnit = Class(MassStorageUnit) {}

-- RADAR STRUCTURES
SRadarUnit = Class(RadarUnit) {}

-- RADAR STRUCTURES
SSonarUnit = Class(SonarUnit) {}

-- SEA FACTORY STRUCTURES
SSeaFactoryUnit = Class(SeaFactoryUnit) {
    StartBuildFx = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFx(self, unitBeingBuilt)
    end,

    StartBuildFxUnpause = function(self, unitBeingBuilt)
        SFactoryUnit.StartBuildFxUnpause(self, unitBeingBuilt)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        -- Set goal for rotator
        local unitid = self.Blueprint.General.UpgradesTo
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

    OnPaused = function(self)
        SFactoryUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        SFactoryUnit.OnUnpaused(self)
    end,
}

-- SEA UNITS
SSeaUnit = Class(DefaultUnitsFile.SeaUnit) {}

-- SHIELD LAND UNITS
SShieldHoverLandUnit = Class(ShieldHoverLandUnit) {}

-- SHIELD LAND UNITS
SShieldLandUnit = Class(ShieldLandUnit) {}

-- SHIELD STRUCTURES
SShieldStructureUnit = Class(ShieldStructureUnit) {
    OnShieldEnabled = function(self)
        ShieldStructureUnit.OnShieldEnabled(self)

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
            self.AnimationManipulator:PlayAnim(self.Blueprint.Display.AnimationActivate, false)
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
SStructureUnit = Class(StructureUnit) {}

-- SUBMARINE UNITS
SSubUnit = Class(DefaultUnitsFile.SubUnit) {
    IdleSubBones = {},
    IdleSubEffects = {}
}

-- TRANSPORT BEACON UNITS
STransportBeaconUnit = Class(DefaultUnitsFile.TransportBeaconUnit) {}

-- WALKING LAND UNITS
SWalkingLandUnit = DefaultUnitsFile.WalkingLandUnit

-- WALL  STRUCTURES
SWallStructureUnit = Class(DefaultUnitsFile.WallStructureUnit) {}

-- CIVILIAN STRUCTURES
SCivilianStructureUnit = Class(SStructureUnit) {}

-- QUANTUM GATE UNITS
SQuantumGateUnit = Class(QuantumGateUnit) {}

-- RADAR JAMMER UNITS
SRadarJammerUnit = Class(RadarJammerUnit) {}

-- Seraphim energy ball units
SEnergyBallUnit = Class(SHoverLandUnit) {
    timeAlive = 0,

    OnCreate = function(self)
        SHoverLandUnit.OnCreate(self)
        self:SetCanTakeDamage(false)
        self:SetCanBeKilled(false)
        self:PlayUnitSound('Spawn')
        ChangeState(self, self.KillingState)
    end,

    KillingState = State {
        LifeThread = function(self)
            WaitSeconds(self.Blueprint.Lifetime)
            ChangeState(self, self.DeathState)
        end,

        Main = function(self)
            local bp = self.Blueprint
            local aiBrain = self:GetAIBrain()

            -- Queue up random moves
            local x, y,z = unpack(self:GetPosition())
            for i = 1, 100 do
                IssueMove({self}, {x + Random(-bp.MaxMoveRange, bp.MaxMoveRange), y, z + Random(-bp.MaxMoveRange, bp.MaxMoveRange)})
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
                local target = filteredUnits[Random(1, table.getn(filteredUnits))]
                if target then
                    weapon:SetTargetEntity(target)
                else
                    weapon:SetTargetGround({location[1] + Random(-20, 20), location[2], location[3] + Random(-20, 20)})
                end
                -- Wait a tick to let the target update awesomely.
                WaitSeconds(.1)
                self.timeAlive = self.timeAlive + .1
                weapon:FireWeapon()

                WaitSeconds(beamLifetime)
                DefaultBeamWeapon.PlayFxBeamEnd(weapon, weapon.Beams[1].Beam)
                WaitSeconds(reaquireTime)
            end
        end,

        ComputeWaitTime = function(self)
            local timeLeft = self.Blueprint.Lifetime - self.timeAlive

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
            self:SetCanBeKilled(true)
            if self:GetCurrentLayer() == 'Water' then
                self:PlayUnitSound('HoverKilledOnWater')
            end
            self:PlayUnitSound('Destroyed')
            self:Destroy()
        end,
    },
}
