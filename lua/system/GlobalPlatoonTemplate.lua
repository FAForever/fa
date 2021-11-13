----------------------------------------------------------------------------
--
--  File     :  /lua/system/GlobalPlatoonTemplate.lua
--
--  Summary  :  Global buff table and blueprint methods
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Global list of all buffs found in the system.
local ipairs = ipairs
local LOG = LOG
local setmetatable = setmetatable
local next = next
local type = type

PlatoonTemplates = {}

--
PlatoonTemplate = {}
PlatoonTemplateDefMeta = {}

PlatoonTemplateDefMeta.__index = PlatoonTemplateDefMeta
PlatoonTemplateDefMeta.__call = function(...)

    if type(arg[2]) ~= 'table' then
        LOG('Invalid PlatoonTemplate: ', repr(arg))
        return
    end

    if not arg[2].Name then
        LOG('Missing name for PlatoonTemplate definition: ',repr(arg))
        return
    end

    if not arg[2].GlobalSquads and not arg[2].FactionSquads then
        LOG('Missing GlobalSquads and FactionSquads for PlatoonTemplate definition - requires one: ',repr(arg))
        return
    end

    local oldFactionSquads = false
    if InitialRegistration and PlatoonTemplates[arg[2].Name] then
        LOG('Hooked PlatoonTemplate: ', arg[2].Name)
        -- Save out any old faction squads in case they aren't being overwritten
        oldFactionSquads = PlatoonTemplates[arg[2].Name]
    end

    if not PlatoonTemplates[arg[2].Name] then
        PlatoonTemplates[arg[2].Name] = {}
    end

    --SPEW('PlatoonTemplate Registered: ', arg[2].Name)

    PlatoonTemplates[arg[2].Name] = arg[2]

    -- if there are old faction squads insert the ones that aren't being overridden
    if oldFactionSquads then
        for k,v in oldFactionSquads do
            if not PlatoonTemplates[arg[2].Name].FactionSquads[k] then
                PlatoonTemplates[arg[2].Name].FactionSquads[k] = v
            end
        end
    end

    return arg[2].Name
end

setmetatable(PlatoonTemplate, PlatoonTemplateDefMeta)
