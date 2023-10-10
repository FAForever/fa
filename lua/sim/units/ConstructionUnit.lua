
local MobileUnit = import("/lua/sim/units/mobileunit.lua").MobileUnit

---@class ConstructionUnit : MobileUnit
---@field BuildingOpenAnim? FileName
---@field BuildingOpenAnimManip? moho.AnimationManipulator
---@field BuildingUnit boolean
---@field UnitBeingBuilt? Unit
---@field UnitBuildOrder? string
---@field Upgrading? boolean
---@field BuildArmManipulator moho.AimManipulator
---@field StoppedBuilding? boolean
ConstructionUnit = ClassUnit(MobileUnit) {

    ---@param self ConstructionUnit
    OnCreate = function(self)
        MobileUnit.OnCreate(self)

        local bp = self.Blueprint

        -- Save build effect bones for faster access when creating build effects
        self.BuildEffectBones = bp.General.BuildBones.BuildEffectBones
        
        if bp.General.BuildBones then
            self:SetupBuildBones()
        end

        if bp.Display.AnimationBuild then
            self.BuildingOpenAnim = bp.Display.AnimationBuild
        end

        if self.BuildingOpenAnim then
            self.BuildingOpenAnimManip = CreateAnimator(self)
            self.BuildingOpenAnimManip:SetPrecedence(1)
            self.BuildingOpenAnimManip:PlayAnim(self.BuildingOpenAnim, false):SetRate(0)
            if self.BuildArmManipulator then
                self.BuildArmManipulator:Disable()
            end
        end
        self.BuildingUnit = false
    end,

    ---@param self ConstructionUnit
    OnPaused = function(self)
        -- When factory is paused take some action
        self:StopUnitAmbientSound('ConstructLoop')
        MobileUnit.OnPaused(self)
        if self.BuildingUnit then
            MobileUnit.StopBuildingEffects(self, self.UnitBeingBuilt)
        end
    end,

    ---@param self ConstructionUnit
    OnUnpaused = function(self)
        if self.BuildingUnit then
            self:PlayUnitAmbientSound('ConstructLoop')
            MobileUnit.StartBuildingEffects(self, self.UnitBeingBuilt, self.UnitBuildOrder)
        end
        MobileUnit.OnUnpaused(self)
    end,

    ---@param self ConstructionUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    OnStartBuild = function(self, unitBeingBuilt, order)
        if unitBeingBuilt.WorkItem.Slot and unitBeingBuilt.WorkProgress == 0 then
            return
        else
            MobileUnit.OnStartBuild(self, unitBeingBuilt, order)
        end

        -- Fix up info on the unit id from the blueprint and see if it matches the 'UpgradeTo' field in the BP.
        self.UnitBeingBuilt = unitBeingBuilt
        self.UnitBuildOrder = order
        self.BuildingUnit = true
        if unitBeingBuilt.UnitId == self.Blueprint.General.UpgradesTo and order == 'Upgrade' then
            self.Upgrading = true
            self.BuildingUnit = false
        end
    end,

    ---@param self ConstructionUnit
    ---@param unitBeingBuilt Unit
    OnStopBuild = function(self, unitBeingBuilt)
        MobileUnit.OnStopBuild(self, unitBeingBuilt)
        if self.Upgrading then
            NotifyUpgrade(self, unitBeingBuilt)
            self:Destroy()
        end
        self.UnitBeingBuilt = nil
        self.UnitBuildOrder = nil

        if self.BuildingOpenAnimManip and self.BuildArmManipulator then
            self.StoppedBuilding = true
        elseif self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(-1)
        end
        self.BuildingUnit = false

        self:SetImmobile(false)
    end,

    ---@param self ConstructionUnit
    OnFailedToBuild = function(self)
        MobileUnit.OnFailedToBuild(self)
        self:SetImmobile(false)
    end,

    ---@param self ConstructionUnit
    ---@param enable boolean
    WaitForBuildAnimation = function(self, enable)
        if self.BuildArmManipulator then
            WaitFor(self.BuildingOpenAnimManip)
            if enable then
                self.BuildArmManipulator:Enable()
            end
        end
    end,

    ---@param self ConstructionUnit
    OnPrepareArmToBuild = function(self)
        MobileUnit.OnPrepareArmToBuild(self)

        if self.BuildingOpenAnimManip then
            self.BuildingOpenAnimManip:SetRate(self.Blueprint.Display.AnimationBuildRate or 1)
            if self.BuildArmManipulator then
                self.StoppedBuilding = false
                self:ForkThread(self.WaitForBuildAnimation, true)
            end
        end

        -- This is an extremely ugly hack to get around an engine bug. If you have used a command such as OC or repair on an illegal
        -- target (An allied unit, or something at full HP, for example) while moving, the engine is tricked into a state where
        -- the unit is still moving, but unaware of it (It thinks it stopped to do the command). This allows it to build on the move,
        -- as it doesn't know it's doing something bad. To fix it, we temporarily make the unit immobile when it starts construction.
        if self:IsMoving() then
            local navigator = self:GetNavigator()
            navigator:AbortMove()
        end
    end,

    ---@param self ConstructionUnit
    OnStopBuilderTracking = function(self)
        MobileUnit.OnStopBuilderTracking(self)

        if self.StoppedBuilding then
            self.StoppedBuilding = false
            self.BuildArmManipulator:Disable()
            self.BuildingOpenAnimManip:SetRate(-(self.Blueprint.Display.AnimationBuildRate or 1))
        end
    end,
}

