local StructureUnit = import('/lua/sim/units/StructureUnit.lua').StructureUnit

--- Base class for factories.
FactoryUnit = Class(StructureUnit) {
    OnCreate = function(self)
        -- Engymod addition: If a normal factory is created, we should check for research stations
        if EntityCategoryContains(categories.FACTORY, self) then
            self:updateBuildRestrictions()
        end

        StructureUnit.OnCreate(self)
        self.BuildingUnit = false
    end,

    -- Added to add engymod logic
    OnDestroy = function(self)
        -- Figure out if we're a research station
        if EntityCategoryContains(categories.RESEARCH, self) then
            local aiBrain = self:GetAIBrain()
            local buildRestrictionVictims = aiBrain:GetListOfUnits(categories.FACTORY+categories.ENGINEER, false)

            for id, unit in buildRestrictionVictims do
                unit:updateBuildRestrictions()
            end
        end

        StructureUnit.OnDestroy(self)
    end,

    OnPaused = function(self)
        --When factory is paused take some action
        self:StopUnitAmbientSound( 'ConstructLoop' )
        StructureUnit.OnPaused(self)
    end,

    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound( 'ConstructLoop' )
        end
        StructureUnit.OnUnpaused(self)
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        local aiBrain = GetArmyBrain(self:GetArmy())
        aiBrain:ESRegisterUnitMassStorage(self)
        aiBrain:ESRegisterUnitEnergyStorage(self)
        local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
        local curMass = aiBrain:GetEconomyStoredRatio('MASS')
        if curEnergy > 0.11 and curMass > 0.11 then
            self:CreateBlinkingLights('Green')
            self.BlinkingLightsState = 'Green'
        else
            self:CreateBlinkingLights('Red')
            self.BlinkingLightsState = 'Red'
        end

        -- If we're a HQ, update build restrictions for all factories
        if EntityCategoryContains(categories.RESEARCH, self) then
            local buildRestrictionVictims = aiBrain:GetListOfUnits(categories.FACTORY + categories.ENGINEER, false)
            for id, unit in buildRestrictionVictims do
                unit:updateBuildRestrictions()
            end
        end

        StructureUnit.OnStopBeingBuilt(self,builder,layer)
    end,

    ChangeBlinkingLights = function(self, state)
        local bls = self.BlinkingLightsState
        if state == 'Yellow' then
            if bls == 'Green' then
                self:CreateBlinkingLights('Yellow')
                self.BlinkingLightsState = state
            end
        elseif state == 'Green' then
            if bls == 'Yellow' then
                self:CreateBlinkingLights('Green')
                self.BlinkingLightsState = state
            elseif bls == 'Red' then
                local aiBrain = GetArmyBrain(self:GetArmy())
                local curEnergy = aiBrain:GetEconomyStoredRatio('ENERGY')
                local curMass = aiBrain:GetEconomyStoredRatio('MASS')
                if curEnergy > 0.11 and curMass > 0.11 then
                    if self:GetNumBuildOrders(categories.ALLUNITS) == 0 then
                        self:CreateBlinkingLights('Green')
                        self.BlinkingLightsState = state
                    else
                        self:CreateBlinkingLights('Yellow')
                        self.BlinkingLightsState = 'Yellow'
                    end
                end
            end
        elseif state == 'Red' then
            self:CreateBlinkingLights('Red')
            self.BlinkingLightsState = state
        end
    end,

    OnMassStorageStateChange = function(self, newState)
        if newState == 'EconLowMassStore' then
            self:ChangeBlinkingLights('Red')
        else
            self:ChangeBlinkingLights('Green')
        end
    end,

    OnEnergyStorageStateChange = function(self, newState)
        if newState == 'EconLowEnergyStore' then
            self:ChangeBlinkingLights('Red')
        else
            self:ChangeBlinkingLights('Green')
        end
    end,

    OnStartBuild = function(self, unitBeingBuilt, order )
        self:ChangeBlinkingLights('Yellow')
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order )
        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        else
            self:RemoveCommandCap('RULEUCC_Guard')
        end

        self.FactoryBuildFailed = false
    end,

    -- Introduce a rolloff delay, where defined.
    OnStopBuild = function(self, unitBeingBuilt, order )
        local bp = self:GetBlueprint()
        if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
            self:ForkThread(self.PauseThread, bp.General.RolloffDelay, unitBeingBuilt, order)
        else
            self:DoStopBuild(unitBeingBuilt, order)
        end
    end,

    --- Adds a pause between unit productions
    PauseThread = function(self, productionpause, unitBeingBuilt, order)
        self:StopBuildFx()
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)

        WaitSeconds(productionpause)

        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        self:DoStopBuild(unitBeingBuilt, order)
    end,

    DoStopBuild = function(self, unitBeingBuilt, order )
        StructureUnit.OnStopBuild(self, unitBeingBuilt, order )

        if not self.FactoryBuildFailed then
            if not EntityCategoryContains(categories.AIR, unitBeingBuilt) then
                self:RollOffUnit()
            end
            self:StopBuildFx()
            self:ForkThread(self.FinishBuildThread, unitBeingBuilt, order )
        end

        if order == 'Upgrade' then
            self:AddCommandCap('RULEUCC_Guard')
        end

        self.BuildingUnit = false
    end,

    FinishBuildThread = function(self, unitBeingBuilt, order )
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self:GetBlueprint()
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim)
            self.Trash:Add(self.RollOffAnim)
            WaitTicks(1)
            WaitFor(self.RollOffAnim)
        end
        if unitBeingBuilt and not unitBeingBuilt.Dead then
            unitBeingBuilt:DetachFrom(true)
        end
        self:DetachAll(bp.Display.BuildAttachBone or 0)
        self:DestroyBuildRotator()
        if order ~= 'Upgrade' then
            ChangeState(self, self.RollingOffState)
        else
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end
    end,

    CheckBuildRestriction = function(self, target_bp)
        if self:CanBuild(target_bp.BlueprintId) then
            return true
        else
            return false
        end
    end,

    OnFailedToBuild = function(self)
        self.FactoryBuildFailed = true
        StructureUnit.OnFailedToBuild(self)
        self:DestroyBuildRotator()
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    RollOffUnit = function(self)
        local spin, x, y, z = self:CalculateRollOffPoint()
        local units = { self.UnitBeingBuilt }
        self.MoveCommand = IssueMove(units, Vector(x, y, z))
    end,

    CalculateRollOffPoint = function(self)
        local bp = self:GetBlueprint().Physics.RollOffPoints
        local px, py, pz = unpack(self:GetPosition())
        if not bp then return 0, px, py, pz end
        local vectorObj = self:GetRallyPoint()
        local bpKey = 1
        local distance, lowest = nil
        for k, v in bp do
            distance = VDist2(vectorObj[1], vectorObj[3], v.X + px, v.Z + pz)
            if not lowest or distance < lowest then
                bpKey = k
                lowest = distance
            end
        end
        local fx, fy, fz, spin
        local bpP = bp[bpKey]
        local unitBP = self.UnitBeingBuilt:GetBlueprint().Display.ForcedBuildSpin
        if unitBP then
            spin = unitBP
        else
            spin = bpP.UnitSpin
        end
        fx = bpP.X + px
        fy = bpP.Y + py
        fz = bpP.Z + pz
        return spin, fx, fy, fz
    end,

    StartBuildFx = function(self, unitBeingBuilt)

    end,

    StopBuildFx = function(self)

    end,

    PlayFxRollOff = function(self)
    end,

    PlayFxRollOffEnd = function(self)
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(-1)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    CreateBuildRotator = function(self)
        if not self.BuildBoneRotator then
            local spin = self:CalculateRollOffPoint()
            local bp = self:GetBlueprint().Display
            self.BuildBoneRotator = CreateRotator(self, bp.BuildAttachBone or 0, 'y', spin, 10000)
            self.Trash:Add(self.BuildBoneRotator)
        end
    end,

    DestroyBuildRotator = function(self)
        if self.BuildBoneRotator then
            self.BuildBoneRotator:Destroy()
            self.BuildBoneRotator = nil
        end
    end,

    RolloffBody = function(self)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayFxRollOff()
        -- Wait until unit has left the factory
        while not self.UnitBeingBuilt.Dead and self.MoveCommand and not IsCommandDone(self.MoveCommand) do
            WaitSeconds(0.5)
        end
        self.MoveCommand = nil
        self:PlayFxRollOffEnd()
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        ChangeState(self, self.IdleState)
    end,

    IdleState = State {

        Main = function(self)
            self:ChangeBlinkingLights('Green')
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
            self:DestroyBuildRotator()
        end,
    },

    BuildingState = State {

        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            local bp = self:GetBlueprint()
            local bone = bp.Display.BuildAttachBone or 0
            self:DetachAll(bone)
            unitBuilding:AttachBoneTo(-2, self, bone)
            self:CreateBuildRotator()
            self:StartBuildFx(unitBuilding)
        end,
    },


    RollingOffState = State {
        Main = function(self)
            self:RolloffBody()
        end,
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        StructureUnit.OnKilled(self, instigator, type, overkillRatio)
        if self.UnitBeingBuilt and not self.UnitBeingBuilt.Dead and self.UnitBeingBuilt:GetFractionComplete() ~= 1 then
            self.UnitBeingBuilt:Kill()
        end
    end,
}
