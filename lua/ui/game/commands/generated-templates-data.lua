---@class GenerativeBuildTemplate
---@field Name string                           # Printed on screen when cycling build templates
---@field TriggersOnHover EntityCategory        # Selection filter based on the categories of the unit we're hovering over
---@field TriggersOnSelection EntityCategory    # selection filter based on the categories of the units in our selection
---@field CopyUnit boolean                      # When true, copies the blueprint id of the unit we're hovering over into the first unit of the build template 
---@field TemplateData BuildTemplate            # A regular build template, except that it is written in Pascal Case
---@field Order? number                         # Allows you to sort the templates
---@field SortTemplate? boolean                 # When true, sorts the buildings based on the distance to the average position of your selection

---@type GenerativeBuildTemplate
CapExtractorWithStorages = {
    Name = 'Storages',
    TriggersOnHover = categories.MASSEXTRACTION,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    TemplateData = {
        0,
        0,
        {
            'uab1106',
            33986,
            2,
            0
        },
        {
            'uab1106',
            33993,
            -2,
            0
        },
        {
            'uab1106',
            34000,
            0,
            -2
        },
        {
            'uab1106',
            34008,
            0,
            2
        },
    }
}

---@type GenerativeBuildTemplate
CapExtractorWithFabs = {
    Name = 'Storages and  fabricators',
    TriggersOnHover = categories.MASSEXTRACTION * categories.TECH2,
    TriggersOnSelection = categories.TECH2 + categories.TECH3,
    TemplateData = {
        10,
        10,
        {
            'uab1106',
            30057,
            -2,
            0
        },
        {
            'uab1106',
            30070,
            2,
            0
        },
        {
            'uab1106',
            30083,
            0,
            -2
        },
        {
            'uab1106',
            30096,
            0,
            2
        },
        {
            'uab1104',
            30109,
            -4,
            0
        },
        {
            'uab1104',
            30134,
            -2,
            2
        },
        {
            'uab1104',
            30158,
            0,
            4
        },
        {
            'uab1104',
            30182,
            2,
            2
        },
        {
            'uab1104',
            30206,
            4,
            0
        },
        {
            'uab1104',
            30231,
            2,
            -2
        },
        {
            'uab1104',
            30255,
            0,
            -4
        },
        {
            'uab1104',
            30279,
            -2,
            -2
        }
    },
}

CapRadarWithPower = {
    Name = 'Power generators',
    TriggersOnHover = (categories.RADAR + categories.OMNI) * categories.STRUCTURE,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    CopyUnit = false,
    TemplateData = {
        0,
        0,
        {
            'uab1101',
            33986,
            2,
            0
        },
        {
            'uab1101',
            33993,
            -2,
            0
        },
        {
            'uab1101',
            34000,
            0,
            -2
        },
        {
            'uab1101',
            34008,
            0,
            2
        },
    }
}

CapT2ArtilleryWithPower = {
    Name = 'Power generators',
    TriggersOnHover = categories.ARTILLERY * categories.STRUCTURE * categories.TECH2,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    CopyUnit = false,
    TemplateData = {
        0,
        0,
        {
            'uab1101',
            33986,
            2,
            0
        },
        {
            'uab1101',
            33993,
            -2,
            0
        },
        {
            'uab1101',
            34000,
            0,
            -2
        },
        {
            'uab1101',
            34008,
            0,
            2
        },
    }
}

---@type GenerativeBuildTemplate
Test01 = {
    Name = 'Test01',
    TriggersOnHover = categories.AIR * categories.FACTORY,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    TemplateData = {
        0,
        0,
        {
            'uab0102',
            8980,
            2,
            2
        },
        {
            'uab1101',
            9005,
            -1,
            7
        },
        {
            'uab1101',
            9012,
            1,
            7
        },
        {
            'uab1101',
            9020,
            3,
            7
        },
        {
            'uab1101',
            9027,
            5,
            7
        }
    },
}

---@type GenerativeBuildTemplate
Test02 = {
    Name = 'Test02',
    TriggersOnHover = categories.AIR * categories.FACTORY,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    TemplateData = {
        10,
        8,
        {
            'uab0102',
            8980,
            2,
            2
        },
        {
            'uab1101',
            9035,
            -3,
            5
        },
        {
            'uab1101',
            9042,
            -3,
            3
        },
        {
            'uab1101',
            9050,
            -3,
            1
        },
        {
            'uab1101',
            9057,
            -3,
            -1
        }
    },
}

---@type GenerativeBuildTemplate
Test03 = {
    Name = 'Test03',
    TriggersOnHover = categories.AIR * categories.FACTORY,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    TemplateData = {
        8,
        10,
        {
            'uab0102',
            8980,
            2,
            2
        },
        {
            'uab1101',
            9096,
            5,
            -3
        },
        {
            'uab1101',
            9104,
            3,
            -3
        },
        {
            'uab1101',
            9111,
            1,
            -3
        },
        {
            'uab1101',
            9119,
            -1,
            -3
        }
    },
}

---@type GenerativeBuildTemplate
Test04 = {
    Name = 'Test04',
    TriggersOnHover = categories.AIR * categories.FACTORY,
    TriggersOnSelection = categories.TECH1 + categories.TECH2 + categories.TECH3 + categories.COMMAND,
    TemplateData = {
        0,
        0,
        {
            'uab0102',
            8980,
            2,
            2
        },
        {
            'uab1101',
            9066,
            7,
            -1
        },
        {
            'uab1101',
            9074,
            7,
            1
        },
        {
            'uab1101',
            9081,
            7,
            3
        },
        {
            'uab1101',
            9089,
            7,
            5
        }
    },
}
