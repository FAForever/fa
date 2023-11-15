--**********************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--**********************************************************************************

local TStructureUnit = import('/lua/terranunits.lua').TStructureUnit

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
        for k, v in self.PodData do
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
        TStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
        local unitid = self:GetBlueprint().General.UpgradesTo
        if unitBeingBuilt.UnitId == unitid and order == 'Upgrade' then
            self.NowUpgrading = true
            ChangeState(self, self.UpgradingState)
        end
    end,

    ---@param self TPodTowerUnit
    ---@param podName string
    NotifyOfPodDeath = function(self, podName)
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
        self.PodData[podName].PodHandle = CreateUnitHPR(self.PodData[podName].PodUnitID, self.Army, location[1],
            location[2], location[3], 0, 0, 0)
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
            ForkThread(function()
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
                self:SetPodConsumptionRebuildRate(self.PodData[self.Rebuilding])
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
            local podData = self.PodData[self.Rebuilding]
            repeat
                WaitTicks(1)
                -- While the pod being built isn't finished
                -- Update mass and energy given to new pod - update build bar
                local fraction = self:GetResourceConsumed()
                local energy = self:GetConsumptionPerSecondEnergy() * fraction * 0.1
                local mass = self:GetConsumptionPerSecondMass() * fraction * 0.1

                self.PodData[self.Rebuilding].EnergyRemain = self.PodData[self.Rebuilding].EnergyRemain - energy
                self.PodData[self.Rebuilding].MassRemain = self.PodData[self.Rebuilding].MassRemain - mass

                self:SetWorkProgress((
                    self.PodData[self.Rebuilding].BuildCostMass - self.PodData[self.Rebuilding].MassRemain) /
                    self.PodData[self.Rebuilding].BuildCostMass)

                if (self.PodData[self.Rebuilding].EnergyRemain <= 0) and
                    (self.PodData[self.Rebuilding].MassRemain <= 0) then
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
                for k, v in self.PodData or {} do
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
