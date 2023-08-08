
---@class ContextBasedTemplate
---@field Name string                           # Printed on screen when cycling the templates
---@field TemplateData BuildTemplate            # A regular build template, except that it is written in Pascal Case and usually the first unit is removed
---@field TriggersOnUnit? EntityCategory        # When defined, includes this template when the unit the mouse is hovering over matches the categories
---@field TriggersOnLand? boolean               # When true, includes this template when the mouse is over land and not over a deposit
---@field TriggersOnWater? boolean              # When true, includes this template when the mouse is over water and not over a deposit
---@field TriggersOnMassDeposit? boolean        # When true, includes this template when the mouse is over a mass deposit
---@field TriggersOnHydroDeposit? boolean       # When true, includes this template when the mouse is over a hydrocarbon deposit

-- Entity categories that are considered valid: https://github.com/FAForever/fa/blob/deploy/fafdevelop/engine/Core/Categories.lua

---@type ContextBasedTemplate
CapExtractorWithStorages = {
    Name = 'Storages',
    TriggersOnUnit = categories.MASSEXTRACTION,
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

---@type ContextBasedTemplate
CapExtractorWithFabs = {
    Name = 'Storages and fabricators',
    TriggersOnUnit = categories.MASSEXTRACTION * (categories.TECH2 + categories.TECH3),
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

---@type ContextBasedTemplate
CapRadarWithPower = {
    Name = 'Power generators',
    TriggersOnUnit = (categories.RADAR + categories.OMNI) * categories.STRUCTURE,
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

---@type ContextBasedTemplate
CapT2ArtilleryWithPower = {
    Name = 'Power generators',
    TriggersOnUnit = categories.ARTILLERY * categories.STRUCTURE * categories.TECH2,
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

---@type ContextBasedTemplate
CapT3FabricatorWithStorages = {
    Name = 'Storages',
    TriggersOnUnit = categories.STRUCTURE * categories.MASSFABRICATION * categories.TECH3,
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

---@type ContextBasedTemplate
CapT3ArtilleryWithPower = {
    Name = 'Power generators',
    TriggersOnUnit = categories.STRUCTURE * categories.ARTILLERY * (categories.TECH3 + categories.EXPERIMENTAL),
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

---@type ContextBasedTemplate
CapAirWithPowerRight = {
    Name = 'Power generators - right',
    TriggersOnUnit = categories.AIR * categories.TECH3 * categories.STRUCTURE,
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

---@type ContextBasedTemplate
CapAirWithPowerLeft = {
    Name = 'Power generators - left',
    TriggersOnUnit = categories.AIR * categories.TECH3 * categories.STRUCTURE,
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

---@type ContextBasedTemplate
CapAirWithPowerTop = {
    Name = 'Power generators - top',
    TriggersOnUnit = categories.AIR * categories.TECH3 * categories.STRUCTURE,
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

---@type ContextBasedTemplate
CapAirWithPowerBottom = {
    Name = 'Power generators - bottom',
    TriggersOnUnit = categories.AIR * categories.TECH3 * categories.STRUCTURE,
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

---@type ContextBasedTemplate
PointDefense = {
    Name = "Point defense",
    TriggersOnLand = true,
    TemplateData = {
        3,
        3,
        {
            'uab2101',
            4646,
            0,
            0
        },
        {
            'uab5101',
            4749,
            -1,
            -1
        },
        {
            'uab5101',
            4753,
            0,
            -1
        },
        {
            'uab5101',
            4757,
            1,
            -1
        },
        {
            'uab5101',
            4761,
            1,
            0
        },
        {
            'uab5101',
            4765,
            1,
            1
        },
        {
            'uab5101',
            4769,
            0,
            1
        },
        {
            'uab5101',
            4773,
            -1,
            1
        },
        {
            'uab5101',
            4777,
            -1,
            0
        }
    },
}

---@type ContextBasedTemplate
T1Extractor = {
    Name = 'Extractor',
    TriggersOnMassDeposit = true,
    TemplateData = {
        0,
        0,
        {
            'uab1103',
            1,
            0,
            0
        },
    }, 
}

---@type ContextBasedTemplate
T2ExtractorWithStorages = {
    Name = 'Extractor and storages',
    TriggersOnMassDeposit = true,
    TemplateData = {
        0,
        0,
        {
            'uab1202',
            1,
            0,
            0
        },
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

---@type ContextBasedTemplate
T3ExtractorWithStorages = {
    Name = 'Extractor and storages',
    TriggersOnMassDeposit = true,
    TemplateData = {
        0,
        0,
        {
            'uab1302',
            1,
            0,
            0
        },
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

---@type ContextBasedTemplate
T3ExtractorWithStoragesAndFabs = {
    Name = 'Extractor, storages and fabricators',
    TriggersOnMassDeposit = true,
    TemplateData = {
        0,
        0,
        {
            'uab1302',
            1,
            0,
            0
        },
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

---@type ContextBasedTemplate
T1Hydrocarbon = {
    Name = 'Hydrocarbon',
    TriggersOnHydroDeposit = true,
    TemplateData = {
        0,
        0,
        {
            'uab1102',
            1,
            1,
            1
        },
    }, 
}
