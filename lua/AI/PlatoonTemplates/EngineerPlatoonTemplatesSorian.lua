--***************************************************************************
--*
--**  File     :  /lua/ai/EngineerPlatoonTemplates.lua
--**
--**  Summary  : Global platoon templates
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

------ Engineer platoons to be formed

PlatoonTemplate {
    Name = 'CommanderAssistSorian',
    Plan = 'SorianManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' },
    },
}

PlatoonTemplate {
    Name = 'SCUEnhance',
    Plan = 'EnhanceAISorian',
    GlobalSquads = {
        { categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CommanderEnhanceSorian',
    Plan = 'EnhanceAISorian',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerAssistSorian',
    Plan = 'SorianManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerAssistSorian',
    Plan = 'SorianManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CommanderBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CommanderAttackSorian',
    Plan = 'CDRHuntAISorian',
    GlobalSquads = {
        { categories.COMMAND, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'AnyEngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { (categories.ENGINEER - categories.ENGINEERSTATION) + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerAssistSorian',
    Plan = 'SorianManagerEngineerAssistAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'UEFT2EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.UEF * categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CybranT2EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.CYBRAN * categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerBuilderOnlySorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 - categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'AeonT3EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.AEON * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'UEFT3EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.UEF * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'CybranT3EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.CYBRAN * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'SeraphimT3EngineerBuilderSorian',
    Plan = 'EngineerBuildAISorian',
    GlobalSquads = {
        { categories.SERAPHIM * categories.ENGINEER * (categories.TECH3 + categories.SUBCOMMANDER), 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'EngineerRepairSorian',
    Plan = 'RepairAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH1, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T2EngineerRepairSorian',
    Plan = 'RepairAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH2 - categories.ENGINEERSTATION, 1, 1, 'support', 'None' }
    },
}

PlatoonTemplate {
    Name = 'T3EngineerRepairSorian',
    Plan = 'RepairAI',
    GlobalSquads = {
        { categories.ENGINEER * categories.TECH3 + categories.SUBCOMMANDER, 1, 1, 'support', 'None' }
    },
}
