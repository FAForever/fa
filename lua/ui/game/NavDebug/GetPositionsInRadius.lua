
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

---@class UINavUtilsGetPositionsInRadius : Window
---@field State NavDebugGetPositionsInRadiusState
UINavUtilsGetPositionsInRadius = ClassUI(Window) {
    __init = function(self, parent)
        Window.__init(self, parent, "NavUtils - Get Positions in Radius", false, false, false, true, false, "NavGetPositionsInRadius02", {
            Left = 10,
            Top = 300,
            Right = 330,
            Bottom = 430
        })

        self.State = {
            Layer = 'Land',
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
                SimCallback({Func = 'NavDebugUpdateGetPositionsInRadius', Args = self.State })
            end
        end

        self:SetAlpha(0.8)
    end,

    OnClose = function(self)
        SimCallback({Func = 'NavDebugDisableGetPositionsInRadius', Args = { }})
        self:Hide()
    end,
}

function OpenWindow()
    if Instance then
        Instance:Show()
    else
        Instance = UINavUtilsGetPositionsInRadius(GetFrame(0))
        Instance:Show()
    end

    SimCallback({Func = 'NavDebugEnableGetPositionsInRadius', Args = { }})
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
