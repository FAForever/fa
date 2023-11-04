
local StructureUnit = import("/lua/sim/units/structureunit.lua").StructureUnit
local FireState = import("/lua/game.lua").FireState

---@class FactoryUnit : StructureUnit
---@field BuildingUnit boolean
---@field BuildBoneRotator moho.RotateManipulator
---@field BuildEffectBones string[]
---@field RollOffPoint Vector
FactoryUnit = ClassUnit(StructureUnit) {

    RollOffAnimationRate = 10,

    ---@param self FactoryUnit
    OnCreate = function(self)
        StructureUnit.OnCreate(self)

        -- if we're a support factory, make sure our build restrictions are correct
        if self.Blueprint.CategoriesHash["SUPPORTFACTORY"] then
            self:UpdateBuildRestrictions()
        end

        -- Save build effect bones for faster access when creating build effects
        self.BuildBoneRotator = CreateRotator(self, self.Blueprint.Display.BuildAttachBone or 0, 'y', 0, 10000)
        self.BuildBoneRotator:SetPrecedence(1000)

        self.Trash:Add(self.BuildBoneRotator)
        self.BuildEffectBones = self.Blueprint.General.BuildBones.BuildEffectBones
        self.BuildingUnit = false
        self:SetFireState(FireState.GROUND_FIRE)

        -- save for quick access later
        self.RollOffPoint = { 0, 0, 0 }
    end,

    ---@param self FactoryUnit
    ---@return string?
    ToSupportFactoryIdentifier = function(self)
        local hashedCategories = self.Blueprint.CategoriesHash
        local identifier = self.Blueprint.BlueprintId
        local faction = identifier:sub(2, 2)
        local layer = identifier:sub(7, 7)

        -- HQs can not upgrade to support factories
        if hashedCategories["RESEARCH"] then
            return nil
        end

        -- tech 1 factories can go tech 2 support factories if we have a tech 2 hq
        if  hashedCategories["TECH1"] and
            self.Brain:CountHQs(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, 'TECH2') > 0
        then
            return 'z' .. faction .. 'b950' .. layer
        end

        -- tech 2 support factories can go tech 3 support factories if we have a tech 3 hq
        if  hashedCategories["TECH2"] and
            hashedCategories["SUPPORTFACTORY"] and
            self.Brain:CountHQs(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, 'TECH3') > 0
        then
            return 'z' .. faction .. 'b960' .. layer
        end

        -- anything else can not upgrade
        return nil
    end,

    ---@param self FactoryUnit
    ToHQFactoryIdentifier = function(self)
        local hashedCategories = self.Blueprint.CategoriesHash
        local identifier = self.Blueprint.BlueprintId
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

    ---@param self FactoryUnit
    DestroyUnitBeingBuilt = function(self)
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and (not unitBeingBuilt.Dead) and (unitBeingBuilt:GetFractionComplete() < 1) then
            if unitBeingBuilt:GetFractionComplete() > 0.5 then
                unitBeingBuilt:Kill()
            else
                unitBeingBuilt:Destroy()
            end
        end
    end,

    ---@param self FactoryUnit
    OnDestroy = function(self)
        StructureUnit.OnDestroy(self)

        if self.Blueprint.CategoriesHash["RESEARCH"] and self:GetFractionComplete() == 1.0 then

            -- update internal state
            self.Brain:RemoveHQ(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, self.Blueprint.TechCategory)
            self.Brain:SetHQSupportFactoryRestrictions(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory)

            -- update all units affected by this
            local affected = self.Brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
            for id, unit in affected do
                unit:UpdateBuildRestrictions()
            end
        end

        self:DestroyUnitBeingBuilt()
    end,

    ---@param self FactoryUnit
    OnPaused = function(self)
        StructureUnit.OnPaused(self)

        -- When factory is paused take some action
        if self:IsUnitState('Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            StructureUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self FactoryUnit
    OnUnpaused = function(self)
        StructureUnit.OnUnpaused(self)
        if self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            StructureUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
    end,

    ---@param self FactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order boolean
    OnStartBuild = function(self, unitBeingBuilt, order)
        StructureUnit.OnStartBuild(self, unitBeingBuilt, order)

        self.BuildingUnit = true
        if order ~= 'Upgrade' then
            ChangeState(self, self.BuildingState)
            self.BuildingUnit = false
        elseif unitBeingBuilt.Blueprint.CategoriesHash["RESEARCH"] then
            -- Removes assist command to prevent accidental cancellation when right-clicking on other factory
            self:RemoveCommandCap('RULEUCC_Guard')
            self.DisabledAssist = true
        end
        self.FactoryBuildFailed = false
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
        StructureUnit.OnStopBeingBuilt(self, builder, layer)

        if self.Blueprint.CategoriesHash["RESEARCH"] then
            -- update internal state
            self.Brain:AddHQ(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory, self.Blueprint.TechCategory)
            self.Brain:SetHQSupportFactoryRestrictions(self.Blueprint.FactionCategory, self.Blueprint.LayerCategory)

            -- update all units affected by this
            local affected = self.Brain:GetListOfUnits(categories.SUPPORTFACTORY - categories.EXPERIMENTAL, false)
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
    ---@param order boolean
    DoStopBuild = function(self, unitBeingBuilt, order)
        StructureUnit.OnStopBuild(self, unitBeingBuilt, order)

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
        if not StructureUnit.CheckBuildRestriction(self, target_bp) then
            return false
        end
        -- Factories never build factories (this does not break Upgrades since CheckBuildRestriction is never called for Upgrades)
        -- Note: We check for the primary category, since e.g. AircraftCarriers have the FACTORY category.
        -- TODO: This is a hotfix for --1043, remove when engymod design is properly fixed
        return target_bp.General.Category ~= 'Factory'
    end,

    ---@param self FactoryUnit
    OnFailedToBuild = function(self)
        StructureUnit.OnFailedToBuild(self)
        self.FactoryBuildFailed = true
        self:StopBuildFx()
        ChangeState(self, self.IdleState)
    end,

    ---@param self FactoryUnit
    RollOffUnit = function(self)
        local rollOffPoint = self.RollOffPoint
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and EntityCategoryContains(categories.ENGINEER, unitBeingBuilt) then
            local spin, x, y, z = self:CalculateRollOffPoint()
            unitBeingBuilt:SetRotation(spin)
            rollOffPoint[1], rollOffPoint[2], rollOffPoint[3] = x, y, z
        end

        IssueToUnitMoveOffFactory(self.UnitBeingBuilt, self.RollOffPoint)
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
        if self.RollOffAnim then
            self.RollOffAnim:SetRate(-1 * self.RollOffAnimationRate)
            WaitFor(self.RollOffAnim)
            self.RollOffAnim:Destroy()
            self.RollOffAnim = nil
        end
    end,

    ---@param self FactoryUnit
    RolloffBody = function(self)
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
        self:PlayFxRollOff()

        -- find out when build pad is free again

        local size = 0.5 * self.UnitBeingBuilt.Blueprint.SizeX
        if size < self.UnitBeingBuilt.Blueprint.SizeZ then
            size = 0.5 * self.UnitBeingBuilt.Blueprint.SizeZ
        end

        size = size * size
        local unitPosition, dx, dz, d
        local buildPosition = self:GetPosition(self.Blueprint.Display.BuildAttachBone or 0)
        repeat
            unitPosition = self.UnitBeingBuilt:GetPosition()
            dx = buildPosition[1] - unitPosition[1]
            dz = buildPosition[3] - unitPosition[3]
            d = dx * dx + dz * dz
            WaitTicks(2)
        until IsDestroyed(self.UnitBeingBuilt) or d > size

        self:PlayFxRollOffEnd()
        self:SetBusy(false)
        self:SetBlockCommandQueue(false)

        ChangeState(self, self.IdleState)
    end,

    ---@deprecated
    ---@param self FactoryUnit
    CreateBuildRotator = function(self)
    end,

    ---@deprecated
    ---@param self FactoryUnit
    DestroyBuildRotator = function(self)
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
            -- to help prevent a 1-tick rotation on most units
            local hasEnhancements = self.UnitBeingBuilt.Blueprint.Enhancements
            if not hasEnhancements then
                self.UnitBeingBuilt:HideBone(0, true)
            end

            -- determine and preserve the roll off point
            local spin, x, y, z = self:CalculateRollOffPoint()
            local rollOffPoint = self.RollOffPoint
            rollOffPoint[1] = x
            rollOffPoint[2] = y
            rollOffPoint[3] = z

            self.BuildBoneRotator:SetGoal(spin)
            self.UnitBeingBuilt:AttachBoneTo(-2, self, self.Blueprint.Display.BuildAttachBone or 0)
            self:StartBuildFx(self.UnitBeingBuilt)

            -- prevents a 1-tick rotating visual 'glitch' of unit
            -- as it is being attached and the rotator is applied
            WaitTicks(3)
            if not hasEnhancements then
                self.UnitBeingBuilt:ShowBone(0, true)
            end
        end,
    },

    RollingOffState = State {
        ---@param self FactoryUnit
        Main = function(self)
            self:RolloffBody()
        end,
    },
}
