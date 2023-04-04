
local WeakValues = { __mode = 'v' }

local TableGetSize = table.getsize

---@alias AIBrainUnitTypes 'SupportFactories'
---@alias AIBrainUnitTech 'TECH1' | 'TECH2' | 'TECH3' | 'EXPERIMENTAL'

---@class AIBrainUnitsInfo
---@field TECH1 { [1]: table<EntityId, Unit>, [2]: number }
---@field TECH2 { [1]: table<EntityId, Unit>, [2]: number }
---@field TECH3 { [1]: table<EntityId, Unit>, [2]: number }
---@field EXPERIMENTAL { [1]: table<EntityId, Unit>, [2]: number }

---@class AIBrainUnitsTracker
---@field SupportFactories AIBrainUnitsInfo

---@class AIBrainUnitTrackerComponent
---@field UnitsAlive AIBrainUnitsTracker
---@field UnitsUnderConstruction AIBrainUnitsTracker
AIBrainUnitTrackerComponent = ClassSimple {

    ---@param self AIBrainUnitTrackerComponent
    CreateBrainShared = function(self)
        self.UnitsAlive = {
            SupportFactories = {
                TECH1 = setmetatable({ }, WeakValues),
                TECH2 = setmetatable({ }, WeakValues),
                TECH3 = setmetatable({ }, WeakValues),
                EXPERIMENTAL = setmetatable({ }, WeakValues),
            }
        }

        self.UnitsUnderConstruction = {
            SupportFactories = {
                TECH1 = setmetatable({ }, WeakValues),
                TECH2 = setmetatable({ }, WeakValues),
                TECH3 = setmetatable({ }, WeakValues),
                EXPERIMENTAL = setmetatable({ }, WeakValues),
            }
        }
    end,

    --- Add a unit that is being constructed to the tracking structure
    ---@param self AIBrainUnitTrackerComponent
    ---@param unit Unit
    TrackUnitBeingConstructed = function(self, unit)
        local id = unit.EntityId
        local blueprint = unit.Blueprint
        local categories = blueprint.CategoriesHash

        if categories['SUPPORT'] and categories['FACTORY'] then
            local tech = blueprint.TechCategory
            self.UnitsUnderConstruction.SupportFactories[tech][1][id] = unit
        end
    end,

    --- Add a unit to the tracking structure
    ---@param self AIBrainUnitTrackerComponent | AIBrain
    ---@param unit Unit
    TrackUnit = function(self, unit)
        local id = unit.EntityId
        local blueprint = unit.Blueprint
        local categories = blueprint.CategoriesHash
        local tech = blueprint.TechCategory

        if categories['SUPPORT'] and categories['FACTORY'] then
            self.UnitsUnderConstruction.SupportFactories[tech][1][id] = nil
            self.UnitsAlive.SupportFactories[tech][1][id] = unit
        end

        reprsl(self.UnitsAlive)
        reprsl(self.UnitsUnderConstruction)
    end,

    --- Remove a unit from the tracking structure
    ---@param self AIBrainUnitTrackerComponent | AIBrain
    ---@param unit Unit
    RemoveUnit = function(self, unit)
        local id = unit.EntityId
        local blueprint = unit.Blueprint
        local categories = blueprint.CategoriesHash
        local tech = blueprint.TechCategory

        if categories['SUPPORT'] and categories['FACTORY'] then
            self.UnitsUnderConstruction.SupportFactories[tech][1][id] = nil
            self.UnitsAlive.SupportFactories[tech][1][id] = nil
        end

        reprsl(self.UnitsAlive)
        reprsl(self.UnitsUnderConstruction)
    end,

    ---comment
    ---@param self any
    ---@param type any
    ---@param tech any
    ---@return integer
    CountUnits = function(self, type, tech)
        return table.getsize()
    end,
}