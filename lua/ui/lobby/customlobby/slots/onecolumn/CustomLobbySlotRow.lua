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

-- The thin slot presentation: one full-width, single-line row used by the one-column layout —
--
--   1  ▣  PlayerName                          Cybran  ▢ 1.4k  T1  ready
--
-- It is pure arrangement over CustomLobbySlotBase: it builds the widgets, lays them out in a row,
-- and assigns the base's normalised player / CPU views to them. All behaviour (subscriptions, CPU
-- math, drag-to-swap, intents) lives in the base.

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local CustomLobbySlotBase = import("/lua/ui/lobby/customlobby/slots/customlobbyslotbase.lua").SlotBase

local Layouter = LayoutHelpers.ReusedLayoutFor

---@class UICustomLobbySlotRow : UICustomLobbySlotBase
---@field SlotNumber Text
---@field ColorSwatch Bitmap
---@field Name Text
---@field Faction Text
---@field Cpu Text
---@field CpuIndicator Bitmap
---@field Team Text
---@field Ready Text
---@field CpuHover Bitmap
local CustomLobbySlotRow = Class(CustomLobbySlotBase) {

    ---@param self UICustomLobbySlotRow
    CreateContents = function(self)
        self.SlotNumber = UIUtil.CreateText(self, tostring(self.SlotIndex), 14, UIUtil.bodyFont)
        self.ColorSwatch = Bitmap(self)
        self.ColorSwatch:SetSolidColor('00000000')
        self.Name = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Faction = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Cpu = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        -- a small square left of the CPU label: green when the machine sustains the
        -- recommended unit cap at full speed, fading to red the more the sim must slow
        self.CpuIndicator = Bitmap(self)
        self.CpuIndicator:SetSolidColor('ff7ad97a')
        self.CpuIndicator:SetAlpha(0.0)
        self.CpuIndicator:DisableHitTest()
        self.Team = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)
        self.Ready = UIUtil.CreateText(self, "", 14, UIUtil.bodyFont)

        -- a hover zone over the CPU score; the base routes enter/exit/press
        self.CpuHover = Bitmap(self)
        self.CpuHover:SetSolidColor('00000000')
        self.CpuHover.HandleEvent = function(control, event)
            return self:HandleCpuHoverEvent(event)
        end
    end,

    ---@param self UICustomLobbySlotRow
    LayoutContents = function(self)
        Layouter(self.SlotNumber):AtLeftIn(self, 6):AtVerticalCenterIn(self):End()
        Layouter(self.ColorSwatch):AnchorToRight(self.SlotNumber, 8):AtVerticalCenterIn(self):Width(14):Height(14):End()
        Layouter(self.Name):AnchorToRight(self.ColorSwatch, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Ready):AtRightIn(self, 8):AtVerticalCenterIn(self):End()
        Layouter(self.Team):AnchorToLeft(self.Ready, 12):AtVerticalCenterIn(self):End()
        Layouter(self.Cpu):AnchorToLeft(self.Team, 12):AtVerticalCenterIn(self):End()
        Layouter(self.CpuIndicator):AnchorToLeft(self.Cpu, 5):AtVerticalCenterIn(self):Width(8):Height(12):End()
        Layouter(self.Faction):AnchorToLeft(self.CpuIndicator, 10):AtVerticalCenterIn(self):End()

        Layouter(self.CpuHover):Fill(self.Cpu):Over(self, 20):End()
    end,

    ---@param self UICustomLobbySlotRow
    ---@param view UICustomLobbySlotPlayerView | nil
    RenderPlayer = function(self, view)
        if not view then
            self.ColorSwatch:SetSolidColor('00000000')
            self.Name:SetText("- open -")
            self.Name:SetColor('ff888888')
            self.Faction:SetText("")
            self.Team:SetText("")
            self.Ready:SetText("")
            return
        end

        self.ColorSwatch:SetSolidColor(view.colorHex)
        self.Name:SetText(view.name)
        self.Name:SetColor(view.nameColor)
        self.Faction:SetText(view.faction)
        self.Team:SetText(view.team)
        self.Ready:SetText(view.ready)
        self.Ready:SetColor(view.readyColor)
    end,

    ---@param self UICustomLobbySlotRow
    ---@param view UICustomLobbySlotCpuView | nil
    RenderCpu = function(self, view)
        if not view then
            self.Cpu:SetText("")
            self.CpuIndicator:SetAlpha(0.0)
            return
        end

        self.Cpu:SetText(view.text)
        self.Cpu:SetColor(view.textColor)
        if view.showIndicator then
            self.CpuIndicator:SetSolidColor(view.indicatorColor)
            self.CpuIndicator:SetAlpha(1.0)
        else
            self.CpuIndicator:SetAlpha(0.0)
        end
    end,
}

---@param parent Control
---@param slotIndex number
---@param coordinator UICustomLobbySlotCoordinator
---@return UICustomLobbySlotRow
Create = function(parent, slotIndex, coordinator)
    return CustomLobbySlotRow(parent, slotIndex, coordinator)
end
