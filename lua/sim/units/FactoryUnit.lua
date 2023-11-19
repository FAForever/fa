
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local StructureUnitOnCreate = StructureUnit.OnCreate
local StructureUnitOnDestroy = StructureUnit.OnDestroy
local StructureUnitOnPaused = StructureUnit.OnPaused
local StructureUnitOnUnpaused = StructureUnit.OnUnpaused
local StructureUnitOnStartBuild = StructureUnit.OnStartBuild
local StructureUnitOnStopBuild = StructureUnit.OnStopBuild
local StructureUnitOnStopBeingBuilt = StructureUnit.OnStopBeingBuilt
local StructureUnitCheckBuildRestriction = StructureUnit.CheckBuildRestriction
local StructureUnitOnFailedToBuild = StructureUnit.OnFailedToBuild

-- upvalue scope for performance
local WaitFor = WaitFor
local WaitTicks = WaitTicks
local ForkThread = ForkThread
local IsDestroyed = IsDestroyed
local ChangeState = ChangeState
local CreateRotator = CreateRotator
local CreateAnimator = CreateAnimator
local EntityCategoryContains = EntityCategoryContains

---@class FactoryUnit : StructureUnit
---@field BuildingUnit boolean
---@field BuildEffectsBag TrashBag
---@field BuildBoneRotator moho.RotateManipulator
---@field BuildEffectBones string[]
---@field RollOffPoint Vector
FactoryUnit = ClassUnit(StructureUnit) {

    RollOffAnimationRate = 10,

    ---@param self FactoryUnit
    OnCreate = function(self)
        StructureUnitOnCreate(self)

        local blueprint = self.Blueprint

        -- if we're a support factory, make sure our build restrictions are correct
        if blueprint.CategoriesHash["SUPPORTFACTORY"] then
            self:UpdateBuildRestrictions()
        end

        -- store build bone rotator to prevent trashing the memory
        local buildBoneRotator = CreateRotator(self, blueprint.Display.BuildAttachBone or 0, 'y', 0, 10000)
        buildBoneRotator:SetPrecedence(1000)
        self.BuildBoneRotator = self.Trash:Add(buildBoneRotator)

        -- store build effect bones for quick access
        self.BuildEffectBones = blueprint.General.BuildBones.BuildEffectBones

        -- default to ground fire mode for all units being produced
        self:SetFireState(2)

        -- save for quick access later
        self.RollOffPoint = { 0, 0, 0 }
    end,

    ---@param self FactoryUnit
    DestroyUnitBeingBuilt = function(self)
        local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]
        if (not IsDestroyed(unitBeingBuilt)) then
            local fraction = unitBeingBuilt:GetFractionComplete()
            if fraction < 1.0 then
                if fraction > 0.5 then
                    unitBeingBuilt:Kill()
                else
                    unitBeingBuilt:Destroy()
                end
            end
        end
    end,

    ---@param self FactoryUnit
    OnDestroy = function(self)
        StructureUnitOnDestroy(self)
        local brain = self.Brain
        local blueprint = self.Blueprint

        if blueprint.CategoriesHash["RESEARCH"] and self:GetFractionComplete() == 1.0 then
            -- update internal state
            brain:RemoveHQ(blueprint.FactionCategory, blueprint.LayerCategory, blueprint.TechCategory)
            brain:SetHQSupportFactoryRestrictions(blueprint.FactionCategory, blueprint.LayerCategory)

            -- update all units affected by this
            local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
            for id, unit in affected do
                unit:UpdateBuildRestrictions()
            end
        end

        self:DestroyUnitBeingBuilt()
    end,

    ---@param self FactoryUnit
    OnPaused = function(self)
        StructureUnitOnPaused(self)

        -- When factory is paused take some action
        if self:IsUnitState('Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            self:StopBuildingEffects(self.UnitBeingBuilt)
        end
    end,

    ---@param self FactoryUnit
    OnUnpaused = function(self)
        StructureUnitOnUnpaused(self)

        local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]
        local unitBuildOrder = self.UnitBuildOrder
        if self:IsUnitState('Building') and (not IsDestroyed(unitBeingBuilt)) then
            self:PlayUnitAmbientSound('ConstructLoop')
            self:StartBuildingEffects(unitBeingBuilt, unitBuildOrder)
        end
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        StructureUnitOnStartBuild(self, unitBeingBuilt, order)

        self.FactoryBuildFailed = nil
        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = nil
        elseif unitBeingBuilt.Blueprint.CategoriesHash["RESEARCH"] then
            -- Removes assist command to prevent accidental cancellation when right-clicking on other factory
            self:RemoveCommandCap('RULEUCC_Guard')
            self.DisabledAssist = true
        end
    end,

    --- Introduce a rolloff delay, where defined.
    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    OnStopBuild = function(self, unitBeingBuilt, order)
        if self.DisabledAssist then
            self:AddCommandCap('RULEUCC_Guard')
            self.DisabledAssist = nil
        end
        local bp = self.Blueprint
        if bp.General.RolloffDelay and bp.General.RolloffDelay > 0 and not self.FactoryBuildFailed then
            self:ForkThread(self.PauseThread, bp.General.RolloffDelay, unitBeingBuilt, order)
        else
            self:DoStopBuild(unitBeingBuilt, order)
        end
    end,

    ---@param self FactoryUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        StructureUnitOnStopBeingBuilt(self, builder, layer)

        local brain = self.Brain
        local blueprint = self.Blueprint

        if blueprint.CategoriesHash["RESEARCH"] then
            -- update internal state
            brain:AddHQ(blueprint.FactionCategory, blueprint.LayerCategory, blueprint.TechCategory)
            brain:SetHQSupportFactoryRestrictions(blueprint.FactionCategory, blueprint.LayerCategory)

            -- update all units affected by this
            local affected = brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
            for _, unit in affected do
                unit:UpdateBuildRestrictions()
            end
        end
    end,

    --- Adds a pause between unit productions
    ---@param self FactoryUnit
    ---@param productionpause number
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    PauseThread = function(self, productionpause, unitBeingBuilt, order)
        self:StopBuildFx()
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)

        WaitSeconds(productionpause)

        self:SetBusy(false)
        self:SetBlockCommandQueue(false)
        self:DoStopBuild(unitBeingBuilt, order)
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    DoStopBuild = function(self, unitBeingBuilt, order)
        StructureUnitOnStopBuild(self, unitBeingBuilt, order)

        if not self.FactoryBuildFailed and not self.Dead then
            if not EntityCategoryContains(categories.AIR, unitBeingBuilt) then
                self:RollOffUnit()
            end
            self:StopBuildFx()
            self:ForkThread(self.FinishBuildThread, unitBeingBuilt, order)
        end
        self.BuildingUnit = false
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    FinishBuildThread = function(self, unitBeingBuilt, order)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        local bp = self.Blueprint
        local bpAnim = bp.Display.AnimationFinishBuildLand
        if bpAnim and EntityCategoryContains(categories.LAND, unitBeingBuilt) then
            self.RollOffAnim = CreateAnimator(self):PlayAnim(bpAnim):SetRate(self.RollOffAnimationRate)
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

    ---@param self FactoryUnit
    ---@param target_bp any
    ---@return boolean
    CheckBuildRestriction = function(self, target_bp)
        -- Check basic build restrictions first (Unit.CheckBuildRestriction but we only go up one inheritance level)
        if not StructureUnitCheckBuildRestriction(self, target_bp) then
            return false
        end
        -- Factories never build factories (this does not break Upgrades since CheckBuildRestriction is never called for Upgrades)
        -- Note: We check for the primary category, since e.g. AircraftCarriers have the FACTORY category.
        -- TODO: This is a hotfix for --1043, remove when engymod design is properly fixed
        return target_bp.General.Category ~= 'Factory'
    end,

    ---@param self FactoryUnit
    OnFailedToBuild = function(self)
        StructureUnitOnFailedToBuild(self)
        self.FactoryBuildFailed = true
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    ---@param self FactoryUnit
    RollOffUnit = function(self)
        local rollOffPoint = self.RollOffPoint
        local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]
        if unitBeingBuilt and EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
            local spin, x, y, z = self:CalculateRollOffPoint()
            unitBeingBuilt:SetRotation(spin)
            rollOffPoint[1], rollOffPoint[2], rollOffPoint[3] = x, y, z
        end

        IssueToUnitMoveOffFactory(unitBeingBuilt, rollOffPoint)
    end,

    ---@param self FactoryUnit
    CalculateRollOffPoint = function(self)
        local px, py, pz = self:GetPositionXYZ()

        -- check if we have roll of points set
        local rollOffPoints = self.Blueprint.Physics.RollOffPoints
        if not rollOffPoints then
            return 0, px, py, pz
        end

        -- find our rally point, or of the factory that we're assisting
        local rally = self:GetRallyPoint()
        local focus = self:GetGuardedUnit()
        while focus and focus != self do
            local next = focus:GetGuardedUnit()
            if next then
                focus = next
            else
                break
            end
        end

        if focus then
            rally = focus:GetRallyPoint()
        end

        -- check if we have a rally point set
        if not rally then
            return 0, px, py, pz
        end

        -- find nearest roll off point for rally point
        local nearestRollOffPoint = nil
        local d, dx, dz, lowest = 0, 0, 0, nil
        for k, rollOffPoint in rollOffPoints do
            dx = rally[1] - (px + rollOffPoint.X)
            dz = rally[3] - (pz + rollOffPoint.Z)
            d = dx * dx + dz * dz

            if not lowest or d < lowest then
                nearestRollOffPoint = rollOffPoint
                lowest = d
            end
        end

        -- determine return parameters
        local spin = self.UnitBeingBuilt.Blueprint.Display.ForcedBuildSpin or nearestRollOffPoint.UnitSpin
        local fx = nearestRollOffPoint.X + px
        local fy = nearestRollOffPoint.Y + py
        local fz = nearestRollOffPoint.Z + pz

        return spin, fx, fy, fz
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    StartBuildFx = function(self, unitBeingBuilt)
    end,

    ---@param self FactoryUnit
    StopBuildFx = function(self)
    end,

    ---@param self FactoryUnit
    PlayFxRollOff = function(self)
    end,

    ---@param self FactoryUnit
    PlayFxRollOffEnd = function(self)
        local rollOffAnim = self.RollOffAnim
        if rollOffAnim then
            rollOffAnim:SetRate(-1 * self.RollOffAnimationRate)
            WaitFor(rollOffAnim)
            rollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    ---@param self FactoryUnit
    RolloffBody = function(self)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayFxRollOff()

        local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]

        -- find out when build pad is free again
        local size = unitBeingBuilt.Blueprint.SizeX
        if size < unitBeingBuilt.Blueprint.SizeZ then
            size = unitBeingBuilt.Blueprint.SizeZ
        end

        size = 0.25 * size * size
        local unitPosition, dx, dz, d
        local buildPosition = self:GetPosition(self.Blueprint.Display.BuildAttachBone or 0)
        repeat
            unitPosition = unitBeingBuilt:GetPosition()
            dx = buildPosition[1] - unitPosition[1]
            dz = buildPosition[3] - unitPosition[3]
            d = dx * dx + dz * dz
            WaitTicks(2)
        until IsDestroyed(unitBeingBuilt) or d > size

        self:PlayFxRollOffEnd()
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        ChangeState(self, self.IdleState)
    end,

    IdleState = State {
        ---@param self FactoryUnit
        Main = function(self)
            self:SetBusy(false)
            self:SetBlockCommandQueue(false)
        end,
    },

    BuildingState = State {
        ---@param self FactoryUnit
        Main = function(self)

            local unitBeingBuilt = self.UnitBeingBuilt --[[@as Unit]]

            -- to help prevent a 1-tick rotation on most units
            local hasEnhancements = unitBeingBuilt.Blueprint.Enhancements
            if not hasEnhancements then
                unitBeingBuilt:HideBone(0, true)
            end

            -- determine and preserve the roll off point
            local spin, x, y, z = self:CalculateRollOffPoint()
            local rollOffPoint = self.RollOffPoint
            rollOffPoint[1] = x
            rollOffPoint[2] = y
            rollOffPoint[3] = z

            self.BuildBoneRotator:SetGoal(spin)
            unitBeingBuilt:AttachBoneTo(-2, self, self.Blueprint.Display.BuildAttachBone or 0)
            self:StartBuildFx(unitBeingBuilt)

            -- prevents a 1-tick rotating visual 'glitch' of unit
            -- as it is being attached and the rotator is applied
            WaitTicks(3)
            if not hasEnhancements then
                unitBeingBuilt:ShowBone(0, true)
            end
        end,
    },

    RollingOffState = State {
        ---@param self FactoryUnit
        Main = function(self)
            self:RolloffBody()
        end,
    },

    ---------------------------------------------------------------------------
    --#region Utility functions

    ---@param self FactoryUnit
    ---@return string?
    ToSupportFactoryIdentifier = function(self)
        local blueprint = self.Blueprint
        local hashedCategories = blueprint.CategoriesHash
        local identifier = blueprint.BlueprintId
        local faction = identifier:sub(2, 2)
        local layer = identifier:sub(7, 7)

        -- HQs can not upgrade to support factories
        if hashedCategories["RESEARCH"] then
            return nil
        end

        -- tech 1 factories can go tech 2 support factories if we have a tech 2 hq
        if  hashedCategories["TECH1"] and
            self.Brain:CountHQs(blueprint.FactionCategory, blueprint.LayerCategory, 'TECH2') > 0
        then
            return 'z' .. faction .. 'b950' .. layer
        end

        -- tech 2 support factories can go tech 3 support factories if we have a tech 3 hq
        if  hashedCategories["TECH2"] and
            hashedCategories["SUPPORTFACTORY"] and
            self.Brain:CountHQs(blueprint.FactionCategory, blueprint.LayerCategory, 'TECH3') > 0
        then
            return 'z' .. faction .. 'b960' .. layer
        end

        -- anything else can not upgrade
        return nil
    end,

    ---@param self FactoryUnit
    ToHQFactoryIdentifier = function(self)
        local blueprint = self.Blueprint
        local hashedCategories = blueprint.CategoriesHash
        local identifier = blueprint.BlueprintId
        local faction = identifier:sub(1, 3)
        local layer = identifier:sub(7, 7)

        -- support factories can not upgrade to HQs
        if hashedCategories["SUPPORTFACTORY"] then
            return nil
        end

        -- tech 1 factories can always upgrade
        if hashedCategories["TECH1"] then
            return faction .. '020' .. layer
        end

        -- tech 2 factories can always upgrade
        if hashedCategories["TECH2"] and hashedCategories["RESEARCH"] then
            return faction .. '030'  .. layer
        end

        -- anything else can not upgrade
        return nil
    end,

    --#endregion

    ---------------------------------------------------------------------------
    --#region Deprecated functionality

    ---@deprecated
    ---@param self FactoryUnit
    CreateBuildRotator = function(self)
    end,

    ---@deprecated
    ---@param self FactoryUnit
    DestroyBuildRotator = function(self)
    end,

    --#endregion
}
