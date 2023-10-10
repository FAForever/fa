local AIPlatoon = import("/lua/aibrains/platoons/platoon-base.lua").AIPlatoon

-- upvalue scope for performance
local TableGetn = table.getn
local TableRandom = table.random

local ParseEntityCategory = ParseEntityCategory
local EntityCategoryGetUnitList = EntityCategoryGetUnitList

---@class AIPlatoonSimpleFactory : AIPlatoon
---@field Base AIBase
---@field Brain EasyAIBrain
---@field BuilderType 'LAND' | 'AIR' | 'NAVAL' | 'GATE'
---@field BuildableCategories EntityCategory
---@field Builder AIBuilder | nil
AIPlatoonSimpleFactory = Class(AIPlatoon) {

    PlatoonName = 'SimpleFactoryBehavior',

    --- Precomputes the buildable categories to make it easier to use throughout the state machine
    ---@param self AIPlatoonSimpleFactory
    PrecomputeBuildableCategories = function(self)

        local units, count = self:GetPlatoonUnits()
        local unit = units[1]

        local buildableCategories = unit.Blueprint.Economy.BuildableCategory
        if (not buildableCategories) or TableGetn(buildableCategories) <= 0 then
            self:LogWarning("requires units that can be build")
            self:ChangeState(self.Error)
        end

        self.BuildableCategories = ParseEntityCategory(buildableCategories[1])
        for k = 2, TableGetn(buildableCategories) do
            self.BuildableCategories = self.BuildableCategories + ParseEntityCategory(buildableCategories[k])
        end
    end,

    Start = State {

        StateName = 'Start',

        --- Initial state of any state machine
        ---@param self AIPlatoonSimpleFactory
        Main = function(self)
            if not self.Base then
                self:LogWarning("requires a base reference")
                self:ChangeState(self.Error)
            end

            if not self.Brain then
                self:LogWarning("requires a brain reference")
                self:ChangeState(self.Error)
            end

            if not self.Base.FactoryManager then
                self:LogWarning("requires a factory manager reference")
                self:ChangeState(self.Error)
            end

            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                self:LogWarning("multiple units is not supported")
                self:ChangeState(self.Error)
                return
            end

            local unit = units[1]

            -- cache builder type
            self.BuilderType = unit.Blueprint.LayerCategory
            self:PrecomputeBuildableCategories()

            self:ChangeState(self.SearchingForTask)
            return
        end,
    },

    SearchingForTask = State {

        StateName = 'SearchingForTask',

        --- The platoon searches for a target
        ---@param self AIPlatoonSimpleFactory
        Main = function(self)

            local units, count = self:GetPlatoonUnits()
            if count > 1 then
                self:LogWarning("multiple units is not supported")
                self:ChangeState(self.Error)
                return
            end

            -------------------------------------------------------------------
            -- determine what to build through the factory manager

            local factory = units[1]

            local builder = self.Base.FactoryManager:GetHighestBuilder(self, units[1], self.BuilderType)

            if builder then
                local candidates = EntityCategoryGetUnitList(builder.BuilderData.Categories * self.BuildableCategories)
                if candidates and TableGetn(candidates) > 0 then
                    local candidate = TableRandom(candidates)
                    if factory:CanBuild(candidate) then
                        IssueBuildFactory(units, candidate, 1)
                        self:ChangeState(self.Building)
                        return
                    else
                        self:LogWarning(string.format("Unable to build: %s", candidate))
                        self:ChangeState(self.Waiting)
                        return
                    end
                else
                    -- try again in a bit
                    self:LogWarning(string.format("Unable to process: %s", builder.Template.BuilderName))
                    self:ChangeState(self.Waiting)
                    return
                end
            else
                -- try again in a bit
                self:ChangeState(self.Waiting)
                return
            end
        end,
    },

    Waiting = State {

        StateName = 'Waiting',

        ---@param self AIPlatoonSimpleFactory
        Main = function(self)
            WaitTicks(40)
            self:ChangeState(self.SearchingForTask)
            return
        end,
    },

    Upgrading = State {

        StateName = 'Upgrading',

        --- The structure is upgrading
        ---@param self AIPlatoonSimpleFactory
        Main = function(self)

            -- ... ?

        end,

    },

    Building = State {

        StateName = 'Building',

        --- The structure is building
        ---@param self AIPlatoonSimpleFactory
        Main = function(self)

            -- ... ?

        end,

        ---@param self AIPlatoonSimpleFactory
        OnStopBuild = function(self, unit, target)
            self:ChangeState(self.SearchingForTask)
            return
        end,
    },

    Idling = State {

        StateName = 'Idling',

        ---@param self AIPlatoonSimpleFactory
        Main = function(self)

            -- ... ?

        end,
    }
}
