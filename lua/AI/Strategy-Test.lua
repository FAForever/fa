--****************************************************************************
--**
--**  File     :  /lua/AI/Strategy-Test.lua
--**  Author(s): N00b Strategy
--**
--**  Summary  : Easily Beaten AI
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local UCBC = '/lua/editor/unitcountbuildconditions.lua'
local EBC = '/lua/editor/economybuildconditions.lua'


-- Strategy for the game
-- This needs to be fleshed out to do something useful, but the idea is that it runs through the BuilderConditions,
-- figures out how many are true, and returns a priority value based on its truthiness.
-- The Strategy Manager can then use this information to evaluate if it should switch to this strategy or not
-- The strategy execution should probably be launched form the ExecuteFunction dealie.
-- Again, a work in (very early) progress
Strategy =     
{
        BuilderName = 'Test Strategy',
        Priority = 100,
        BuilderType = 'Any',
        InstanceCount = 1,
        BuilderConditions = {
                { UCBC, 'HaveGreaterThanUnitsWithCategory', { 0, categories.FACTORY * categories.AIR * categories.TECH3}},
                { EBC, 'GreaterThanEconStorageRatio', { 0.3, 0.3}},
                { EBC, 'GreaterThanEconTrend', { -1, -2}},
        },
        FailureThreshold = 50,
        
        BuilderData = {},
        
        ExecuteFunction = function()
            return true
        end,
        
        EvaluateFunction = function()
            return Priority
        end,
        
        
}