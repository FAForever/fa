----------------------------------------------------------------------------
--
--  File     :  /lua/system/GlobalBaseTemplate.lua
--
--  Summary  :  Global base table and template methods
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Global list of all BaseBuilderTemplates found in the system.
local ipairs = ipairs
local LOG = LOG
local setmetatable = setmetatable
local WARN = WARN
local next = next
local type = type

BaseBuilderTemplates = {}

--
BaseBuilderTemplate = {}
BaseBuilderTemplateDefMeta = {}

BaseBuilderTemplateDefMeta.__index = BaseBuilderTemplateDefMeta
BaseBuilderTemplateDefMeta.__call = function(...)
    if type(arg[2]) ~= 'table' then
        LOG('Invalid BaseBuilderTemplate: ', repr(arg))
        return
    end

    if not arg[2].BaseTemplateName then
        WARN('Missing BaseTemplateName for BaseBuilderTemplate definition: ',repr(arg))
        return
    end

    if not arg[2].Builders then
        WARN('Missing Builders for BaseBuilderTemplate definition - BaseTemplateName = ' .. arg[2].BaseTemplateName)
        return
    end
    for k,v in arg[2].Builders do
        if not BuilderGroups[v] then
            WARN('Invalid BuilderGroup named - ' .. v .. ' - in BaseBuilderTemplate: ' .. arg[2].BaseTemplateName)
        end
    end

    if not arg[2].ExpansionFunction then
        WARN('Missing Builders for ExpansionFunction definition - BaseTemplateName = ' .. arg[2].BaseTemplateName)
        return
    end

    if not arg[2].BaseSettings then
        WARN('Missing BaseSettings for BaseBuilderTemplate definition - BaseTemplateName = ' .. arg[2].BaseTemplateName)
        return
    end

    if BaseBuilderTemplates[arg[2].BaseTemplateName] then
        LOG('Hooked BaseBuilderTemplate: ', arg[2].BaseTemplateName)
        for k,v in arg[2] do
            BaseBuilderTemplates[arg[2].BaseTemplateName][k] = v
        end
    else
        BaseBuilderTemplates[arg[2].BaseTemplateName] = arg[2]
    end
    --SPEW('BaseBuilderTemplate Registered: ', arg[2].BaseTemplateName)
    return arg[2].BaseTemplateName
end

setmetatable(BaseBuilderTemplate, BaseBuilderTemplateDefMeta)
