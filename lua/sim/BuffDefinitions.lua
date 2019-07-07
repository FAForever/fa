-----------------------------------------------------------------
-- File     :  /lua/sim/buffdefinition.lua
-- Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

import('/lua/sim/AdjacencyBuffs.lua')
import('/lua/sim/CheatBuffs.lua') -- Buffs for AI Cheating

DefineBasicBuff = function(name, type, stacks, rate, health, regen)
    if not Buffs[name] then
        BuffBlueprint {
            Name = name,
            DisplayName = name,
            BuffType = type,
            Stacks = stacks,
            Duration = -1,
            Affects = {
                BuildRate = {
                    Add = rate or 0,
                    Mult = 1,
                },
                MaxHealth = {
                    Add = health or 0,
                    Mult = 1,
                },
                Regen = {
                    Add = regen or 0,
                    Mult = 1,
                },
            },
        }
    end
end

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
DefineBasicBuff('VeterancyRegen1', 'VETERANCYREGEN', 'REPLACE', nil, nil, 2)
DefineBasicBuff('VeterancyRegen2', 'VETERANCYREGEN', 'REPLACE', nil, nil, 4)
DefineBasicBuff('VeterancyRegen3', 'VETERANCYREGEN', 'REPLACE', nil, nil, 6)
DefineBasicBuff('VeterancyRegen4', 'VETERANCYREGEN', 'REPLACE', nil, nil, 8)
DefineBasicBuff('VeterancyRegen5', 'VETERANCYREGEN', 'REPLACE', nil, nil, 10)

__moduleinfo.auto_reload = true
