
local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon
local NavUtils = import("/lua/sim/navutils.lua")
local MarkerUtils = import("/lua/sim/markerutilities.lua")

-- upvalue scope for performance
local Random = Random
local IsDestroyed = IsDestroyed

local TableGetn = table.getn
local TableEmpty = table.empty

---@class AIPlatoonSimpleStructure : AIPlatoon
---@field Base AIBase
---@field Brain EasyAIBrain
---@field Builder AIBuilder | nil
AIPlatoonSimpleStructure = Class(AIPlatoon) {

    PlatoonName = 'SimpleStructureBehavior',

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            LOG("AIPlatoonSimpleStructure - Start")
            if not self.Base then
                self:LogWarning("requires a base reference")
                self:ChangeState(self.Error)
            end

            if not self.Brain then
                self:LogWarning("requires a brain reference")
                self:ChangeState(self.Error)
            end

            if not self.Base.StructureManager then
                self:LogWarning("requires a structure manager reference")
                self:ChangeState(self.Error)
            end

            self:ChangeState(self.SearchingForTask)
            return
        end,
    },

    SearchingForTask = State {

        StateName = 'SearchingForTask',

        --- The platoon searches for a target
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                self:LogWarning("multiple units is not supported")
                self:ChangeState(self.Error)
                return
            end

            local unit = units[1]

            if not IsDestroyed(unit) then
                local builder = self.Base.StructureManager:GetHighestBuilder(self, unit)
                if builder then
                    self.Builder = builder
                    self:ChangeState(self.Upgrading)
                else
                    self:ChangeState(self.Waiting)
                end
            end
        end,
    },

    Waiting = State {

        StateName = 'Waiting',

        --- 
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)
            WaitTicks(10)
            self:ChangeState(self.SearchingForTask)
        end,
    },

    Upgrading = State {

        StateName = 'Upgrading',

        --- The structure is upgrading. At the end of the sequence the structure no longer exists
        ---@param self AIPlatoonSimpleStructure
        Main = function(self)

            local builder = self.Builder
            if not builder then
                self:LogWarning('no builder defined')
                self:ChangeState(self.Waiting)
                return
            end

            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                self:LogWarning('multiple units in platoon is not supported')
                self:ChangeState(self.Error)
                return
            end

            local builderData = builder.BuilderData
            if builderData.UseUpgradeToBlueprintField then
                local unit = units[1]
                local upgradeId = unit.Blueprint.General.UpgradesTo
                if not upgradeId then
                    self:LogWarning(string.format('the field "UseUpgradeToBlueprintField" is set but no field "UpgradesTo" in blueprint %s exists', unit.Blueprint.BlueprintId))
                    self:ChangeState(self.Error)
                    return
                end

                IssueUpgrade(units, upgradeId)
            end
        end,
    },

    -----------------------------------------------------------------
    -- brain events
}

---@param data { }
---@param units Unit[]
DebugAssignToUnits = function(data, units)
    if units and not TableEmpty(units) then
        -- trigger the on stop being built event of the brain
        for k = 1, table.getn(units) do
            local unit = units[k]
            unit.Brain:OnUnitStopBeingBuilt(unit, nil, unit.Layer)
        end
    end
end



