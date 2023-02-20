--****************************************************************************
--**
--**  File     :  /lua/sim/CheatBuffs.lua
--**
--**  Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************


---@alias CheatBuffType
---| "CHEATBUILDRATE"
---| "CHEATINCOME"
---| "INTELCHEAT"

---@alias CheatBuffName
---| "CheatBuildRate"
---| "CheatIncome"
---| "CheatIntel"

BuffBlueprint {
    Name = 'CheatBuildRate',
    DisplayName = 'CheatBuildRate',
    BuffType = 'CHEATBUILDRATE',
    Stacks = 'ALWAYS',
    Duration = -1,
    Affects = {
        BuildRate = {
            Add = 0,
            Mult = 2.0,
        },
    },
}

BuffBlueprint {
    Name = 'CheatIncome',
    DisplayName = 'CheatIncome',
    BuffType = 'CHEATINCOME',
    Stacks = 'ALWAYS',
    Duration = -1,
    Affects = {
        EnergyProduction = {
            Add = 0,
            Mult = 2.0,
        },
        MassProduction = {
            Add = 0,
            Mult = 2.0,
        },
    },
}

BuffBlueprint {
    Name = 'IntelCheat',
    DisplayName = 'IntelCheat',
    BuffType = 'INTELCHEAT',
    Stacks = 'ALWAYS',
    Duration = -1,
    Affects = {
        VisionRadius = {
            Add = 10000,
            Mult = 1.0,
        },
        OmniRadius = {
            Add = 10000,
            Mult = 1.0,
        }
    },
}