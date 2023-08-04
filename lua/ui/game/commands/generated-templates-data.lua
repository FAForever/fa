---@class GenerativeBuildTemplate
---@field Name string                           # Printed on screen when cycling build templates
---@field TriggersOnHover EntityCategory        # Selection filter based on the categories of the unit we're hovering over
---@field CopyUnit boolean                      # When true, copies the blueprint id of the unit we're hovering over into the first unit of the build template
---@field TemplateData BuildTemplate            # A regular build template, except that it is written in Pascal Case
---@field Order? number                         # Allows you to sort the templates
---@field SortTemplate? boolean                 # When true, sorts the buildings based on the distance to the average position of your selection

---@type GenerativeBuildTemplate
CapExtractorWithStorages = {
    Name = 'Storages',
    TriggersOnHover = categories.MASSEXTRACTION,
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
    Name = 'Storages and fabricators',
    TriggersOnHover = categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3),
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

CapT3FabricatorWithStorages = {
    Name = 'Storages',
    TriggersOnHover = categories.STRUCTURE * categories.MASSFABRICATION * categories.TECH3,
    TemplateData = {
        0,
        0,
        {
            'uab1106',
            2605,
            -2,
            4
        },
        {
            'uab1106',
            2621,
            0,
            4
        },
        {
            'uab1106',
            2636,
            2,
            4
        },
        {
            'uab1106',
            2651,
            4,
            2
        },
        {
            'uab1106',
            2666,
            4,
            0
        },
        {
            'uab1106',
            2680,
            4,
            -2
        },
        {
            'uab1106',
            2695,
            2,
            -4
        },
        {
            'uab1106',
            2710,
            0,
            -4
        },
        {
            'uab1106',
            2724,
            -2,
            -4
        },
        {
            'uab1106',
            2738,
            -4,
            -2
        },
        {
            'uab1106',
            2753,
            -4,
            0
        },
        {
            'uab1106',
            2767,
            -4,
            2
        }
    },
}

CapT3ArtilleryWithPower = {
    Name = 'Power generators',
    TriggersOnHover = categories.STRUCTURE * categories.ARTILLERY * (categories.TECH3 + categories.EXPERIMENTAL),
    TemplateData = {
        0,
        0,
        {
            'uab1301',
            5352,
            10,
            2
        },
        {
            'uab1301',
            5369,
            2,
            10
        },
        {
            'uab1301',
            5385,
            -6,
            2
        },
        {
            'uab1301',
            5408,
            2,
            -6
        }
    },
}

CapAirWithPowerRight = {
    Name = 'Power generators - right',
    TriggersOnHover = categories.AIR * categories.TECH3 * categories.STRUCTURE,
    TemplateData = {
        0,
        0,
        {
            'uab1301',
            5352,
            10,
            2
        },
    },
}

CapAirWithPowerLeft = {
    Name = 'Power generators - left',
    TriggersOnHover = categories.AIR * categories.TECH3 * categories.STRUCTURE,
    TemplateData = {
        0,
        0,
        {
            'uab1301',
            5385,
            -6,
            2
        },
    },
}

CapAirWithPowerTop = {
    Name = 'Power generators - top',
    TriggersOnHover = categories.AIR * categories.TECH3 * categories.STRUCTURE,
    TemplateData = {
        0,
        0,
        {
            'uab1301',
            5408,
            2,
            -6
        }
    },
}

CapAirWithPowerBottom = {
    Name = 'Power generators - bottom',
    TriggersOnHover = categories.AIR * categories.TECH3 * categories.STRUCTURE,
    TemplateData = {
        0,
        0,
        {
            'uab1301',
            5369,
            2,
            10
        },
    },
}
