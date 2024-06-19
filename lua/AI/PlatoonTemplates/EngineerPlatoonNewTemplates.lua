--------------------------------------------------------------------------*
--
--  File     :  /lua/ai/EngineerPlatoonNewTemplates.lua
--
--  Summary  : Global platoon templates
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Engineer platoons to be formed

PlatoonTemplate {
    Name = 'T123EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.ENGINEER * (categories.TECH1 + categories.TECH2 + categories.TECH3) - categories.ENGINEERSTATION - categories.COMMAND, 1, 1, 'support', 'none' },
    },
}

PlatoonTemplate {
    Name = 'T1EngineerGridReclaimer',
    Plan = 'ReclaimGridAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerGridReclaimer',
    Plan = 'ReclaimGridAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerGridReclaimer',
    Plan = 'ReclaimGridAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerDrop',
    Plan = 'EngineerDropAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 6, 6, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CommanderInitialBuilder',
    Plan = 'CommanderInitialBOAI',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}