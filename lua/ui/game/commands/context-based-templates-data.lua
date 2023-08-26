
--******************************************************************************************************
--** Copyright (c) 2023  Willem 'Jip' Wijnia
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

---@class ContextBasedTemplate
---@field Name string                           # Printed on screen when cycling the templates
---@field TemplateData BuildTemplate            # A regular build template, except that it is written in Pascal Case and usually the first unit is removed
---@field TemplateSortingOrder number           # Lower numbers end up first in the queue 
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
    TemplateSortingOrder = 100,
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
    TemplateSortingOrder = 101,
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
    TemplateSortingOrder = 100,
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
    TemplateSortingOrder = 100,
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
    TemplateSortingOrder = 100,
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
    TemplateSortingOrder = 100,
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
PointDefense = {
    Name = "Point defense",
    TriggersOnLand = true,
    TemplateSortingOrder = 10,
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
AirDefenseLand = {
    Name = "Anti-air defense",
    TriggersOnLand = true,
    TemplateSortingOrder = 11,
    TemplateData = {
        3,
        3,
        {
            'uab2104',
            4646,
            0,
            0
        },
    },
}


---@type ContextBasedTemplate
AirDefenseWater = {
    Name = "Anti-air defense",
    TriggersOnWater = true,
    TemplateSortingOrder = 11,
    TemplateData = {
        3,
        3,
        {
            'uab2104',
            4646,
            0,
            0
        },
    },
}


---@type ContextBasedTemplate
TorpedoDefense = {
    Name = "Torpedo defense",
    TriggersOnWater = true,
    TemplateSortingOrder = 10,
    TemplateData = {
        3,
        3,
        {
            'uab2109',
            4646,
            0,
            0
        },
    },
}

---@type ContextBasedTemplate
T1Extractor = {
    Name = 'Extractor',
    TriggersOnMassDeposit = true,
    TemplateSortingOrder = 100,
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
    TemplateSortingOrder = 101,
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
    TemplateSortingOrder = 102,
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
    TemplateSortingOrder = 103,
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
    TemplateSortingOrder = 100,
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
