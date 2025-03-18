
--******************************************************************************************************
--** Copyright (c) 2022  Willem 'Jip' Wijnia
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

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo = import("/lua/ui/controls/combo.lua").Combo
local Edit = import("/lua/maui/edit.lua").Edit
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

local Shared = import("/lua/shared/navgenerator.lua")

local Root = nil
local DebugInterface = false

---@alias NavUIStates 'overview' | 'actions'

---@class NavUIOverview : Group
NavUIOverview = ClassUI(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIOverview')
    end
}

---@class NavUIPathTo : Group
---@field State NavDebugGetLabelState
NavUIGetLabel = ClassUI(Group) {
    __init = function (self, parent)
        local name = 'NavUIGetLabel'
        Group.__init(self, parent, name)

        self.State = { }

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77999999')
            :DisableHitTest(true)
            :End()

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Debug \'GetLabel\'', 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End() --[[@as Text]]


        self.ButtonPosition = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Position"))
            :AtLeftBottomIn(self.Background, -5, 5)
            :Over(self, 1)
            :End()

        self.ButtonPosition.OnClick = function()

            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Position = command.Target.Position
                        SimCallback({Func = 'NavDebugGetLabel', Args = self.State })
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonPosition)
            :Top(function() return self.ButtonPosition.Top() + LayoutHelpers.ScaleNumber(6) end)
            :Over(self, 1)
            :End()

        self.ComboLayer = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :RightOf(self.ButtonPosition)
            :Top(function() return self.ButtonPosition.Top() + LayoutHelpers.ScaleNumber(18) end)
            :Width(100)
            :End() --[[@as Combo]]

        self.ComboLayer:AddItems(Shared.Layers)
        self.ComboLayer:SetItem(1)
        self.State.Layer = Shared.Layers[1]
        self.ComboLayer.OnClick = function(combo, index, text)
            self.State.Layer = Shared.Layers[index]
            SimCallback({Func = 'NavDebugGetLabel', Args = self.State })
        end

        self.ButtonRerun = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Rerun"))
            :RightOf(self.ComboLayer)
            :Top(self.ButtonPosition.Top)
            :Over(self, 1)
            :End()

        self.ButtonRerun.OnClick = function()
            SimCallback({Func = 'NavDebugGetLabel', Args = self.State })
        end

        self.ButtonReset = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Reset"))
            :RightOf(self.ButtonRerun, -20)
            :Over(self, 1)
            :End()

        self.ButtonReset.OnClick = function()
            self.State.Position = nil
            SimCallback({Func = 'NavDebugGetLabel', Args = self.State})
        end

        AddOnSyncCallback(
            function(Sync)
                if Sync.NavDebugGetLabel then
                    local data = Sync.NavDebugGetLabel
                    if data.Label then
                        self.Title:SetText(string.format('Debug \'GetLabel\': %s', tostring(data.Label)))
                    else
                        self.Title:SetText(string.format('Debug \'GetLabel\': %s (%s)', tostring(data.Label), data.Msg))
                    end
                end
            end, name
        )
    end,
}

---@class NavUIPathTo : Group
---@field State NavDebugGetLabelState
NavUIGetLabelMetadata = ClassUI(Group) {
    __init = function (self, parent)
        local name = 'NavUIGetLabelMetadata'
        Group.__init(self, parent, name)

        self.State = { Id = 1.0 }

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77999999')
            :DisableHitTest(true)
            :End()

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Debug \'GetLabelMetadata\'', 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End() --[[@as Text]]

        self.ButtonPosition = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Query for label"))
            :AtLeftBottomIn(self.Background, -5, 5)
            :Over(self, 1)
            :End()

        self.ButtonPosition.OnClick = function()
            SimCallback({ Func = 'NavDebugGetLabelMetadata', Args = self.State })
        end

        self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonPosition)
            :Top(function() return self.ButtonPosition.Top() - LayoutHelpers.ScaleNumber(4) end)
            :Over(self, 1)
        :End()

        self.Edit = LayoutHelpers.LayoutFor(Edit(self))
            :RightOf(self.ButtonPosition)
            :Top(function() return self.ButtonPosition.Top() + LayoutHelpers.ScaleNumber(14) end)
            :Width(50)
            :Height(20)
            :End() --[[@as Edit]]

        self.Edit.OnTextChanged = function (_, new, old)
            self.State.Id = tonumber(new) or -1
        end

        self.Group = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.Edit.Right() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.Background.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.Background.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Background.Bottom() - LayoutHelpers.ScaleNumber(10) end)
            :End() --[[@as Group]]

        self.TextArea = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Area: ', 10, UIUtil.bodyFont))
            :Left(function() return self.Group.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.Group.Top() + LayoutHelpers.ScaleNumber(14) end)
            :End() --[[@as Text]]

        self.TextLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Layer: ', 10, UIUtil.bodyFont))
            :Left(function() return self.Group.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.TextArea.Bottom() + LayoutHelpers.ScaleNumber(4) end)
            :End() --[[@as Text]]

        self.TextNumberOfExtractors = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Number of extractors: ', 10, UIUtil.bodyFont))
            :Left(function() return self.Group.Left() + LayoutHelpers.ScaleNumber(100) end)
            :Top(function() return self.Group.Top() + LayoutHelpers.ScaleNumber(14) end)
            :End() --[[@as Text]]

        self.TextNumberOfHydrocarbons = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Number of hydrocarbons: ', 10, UIUtil.bodyFont))
            :Left(function() return self.Group.Left() + LayoutHelpers.ScaleNumber(100) end)
            :Top(function() return self.TextNumberOfExtractors.Bottom() + LayoutHelpers.ScaleNumber(4) end)
            :End() --[[@as Text]]

        AddOnSyncCallback(
            function(Sync)
                if Sync.NavDebugGetLabelMetadata then
                    local response = Sync.NavDebugGetLabelMetadata

                    ---@type NavLabelMetadata
                    local data = response.data
                    if data then
                        self.Title:SetText(string.format('Debug \'GetLabelMetadata\': %s', 'ok'))
                        self.TextArea:SetText(string.format('Area: %f', data.Area))
                        self.TextLayer:SetText(string.format('Layer: %s', data.Layer))
                        self.TextNumberOfExtractors:SetText(string.format('Number of extractors: %d', data.NumberOfExtractors))
                        self.TextNumberOfHydrocarbons:SetText(string.format('Number of hydrocarbons: %d', data.NumberOfHydrocarbons))
                    else 
                        self.Title:SetText(string.format('Debug \'GetLabelMetadata\': %s', response.msg))
                    end
                end
            end, name
        )
    end,
}

---@class NavUIPathTo : Group
---@field State NavDebugCanPathToState
NavUIPathTo = ClassUI(Group) {
    ---@param self NavUIPathTo
    ---@param parent Control
    __init = function (self, parent)
        local name = 'NavUIPathTo'
        Group.__init(self, parent, name)

        self.State = {}

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77999999')
            :DisableHitTest(true)
            :End()

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Debug \'PathTo\'', 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End() --[[@as Text]]


        self.ButtonOrigin = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Origin"))
            :AtLeftBottomIn(self.Background, -5, 5)
            :Over(self, 1)
            :End()

        self.ButtonOrigin.OnClick = function()

            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Origin = command.Target.Position
                        SimCallback({Func = 'NavDebugPathTo', Args = self.State })
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.ButtonDestination = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Destination"))
            :RightOf(self.ButtonOrigin, -20)
            :Over(self, 1)
            :End()

        self.ButtonDestination.OnClick = function()
            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Destination = command.Target.Position
                        SimCallback({Func = 'NavDebugPathTo', Args = self.State })
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(6) end)
            :Over(self, 1)
            :End()

        self.ComboLayer = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(18) end)
            :Width(100)
            :End() --[[@as Combo]]

        self.ComboLayer:AddItems(Shared.Layers)
        self.ComboLayer:SetItem(1)
        self.State.Layer = Shared.Layers[1]
        self.ComboLayer.OnClick = function(combo, index, text)
            self.State.Layer = Shared.Layers[index]
            SimCallback({Func = 'NavDebugPathTo', Args = self.State })
        end

        self.ButtonRerun = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Rerun"))
            :RightOf(self.ComboLayer)
            :Top(self.ButtonDestination.Top)
            :Over(self, 1)
            :End()

        self.ButtonRerun.OnClick = function()
            SimCallback({Func = 'NavDebugPathTo', Args = self.State })
        end

        self.ButtonReset = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Reset"))
            :RightOf(self.ButtonRerun, -20)
            :Over(self, 1)
            :End()

        self.ButtonReset.OnClick = function()
            self.State.Origin = nil
            self.State.Destination = nil
            SimCallback({Func = 'NavDebugPathTo', Args = self.State})
        end
    end,
}

---@class NavUIPathToWithThreatThreshold : Group
---@field State NavDebugPathToStateWithThreatThreshold
NavUIPathToWithThreatThreshold = ClassUI(Group) {

    ---@param self NavUIPathToWithThreatThreshold
    ---@param parent Control
    __init = function (self, parent)
        local name = 'NavUIPathToWithThreatThreshold'
        Group.__init(self, parent, name)

        self.State = { 
            Layer = 'Land',
            Radius = 0,
            ThreatFunctionName = 'AntiSurface',
            Threshold = 0,
        }

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77999999')
            :DisableHitTest(true)
            :End()

        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Debug \'PathToWithThreatThreshold\'', 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End() --[[@as Text]]


        self.ButtonOrigin = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Origin"))
            :AtLeftBottomIn(self.Background, -5, 5)
            :Over(self, 1)
            :End()

        self.ButtonOrigin.OnClick = function()

            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Army = GetFocusArmy()
                        self.State.Origin = command.Target.Position
                        SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.ButtonDestination = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Destination"))
            :RightOf(self.ButtonOrigin, -20)
            :Over(self, 1)
            :End()

        self.ButtonDestination.OnClick = function()
            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Army = GetFocusArmy()
                        self.State.Destination = command.Target.Position
                        SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(8) end)
            :Over(self, 1)
            :End()

        self.ComboLayer = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(20) end)
            :Width(100)
            :End() --[[@as Combo]]

        self.ComboLayer:AddItems(Shared.Layers)
        self.ComboLayer:SetItem(1)
        self.State.Layer = Shared.Layers[1]
        self.ComboLayer.OnClick = function(combo, index, text)
            self.State.Army = GetFocusArmy()
            self.State.Layer = Shared.Layers[index]
            SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
        end

        self.LabelThreatFunction = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For threat function:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() - LayoutHelpers.ScaleNumber(22) end)
            :Over(self, 1)
            :End()

        self.ComboThreatFunction = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() - LayoutHelpers.ScaleNumber(10) end)
            :Width(100)
            :End() --[[@as Combo]]

        self.ComboThreatFunction:AddItems(Shared.ThreatFunctionsList)
        self.ComboThreatFunction:SetItem(1)
        self.State.ThreatFunctionName = Shared.ThreatFunctionsList[1]
        self.ComboThreatFunction.OnClick = function(combo, index, text)
            self.State.Army = GetFocusArmy()
            self.State.ThreatFunctionName = text
            SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
        end

        self.Radius = LayoutHelpers.LayoutFor(IntegerSlider(self, false, 0, 8, 1))
            :RightOf(self.ComboLayer, 10)
            :Over(self, 1)
            :End()

        self.Radius.OnValueChanged = function(slider, value)
            self.LabelRadius:SetText(string.format("Radius: %d", value))
            self.State.Radius = value
            self.State.Army = GetFocusArmy()
            SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
        end

        self.LabelRadius = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Radius: 0', 10, UIUtil.bodyFont))
            :Above(self.Radius)
            :Over(self, 1)
            :End()

        self.ThreatThreshold = LayoutHelpers.LayoutFor(IntegerSlider(self, false, 0, 1000, 10))
            :RightOf(self.ComboThreatFunction, 10)
            :Over(self, 1)
            :End()

        self.ThreatThreshold.OnValueChanged = function(slider, value)
            self.LabelThreatThreshold:SetText(string.format("Threat threshold: %d", value))
            self.State.Army = GetFocusArmy()
            self.State.Threshold = value
            SimCallback({Func = 'NavDebugPathToWithThreatThreshold', Args = self.State })
        end

        self.LabelThreatThreshold = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Threat threshold: 0', 10, UIUtil.bodyFont))
            :Above(self.ThreatThreshold)
            :Over(self, 1)
            :End()
    end,
}

---@class NavUICanPathTo : Group
---@field State NavDebugCanPathToState
NavUICanPathTo = ClassUI(Group) {
    __init = function (self, parent)
        local name = 'NavUICanPathTo'
        Group.__init(self, parent, name)

        self.State = { }

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77999999')
            :DisableHitTest(true)
            :End()

        ---@type Text
        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Debug \'CanPathTo\'', 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End()


        self.ButtonOrigin = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Origin"))
            :AtLeftBottomIn(self.Background, -5, 5)
            :Over(self, 1)
            :End()

        self.ButtonOrigin.OnClick = function()

            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Origin = command.Target.Position
                        SimCallback({Func = 'NavDebugCanPathTo', Args = self.State})
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.ButtonDestination = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Destination"))
            :RightOf(self.ButtonOrigin, -20)
            :Over(self, 1)
            :End()

        self.ButtonDestination.OnClick = function()
            -- make sure we have nothing selected
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    name = 'uaa0101',

                    --- 
                    ---@param mode CommandModeDataBuild
                    ---@param command any
                    callback = function(mode, command)
                        self.State.Destination = command.Target.Position
                        SimCallback({Func = 'NavDebugCanPathTo', Args = self.State})
                        SelectUnits(selection)
                    end,
                }
            )
        end

        self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(6) end)
            :Over(self, 1)
            :End()

        ---@type Combo
        self.ComboLayer = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
            :RightOf(self.ButtonDestination)
            :Top(function() return self.ButtonDestination.Top() + LayoutHelpers.ScaleNumber(18) end)
            :Width(100)
            :End()

        self.ComboLayer:AddItems(Shared.Layers)
        self.ComboLayer:SetItem(1)
        self.State.Layer = Shared.Layers[1]
        self.ComboLayer.OnClick = function(combo, index, text)
            self.State.Layer = Shared.Layers[index]
            SimCallback({Func = 'NavDebugCanPathTo', Args = self.State})
        end

        self.ButtonRerun = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Rerun"))
            :RightOf(self.ComboLayer)
            :Top(self.ButtonDestination.Top)
            :Over(self, 1)
            :End()

        self.ButtonRerun.OnClick = function()
            SimCallback({Func = 'NavDebugCanPathTo', Args = self.State})
        end

        self.ButtonReset = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self, '/BUTTON/medium/', "Reset"))
            :RightOf(self.ButtonRerun, -20)
            :Over(self, 1)
            :End()

        self.ButtonReset.OnClick = function()
            self.State.Origin = nil
            self.State.Destination = nil
            SimCallback({Func = 'NavDebugCanPathTo', Args = self.State })
        end

        AddOnSyncCallback(
            function(Sync)
                if Sync.NavCanPathToDebug then
                    local data = Sync.NavCanPathToDebug

                    if data.Ok then
                        self.Title:SetText(string.format('Debug \'CanPathTo\': %s', tostring(data.Ok)))
                    else 
                        self.Title:SetText(string.format('Debug \'CanPathTo\': %s (%s)', tostring(data.Ok), data.Msg))
                    end
                end
            end, name
        )
    end,
}

---@class NavUILayerStatistics : Group
NavUILayerStatistics = ClassUI(Group) {
    __init = function(self, parent, layer)
        local name = 'NavUILayerStatistics - ' .. tostring(layer)
        Group.__init(self, parent, 'NavUILayerStatistics - ' .. tostring(layer))

        self.Background = LayoutHelpers.LayoutFor(Bitmap(self))
            :Fill(self)
            :Color('77' .. Shared.LayerColors[layer])
            :DisableHitTest(true)
            :End()

        ---@type Text
        self.Title = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, string.format('Layer: %s', layer), 10, UIUtil.bodyFont))
            :AtLeftTopIn(self, 10, 10)
            :Over(self, 1)
            :End()

        ---@type Text
        self.Subdivisions = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Subdivisions: 0', 11, UIUtil.bodyFont))
            :Below(self.Title, 2)
            :Over(self, 1)
            :End()

        ---@type Text
        self.PathableLeafs = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'PathableLeafs: 0', 11, UIUtil.bodyFont))
            :Below(self.Subdivisions)
            :Over(self, 1)
            :End()

        ---@type Text
        self.UnpathableLeafs = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'UnpathableLeafs: 0', 11, UIUtil.bodyFont))
            :Below(self.PathableLeafs)
            :Over(self, 1)
            :End()

        ---@type Text
        self.Neighbors = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Neighbors: 0', 11, UIUtil.bodyFont))
            :Below(self.UnpathableLeafs)
            :Over(self, 1)
            :End()

        ---@type Text
        self.Labels = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Labels: 0', 11, UIUtil.bodyFont))
            :Below(self.Neighbors)
            :Over(self, 1)
            :End()

        self.ToggleLayerGrid = LayoutHelpers.LayoutFor(UIUtil.CreateButtonStd(self, '/game/nav-ui/toggle-layer-grid/', nil, nil, nil, nil, 'UI_Tab_Click_01', 'UI_Tab_Rollover_01'))
            :AtRightTopIn(self, 2, 16)
            :Width(32)
            :Height(32)
            :Over(self, 1)
            :End()

        self.ToggleLayerGrid.OnClick = function()
            SimCallback({ Func = 'NavToggleScanLayer', Args = { Layer = layer }}, false)
        end

        self.ToggleLabelGrid = LayoutHelpers.LayoutFor(UIUtil.CreateButtonStd(self, '/game/nav-ui/toggle-label-grid/', nil, nil, nil, nil, 'UI_Tab_Click_01', 'UI_Tab_Rollover_01'))
            :Below(self.ToggleLayerGrid, 0)
            :Width(32)
            :Height(32)
            :Over(self, 1)
            :End()

        self.ToggleLabelGrid.OnClick = function()
            SimCallback({ Func = 'NavToggleScanLabels', Args = { Layer = layer }}, false)
        end

        -- tell sim to send the known stats
        SimCallback({
            Func = "NavDebugStatisticsToUI",
            Args = { }
        })

        -- list to sim sending us stats
        AddOnSyncCallback(
            function(Sync)
                if Sync.NavLayerData then
                    ---@type NavLayerData
                    local data = Sync.NavLayerData

                    self.Subdivisions:SetText(string.format('Subdivisions: %d', data[layer].Subdivisions))
                    self.PathableLeafs:SetText(string.format('PathableLeafs: %d', data[layer].PathableLeafs))
                    self.UnpathableLeafs:SetText(string.format('UnpathableLeafs: %d', data[layer].UnpathableLeafs))
                    self.Neighbors:SetText(string.format('Neighbors: %d', data[layer].Neighbors))
                    self.Labels:SetText(string.format('Labels: %d', data[layer].Labels))
                end
            end, name
        )
    end,
}

---@class NavUIActions : Group
NavUIActions = ClassUI(Group) {
    __init = function(self, parent) 
        Group.__init(self, parent, 'NavUIActions')

        self.Debug = LayoutHelpers.LayoutFor(Group(GetFrame(0)))
            :Fill(self)
            :End()

        self.BodyGenerate = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.Left() + LayoutHelpers.ScaleNumber(200) end)
            :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Bottom() - LayoutHelpers.ScaleNumber(10) end)
            :Over(self, 1)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(self.Debug))
            :Fill(self.BodyGenerate)
            :Color('99999999')
            :End()

        self.StatisticsLand = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Land'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.BodyGenerate.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.BodyGenerate.Top() + LayoutHelpers.ScaleNumber(110) end)
            :Over(self, 1)
            :End()

        self.StatisticsAmph = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Amphibious'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsLand.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsLand.Bottom() + LayoutHelpers.ScaleNumber(110) end)
            :Over(self, 1)
            :End()

        self.StatisticsHover = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Hover'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsAmph.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsAmph.Bottom() + LayoutHelpers.ScaleNumber(110) end)
            :Over(self, 1)
            :End()

        self.StatisticsNaval = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Water'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsHover.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsHover.Bottom() + LayoutHelpers.ScaleNumber(110) end)
            :Over(self, 1)
            :End()

        self.StatisticsAir = LayoutHelpers.LayoutFor(NavUILayerStatistics(self, 'Air'))
            :Left(function() return self.BodyGenerate.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyGenerate.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.StatisticsNaval.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.StatisticsNaval.Bottom() + LayoutHelpers.ScaleNumber(110) end)
            :Over(self, 1)
            :End()

        self.ButtonGenerate = LayoutHelpers.LayoutFor(UIUtil.CreateButtonWithDropshadow(self.BodyGenerate, '/BUTTON/medium/', "Generate"))
            :CenteredBelow(self.StatisticsAir, 10)
            :Over(self.BodyGenerate, 1)
            :End()

        self.ButtonGenerate.OnClick = function()
            SimCallback({ Func = 'NavGenerate', Args = { }}, false)
        end

        self.BodyDebug = LayoutHelpers.LayoutFor(Group(self))
            :Left(function() return self.BodyGenerate.Right() + LayoutHelpers.ScaleNumber(20) end)
            :Right(function() return self.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.Bottom() - LayoutHelpers.ScaleNumber(10) end)
            :Over(self, 1)
            :End()

        self.NavUICanPathTo = LayoutHelpers.LayoutFor(NavUICanPathTo(self))
            :Left(function() return self.BodyDebug.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyDebug.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.BodyDebug.Top() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.BodyDebug.Top() + LayoutHelpers.ScaleNumber(85) end)
            :End()

        self.NavUIPathTo = LayoutHelpers.LayoutFor(NavUIPathTo(self))
            :Left(function() return self.BodyDebug.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyDebug.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.NavUICanPathTo.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.NavUICanPathTo.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :End()

        self.NavUIPathToWithThreatThreshold = LayoutHelpers.LayoutFor(NavUIPathToWithThreatThreshold(self))
            :Left(function() return self.BodyDebug.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyDebug.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.NavUIPathTo.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.NavUIPathTo.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :End()

        self.NavUIGetLabel = LayoutHelpers.LayoutFor(NavUIGetLabel(self))
            :Left(function() return self.BodyDebug.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyDebug.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.NavUIPathToWithThreatThreshold.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.NavUIPathToWithThreatThreshold.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :End()

        self.NavUIGetLabelMetadata = LayoutHelpers.LayoutFor(NavUIGetLabelMetadata(self))
            :Left(function() return self.BodyDebug.Left() + LayoutHelpers.ScaleNumber(10) end)
            :Right(function() return self.BodyDebug.Right() - LayoutHelpers.ScaleNumber(10) end)
            :Top(function() return self.NavUIGetLabel.Bottom() + LayoutHelpers.ScaleNumber(10) end)
            :Bottom(function() return self.NavUIGetLabel.Bottom() + LayoutHelpers.ScaleNumber(85) end)
            :End()

        self.Debug:DisableHitTest(true)
        if not DebugInterface then
            self.Debug:Hide()
        end
    end,
}

---@class NavUI : Window
NavUI = ClassUI(Window) {

    __init = function(self, parent)

        -- prepare base class

        Window.__init(self, parent, "NavUI", false, false, false, true, false, "NavUI7", {
            Left = 10,
            Top = 300,
            Right = 830,
            Bottom = 960
        })

        self:SetAlpha(0.8)

        LayoutHelpers.DepthOverParent(self, parent, 1)

        -- prepare this class

        self.Debug = LayoutHelpers.LayoutFor(Group(GetFrame(0)))
            :Fill(self)
            :End()

        self.Header = LayoutHelpers.LayoutFor(Group(self))
            :Left(self.Left)
            :Right(self.Right)
            :Top(self.Top)
            :Bottom(function() return self.Top() + LayoutHelpers.ScaleNumber(25) end)
            :End()

        self.Body = LayoutHelpers.LayoutFor(Group(self))
            :Left(self.Left)
            :Right(self.Right)
            :Top(function() return self.Header.Bottom() + LayoutHelpers.ScaleNumber(4) end)
            :Bottom(self.Bottom)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(self.Debug))
            :Fill(self.Body)
            :Color('9999ff99')
            :End() 

        -- prepare header



        -- prepare body

        -- self.NavUIOverview = LayoutHelpers.LayoutFor(NavUIOverview(self.Body))
        --     :Fill(self.Body)
        --     :End()

        self.NavUIActions = LayoutHelpers.LayoutFor(NavUIActions(self.Body))
            :Fill(self.Body)
            :End()

        self.Debug:DisableHitTest(true)
        if not DebugInterface then
            self.Debug:Hide()
        end
    end,

    ---comment
    ---@param self any
    ---@param identifier any
    SwitchState = function(self, identifier)

    end,

    OnClose = function(self)
        -- SimCallback({Func = 'NavDisableDebugging', Args = { }})
        self:Hide()
    end,
}

function OpenWindow()
    if Root then
        Root:Show()
    else
        Root = NavUI(GetFrame(0))
        Root:Show()
    end

    SimCallback({Func = 'NavEnableDebugging', Args = { }})
end

function CloseWindow()
    if Root then
        Root:OnClose()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Root then
        Root:Destroy()
    end
end