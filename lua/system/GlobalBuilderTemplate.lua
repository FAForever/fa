---@declare-global
----------------------------------------------------------------------------
--
--  File     :  /lua/system/GlobalBuilderTemplate.lua
--
--  Summary  :  Global builder table and template methods
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

---@alias BuilderNamesBase ''
---@alias BuilderNamesSorian ''
---@alias BuilderNames BuilderNamesBase | BuilderNamesSorian | string

---@alias FileReference string
---@alias FunctionReference string
---@alias FunctionParameters table

---@class BuilderCondition
---@field [1] FileReference
---@field [2] FunctionReference
---@field [3] FunctionParameters

---@alias BuilderType 'Any' | 'Land' | 'Air' | 'Sea' | 'Gate' 

---@class BuilderSpec
---@field BuilderName BuilderNames
---@field BuilderType BuilderType
---@field BuilderData table
---@field PlatoonTemplate string
---@field Priority number
---@field InstanceCount number
---@field BuilderConditions BuilderCondition[]

-- Global list of all builders found in the game
---@type table<string, BuilderSpec>
Builders = {}

--- Register a base builder template, or override an existing base builder template
---@param spec BuilderSpec
---@return string
Builder = function(spec)
    -- it should be a table
    if type(spec) ~= 'table' then
        WARN('Invalid Builder: ', repr(arg))
        return
    end

    -- should have a name, as that is used as its identifier
    if not spec.BuilderName then 
        WARN('Builder excluded for missing BuilderName in its specification: ', reprs(spec))
        return
    end

    -- should have a priority
    if not spec.Priority then 
        WARN('Builder excluded for missing Priority in its specification: ', reprs(spec))
        return
    end

    -- should have a type
    if not spec.BuilderType then 
        WARN('Builder excluded for missing Priority in its specification: ', reprs(spec))
        return
    end

    -- default value
    if not spec.BuilderData then
        spec.BuilderData = {}
    end

    -- overwrite any existing definitions
    if Builders[spec.BuilderName] then
        LOG(string.format('Overwriting builder: %s', spec.BuilderName))
        for k,v in spec do
            Builders[spec.BuilderName][k] = v
        end

    -- first one, we become the definition
    else
        Builders[spec.BuilderName] = spec
    end

    return spec.BuilderName
end
