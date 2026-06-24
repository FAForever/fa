--******************************************************************************************************
--** Copyright (c) 2026 FAForever
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

-- The fat slot presentation: a half-width, double-height card used by the two-column team layout.
-- The same data as the thin row, reflowed onto two lines so it reads in a narrow column —
--
--   ┌──────────────────────────┐
--   │ ▣  PlayerName       ready │   line 1: colour swatch · name · ready
--   │ Cybran · T1       1.4k ▢  │   line 2: faction · team · cpu (+ headroom square)
--   └──────────────────────────┘
--
-- It is pure arrangement over CustomLobbySlotBase: it builds the standard named controls and lays
-- them out; the base paints them and owns all behaviour (subscriptions, CPU math, drag-to-swap,
-- intents).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbySlotBase = import("/lua/ui/lobby/customlobby/slots/customlobbyslotbase.lua").SlotBase

local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbySlotCard : UICustomLobbySlotBase
---@field ColorSwatch Bitmap
---@field Name Text
---@field Ready Text
---@field Faction Text
---@field Team Text
---@field Cpu Text
---@field CpuIndicator Bitmap
---@field CpuHover Bitmap
local CustomLobbySlotCard = Class(CustomLobbySlotBase) {

    ---@param self UICustomLobbySlotCard
    CreateContents = function(self)
        self.ColorSwatch = Bitmap(self)
        self.ColorSwatch:SetSolidColor('00000000')
        self.Name = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Ready = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Faction = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Team = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.Cpu = UIUtil.CreateText(self, "", 12, UIUtil.bodyFont)
        self.CpuIndicator = Bitmap(self)
        self.CpuIndicator:SetSolidColor('ff7ad97a')
        self.CpuIndicator:SetAlpha(0.0)
        self.CpuIndicator:DisableHitTest()

        -- a hover zone over the CPU score; the base routes enter/exit/press
        self.CpuHover = Bitmap(self)
        self.CpuHover:SetSolidColor('00000000')
        self.CpuHover.HandleEvent = function(control, event)
            return self:HandleCpuHoverEvent(event)
        end
    end,

    ---@param self UICustomLobbySlotCard
    LayoutContents = function(self)
        -- line 1 (top): swatch · name … ready
        Layouter(self.ColorSwatch):AtLeftIn(self, 6):AtTopIn(self, 7):Width(14):Height(14):End()
        Layouter(self.Name):AnchorToRight(self.ColorSwatch, 6):AtVerticalCenterIn(self.ColorSwatch):End()
        Layouter(self.Ready):AtRightIn(self, 6):AtVerticalCenterIn(self.ColorSwatch):End()

        -- line 2 (bottom): faction · team … [indicator] cpu
        Layouter(self.Faction):AtLeftIn(self, 6):AtBottomIn(self, 7):End()
        Layouter(self.Team):AnchorToRight(self.Faction, 8):AtVerticalCenterIn(self.Faction):End()
        Layouter(self.Cpu):AtRightIn(self, 6):AtVerticalCenterIn(self.Faction):End()
        Layouter(self.CpuIndicator):AnchorToLeft(self.Cpu, 5):AtVerticalCenterIn(self.Faction):Width(8):Height(12):End()

        Layouter(self.CpuHover):Fill(self.Cpu):Over(self, 20):End()
    end,
}

---@param parent Control
---@param slotIndex number
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbySlotCard
Create = function(parent, slotIndex, coordinator)
    return CustomLobbySlotCard(parent, slotIndex, coordinator)
end
