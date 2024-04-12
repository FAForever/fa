--*****************************************************************************
--* File: lua/modules/ui/game/rangeoverlayparams.lua
--* Author: ???
--* Summary: Range overlay definitions
--*
--* "NormalColor" - overlay color used (AARRGGBB, AA = glow amount)
--* "SelectedColor" - overlay color when the unit is selected (RRGGBB
--* "RolloverColor" - overlay color when the unit is hovered over (RRGGBB
--* "Inner" - Thickness of minimum range line (zoomed in, zoomed out)
--* "Outer" - Thickness of maximum range line (zoomed in, zoomed out)
--*
--* Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local innerMilAll = {0.03, 3.0}
local outerMilAll = {0.06, 6.0}
local innerMilitary = {0.02, 2.0}
local outerMilitary = {0.04, 4.0}

local innerIntelAll = {1, 1} -- Not really used
local outerIntelAll = {0.03, 3.0}
local innerIntel = {1, 1} -- Not really used
local outerIntel = {0.02, 2.0}

local glowAllNormal = '00'
local glowAllSelect = '08'
local glowAllOver = '10'

local glowMilNormal = '00'
local glowMilSelect = '08'
local glowMilOver = '10'

local glowIntelNormal = '00'
local glowIntelSelect = '08'
local glowIntelOver = '10'

---@class RangeOverlay
---@field key string
---@field Label string
---@field Categories moho.EntityCategory
---@field NormalColor Color
---@field SelectColor Color
---@field RolloverColor Color
---@field Inner number[]
---@field Outer number[]
---@field Type number
---@field Combo? boolean
---@field Tooltip string

---@type table<string, RangeOverlay>
RangeOverlayParams = {
    AllMilitary = {
        key = 'allmilitary',
        Label = '<LOC range_0011>Combine Military',
        Categories = categories.OVERLAYANTIAIR + categories.OVERLAYANTINAVY + categories.OVERLAYDIRECTFIRE + categories.OVERLAYINDIRECTFIRE,
        NormalColor = glowAllNormal..'ff2c2c',
        SelectColor = glowAllSelect..'ff5253',
        RolloverColor = glowAllOver..'ff6363',
        Inner = innerMilAll,
        Outer = outerMilAll,
        Type = 1,
        Combo = true,
        Tooltip = "overlay_combine_military",
    },
    AntiAir = {
        key = 'antiair',
        Label = '<LOC range_0000>Anti-Air',
        Categories = categories.OVERLAYANTIAIR,
        NormalColor = glowMilNormal..'29def2',
        SelectColor = glowMilSelect..'52eafc',
        RolloverColor = glowMilOver..'63efff',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_anti_air",
    },
    AntiNavy = {
        key = 'antinavy',
        Label = '<LOC range_0001>Anti-Navy',
        Categories = categories.OVERLAYANTINAVY,
        NormalColor = glowMilNormal..'7af229',
        SelectColor = glowMilSelect..'96fb52',
        RolloverColor = glowMilOver..'a2ff63',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_anti_navy",
    },
    Defense = {
        key = 'defense',
        Label = '<LOC range_0002>Countermeasure',
        Categories = categories.OVERLAYCOUNTERMEASURE + categories.OVERLAYDEFENSE,
        NormalColor = glowMilNormal..'ff8a2c',
        SelectColor = glowMilSelect..'ffa053',
        RolloverColor = glowMilOver..'ffa963',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_defenses",
    },
    DirectFire = {
        key = 'directfire',
        Label = '<LOC range_0003>Direct Fire',
        Categories = categories.OVERLAYDIRECTFIRE,
        NormalColor = glowMilNormal..'ff2c2c',
        SelectColor = glowMilSelect..'ff5253',
        RolloverColor = glowMilOver..'ff6363',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_direct_fire",
    },
    IndirectFire = {
        key = 'indirectfire',
        Label = '<LOC range_0005>Indirect Fire',
        Categories = categories.OVERLAYINDIRECTFIRE,
        NormalColor = glowMilNormal..'f2f029',
        SelectColor = glowMilSelect..'fbf851',
        RolloverColor = glowMilOver..'fffc63',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_indirect_fire",
    },

    Miscellaneous = {
        key = 'miscellaneous',
        Label = '<LOC range_0012>Build Range',
        Categories = categories.OVERLAYMISC,
        NormalColor = glowIntelNormal .. 'b09200',
        SelectColor = glowIntelSelect .. 'bd9c00',
        RolloverColor = glowIntelOver.. 'c9a700',
        Inner = innerMilitary,
        Outer = outerMilitary,
        Type = 1,
        Tooltip = "overlay_misc",
    },

    AllIntel = {
        key = 'allintel',
        Label = '<LOC range_0013>Combine Intel',
        Categories = categories.OVERLAYRADAR * categories.OVERLAYSONAR * categories.OVERLAYOMNI * categories.OVERLAYCOUNTERINTEL,
        NormalColor = glowIntelNormal..'156f79',
        SelectColor = glowIntelSelect..'29757e',
        RolloverColor = glowIntelOver..'327880',
        Inner = innerIntelAll,
        Outer = outerIntelAll,
        Type = 2,
        Combo = true,
        Tooltip = "overlay_combine_intel",
    },
    Radar = {
        key = 'radar',
        Label = '<LOC range_0007>Radar',
        Categories = categories.OVERLAYRADAR,
        NormalColor = glowIntelNormal..'156f79',
        SelectColor = glowIntelSelect..'29757e',
        RolloverColor = glowIntelOver..'327880',
        Inner = innerIntel,
        Outer = outerIntel,
        Type = 2,
        Tooltip = "overlay_radar",
    },
    Sonar = {
        key = 'sonar',
        Label = '<LOC range_0008>Sonar',
        Categories = categories.OVERLAYSONAR,
        NormalColor = glowIntelNormal..'3d7915',
        SelectColor = glowIntelSelect..'4b7e29',
        RolloverColor = glowIntelOver..'518032',
        Inner = innerIntel,
        Outer = outerIntel,
        Type = 2,
        Tooltip = "overlay_sonar",
    },
    Omni = {
        key = 'omni',
        Label = '<LOC range_0009>Omni',
        Categories = categories.OVERLAYOMNI,
        NormalColor = glowIntelNormal..'801616',
        SelectColor = glowIntelSelect..'802a2a',
        RolloverColor = glowIntelOver..'803232',
        Inner = innerIntel,
        Outer = outerIntel,
        Type = 2,
        Tooltip = "overlay_omni",
    },
    CounterIntel = {
        key = 'counterintel',
        Label = '<LOC range_0010>Counter Intelligence',
        Categories = categories.OVERLAYCOUNTERINTEL,
        NormalColor = glowIntelNormal..'804516',
        SelectColor = glowIntelSelect..'80502a',
        RolloverColor = glowIntelOver..'805532',
        Inner = innerIntel,
        Outer = outerIntel,
        Type = 2,
        Tooltip = "overlay_counter_intel",
    },
}
