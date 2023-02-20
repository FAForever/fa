---@declare-global

---@alias BuilderGroupNamesBase BuilderGroupsAirAttack | BuilderGroupsArtillery | BuilderGroupsDefense | BuilderGroupsEconomic | BuilderGroupsEconomicUpgrade | BuilderGroupsExpansion | BuildergroupsExperimentals | BuilderGroupsFactoryConstruction | BuilderGroupsIntel | BuilderGroupsLandAttack | BuilderGroupsNaval | BuilderGroupsSeaAttack | string
---@alias BuilderGroupNamesSorian ''
---@alias BuilderGroupNames BuilderGroupNamesBase | BuilderGroupNamesSorian | string

---@class BuilderGroupSpec
---@field BuilderGroupName string
---@field BuildersType BuildersType
---@field [1] BuilderGroupNames?
---@field [2] BuilderGroupNames?
---@field [3] BuilderGroupNames?
---@field [4] BuilderGroupNames?
---@field [5] BuilderGroupNames?
---@field [6] BuilderGroupNames?
---@field [7] BuilderGroupNames?
---@field [8] BuilderGroupNames?
---@field [9] BuilderGroupNames?
---@field [10] BuilderGroupNames?
---@field [11] BuilderGroupNames?
---@field [12] BuilderGroupNames?
---@field [13] BuilderGroupNames?
---@field [14] BuilderGroupNames?
---@field [15] BuilderGroupNames?

--- Global list of all builder groups
---@type table<string, BuilderGroupSpec>
BuilderGroups = {}

--- List of all valid builder group types
local ValidBuildersType = {
    EngineerBuilder = true,
    FactoryBuilder = true,
    PlatoonFormBuilder = true,
    StrategyBuilder = true,
}

---@alias BuildersType 'EngineerBuilder' | 'FactoryBuilder' | 'PlatoonFormBuilder' | 'StrategyBuilder'

--- Register a builder group, or override an existing builder group
---@param spec BuilderGroupSpec
---@return string String reference to the builder group
function BuilderGroup (spec)

    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder group: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.BuilderGroupName then 
        WARN('Builder group excluded for missing BuilderGroupName in its specification: ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.BuildersType then 
        WARN('Builder group excluded for missing BuildersType in its specification: ', reprs(spec))
        return
    end

    -- should have a valid type
    if not ValidBuildersType[spec.BuildersType] then 
        WARN('Builder group excluded for invalid BuildersType: ', reprs(spec.BuildersType))
        return
    end

    -- overwrite any existing definitions
    if BuilderGroups[spec.BuilderGroupName] then
        LOG(string.format('Overwriting builder group: %s', spec.BuilderGroupName))
        for k,v in spec do
            BuilderGroups[spec.BuilderGroupName][k] = v
        end

    -- first one, we become the definition
    else
        BuilderGroups[spec.BuilderGroupName] = spec
    end

    return spec.BuilderGroupName
end
