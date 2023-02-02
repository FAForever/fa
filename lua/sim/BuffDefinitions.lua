-----------------------------------------------------------------
-- File     :  /lua/sim/buffdefinition.lua
-- Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

---@alias VeterancyBuffType
---| "VERTANCYHEALTH"
---| "VETERANCYREGEN"

---@alias VeterancyBuffName
---| 'VeterancyMaxHealth1'
---| 'VeterancyMaxHealth2'
---| 'VeterancyMaxHealth3'
---| 'VeterancyMaxHealth4'
---| 'VeterancyMaxHealth5'
---| 'VeterancyRegen1'
---| 'VeterancyRegen2'
---| 'VeterancyRegen3'
---| 'VeterancyRegen4'
---| 'VeterancyRegen5'

import("/lua/sim/adjacencybuffs.lua")
import("/lua/sim/cheatbuffs.lua") -- Buffs for AI Cheating

-- VETERANCY BUFFS - UNIT MAX HEALTH ONLY
BuffBlueprint {
    Name = 'VeterancyMaxHealth1',
    DisplayName = 'VeterancyMaxHealth1',
    BuffType = 'VETERANCYHEALTH',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        MaxHealth = {
            DoNotFill = true,
            Add = 0,
            Mult = 1.1,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyMaxHealth2',
    DisplayName = 'VeterancyMaxHealth2',
    BuffType = 'VETERANCYHEALTH',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        MaxHealth = {
            DoNotFill = true,
            Add = 0,
            Mult = 1.2,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyMaxHealth3',
    DisplayName = 'VeterancyMaxHealth3',
    BuffType = 'VETERANCYHEALTH',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        MaxHealth = {
            DoNotFill = true,
            Add = 0,
            Mult = 1.3,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyMaxHealth4',
    DisplayName = 'VeterancyMaxHealth4',
    BuffType = 'VETERANCYHEALTH',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        MaxHealth = {
            DoNotFill = true,
            Add = 0,
            Mult = 1.4,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyMaxHealth5',
    DisplayName = 'VeterancyMaxHealth5',
    BuffType = 'VETERANCYHEALTH',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        MaxHealth = {
            DoNotFill = true,
            Add = 0,
            Mult = 1.5,
        },
    },
}

-- VETERANCY BUFFS - UNIT REGEN
BuffBlueprint {
    Name = 'VeterancyRegen1',
    DisplayName = 'VeterancyRegen1',
    BuffType = 'VETERANCYREGEN',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        Regen = {
            Add = 2,
            Mult = 1,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyRegen2',
    DisplayName = 'VeterancyRegen2',
    BuffType = 'VETERANCYREGEN',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        Regen = {
            Add = 4,
            Mult = 1,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyRegen3',
    DisplayName = 'VeterancyRegen3',
    BuffType = 'VETERANCYREGEN',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        Regen = {
            Add = 6,
            Mult = 1,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyRegen4',
    DisplayName = 'VeterancyRegen4',
    BuffType = 'VETERANCYREGEN',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        Regen = {
            Add = 8,
            Mult = 1,
        },
    },
}

BuffBlueprint {
    Name = 'VeterancyRegen5',
    DisplayName = 'VeterancyRegen5',
    BuffType = 'VETERANCYREGEN',
    Stacks = 'REPLACE',
    Duration = -1,
    Affects = {
        Regen = {
            Add = 10,
            Mult = 1,
        },
    },
}
