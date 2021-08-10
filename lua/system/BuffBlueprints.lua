--****************************************************************************
--**
--**  File     :  /lua/system/BuffBlueprints.lua
--**
--**  Summary  :  Global buff table and blueprint methods
--**
--**  Copyright � 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

-- Global list of all buffs found in the system.
Buffs = {}

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
BuffBlueprint = {}
BuffDefMeta = {}

BuffDefMeta.__index = BuffDefMeta
BuffDefMeta.__call = function(...)
    
    if type(arg[2]) ~= 'table' then
        --LOG('Invalid BuffDefinition: ', repr(arg))
        return
    end
    
    if not arg[2].Name then
        --LOG('Missing name for buff definition: ',repr(arg))
        return
    end
    
    if InitialRegistration and Buffs[arg[2].Name] then
        WARN('Duplicate buff detected: ', arg[2].Name)
    end

    if not Buffs[arg[2].Name] then
        Buffs[arg[2].Name] = {}
    end

    --SPEW('Buff Registered: ', arg[2].Name)
    
    Buffs[arg[2].Name] = arg[2]
    return arg[2].Name
end

setmetatable(BuffBlueprint, BuffDefMeta)
