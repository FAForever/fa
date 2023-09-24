--------------------------------------------------------------------------*
--
--  File     :  /lua/ai/EngineerPlatoonTemplates.lua
--
--  Summary  : Global platoon templates
--
--  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------

-- Note some mods will replace this file, any new templates that need to be added should be added to EngineerPlatoonNewTemplates.lua
-- Engineer platoons to be formed

PlatoonTemplate {
    Name = 'CommanderAssist',
    Plan = 'ManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' },
    },
}

PlatoonTemplate {
    Name = 'CommanderBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CommanderEnhance',
    Plan = 'EnhanceAI',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerAssist',
    Plan = 'ManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T1EngineerReclaimer',
    Plan = 'ReclaimAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerAssist',
    Plan = 'ManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerTransfer',
    Plan = 'TransferAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'none' },
    },
}

PlatoonTemplate {
    Name = 'UEFT2EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.UEF * categories.ENGINEER * categories.TECH2, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CybranT2EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.CYBRAN * categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerAssist',
    Plan = 'ManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerTransfer',
    Plan = 'TransferAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 - categories.ENGINEERSTATION, 1, 1, 'support', 'none' },
    },
}

PlatoonTemplate {
    Name = 'AeonT3EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.AEON * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'UEFT3EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.UEF * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CybranT3EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.CYBRAN * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER) - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'SeraphimT3EngineerBuilder',
    Plan = 'EngineerBuildAI',
    GlobalSquads = {
        { categories.SERAPHIM * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'StateMachineEngineerT1',
    Plan = 'StateMachineAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1 - categories.COMMAND, 1, 1, 'support', 'None' },
    },
}

PlatoonTemplate {
    Name = 'StateMachineEngineerT2',
    Plan = 'StateMachineAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.COMMAND, 1, 1, 'support', 'None' },
    },
}

PlatoonTemplate {
    Name = 'StateMachineEngineerT3',
    Plan = 'StateMachineAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 - categories.COMMAND, 1, 1, 'support', 'None' },
    },
}

-- Factory built Engineers below

PlatoonTemplate {
    Name = 'T1BuildEngineer',
    FactionSquads = {
        UEF = {
            { 'uel0105', 1, 1, 'support', 'None' }
        },
        Aeon = {
            { 'ual0105', 1, 1, 'support', 'None' }
        },
        Cybran = {
            { 'url0105', 1, 1, 'support', 'None' }
        },
        Seraphim = {
            { 'xsl0105', 1, 1, 'support', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T2BuildEngineer',
    FactionSquads = {
        UEF = {
            { 'uel0208', 1, 1, 'support', 'None' }
        },
        Aeon = {
            { 'ual0208', 1, 1, 'support', 'None' }
        },
        Cybran = {
            { 'url0208', 1, 1, 'support', 'None' }
        },
        Seraphim = {
            { 'xsl0208', 1, 1, 'support', 'None' }
        },
    }
}

PlatoonTemplate {
    Name = 'T3BuildEngineer',
    FactionSquads = {
        UEF = {
            { 'uel0309', 1, 1, 'support', 'None' }
        },
        Aeon = {
            { 'ual0309', 1, 1, 'support', 'None' }
        },
        Cybran = {
            { 'url0309', 1, 1, 'support', 'None' }
        },
        Seraphim = {
            { 'xsl0309', 1, 1, 'support', 'None' }
        },
    }
}
