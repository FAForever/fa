----------------------------------------------------------------------------
--
--  File     :  /lua/system/GlobalBuilderGroup.lua
--
--  Summary  :  Global builder group table and blueprint methods
--
--  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Global list of all buffs found in the system.
local ipairs = ipairs
local LOG = LOG
local setmetatable = setmetatable
local WARN = WARN
local next = next
local type = type

BuilderGroups = {}

-- Buff blueprints are created by invoking BuffBlueprint() with a table
-- as the buff data. Buffs can be defined in any module at any time.
-- e.g.
--
-- BuffBlueprint {
--    Name = HealingOverTime1,
--    DisplayName = 'Healing Over Time',
--    [...]
--    Affects = {
--        Health = {
--            Add = 10,
--        },
--    },
-- }
--
--
--
BuilderGroup = {}
BuilderGroupDefMeta = {}

BuilderGroupDefMeta.__index = BuilderGroupDefMeta
BuilderGroupDefMeta.__call = function(...)
    if type(arg[2]) ~= 'table' then
        LOG('Invalid BuilderGroup: ', repr(arg))
        return
    end

    if not arg[2].BuilderGroupName then
        WARN('Missing BuilderGroupName for BuilderGroup definition: ',repr(arg))
        return
    end

    if not arg[2].BuildersType then
        WARN('Missing BuildersType for BuilderGroup definition - BuilderGroupName = ' .. arg[2].BuilderGroupName)
        return
    end

    if arg[2].BuildersType ~= 'EngineerBuilder' and arg[2].BuildersType ~= 'FactoryBuilder' and arg[2].BuildersType ~= 'PlatoonFormBuilder' and arg[2].BuildersType ~= 'StrategyBuilder' then
        WARN('Invalid BuildersType for BuilderGroup definition - BuilderGroupName = ' .. arg[2].BuilderGroupName)
        return
    end

    if BuilderGroups[arg[2].BuilderGroupName] then
        LOG('Hooked PlatoonTemplate: ', arg[2].BuilderGroupName)
        for k,v in arg[2] do
            BuilderGroups[arg[2].BuilderGroupName][k] = v
        end
    else
        BuilderGroups[arg[2].BuilderGroupName] = arg[2]
    end
    --SPEW('BuilderGroup Registered: ', arg[2].BuilderGroupName)
    return arg[2].BuilderGroupName
end

setmetatable(BuilderGroup, BuilderGroupDefMeta)
