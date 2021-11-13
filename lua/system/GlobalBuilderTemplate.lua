----------------------------------------------------------------------------
--
--  File     :  /lua/system/GlobalBuilderTemplate.lua
--
--  Summary  :  Global builder table and template methods
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Global list of all buffs found in the system.
local ipairs = ipairs
local LOG = LOG
local setmetatable = setmetatable
local WARN = WARN
local next = next
local type = type

Builders = {}

--
Builder = {}
BuilderDefMeta = {}

BuilderDefMeta.__index = BuilderDefMeta
BuilderDefMeta.__call = function(...)
    if type(arg[2]) ~= 'table' then
        LOG('Invalid Builder: ', repr(arg))
        return
    end

    if not arg[2].BuilderName then
        WARN('Missing BuilderName for Builder definition: ',repr(arg))
        return
    end

    if not arg[2].Priority then
        WARN('Missing Priority for Builder definition - BuilderName = ' .. arg[2].BuilderName)
        return
    end

    if not arg[2].BuilderType then
        WARN('Missing BuilderType for Builder definition - BuilderName = ' .. arg[2].BuilderName)
        return
    end

    if Builders[arg[2].BuilderName] then
        LOG('Hooked Builder: ', arg[2].BuilderName)
        for k,v in arg[2] do
            Builders[arg[2].BuilderName][k] = v
        end
    else
        Builders[arg[2].BuilderName] = arg[2]
    end

    if not arg[2].BuilderData then
        arg[2].BuilderData = {}
    end
    --SPEW('Builder Registered: ', arg[2].BuilderName)
    return arg[2].BuilderName
end

setmetatable(Builder, BuilderDefMeta)
