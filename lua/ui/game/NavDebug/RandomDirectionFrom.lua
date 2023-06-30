
--**********************************************************************************
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
--**********************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Window = import("/lua/maui/window.lua").Window
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

local Shared = import("/lua/shared/navgenerator.lua")

local Instance = nil

---@class UINavUtilsRandomDirectionFrom : Window
---@field State NavDebugRandomDirectionFromState
UINavUtilsRandomDirectionFrom = ClassUI(Window) {
    __init = function(self, parent)
        Window.__init(self, parent, "NavUtils - Random Direction From", false, false, false, true, false, "NavRandomDirectionFrom02", {
            Left = 10,
            Top = 300,
            Right = 330,
            Bottom = 460
        })

        self.State = {
            Layer = 'Land',
            Distance = 30,
            Threshold = 4,
        }

        do
            self.LabelLayer = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'For layer:', 10, UIUtil.bodyFont))
                :AtLeftTopIn(self, 16, 36)
                :Over(self, 10)
                :End()

            self.ComboLayer = LayoutHelpers.LayoutFor(Combo(self, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01"))
                :Below(self.LabelLayer, 6)
                :Over(self, 10)
                :Width(100)
                :End() --[[@as Combo]]

            self.ComboLayer:AddItems(Shared.Layers)
            self.ComboLayer:SetItem(1)
            self.State.Layer = Shared.Layers[1]
            self.ComboLayer.OnClick = function(combo, index, text)
                self.State.Layer = Shared.Layers[index]
                SimCallback({Func = 'NavDebugUpdateRandomDirectionFrom', Args = self.State })
            end
        end

        do
            self.Distance = LayoutHelpers.LayoutFor(IntegerSlider(self, false, 1, 128, 1))
                :Below(self.LabelLayer, 40)
                :Over(self, 10)
                :End()

            self.Distance.OnValueChanged = function(slider, value)
                self.LabelDistance:SetText(string.format("Distance: %d", value))
                self.State.Distance = value
                SimCallback({Func = 'NavDebugUpdateRandomDirectionFrom', Args = self.State })
            end

            self.LabelDistance = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Distance: 0', 10, UIUtil.bodyFont))
                :Above(self.Distance)
                :Over(self, 10)
                :End()

            self.Distance:SetValue(self.State.Distance)
        end

        do
            self.Threshold = LayoutHelpers.LayoutFor(IntegerSlider(self, false, 1, 128, 1))
                :Below(self.Distance, 10)
                :Over(self, 10)
                :End()

            self.Threshold.OnValueChanged = function(slider, value)
                self.LabelThreshold:SetText(string.format("Cell size threshold: %d", value))
                self.State.Threshold = value
                SimCallback({Func = 'NavDebugUpdateRandomDirectionFrom', Args = self.State })
            end

            self.LabelThreshold = LayoutHelpers.LayoutFor(UIUtil.CreateText(self, 'Cell size threshold: 0', 10, UIUtil.bodyFont))
                :Above(self.Threshold)
                :Over(self, 10)
                :End()

            self.Threshold:SetValue(self.State.Threshold)
        end

        self:SetAlpha(0.8)
    end,

    OnClose = function(self)
        SimCallback({Func = 'NavDebugDisableRandomDirectionFrom', Args = { }})
        self:Hide()
    end,
}

function OpenWindow()
    if Instance then
        Instance:Show()
    else
        Instance = UINavUtilsRandomDirectionFrom(GetFrame(0))
        Instance:Show()
    end

    SimCallback({Func = 'NavDebugEnableRandomDirectionFrom', Args = { }})
end

function CloseWindow()
    if Instance then
        Instance:OnClose()
    end
end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Instance then
        Instance:Destroy()
    end
end
