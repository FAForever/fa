
local FactoryManager = import("/lua/aibrains/managers/factory-manager.lua")
local EngineerManager = import("/lua/aibrains/managers/engineer-manager.lua")
local StructureManager = import("/lua/aibrains/managers/structure-manager.lua")

---@alias LocationType
--- can only be applied to the main base
--- | 'MAIN'
--- can be applied by any base
--- | 'LocationType'
--- name of expansion marker of the base
--- | string

---@class AIBase
---@field BuilderHandles table
---@field FactoryManager AIFactoryManager
---@field EngineerManager AIEngineerManager
---@field StructureManager AIStructureManager
---@field Position Vector
---@field Radius number
AIBase = ClassSimple {

    ---@param self AIBase
    Create = function(self, brain, locationType, location, radius)
        -- determine layer
        local baseLayer = 'Land'
        location[2] = GetTerrainHeight(location[1], location[3])
        if GetSurfaceHeight(location[1], location[3]) > location[2] then
            location[2] = GetSurfaceHeight(location[1], location[3])
            baseLayer = 'Water'
        end

        -- store various properties
        self.Position = location
        self.Layer = baseLayer
        self.Radius = radius

        -- create the various managers
        self.FactoryManager = FactoryManager.CreateFactoryManager(brain, self, locationType)
        self.EngineerManager = EngineerManager.CreateEngineerManager(brain, self, locationType)
        self.StructureManager = StructureManager.CreateStructureManager(brain, self, locationType)
    end,

    --------------------------------------------------------------------------------------------
    -- builder interface

    --- Adds all builders of the given base template to this base
    --- 
    --- For reference, see `base-template.lua` file
    ---@param self AIBase
    ---@param baseTemplate AIBaseTemplate
    AddBaseTemplate = function(self, baseTemplate)
        SPEW("Loading base template: " .. baseTemplate.BaseTemplateName)
        if baseTemplate.EngineerManager then
            local builderGroups
            builderGroups = baseTemplate.EngineerManager.BuilderGroupTemplates
            for k = 1, table.getn(builderGroups) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.EngineerManager)
            end

            for k = 1, table.getn(baseTemplate.EngineerManager.BuilderGroupTemplatesNonCheating) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.EngineerManager)
            end
        end

        if baseTemplate.FactoryManager then
            local builderGroups
            builderGroups = baseTemplate.FactoryManager.BuilderGroupTemplates
            for k = 1, table.getn(builderGroups) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.FactoryManager)
            end

            for k = 1, table.getn(baseTemplate.FactoryManager.BuilderGroupTemplatesNonCheating) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.FactoryManager)
            end
        end

        if baseTemplate.StructureManager then
            local builderGroups
            builderGroups = baseTemplate.StructureManager.BuilderGroupTemplates
            for k = 1, table.getn(builderGroups) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.StructureManager)
            end

            for k = 1, table.getn(baseTemplate.StructureManager.BuilderGroupTemplatesNonCheating) do
                local builderGroup = builderGroups[k]
                self:AddBuilderGroup(builderGroup, self.StructureManager)
            end
        end
    end,

    ---@param self AIBase
    ---@param builderGroupTemplate AIBuilderGroupTemplate
    ---@param manager AIBuilderManager
    AddBuilderGroup = function(self, builderGroupTemplate, manager)
        SPEW("Loading builder group template: " .. builderGroupTemplate.BuilderGroupName)
        local builderTemplates = builderGroupTemplate.BuilderTemplates
        for k = 1, table.getn(builderTemplates) do
            local builderTemplate = builderTemplates[k]
            manager:AddBuilder(builderTemplate)
        end
    end,

    ------------------------------------------------------------------------------------------
    -- unit events

    --- Called by a unit as it starts being built
    ---@param self AIBase
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStartBeingBuilt = function(self, unit, builder, layer)
        self.FactoryManager:OnUnitStartBeingBuilt(unit, builder, layer)
        self.EngineerManager:OnUnitStartBeingBuilt(unit, builder, layer)
        self.StructureManager:OnUnitStartBeingBuilt(unit, builder, layer)
    end,

    --- Called by a unit as it is finished being built
    ---@param self AIBase
    ---@param unit Unit
    ---@param builder Unit
    ---@param layer Layer
    OnUnitStopBeingBuilt = function(self, unit, builder, layer)
        self.FactoryManager:OnUnitStopBeingBuilt(unit, builder, layer)
        self.EngineerManager:OnUnitStopBeingBuilt(unit, builder, layer)
        self.StructureManager:OnUnitStopBeingBuilt(unit, builder, layer)
    end,

    --- Called by a unit as it is destroyed
    ---@param self AIBase
    ---@param unit Unit
    OnUnitDestroyed = function(self, unit)
        self.FactoryManager:OnUnitDestroyed(unit)
        self.EngineerManager:OnUnitDestroyed(unit)
        self.StructureManager:OnUnitDestroyed(unit)
    end,

    --- Called by a unit as it starts building
    ---@param self AIBase
    ---@param unit Unit
    ---@param built Unit
    OnUnitStartBuilding = function(self, unit, built)
        self.FactoryManager:OnUnitStartBuilding(unit, built)
        self.EngineerManager:OnUnitStartBuilding(unit, built)
        self.StructureManager:OnUnitStartBuilding(unit, built)
    end,

    --- Called by a unit as it stops building
    ---@param self AIBase
    ---@param unit Unit
    ---@param built Unit
    OnUnitStopBuilding = function(self, unit, built)
        self.FactoryManager:OnUnitStopBuilding(unit, built)
        self.EngineerManager:OnUnitStopBuilding(unit, built)
        self.StructureManager:OnUnitStopBuilding(unit, built)
    end,
}

---@param brain AIBrain
---@param locationType LocationType
---@param location Vector
---@param radius number
---@return AIBase
function CreateBaseManager(brain, locationType, location, radius)
    local em = AIBase()
    em:Create(brain, locationType, location, radius)
    return em
end