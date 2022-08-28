
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local LazyVar = import('/lua/Lazyvar.lua').Create

-- # locals

local scenario = SessionGetScenarioInfo()

ScoreboardHeader = Class(Group) {

    __init = function(header, scoreboard, debug)
        Group.__init(header, scoreboard, "scoreboard-header")

        -- # Setup lazy vars

        header.time = LazyVar(0)

        header.simSpeed = LazyVar(0)
        header.simSpeedDesired = LazyVar(0)
    
        header.unitData = LazyVar({
            Count = 0, 
            Cap = 0,
        })

        -- # Setup UI

        LayoutHelpers.LayoutFor(header)
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(scoreboard.Top)        -- dummy value
            :Height(60)
            :End()

        header.debug = LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(header)
            :Color('44ff0000')
            :End()

        -- # Setup UI: time

        header.timeIcon = LayoutHelpers.LayoutFor(
            Bitmap(header))
            :Texture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
            :AtLeftIn(header, 2)
            :AtTopIn(header, 2)
            :Width(14)
            :Height(14)
            :Over(scoreboard, 10)
            :End()

        header.timeText = LayoutHelpers.LayoutFor(
            UIUtil.CreateText(header, "",  12, UIUtil.bodyFont)) 
            :RightOf(header.timeIcon, 2)
            :AtTopIn(header, 2)
            :Color('ff00dbff')
            :Over(scoreboard, 10)
            :End()

        header.time.OnDirty = function(self)
            header.timeText:SetText(self())
        end

        -- # Setup UI: unit statistics

        header.unitIcon = LayoutHelpers.LayoutFor(
            Bitmap(scoreboard))
            :Texture(UIUtil.UIFile('/dialogs/score-overlay/tank_bmp.dds'))
            :AtRightIn(header, 2)
            :AtTopIn(header, 2)
            :Width(28)
            :Height(14)
            :Over(scoreboard, 10)
            :End()

        header.unitText = LayoutHelpers.LayoutFor(
            UIUtil.CreateText(header, "",  12, UIUtil.bodyFont))
            :LeftOf(header.unitIcon, 2)
            :AtTopIn(header, 2)
            :Color('ff00dbff')
            :Over(scoreboard, 10)
            :End()

        header.unitData.OnDirty = function(self)
            local data = self()
            header.unitText:SetText(string.format("%d/%d", data.Count or 0, data.Cap or 0))
        end

        -- # Setup UI: icons

        local massIcon = LayoutHelpers.LayoutFor(Bitmap(header))
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :AtRightIn(header, 100)
            :AtTopIn(header, 42)
            :Width(16)
            :Height(16)
            :Over(scoreboard, 10)
            :End()

        local energyIcon = LayoutHelpers.LayoutFor(Bitmap(header))
            :Texture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            :AtRightIn(header, 50)
            :AtTopIn(header, 42)
            :Width(16)
            :Height(16)
            :Over(scoreboard, 10)
            :End()

        local statusText = LayoutHelpers.LayoutFor(
            UIUtil.CreateText(header, "income",  12, UIUtil.bodyFont))
            :AtRightIn(header, 50)
            :AtTopIn(header, 22)
            :Over(scoreboard, 10)
            :End()

        -- # initial sane values 

        header.time:Set(GetGameTime())
        header.simSpeed:Set(0)
        header.simSpeedDesired:Set(0)
        header.unitData:Set({
            Count = 0,
            Cap = scenario.Options.UnitCap,
        })
    end,

    UpdateTime = function(header, value)
        header.time:Set(value)
    end,

    UpdateUnitData = function(header, count, cap)
        local data = header.unitData()
        data.Count = count 
        data.Cap = cap 
        header.unitData:Set(data)
    end,

}