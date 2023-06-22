-- ****************************************************************************
-- **
-- **  File     :  /lua/terranunits.lua
-- **  Author(s): John Comes, Dave Tomandl, Gordon Duclos
-- **
-- **  Summary  :
-- **
-- **  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************
---------------------------------------------------------------------------
-- TERRAN DEFAULT UNITS
---------------------------------------------------------------------------
local DefaultUnitsFile = import("/lua/defaultunits.lua")
local AirFactoryUnit = DefaultUnitsFile.AirFactoryUnit
local ConstructionUnit = DefaultUnitsFile.ConstructionUnit
local LandFactoryUnit = DefaultUnitsFile.LandFactoryUnit
local RadarJammerUnit = DefaultUnitsFile.RadarJammerUnit
local SeaFactoryUnit = DefaultUnitsFile.SeaFactoryUnit
local AmphibiousLandUnit = DefaultUnitsFile.AmphibiousLandUnit

local EffectUtil = import("/lua/effectutilities.lua")
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread

--------------------------------------------------------------
--  AIR FACTORY STRUCTURES
--------------------------------------------------------------
---@class TAirFactoryUnit : AirFactoryUnit
TAirFactoryUnit = ClassUnit(AirFactoryUnit) {

    ---@param self TAirFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        WaitSeconds(0.1)
        for _, v in self.BuildEffectBones do
            self.BuildEffectsBag:Add(CreateAttachedEmitter(self, v, self.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateDefaultBuildBeams, unitBeingBuilt, {v}, self.BuildEffectsBag))
        end
    end,

    ---@param self TAirFactoryUnit
    OnPaused = function(self)
        AirFactoryUnit.OnPaused(self)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    OnUnpaused = function(self)
        AirFactoryUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') then
            self:StartArmsMoving()
        end
    end,

    ---@param self TAirFactoryUnit
    ---@param unitBeingBuilt boolean
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        AirFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order  ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self TAirFactoryUnit
    ---@param unitBuilding boolean
    OnStopBuild = function(self, unitBuilding)
        AirFactoryUnit.OnStopBuild(self, unitBuilding)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    OnFailedToBuild = function(self)
        AirFactoryUnit.OnFailedToBuild(self)
        self:StopArmsMoving()
    end,

    ---@param self TAirFactoryUnit
    StartArmsMoving = function(self)
        if not self.ArmsThread then
            self.ArmsThread = self:ForkThread(self.MovingArmsThread)
        end
    end,

    ---@param self TAirFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self TAirFactoryUnit
    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}

--------------------------------------------------------------
--  AIR STAGING STRUCTURES
--------------------------------------------------------------
---@class TAirStagingPlatformUnit : AirStagingPlatformUnit
TAirStagingPlatformUnit = ClassUnit(DefaultUnitsFile.AirStagingPlatformUnit) {}

--------------------------------------------------------------
--  AIR UNITS
--------------------------------------------------------------
---@class TAirUnit : AirUnit
TAirUnit = ClassUnit(DefaultUnitsFile.AirUnit) {}

--------------------------------------------------------------
--  WALL  STRUCTURES
--------------------------------------------------------------
---@class TConcreteStructureUnit : ConcreteStructureUnit
TConcreteStructureUnit = ClassUnit(DefaultUnitsFile.ConcreteStructureUnit) {}

--------------------------------------------------------------
--  Construction Units
--------------------------------------------------------------
---@class TConstructionUnit : ConstructionUnit
TConstructionUnit = ClassUnit(ConstructionUnit) {

    ---@param self TConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        ConstructionUnit.OnStopBeingBuilt(self, builder, layer)
        if self.Layer == 'Water' then
            self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, true)
        end
    end,

    ---@param self TConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        -- Different effect if we have building cube
        if unitBeingBuilt.BuildingCube then
            EffectUtil.CreateUEFBuildSliceBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        else
            EffectUtil.CreateDefaultBuildBeams(self, unitBeingBuilt, self.BuildEffectBones, self.BuildEffectsBag)
        end
    end,

    ---@param self TConstructionUnit
    ---@param new any
    ---@param old any
    LayerChangeTrigger = function(self, new, old)
        if self.Blueprint.Display.AnimationWater then
            if self.TerrainLayerTransitionThread then
                self.TerrainLayerTransitionThread:Destroy()
                self.TerrainLayerTransitionThread = nil
            end
            if (old ~= 'None') then
                self.TerrainLayerTransitionThread = self:ForkThread(self.TransformThread, (new == 'Water'))
            end
        end
    end,

    ---@param self TConstructionUnit
    ---@param water boolean
    TransformThread = function(self, water)
        if not self.TransformManipulator then
            self.TransformManipulator = CreateAnimator(self)
            self.Trash:Add(self.TransformManipulator)
        end

        if water then
            self.TransformManipulator:PlayAnim(self.Blueprint.Display.AnimationWater)
            self.TransformManipulator:SetRate(1)
            self.TransformManipulator:SetPrecedence(0)
        else
            self.TransformManipulator:SetRate(-1)
            self.TransformManipulator:SetPrecedence(0)
            WaitFor(self.TransformManipulator)
            self.TransformManipulator:Destroy()
            self.TransformManipulator = nil
        end
    end,
}

--------------------------------------------------------------
-- ENERGY CREATION STRUCTURES
--------------------------------------------------------------
---@class TEnergyCreationUnit : EnergyCreationUnit
TEnergyCreationUnit = ClassUnit(DefaultUnitsFile.EnergyCreationUnit) {}

--------------------------------------------------------------
-- ENERGY STORAGE STRUCTURES
--------------------------------------------------------------
---@class TEnergyStorageUnit : EnergyStorageUnit
TEnergyStorageUnit = ClassUnit(DefaultUnitsFile.EnergyStorageUnit) {}

--------------------------------------------------------------
--  HOVER LAND UNITS
--------------------------------------------------------------
---@class THoverLandUnit : HoverLandUnit
THoverLandUnit = ClassUnit(DefaultUnitsFile.HoverLandUnit) {}

--------------------------------------------------------------
--  LAND FACTORY STRUCTURES
--------------------------------------------------------------
---@class TLandFactoryUnit : LandFactoryUnit
TLandFactoryUnit = ClassUnit(LandFactoryUnit) {
    ---@param self TConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        WaitSeconds(0.1)
        for _, v in self.BuildEffectBones do
            self.BuildEffectsBag:Add(CreateAttachedEmitter(self, v, self.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateDefaultBuildBeams, unitBeingBuilt, {v}, self.BuildEffectsBag))
        end
    end,
}

--------------------------------------------------------------
--  LAND UNITS
--------------------------------------------------------------
---@class TLandUnit : LandUnit
TLandUnit = ClassUnit(DefaultUnitsFile.LandUnit) {}

--------------------------------------------------------------
--  MASS COLLECTION UNITS
--------------------------------------------------------------
---@class TMassCollectionUnit : MassCollectionUnit
TMassCollectionUnit = ClassUnit(DefaultUnitsFile.MassCollectionUnit) {}

--------------------------------------------------------------
-- MASS FABRICATION STRUCTURES
--------------------------------------------------------------
---@class TMassFabricationUnit : MassFabricationUnit
TMassFabricationUnit = ClassUnit(DefaultUnitsFile.MassFabricationUnit) {}

--------------------------------------------------------------
-- MASS STORAGE STRUCTURES
--------------------------------------------------------------
---@class TMassStorageUnit : MassStorageUnit
TMassStorageUnit = ClassUnit(DefaultUnitsFile.MassStorageUnit) {}

--------------------------------------------------------------
--  MOBILE FACTORY UNIT
--------------------------------------------------------------
---@class TMobileFactoryUnit : AmphibiousLandUnit
TMobileFactoryUnit = ClassUnit(AmphibiousLandUnit) {
    ---@param self TConstructionUnit
    ---@param builder Unit
    ---@param layer Layer
    StartBeingBuiltEffects = function(self, builder, layer)
        self:SetMesh(self:GetBlueprint().Display.BuildMeshBlueprint, true)
        if self:GetBlueprint().General.UpgradesFrom  ~= builder.UnitId then
            self:HideBone(0, true)
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
        end
    end,
}

--------------------------------------------------------------
--  RADAR STRUCTURES
--------------------------------------------------------------
---@class TRadarUnit : RadarUnit
TRadarUnit = ClassUnit(DefaultUnitsFile.RadarUnit) {}

--------------------------------------------------------------
--  SONAR STRUCTURES
--------------------------------------------------------------
---@class TSonarUnit : SonarUnit
TSonarUnit = ClassUnit(DefaultUnitsFile.SonarUnit) {}

--------------------------------------------------------------
--  SEA FACTORY STRUCTURES
--------------------------------------------------------------
---@class TSeaFactoryUnit : SeaFactoryUnit
TSeaFactoryUnit = ClassUnit(SeaFactoryUnit) {
    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        WaitSeconds(0.1)
        for _, v in self.BuildEffectBones do
            self.BuildEffectsBag:Add(CreateAttachedEmitter(self, v, self.Army, '/effects/emitters/flashing_blue_glow_01_emit.bp'))
            self.BuildEffectsBag:Add(self:ForkThread(EffectUtil.CreateDefaultBuildBeams, unitBeingBuilt, {v}, self.BuildEffectsBag))
        end
    end,

    ---@param self TSeaFactoryUnit
    OnPaused = function(self)
        SeaFactoryUnit.OnPaused(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnUnpaused = function(self)
        SeaFactoryUnit.OnUnpaused(self)
        if self:GetNumBuildOrders(categories.ALLUNITS) > 0 and not self:IsUnitState('Upgrading') then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        SeaFactoryUnit.OnStartBuild(self, unitBeingBuilt, order)
        if order  ~= 'Upgrade' then
            self:StartArmsMoving()
        end
    end,

    ---@param self TSeaFactoryUnit
    ---@param unitBuilding boolean
    OnStopBuild = function(self, unitBuilding)
        SeaFactoryUnit.OnStopBuild(self, unitBuilding)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    OnFailedToBuild = function(self)
        SeaFactoryUnit.OnFailedToBuild(self)
        self:StopArmsMoving()
    end,

    ---@param self TSeaFactoryUnit
    StartArmsMoving = function(self)
        if not self.ArmsThread then
            self.ArmsThread = self:ForkThread(self.MovingArmsThread)
        end
    end,

    ---@param self TSeaFactoryUnit
    MovingArmsThread = function(self)
    end,

    ---@param self TSeaFactoryUnit
    StopArmsMoving = function(self)
        if self.ArmsThread then
            KillThread(self.ArmsThread)
            self.ArmsThread = nil
        end
    end,
}

--------------------------------------------------------------
--  SEA UNITS
--------------------------------------------------------------
---@class TSeaUnit : SeaUnit
TSeaUnit = ClassUnit(DefaultUnitsFile.SeaUnit) {}

--------------------------------------------------------------
--  SHIELD LAND UNITS
--------------------------------------------------------------
---@class TShieldLandUnit : ShieldLandUnit
TShieldLandUnit = ClassUnit(DefaultUnitsFile.ShieldLandUnit) {}

--------------------------------------------------------------
--  SHIELD STRUCTURES
--------------------------------------------------------------
---@class TShieldStructureUnit : ShieldStructureUnit
TShieldStructureUnit = ClassUnit(DefaultUnitsFile.ShieldStructureUnit) {}

--------------------------------------------------------------
--  STRUCTURES
--------------------------------------------------------------
---@class TStructureUnit : StructureUnit
TStructureUnit = ClassUnit(DefaultUnitsFile.StructureUnit) {}

---@class TRadarJammerUnit : RadarJammerUnit
---@field MySpinner? moho.RotateManipulator
TRadarJammerUnit = ClassUnit(DefaultUnitsFile.RadarJammerUnit) {

    ---@param self TRadarJammerUnit
    OnIntelEnabled = function(self, intel)
        if not self.MySpinner then
            self.MySpinner = CreateRotator(self, 'Spinner', 'y', nil, 0, 45, 180)
            self.Trash:Add(self.MySpinner)
        end
        RadarJammerUnit.OnIntelEnabled(self, intel)
        self.MySpinner:SetTargetSpeed(180)
    end,

    ---@param self TRadarJammerUnit
    OnIntelDisabled = function(self, intel)
        RadarJammerUnit.OnIntelDisabled(self, intel)
        self.MySpinner:SetTargetSpeed(0)
    end,
}

--------------------------------------------------------------
--  SUBMARINE UNITS
--------------------------------------------------------------
---@class TSubUnit : SubUnit
TSubUnit = ClassUnit(DefaultUnitsFile.SubUnit) {}

--------------------------------------------------------------
--  TRANSPORT BEACON UNITS
--------------------------------------------------------------
---@class TTransportBeaconUnit : TransportBeaconUnit
TTransportBeaconUnit = ClassUnit(DefaultUnitsFile.TransportBeaconUnit) {}

--------------------------------------------------------------
--  WALKING LAND UNITS
--------------------------------------------------------------
---@class TWalkingLandUnit : WalkingLandUnit
TWalkingLandUnit = ClassUnit(DefaultUnitsFile.WalkingLandUnit) { }

--------------------------------------------------------------
--  WALL  STRUCTURES
--------------------------------------------------------------
---@class TWallStructureUnit : WallStructureUnit
TWallStructureUnit = ClassUnit(DefaultUnitsFile.WallStructureUnit) {}

--------------------------------------------------------------
--  CIVILIAN STRUCTURES
--------------------------------------------------------------
---@class TCivilianStructureUnit : StructureUnit
TCivilianStructureUnit = ClassUnit(DefaultUnitsFile.StructureUnit) {}

--------------------------------------------------------------
--  QUANTUM GATE UNITS
--------------------------------------------------------------
---@class TQuantumGateUnit : QuantumGateUnit
TQuantumGateUnit = ClassUnit(DefaultUnitsFile.QuantumGateUnit) {}

--------------------------------------------------------------
--  SHIELD SEA UNITS
--------------------------------------------------------------
---@class TShieldSeaUnit : ShieldSeaUnit
TShieldSeaUnit = ClassUnit(DefaultUnitsFile.ShieldSeaUnit) {}

--------------------------------------------------------------
--  Pod Tower Unit (Kennels)
--------------------------------------------------------------
---@class TPodTowerUnit : TStructureUnit
TPodTowerUnit = ClassUnit(TStructureUnit) {

    ---@param self TPodTowerUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        TStructureUnit.OnStopBeingBuilt(self, builder, layer)
        ChangeState(self, self.FinishedBeingBuilt)
    end,

    ---@param self TPodTowerUnit
    ---@param pod any
    ---@param podData any
    PodTransfer = function(self, pod, podData)
        -- Set the pod as active, set new parent and creator for the pod, store the pod handle
        if not self.PodData[pod.PodName].Active then
            if not self.PodData then
                self.PodData = {}
            end
            self.PodData[pod.PodName] = {}
            self.PodData[pod.PodName].PodHandle = pod
            self.PodData[pod.PodName].PodUnitID = podData.PodUnitID
            self.PodData[pod.PodName].PodName = podData.PodName
            self.PodData[pod.PodName].Active = podData.Active
            self.PodData[pod.PodName].PodAttachpoint = podData.PodAttachpoint
            self.PodData[pod.PodName].CreateWithUnit = podData.CreateWithUnit
            pod:SetParent(self, pod.PodName)
        end
    end,

    ---@param self TPodTowerUnit
    ---@param captor Unit
    OnCaptured = function(self, captor)
        -- Iterate through pod data and set up callbacks for transfer of pods.
        -- We never get the handle to the new tower, so we set up a new unit capture trigger to do the same thing
        -- not the most efficient thing ever but it makes for never having to update the capture codepath here
        for k,v in self.PodData do
            if v.Active then
                v.Active = false

                -- store off the pod name so we can give to new unit
                local podName = k
                local newPod = import("/lua/scenarioframework.lua").GiveUnitToArmy(v.PodHandle, captor.Army)
                newPod.PodName = podName

                -- create a callback for when the unit is flipped.  set creator for the new pod to the new tower
                self:AddUnitCallback(
                    function(newUnit, captor)
                        newUnit:PodTransfer(newPod, v)
                    end,
                    'OnCapturedNewUnit'
                )
            end
        end

        -- Calling the parent OnCaptured will cause all the callbacks to happen and happiness will reign !
        TStructureUnit.OnCaptured(self, captor)
    end,

    ---@param self TPodTowerUnit
    OnDestroy = function(self)
        TStructureUnit.OnDestroy(self)
        -- Iterate through pod data, kill all the pods and set them inactive
        if self.PodData then
            for _, v in self.PodData do
                if v.Active and not v.PodHandle.Dead then
                    v.PodHandle:Kill()
                end
            end
        end
    end,

    ---@param self TPodTowerUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        TStructureUnit.OnStartBuild(self,unitBeingBuilt,order)
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            self.NowUpgrading = true
            ChangeState(self, self.UpgradingState)
        end
    end,

    ---@param self TPodTowerUnit
    ---@param podName string
    NotifyOfPodDeath = function(self,podName)
        self.PodData[podName].Active = false
    end,

    ---@param self TPodTowerUnit
    ---@param podData any
    SetPodConsumptionRebuildRate = function(self, podData)
        local bp = self:GetBlueprint()
        -- Get build rate of tower
        local buildRate = bp.Economy.BuildRate

        local energy_rate = (podData.BuildCostEnergy / podData.BuildTime) * buildRate
        local mass_rate = (podData.BuildCostMass / podData.BuildTime) * buildRate

        -- Set Consumption - Buff system will replace this here
        self:SetConsumptionPerSecondEnergy(energy_rate)
        self:SetConsumptionPerSecondMass(mass_rate)
        self:SetConsumptionActive(true)
    end,

    ---@param self TPodTowerUnit
    ---@param podName string
    ---@return Unit
    CreatePod = function(self, podName)
        local location = self:GetPosition(self.PodData[podName].PodAttachpoint)
        self.PodData[podName].PodHandle = CreateUnitHPR(self.PodData[podName].PodUnitID, self.Army, location[1], location[2], location[3], 0, 0, 0)
        self.PodData[podName].PodHandle:SetParent(self, podName)
        self.PodData[podName].Active = true
        return self.PodData[podName].PodHandle
    end,

    ---@param self TPodTowerUnit
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportAttach = function(self, bone, attachee)
        attachee:SetDoNotTarget(true)
        
        self:PlayUnitSound('Close')
        self:RequestRefreshUI()
        local PodPresent = 0
        for _, v in self.PodData or {} do
            if v.Active then
                PodPresent = PodPresent + 1
            end
        end
        local PodAttached = 0
        for _, v in self:GetCargo() do
            PodAttached = PodAttached + 1
        end
        if PodAttached == PodPresent and self.OpeningAnimationStarted then
            local bp = self:GetBlueprint()
            if not self.OpenAnim then return end
            self.OpenAnim:SetRate(1.5)
            self.OpeningAnimationStarted = false
        end
    end,

    ---@param self TPodTowerUnit
    ---@param bone Bone
    ---@param attachee Unit
    OnTransportDetach = function(self, bone, attachee)
        attachee:SetDoNotTarget(false)

        self:PlayUnitSound('Open')
        self:RequestRefreshUI()
        if not self.OpeningAnimationStarted then
            self.OpeningAnimationStarted = true
            local bp = self:GetBlueprint()
            if not self.OpenAnim then
                self.OpenAnim = CreateAnimator(self)
                self.Trash:Add(self.OpenAnim)
            end
            self.OpenAnim:PlayAnim(bp.Display.AnimationOpen, false):SetRate(2.0)
            -- wait 5 ticks and stop the animation so that the doors stay open
            ForkThread(function ()
                coroutine.yield(5)
                self.OpenAnim:SetRate(0)
            end)
        end
    end,

    ---@param self TPodTowerUnit
    ---@param forceAnimation boolean
    InitializeTower = function(self, forceAnimation)
        -- Create the pod for the kennel.  DO NOT ADD TO TRASH.
        -- This pod may have to be passed to another unit after it upgrades.  We cannot let the trash clean it up
        -- when this unit is destroyed at the tail end of the upgrade.  Make sure the unit dies properly elsewhere.
        self.TowerCaptured = nil
        local bp = self:GetBlueprint()
        for _, v in bp.Economy.EngineeringPods do
            if v.CreateWithUnit and not self.PodData[v.PodName].Active then
                if not self.PodData then
                    self.PodData = {}
                end
                self.PodData[v.PodName] = table.copy(v)
                self:OnTransportDetach(false, self:CreatePod(v.PodName))
            end
        end

        self.InitializedTower = true
    end,

    FinishedBeingBuilt = State {
        Main = function(self)
            -- Wait one tick to make sure this wasn't captured and we don't create an extra pod
            coroutine.yield(1)

            self:InitializeTower()

            ChangeState(self, self.MaintainPodsState)
        end,
    },

    MaintainPodsState = State {
        Main = function(self)
            self.MaintainState = true
            if self.Rebuilding then
                self:SetPodConsumptionRebuildRate(self.PodData[ self.Rebuilding ])
                ChangeState(self, self.RebuildingPodState)
            end
            local bp = self:GetBlueprint()
            while true and not self.Rebuilding do
                for _, v in bp.Economy.EngineeringPods do
                    -- Check if all the pods are active
                    if not self.PodData[v.PodName].Active then
                        -- Cost of new pod
                        local podBP = self:GetAIBrain():GetUnitBlueprint(v.PodUnitID)
                        self.PodData[v.PodName].EnergyRemain = podBP.Economy.BuildCostEnergy
                        self.PodData[v.PodName].MassRemain = podBP.Economy.BuildCostMass

                        self.PodData[v.PodName].BuildCostEnergy = podBP.Economy.BuildCostEnergy
                        self.PodData[v.PodName].BuildCostMass = podBP.Economy.BuildCostMass

                        self.PodData[v.PodName].BuildTime = podBP.Economy.BuildTime

                        -- Enable consumption for the rebuilding
                        self:SetPodConsumptionRebuildRate(self.PodData[v.PodName])

                        -- Change to RebuildingPodState
                        self.Rebuilding = v.PodName
                        self:SetWorkProgress(0.01)
                        ChangeState(self, self.RebuildingPodState)
                    end
                end
                coroutine.yield(1)
            end
        end,

        OnProductionPaused = function(self)
            ChangeState(self, self.PausedState)
        end,
    },

    RebuildingPodState = State {
        Main = function(self)
            local rebuildFinished = false
            local podData = self.PodData[ self.Rebuilding ]
            repeat
                WaitTicks(1)
                -- While the pod being built isn't finished
                -- Update mass and energy given to new pod - update build bar
                local fraction = self:GetResourceConsumed()
                local energy = self:GetConsumptionPerSecondEnergy() * fraction * 0.1
                local mass = self:GetConsumptionPerSecondMass() * fraction * 0.1

                self.PodData[ self.Rebuilding ].EnergyRemain = self.PodData[ self.Rebuilding ].EnergyRemain - energy
                self.PodData[ self.Rebuilding ].MassRemain = self.PodData[ self.Rebuilding ].MassRemain - mass

                self:SetWorkProgress((self.PodData[ self.Rebuilding ].BuildCostMass - self.PodData[ self.Rebuilding ].MassRemain) / self.PodData[ self.Rebuilding ].BuildCostMass)

                if (self.PodData[ self.Rebuilding ].EnergyRemain <= 0) and (self.PodData[ self.Rebuilding ].MassRemain <= 0) then
                    rebuildFinished = true
                end
            until rebuildFinished

            -- create pod, deactivate consumption, clear building
            self:CreatePod(self.Rebuilding)
            self.Rebuilding = false
            self:SetWorkProgress(0)
            self:SetConsumptionPerSecondEnergy(0)
            self:SetConsumptionPerSecondMass(0)
            self:SetConsumptionActive(false)

            ChangeState(self, self.MaintainPodsState)
        end,

        OnProductionPaused = function(self)
            self:SetConsumptionPerSecondEnergy(0)
            self:SetConsumptionPerSecondMass(0)
            self:SetConsumptionActive(false)
            ChangeState(self, self.PausedState)
        end,
    },

    PausedState = State {
        Main = function(self)
            self.MaintainState = false
        end,

        OnProductionUnpaused = function(self)
            ChangeState(self, self.MaintainPodsState)
        end,
    },

    UpgradingState = State {
        Main = function(self)

            -- catch case when tower is immediately upgraded during build
            if not self.InitializedTower then 
                self:InitializeTower()
            end

            local bp = self:GetBlueprint().Display
            self:DestroyTarmac()
            self:PlayUnitSound('UpgradeStart')
            self:DisableDefaultToggleCaps()
            if bp.AnimationUpgrade then
                local unitBuilding = self.UnitBeingBuilt
                self.AnimatorUpgradeManip = CreateAnimator(self)
                self.Trash:Add(self.AnimatorUpgradeManip)
                local fractionOfComplete = 0
                self:StartUpgradeEffects(unitBuilding)
                self.AnimatorUpgradeManip:PlayAnim(bp.AnimationUpgrade, false):SetRate(0)

                while fractionOfComplete < 1 and not self.Dead do
                    fractionOfComplete = unitBuilding:GetFractionComplete()
                    self.AnimatorUpgradeManip:SetAnimationFraction(fractionOfComplete)
                    WaitTicks(1)
                end
                if not self.Dead then
                    self.AnimatorUpgradeManip:SetRate(1)
                end
            end
        end,

        OnProductionPaused = function(self)
            self.MaintainState = false
        end,

        OnProductionUnpaused = function(self)
            self.MaintainState = true
        end,

        OnStopBuild = function(self, unitBuilding)
            TStructureUnit.OnStopBuild(self, unitBuilding)
            self:EnableDefaultToggleCaps()
            if unitBuilding:GetFractionComplete() == 1 then
                NotifyUpgrade(self, unitBuilding)
                self:StopUpgradeEffects(unitBuilding)
                self:PlayUnitSound('UpgradeEnd')
                -- Iterate through pod data and transfer pods to the new unit
                for k,v in self.PodData or {} do
                    if v.Active then
                        unitBuilding:PodTransfer(v.PodHandle, v)
                        v.Active = false
                    end
                end
                self:Destroy()
            end
        end,

        OnFailedToBuild = function(self)
            TStructureUnit.OnFailedToBuild(self)
            self:EnableDefaultToggleCaps()
            self.AnimatorUpgradeManip:Destroy()
            self:PlayUnitSound('UpgradeFailed')
            self:PlayActiveAnimation()
            self:CreateTarmac(true, true, true, self.TarmacBag.Orientation, self.TarmacBag.CurrentBP)
            if self.MaintainState then
                ChangeState(self, self.MaintainPodsState)
            else
                ChangeState(self, self.PausedState)
            end
        end,

    },
}

-- kept for mod compatiablilty
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams