--****************************************************************************
--**
--**  File     :  /lua/sim/OpBuffDefinitions.lua
--**
--**  Summary  : Buffs for Ops
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************


---@alias OpBuffType
---| "AIBUILDRATE"

---@alias OpBuffName
---| "BaseManagerFactoryDefaultBuildRate"
---| "BaseManagerEngineerDefaultBuildRate"

BuffBlueprint {
    Name = 'BaseManagerFactoryDefaultBuildRate',
    DisplayName = 'BaseManagerFactoryDefaultBuildRate',
    BuffType = 'AIBUILDRATE',
    Stacks = 'REPLACE',
    Duration = -1,
    EntityCategory = 'FACTORY',
    Affects = {
        BuildRate = {
            Add = 0,
            Mult = 2,
        },
    },
}

BuffBlueprint {
    Name = 'BaseManagerEngineerDefaultBuildRate',
    DisplayName = 'BaseManagerEngineerDefaultBuildRate',
    BuffType = 'AIBUILDRATE',
    Stacks = 'REPLACE',
    Duration = -1,
    EntityCategory = 'ENGINEER',
    Affects = {
        BuildRate = {
            Add = 0,
            Mult = 3,
        },
    },
}