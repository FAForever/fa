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

local Unit = import("/lua/sim/unit.lua").Unit
local UnitOnCreate = Unit.OnCreate
local UnitOnDestroy = Unit.OnDestroy
local UnitOnStartBuild = Unit.OnStartBuild
local UnitOnStopBuild = Unit.OnStopBuild
local UnitOnFailedToBuild = Unit.OnFailedToBuild
local UnitOnPaused = Unit.OnPaused
local UnitOnUnpaused = Unit.OnUnpaused

local FactoryUnit = import("/lua/sim/units/factoryunit.lua").FactoryUnit

---@class ExternalFactoryUnit : Unit
---@field Parent Unit
---@field UpdateParentProgressThread? thread
ExternalFactoryUnit = ClassUnit(Unit) {

    UpdateProgressOfParent = true,

    ---@param self ExternalFactoryUnit
    OnCreate = function(self)
        UnitOnCreate(self)

        -- do not show the mesh
        self:HideBone(0, true)

        -- do not allow the unit to be killed or to take damage
        self.CanTakeDamage = false
        self.CanBeKilled = false

        -- is inherited by units, mimic what factories have as their default
        self:SetFireState(2)

        -- do not allow the unit to be reclaimed or targeted by weapons
        self:SetReclaimable(false)
        self:SetDoNotTarget(true)
    end,

    ---@param self ExternalFactoryUnit
    OnDestroy = function(self)
        UnitOnDestroy(self)

        if self.UpdateParentProgressThread then
            KillThread(self.UpdateParentProgressThread)
        end

        -- Similar to SeaFactoryUnit
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and not unitBeingBuilt.Dead and unitBeingBuilt:GetFractionComplete() < 1 then
            unitBeingBuilt:Destroy()
        end
    end,

    --- Modified version of `FactoryUnit.KillUnitBeingBuilt` so that vet is dispersed from the exfac's parent.  
    --- Kills the unit being built, with veterancy dispersal and credit to the instigator.
    ---@param self ExternalFactoryUnit
    ---@param instigator Unit | Projectile
    ---@param type DamageType
    ---@param overkillRatio number
    KillUnitBeingBuilt = function(self, instigator, type, overkillRatio)
        local unitBeingBuilt = self.UnitBeingBuilt
        if unitBeingBuilt and not unitBeingBuilt.Dead and not unitBeingBuilt.isFinishedUnit then
            -- Detach the unit to allow things like sinking
            unitBeingBuilt:DetachFrom(true)
            -- Disperse the unit's veterancy to our killers
            -- only take remaining HP so we don't double count
            -- Identical logic is used for cargo of transports, so this vet behavior is consistent.
            self.Parent:VeterancyDispersal(unitBeingBuilt:GetTotalMassCost() * unitBeingBuilt:GetHealth() / unitBeingBuilt:GetMaxHealth())
            if instigator then
                unitBeingBuilt:Kill(instigator, type, 0)
            else
                unitBeingBuilt:Kill()
            end
        end
    end,

    ---@param self ExternalFactoryUnit
    ---@param parent Unit
    SetParent = function(self, parent)
        self.Parent = parent
    end,

    ---@param self ExternalFactoryUnit
    UpdateParentProgress = function(self)

        -- This thread runs instead of using:
        -- - `OnBuildProgress = function(self, unit, oldProg, newProg)`
        --
        -- The former is only called in intervals of 25%, which is not what users expect

        local parent = self.Parent
        while self.UnitBeingBuilt do
            parent:SetWorkProgress(self:GetWorkProgress())
            WaitTicks(2)
        end
    end,

    ---@param self ExternalFactoryUnit
    ---@param unitbuilding Unit
    ---@param order "FactoryBuild" | "Repair" | "MobileBuild"
    OnStartBuild = function(self, unitbuilding, order)
        UnitOnStartBuild(self, unitbuilding, order)
        self.Parent:OnStartBuild(unitbuilding, order)
        self.UnitBeingBuilt = unitbuilding

        if self.UpdateProgressOfParent then
            self.UpdateParentProgressThread = self.Trash:Add(
                ForkThread(
                    self.UpdateParentProgress, self
                )
            )
        end
    end,

    ---@param self ExternalFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order "FactoryBuild" | "Repair" | "MobileBuild"
    OnStopBuild = function(self, unitBeingBuilt, order)
        UnitOnStopBuild(self, unitBeingBuilt, order)
        self.Parent:OnStopBuild(unitBeingBuilt, order)
        self.UnitBeingBuilt = nil

        if self.UpdateParentProgressThread then
            KillThread(self.UpdateParentProgressThread)
            self.Parent:SetWorkProgress(0)
        end

        -- block building until our creator tells us to continue
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
    end,

    ---@param self ExternalFactoryUnit
    OnFailedToBuild = function(self)
        UnitOnFailedToBuild(self)
        self.Parent:OnFailedToBuild()
        self.UnitBeingBuilt = nil

        if self.UpdateParentProgressThread then
            KillThread(self.UpdateParentProgressThread)
            self.Parent:SetWorkProgress(0)
        end

        -- block building until our creator tells us to continue
        self:SetBusy(true)
        self:SetBlockCommandQueue(true)
    end,

    ---@param self ExternalFactoryUnit
    CalculateRollOffPoint = function(self)
        return self.Parent:CalculateRollOffPoint()
    end,

    ---@param self ExternalFactoryUnit
    RolloffBody = function(self)
        self.Parent:RolloffBody()
    end,

    ---@param self ExternalFactoryUnit
    RollOffUnit = function(self)
        self.Parent:RollOffUnit()
    end,

    ---@param self ExternalFactoryUnit
    ---@param unitBeingBuilt Unit
    ---@param order string
    CreateBuildEffects = function(self, unitBeingBuilt, order)
        self.Parent:CreateBuildEffects(unitBeingBuilt, order)
    end,

    ---@param self ExternalFactoryUnit
    ---@param unitBeingBuilt Unit
    StopBuildingEffects = function(self, unitBeingBuilt)
        self.Parent:StopBuildingEffects(unitBeingBuilt)
    end,

    ---@param self ExternalFactoryUnit
    StartBuildFx = function(self, unitBeingBuilt)
        self.Parent:StartBuildFx(unitBeingBuilt)
    end,

    ---@param self ExternalFactoryUnit
    StopBuildFx = function(self)
        self.Parent:StopBuildFx()
    end,

    ---@param self ExternalFactoryUnit
    PlayFxRollOff = function(self)
        self.Parent:PlayFxRollOff()
    end,

    ---@param self ExternalFactoryUnit
    PlayFxRollOffEnd = function(self)
        self.Parent:PlayFxRollOffEnd()
    end,

    ---@param self FactoryUnit
    OnPaused = function(self)
        UnitOnPaused(self)

        -- When factory is paused take some action
        if self:IsUnitState('Building') then
            self:StopUnitAmbientSound('ConstructLoop')
            self:StopBuildingEffects(self.UnitBeingBuilt)
        end
    end,

    ---@param self FactoryUnit
    OnUnpaused = function(self)
        UnitOnUnpaused(self)
        if self:IsUnitState('Building') then
            self:PlayUnitAmbientSound('ConstructLoop')
            self:StartBuildingEffects(self.UnitBeingBuilt, self.UnitBuildOrder)
        end
    end,

    --- Prevent leaving a wreckage of any kind
    ---@param self Unit
    ---@param overkillRatio number
    ---@return nil
    CreateWreckage = function(self, overkillRatio)
    end,

    IdleState = FactoryUnit.IdleState,
    BuildingState = FactoryUnit.BuildingState,
    RollingOffState = FactoryUnit.RollingOffState,
}
