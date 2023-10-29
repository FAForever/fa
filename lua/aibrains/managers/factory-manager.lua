--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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
--******************************************************************************************************

local BuilderManager = import("/lua/aibrains/managers/builder-manager.lua").AIBuilderManager

local IsDestroyed = IsDestroyed

local TableGetSize = table.getsize
local TableGetn = table.getn

local WeakValues = { __mode = 'v' }

---@class AIFactoryManagerDebugInfo

---@class AIFactoryTemplate : PlatoonTemplateFactionalSpec[]
---@field [1] string    # Name of platoon template
---@field [2] string    # Always ''


---@class AIFactoryManagerReferenceTechs
---@field TECH1 AIFactoryManagerReferenceLayers
---@field TECH2 AIFactoryManagerReferenceLayers
---@field TECH3 AIFactoryManagerReferenceLayers
---@field EXPERIMENTAL AIFactoryManagerReferenceLayers

---@class AIFactoryManagerReferenceLayers
---@field LAND table<EntityId, Unit>
---@field AIR table<EntityId, Unit>
---@field NAVAL table<EntityId, Unit>

---@class AIFactoryManagerReferences
---@field RESEARCH AIFactoryManagerReferenceTechs
---@field SUPPORT AIFactoryManagerReferenceTechs

---@class AIFactoryManagerCountTechs
---@field TECH1 AIFactoryManagerCountLayers
---@field TECH2 AIFactoryManagerCountLayers
---@field TECH3 AIFactoryManagerCountLayers
---@field EXPERIMENTAL AIFactoryManagerCountLayers

---@class AIFactoryManagerCountLayers
---@field LAND number
---@field AIR number
---@field NAVAL number

---@class AIFactoryManagerCounts
---@field RESEARCH AIFactoryManagerCountTechs
---@field SUPPORT AIFactoryManagerCountTechs

---@class AIFactoryManager : AIBuilderManager
---@field Factories AIFactoryManagerReferences
---@field FactoriesBeingBuilt AIFactoryManagerReferences
---@field FactoryCount AIFactoryManagerCounts               # Recomputed every 10 ticks
---@field FactoryBeingBuiltCount AIFactoryManagerCounts     # Recomputed every 10 ticks
AIFactoryManager = Class(BuilderManager) {

    ManagerName = "FactoryManager",

    ---@param self AIFactoryManager
    ---@param brain AIBrain
    ---@param base AIBase
    ---@param locationType LocationType
    Create = function(self, brain, base, locationType)
        BuilderManager.Create(self, brain, base, locationType)
        self.Identifier = 'AIFactoryManager at ' .. locationType

        self.Factories = {
            RESEARCH = {
                TECH1 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH2 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH3 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                EXPERIMENTAL = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
            },
            SUPPORT = {
                TECH1 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH2 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH3 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                EXPERIMENTAL = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
            }
        }

        self.FactoryCount = {
            RESEARCH = {
                TECH1 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH2 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH3 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                EXPERIMENTAL = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
            },
            SUPPORT = {
                TECH1 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH2 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH3 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                EXPERIMENTAL = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
            }
        }

        self.FactoriesBeingBuilt = {
            RESEARCH = {
                TECH1 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH2 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH3 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                EXPERIMENTAL = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
            },
            SUPPORT = {
                TECH1 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH2 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                TECH3 = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
                EXPERIMENTAL = {
                    LAND = setmetatable({}, WeakValues),
                    AIR = setmetatable({}, WeakValues),
                    NAVAL = setmetatable({}, WeakValues),
                },
            }
        }

        self.FactoryBeingBuiltCount = {
            RESEARCH = {
                TECH1 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH2 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH3 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                EXPERIMENTAL = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
            },
            SUPPORT = {
                TECH1 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH2 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                TECH3 = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
                EXPERIMENTAL = {
                    LAND = 0,
                    AIR = 0,
                    NAVAL = 0,
                },
            }
        }

        self.Trash:Add(ForkThread(self.UpdateFactoryThread, self))
    end,


    ---@param self AIFactoryManager
    UpdateFactoryThread = function(self)
        while true do
            for category, techs in self.Factories do
                for tech, layers in techs do
                    for layer, factories in layers do
                        self.FactoryCount[category][tech][layer] = TableGetSize(factories)
                    end
                end
            end

            for category, techs in self.FactoriesBeingBuilt do
                for tech, layers in techs do
                    for layer, factories in layers do
                        self.FactoryBeingBuiltCount[category][tech][layer] = TableGetSize(factories)
                    end
                end
            end

            WaitTicks(10)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local layer = blueprint.LayerCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][layer][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or {}
            unit.BuilderManagerData = builderManagerData
            builderManagerData.FactoryManager = self
        end
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        self:AddFactory(unit)
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIFactoryManager
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local layer = blueprint.LayerCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][layer][id] = nil
            self.Factories[type][tech][layer][id] = nil
        end
    end,

    --- Called by a unit as it starts building
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        -- local blueprint = unit.Blueprint
        -- if blueprint.CategoriesHash['STRUCTURE'] then
        -- end
    end,

    --- Called by a unit as it stops building
    ---@param self AIFactoryManager
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            -- self:DelayOrder(unit, 'Any', 10)
        end
    end,

    --------------------------------------------------------------------------------------------
    -- factory manager interface

    ---@param self AIFactoryManager
    ---@return AIPlatoon
    GetFactoryPlatoonMetaTable = function(self)
        return import("/lua/aibrains/platoons/platoon-simple-factory.lua").AIPlatoonSimpleFactory
    end,

    --- Add a unit to the factory manager
    ---@param self AIFactoryManager
    ---@param unit Unit
    AddFactory = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] and blueprint.CategoriesHash['FACTORY'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local layer = blueprint.LayerCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][layer][id] = nil
            self.Factories[type][tech][layer][id] = unit

            -- used by platoon functions to find the manager
            local builderManagerData = unit.BuilderManagerData or {}
            unit.BuilderManagerData = builderManagerData
            builderManagerData.StructureManager = self

            -- create a new platoon instance
            local platoon = self.Brain:MakePlatoon("FactoryManager - " .. tostring(unit), '') --[[@as AIPlatoon]]
            setmetatable(platoon, self:GetFactoryPlatoonMetaTable())
            platoon.Base = self.Base
            platoon.Brain = self.Brain
            self.Brain:AssignUnitsToPlatoon(platoon, { unit }, 'Unassigned', 'None')
            ChangeState(platoon, platoon.Start)
        end
    end,

    --- Remove a unit, similar to calling `OnUnitDestroyed`
    ---@param self AIFactoryManager
    ---@param unit Unit
    RemoveFactory = function(self, unit)
        local blueprint = unit.Blueprint
        if blueprint.CategoriesHash['STRUCTURE'] then
            local type = (blueprint.CategoriesHash['RESEARCH'] and 'RESEARCH') or 'SUPPORT'
            local tech = blueprint.TechCategory
            local id = unit.EntityId
            self.FactoriesBeingBuilt[type][tech][id] = nil
            self.Factories[type][tech][id] = nil
        end
    end,

    --------------------------------------------------------------------------------------------
    -- factory conditions interface

    ---------------------------------------------------------------------------
    --#region Debug functionality

    ---@param self AIFactoryManager
    ---@return AIFactoryManagerDebugInfo
    GetDebugInfo = function(self)
        local info = self.DebugInfo
        if not info then
            info = {}
            self.DebugInfo = info
        end

        return info
    end,

    --#endregion


}

---@param brain AIBrain
---@param base AIBase
---@param locationType LocationType
---@return AIFactoryManager
function CreateFactoryManager(brain, base, locationType)
    local manager = AIFactoryManager()
    manager:Create(brain, base, locationType)
    return manager
end
